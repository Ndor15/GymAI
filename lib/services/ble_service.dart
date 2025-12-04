import 'dart:async';
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

  // REP LOGIC
  int reps = 0;
  bool goingUp = false;
  bool goingDown = false;
  double lastAz = 0;
  bool lastAzInitialized = false;
  DateTime? repStart;
  DateTime? lastRepTime;
  String currentExercise = "détection...";
  double currentConfidence = 0;

  // Smoothing filter for az values (moving average)
  List<double> azBuffer = [];
  final int smoothingWindow = 5; // 5 samples moving average
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
                lastAzInitialized = false;
                goingUp = false;
                repStart = null;
                lastRepTime = null;
                imuBuffer.clear();
                azBuffer.clear();
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
    _processReps(az);

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

  double _smoothAz(double az) {
    // Add new value to buffer
    azBuffer.add(az);

    // Keep only last N samples
    if (azBuffer.length > smoothingWindow) {
      azBuffer.removeAt(0);
    }

    // Return moving average
    return azBuffer.reduce((a, b) => a + b) / azBuffer.length;
  }

  void _processReps(double rawAz) {
    // Apply smoothing filter to reduce noise
    final az = _smoothAz(rawAz);

    // Initialize lastAz with first smoothed value
    if (!lastAzInitialized) {
      lastAz = az;
      lastAzInitialized = true;
      // Emit initial metrics to show UI
      _emitMetrics();
      print("🎯 Rep counter initialized (az baseline: ${az.toStringAsFixed(2)})");
      return;
    }

    final delta = az - lastAz;

    // Detect upward movement (threshold: 2.5 m/s² - adjusted for smoothed data)
    if (delta > 2.5 && !goingUp) {
      goingUp = true;
      repStart = DateTime.now();
      print("⬆️  Going UP (az: ${az.toStringAsFixed(2)}, delta: ${delta.toStringAsFixed(2)})");
    }

    // Detect downward movement = rep completed
    if (goingUp && delta < -2.5) {
      final now = DateTime.now();

      // Check minimum time between reps (600ms minimum for realistic curl)
      if (lastRepTime != null && now.difference(lastRepTime!).inMilliseconds < 600) {
        print("⚠️  Rep too fast, ignored (${now.difference(lastRepTime!).inMilliseconds}ms)");
        goingUp = false;
        repStart = null;
        lastAz = az;
        return;
      }

      // Check minimum rep duration (400ms minimum)
      final duration = now.difference(repStart!).inMilliseconds;
      if (duration < 400) {
        print("⚠️  Rep too short, ignored (${duration}ms)");
        goingUp = false;
        repStart = null;
        lastAz = az;
        return;
      }

      goingUp = false;
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
      print("⬇️  Going DOWN - REP #$reps ✓ (tempo: $tempo, ${duration}ms) [Set: $currentSetReps reps]");
      _emitMetrics(tempo: tempo);
      repStart = null;
    }

    lastAz = az;
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
