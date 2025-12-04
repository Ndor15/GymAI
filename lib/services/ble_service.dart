import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'rep_ai.dart';
import '../models/workout_models.dart';
import 'workout_history_service.dart';

class TrainingMetrics {
  final int reps;
  final String tempo;
  final String exercise;
  final double confidence;

  TrainingMetrics({
    required this.reps,
    required this.tempo,
    required this.exercise,
    required this.confidence,
  });
}

// State machine for rep detection (simplified to 2 states)
enum RepState { IDLE, MOVING }

class BLEService {
  // Singleton
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  final String targetName = "HalteresBLE";
  final Guid serviceUuid = Guid("FFE0");
  final Guid charUuid = Guid("FFE1");

  // STREAMS
  final _detectedController = StreamController<bool>.broadcast();
  Stream<bool> get onDetected => _detectedController.stream;

  final _metricsController = StreamController<TrainingMetrics>.broadcast();
  Stream<TrainingMetrics> get metricsStream => _metricsController.stream;

  // IA + IMU buffer
  final RepAI ai = RepAI();
  bool aiReady = false;
  List<List<double>> imuBuffer = [];

  // REP LOGIC - Robust system using acceleration magnitude
  int reps = 0;
  String currentExercise = "détection...";
  double currentConfidence = 0;

  // State machine for rep detection
  RepState repState = RepState.IDLE;

  // Acceleration tracking (uses magnitude, not just z-axis)
  List<double> accelMagnitudeBuffer = []; // For smoothing
  final int smoothingWindow = 5; // 5 samples moving average
  double lastAccelMagnitude = 0;
  bool magnitudeInitialized = false;

  // Peak/valley tracking for detecting complete movement cycles
  double currentPeakValue = 0;
  double currentValleyValue = 999;
  DateTime? repStartTime;
  DateTime? lastRepTime;

  // Thresholds FIXES et TRÈS SENSIBLES (repos ~11 m/s²)
  static const double MOVEMENT_START_THRESHOLD = 11.5; // Très sensible
  static const double MOVEMENT_END_THRESHOLD = 11.2; // Hysteresis
  static const double MIN_PEAK_VALUE = 12.5; // Peak bas pour compter facilement
  static const int MIN_REP_DURATION_MS = 200;
  static const int MAX_REP_DURATION_MS = 4000;
  static const int MIN_TIME_BETWEEN_REPS_MS = 300; // Très court

  // Debug counter
  int _sampleCount = 0;

  bool mlNotReadyLogged = false; // Track if we've logged ML not ready

  // BLE scanning
  Timer? scanTimer;
  BluetoothDevice? connectedDevice;
  bool isConnected = false;

  // WORKOUT SESSION
  bool isWorkoutActive = false;
  DateTime? workoutStartTime;
  Timer? sessionTimer;
  Duration sessionDuration = Duration.zero;

  final _sessionDurationController = StreamController<Duration>.broadcast();
  Stream<Duration> get sessionDurationStream => _sessionDurationController.stream;

  final _workoutStateController = StreamController<bool>.broadcast();
  Stream<bool> get workoutStateStream => _workoutStateController.stream;

  // SET TRACKING
  List<WorkoutSet> currentSessionSets = [];
  int currentSetReps = 0;
  List<int> currentSetRepDurations = []; // durations in ms for current set
  Timer? setEndTimer; // Timer to detect end of set (30s no reps)
  DateTime? lastRepInSetTime;

  final _currentSetsController = StreamController<List<WorkoutSet>>.broadcast();
  Stream<List<WorkoutSet>> get currentSetsStream => _currentSetsController.stream;

  final historyService = WorkoutHistoryService();

  // --------------------------------------------------
  // WORKOUT CONTROL
  // --------------------------------------------------
  void startWorkout() {
    if (isWorkoutActive) return;

    print("🏋️ Starting workout session...");
    isWorkoutActive = true;
    workoutStartTime = DateTime.now();
    sessionDuration = Duration.zero;
    _workoutStateController.add(true);

    // Start session timer (update every second)
    sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (workoutStartTime != null) {
        sessionDuration = DateTime.now().difference(workoutStartTime!);
        _sessionDurationController.add(sessionDuration);
      }
    });

    // Initialize AI and start BLE scan
    _initAI();
    _scanLoop();
  }

  void _finalizeCurrentSet() {
    if (currentSetReps == 0) return;

    // Calculate average tempo
    final avgTempo = currentSetRepDurations.isEmpty
        ? 1.0
        : currentSetRepDurations.reduce((a, b) => a + b) /
            currentSetRepDurations.length /
            1000.0; // Convert ms to seconds

    // Create WorkoutSet
    final set = WorkoutSet(
      exercise: currentExercise,
      reps: currentSetReps,
      averageTempo: avgTempo,
      timestamp: DateTime.now(),
    );

    currentSessionSets.add(set);
    _currentSetsController.add(List.from(currentSessionSets));

    print("✅ Set completed: ${set.displayExercise} - $currentSetReps reps @ ${avgTempo.toStringAsFixed(1)}s/rep");

    // Reset current set tracking
    currentSetReps = 0;
    currentSetRepDurations.clear();
    lastRepInSetTime = null;
  }

  void stopWorkout() async {
    if (!isWorkoutActive) return;

    print("🛑 Stopping workout session...");

    // Finalize any ongoing set
    _finalizeCurrentSet();

    // Stop timers
    sessionTimer?.cancel();
    sessionTimer = null;
    setEndTimer?.cancel();
    setEndTimer = null;

    // Stop BLE
    scanTimer?.cancel();
    scanTimer = null;
    FlutterBluePlus.stopScan();

    // Disconnect if connected
    if (isConnected && connectedDevice != null) {
      connectedDevice!.disconnect();
    }

    // Save workout session to history
    if (currentSessionSets.isNotEmpty && workoutStartTime != null) {
      final session = WorkoutSession(
        date: workoutStartTime!,
        duration: sessionDuration,
        sets: List.from(currentSessionSets),
      );

      await historyService.saveSession(session);
      print("💾 Session saved: ${currentSessionSets.length} sets, ${session.totalReps} total reps");
    }

    // Reset state
    isWorkoutActive = false;
    _workoutStateController.add(false);
    currentSessionSets.clear();
    _currentSetsController.add([]);

    // Reset rep counter for next session
    reps = 0;
    _emitMetrics();

    print("✓ Workout stopped. Duration: ${_formatDuration(sessionDuration)}");
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  // --------------------------------------------------
  // START (deprecated - use startWorkout instead)
  // --------------------------------------------------
  void start() {
    // Keep for backward compatibility but prefer startWorkout()
    startWorkout();
  }

  Future<void> _initAI() async {
    try {
      print("🤖 Loading ML model...");
      await ai.load();
      aiReady = true;
      print("✓ AI READY - Model loaded successfully");
    } catch (e) {
      print("❌ ML model failed to load: $e");
      print("⚠️  Rep counting will still work without ML");
    }
  }

  void _scanLoop() async {
    print("🔍 Starting BLE scan loop...");

    // Wait for Bluetooth to be ready before scanning
    print("⏳ Waiting for Bluetooth to be ready...");
    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print("❌ Bluetooth timeout - make sure Bluetooth is ON");
            return BluetoothAdapterState.unknown;
          },
        );

    print("✓ Bluetooth is ready!");

    scanTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!isConnected) {
        print("📡 Scanning for $targetName...");
        try {
          FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));
        } catch (e) {
          print("❌ Scan failed: $e");
        }
      }
    });

    FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        if (r.device.name == targetName) {
          print("✓ Found $targetName (RSSI: ${r.rssi})");
          _detectedController.add(true);

          if (!isConnected) {
            // Stop scan before connecting
            scanTimer?.cancel();
            FlutterBluePlus.stopScan();
            print("⏸️  Scan stopped, connecting...");

            try {
              await r.device.disconnect();
            } catch (_) {}

            await r.device.connect(timeout: const Duration(seconds: 10));
            print("✓ Connected to $targetName");

            connectedDevice = r.device;
            isConnected = true;

            // Listen for disconnection
            r.device.connectionState.listen((state) {
              if (state == BluetoothConnectionState.disconnected) {
                print("❌ Disconnected from $targetName");
                isConnected = false;
                connectedDevice = null;
                _detectedController.add(false); // Update UI

                // Reset counters
                reps = 0;
                repState = RepState.IDLE;
                magnitudeInitialized = false;
                currentPeakValue = 0;
                currentValleyValue = 999;
                repStartTime = null;
                lastRepTime = null;
                imuBuffer.clear();
                accelMagnitudeBuffer.clear();
                currentExercise = "détection...";
                currentConfidence = 0;

                // Restart scan
                _scanLoop();
              }
            });

            await _discoverIMU(r.device);
          }
          return;
        }
      }
      _detectedController.add(false);
    });
  }

  // --------------------------------------------------
  // DISCOVER + SUBSCRIBE
  // --------------------------------------------------
  Future<void> _discoverIMU(BluetoothDevice dev) async {
    print("🔎 Discovering services...");
    final services = await dev.discoverServices();
    print("✓ Found ${services.length} services");

    bool foundService = false;
    bool foundChar = false;

    for (var s in services) {
      print("  Service: ${s.uuid}");
      if (s.uuid == serviceUuid) {
        foundService = true;
        print("  ✓ Found IMU service FFE0");

        for (var c in s.characteristics) {
          print("    Characteristic: ${c.uuid}");
          if (c.uuid == charUuid) {
            foundChar = true;
            print("    ✓ Found IMU characteristic FFE1");

            await c.setNotifyValue(true);
            print("    ✓ Notifications enabled");

            c.lastValueStream.listen(_onDataReceived);
            print("    ✓ Listening for IMU data...");
          }
        }
      }
    }

    if (!foundService) {
      print("❌ ERROR: Service FFE0 not found!");
    }
    if (!foundChar) {
      print("❌ ERROR: Characteristic FFE1 not found!");
    }
  }

  // --------------------------------------------------
  // PARSING IMU DATA
  // --------------------------------------------------
  void _onDataReceived(List<int> bytes) {
    final text = String.fromCharCodes(bytes);
    print("📦 BLE data received: $text");

    // ex: ax=1.23;ay=-0.1;az=9.81;gx=0.04;gy=0.01;gz=0.0
    try {
      final parts = text.split(";");

      double ax = double.parse(parts[0].split("=")[1]);
      double ay = double.parse(parts[1].split("=")[1]);
      double az = double.parse(parts[2].split("=")[1]);
      double gx = double.parse(parts[3].split("=")[1]);
      double gy = double.parse(parts[4].split("=")[1]);
      double gz = double.parse(parts[5].split("=")[1]);

      print("✓ IMU: ax=$ax ay=$ay az=$az gx=$gx gy=$gy gz=$gz");
      onImuSample(ax, ay, az, gx, gy, gz);
    } catch (e) {
      print("❌ Invalid IMU packet: $text (error: $e)");
    }
  }

  // --------------------------------------------------
  // IMU PROCESS → IA + REP LOGIC
  // --------------------------------------------------
  void onImuSample(double ax, double ay, double az, double gx, double gy, double gz) {
    // REP LOGIC - Always run, independent of ML
    // Use all 3 acceleration axes for robust detection
    _processReps(ax, ay, az);

    // IA BUFFER - Only if ML is ready
    if (aiReady) {
      imuBuffer.add([ax, ay, az, gx, gy, gz]);

      // Log buffer progress every 5 samples (window size is 20)
      if (imuBuffer.length % 5 == 0) {
        print("📊 ML buffer: ${imuBuffer.length}/20 samples");
      }

      if (imuBuffer.length == 20) {
        print("🔮 Running ML prediction on 20 samples...");
        print("📊 Sample range - ax:[${imuBuffer.map((s) => s[0]).reduce((a, b) => a < b ? a : b).toStringAsFixed(2)}, ${imuBuffer.map((s) => s[0]).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}], az:[${imuBuffer.map((s) => s[2]).reduce((a, b) => a < b ? a : b).toStringAsFixed(2)}, ${imuBuffer.map((s) => s[2]).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}]");
        _runPrediction();
        imuBuffer.clear();
      }
    } else {
      // Log once when ML is not ready
      if (!mlNotReadyLogged) {
        print("⚠️  ML not ready, skipping buffer (check if model loaded)");
        mlNotReadyLogged = true;
      }
    }
  }

  // Calculate and smooth acceleration magnitude (total movement regardless of orientation)
  double _smoothAccelMagnitude(double ax, double ay, double az) {
    // Calculate magnitude: sqrt(ax² + ay² + az²)
    // This represents total acceleration regardless of device orientation
    final magnitude = math.sqrt(ax * ax + ay * ay + az * az);

    // Add to smoothing buffer
    accelMagnitudeBuffer.add(magnitude);

    // Keep only last N samples
    if (accelMagnitudeBuffer.length > smoothingWindow) {
      accelMagnitudeBuffer.removeAt(0);
    }

    // Return moving average
    return accelMagnitudeBuffer.reduce((a, b) => a + b) / accelMagnitudeBuffer.length;
  }

  void _processReps(double ax, double ay, double az) {
    // Calculate smoothed acceleration magnitude
    final accelMag = _smoothAccelMagnitude(ax, ay, az);

    // Initialize on first sample
    if (!magnitudeInitialized) {
      lastAccelMagnitude = accelMag;
      magnitudeInitialized = true;
      _emitMetrics();
      print("🎯 Rep counter initialized (seuils: START=${MOVEMENT_START_THRESHOLD}, END=${MOVEMENT_END_THRESHOLD}, PEAK_MIN=${MIN_PEAK_VALUE})");
      return;
    }

    final now = DateTime.now();

    // Log magnitude periodically for debugging (every 10 samples)
    _sampleCount++;
    if (_sampleCount % 10 == 0) {
      print("📊 Magnitude: ${accelMag.toStringAsFixed(2)} m/s² [État: ${repState == RepState.IDLE ? 'IDLE' : 'MOVING'}] (seuil START: $MOVEMENT_START_THRESHOLD, END: $MOVEMENT_END_THRESHOLD)");
    }

    // SIMPLIFIED STATE MACHINE - 2 states only
    if (repState == RepState.IDLE) {
      // IDLE -> MOVING: Detect movement start
      if (accelMag > MOVEMENT_START_THRESHOLD) {
        repState = RepState.MOVING;
        repStartTime = now;
        currentPeakValue = accelMag;
        print("🏃 START movement (mag: ${accelMag.toStringAsFixed(2)} m/s²)");
      }
    } else {
      // MOVING state: Track peak and detect end

      // Track peak value during movement
      if (accelMag > currentPeakValue) {
        currentPeakValue = accelMag;
        print("📈 New peak: ${currentPeakValue.toStringAsFixed(2)} m/s²");
      }

      // MOVING -> IDLE: Detect movement end
      if (accelMag < MOVEMENT_END_THRESHOLD) {
        // Movement ended, validate and count rep
        final duration = now.difference(repStartTime!).inMilliseconds;

        print("🏁 END movement (mag: ${accelMag.toStringAsFixed(2)} m/s², peak was: ${currentPeakValue.toStringAsFixed(2)} m/s², duration: ${duration}ms)");

        // Validation checks
        bool isValid = true;
        String? rejectReason;

        // Check 1: Peak must be high enough (significant movement)
        if (currentPeakValue < MIN_PEAK_VALUE) {
          isValid = false;
          rejectReason = "Peak too low (${currentPeakValue.toStringAsFixed(2)} < $MIN_PEAK_VALUE m/s²)";
        }
        // Check 2: Duration must be realistic
        else if (duration < MIN_REP_DURATION_MS) {
          isValid = false;
          rejectReason = "Too fast (${duration}ms < ${MIN_REP_DURATION_MS}ms)";
        }
        else if (duration > MAX_REP_DURATION_MS) {
          isValid = false;
          rejectReason = "Too slow (${duration}ms > ${MAX_REP_DURATION_MS}ms)";
        }
        // Check 3: Time since last rep (avoid double-counting)
        else if (lastRepTime != null && now.difference(lastRepTime!).inMilliseconds < MIN_TIME_BETWEEN_REPS_MS) {
          isValid = false;
          rejectReason = "Too soon after last rep (${now.difference(lastRepTime!).inMilliseconds}ms < ${MIN_TIME_BETWEEN_REPS_MS}ms)";
        }

        if (isValid) {
          // ✅ VALID REP!
          reps++;
          lastRepTime = now;

          // Track rep for current set
          currentSetReps++;
          currentSetRepDurations.add(duration);
          lastRepInSetTime = now;

          // Start/restart 30s timer to detect end of set
          setEndTimer?.cancel();
          setEndTimer = Timer(const Duration(seconds: 30), () {
            print("⏱️  30s without reps - Finalizing set...");
            _finalizeCurrentSet();
          });

          final tempo = _tempo(duration);
          print("✅ REP #$reps COUNTED! (peak: ${currentPeakValue.toStringAsFixed(2)} m/s², tempo: $tempo, ${duration}ms) [Set: $currentSetReps]");
          _emitMetrics(tempo: tempo);
        } else {
          print("⚠️  Rep REJECTED: $rejectReason");
        }

        // Reset for next rep
        repState = RepState.IDLE;
        currentPeakValue = 0;
      }
    }

    lastAccelMagnitude = accelMag;
  }

  String _tempo(int ms) {
    if (ms < 600) return "trop rapide";
    if (ms < 1500) return "tempo normal";
    return "trop lent";
  }

  // --------------------------------------------------
  // IA PREDICTION
  // --------------------------------------------------
  void _runPrediction() {
    try {
      final out = ai.predict(imuBuffer);
      print("📈 ML raw output: [${out[0].toStringAsFixed(4)}, ${out[1].toStringAsFixed(4)}]");
      print("📈 ML percentages: curl_biceps=${(out[0] * 100).toStringAsFixed(1)}%, curl_marteau=${(out[1] * 100).toStringAsFixed(1)}%");

      // Find highest confidence
      final idx = out.indexOf(out.reduce((a, b) => a > b ? a : b));
      final maxConfidence = out[idx];
      final ex = idx == 0 ? "curl_biceps" : "curl_marteau";

      print("🤖 Highest: $ex with confidence ${(maxConfidence * 100).toStringAsFixed(1)}%");

      // Only update if confidence is above threshold (30%)
      if (maxConfidence > 0.30) {
        currentExercise = ex;
        currentConfidence = maxConfidence;
        print("✓ ML Prediction: $ex (confidence: ${(maxConfidence * 100).toStringAsFixed(1)}%)");
        _emitMetrics(exercise: ex, confidence: maxConfidence);
      } else {
        print("⚠️  Confidence too low (${(maxConfidence * 100).toStringAsFixed(1)}%), keeping previous: $currentExercise");
        // Still emit metrics but keep current exercise
        _emitMetrics();
      }
    } catch (e, stackTrace) {
      print("❌ ML prediction failed: $e");
      print("Stack trace: $stackTrace");
    }
  }

  // --------------------------------------------------
  // EMIT UI UPDATE
  // --------------------------------------------------
  void _emitMetrics({
    String? exercise,
    String? tempo,
    double? confidence,
  }) {
    // Update stored values if provided
    if (exercise != null) currentExercise = exercise;
    if (confidence != null) currentConfidence = confidence;

    _metricsController.add(TrainingMetrics(
      reps: reps,
      tempo: tempo ?? "tempo normal",
      exercise: currentExercise,
      confidence: currentConfidence,
    ));
  }
}
