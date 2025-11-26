import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'rep_ai.dart';

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

  // BLE scanning
  Timer? scanTimer;
  BluetoothDevice? connectedDevice;
  bool isConnected = false;

  // --------------------------------------------------
  // START
  // --------------------------------------------------
  void start() {
    _initAI();
    _scanLoop();
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

  void _scanLoop() {
    print("🔍 Starting BLE scan loop...");

    scanTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!isConnected) {
        print("📡 Scanning for $targetName...");
        FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));
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

      // Log buffer progress every 25 samples
      if (imuBuffer.length % 25 == 0) {
        print("📊 ML buffer: ${imuBuffer.length}/125 samples");
      }

      if (imuBuffer.length == 125) {
        print("🔮 Running ML prediction on 125 samples...");
        _runPrediction();
        imuBuffer.clear();
      }
    } else {
      // Log once when ML is not ready
      if (imuBuffer.isEmpty) {
        print("⚠️  ML not ready, skipping buffer (check if model loaded)");
      }
    }
  }

  void _processReps(double az) {
    // Initialize lastAz with first real value
    if (!lastAzInitialized) {
      lastAz = az;
      lastAzInitialized = true;
      // Emit initial metrics to show UI
      _emitMetrics();
      print("🎯 Rep counter initialized (az baseline: $az)");
      return;
    }

    // Detect upward movement (threshold: 3.0 m/s² for better noise filtering)
    if (az > lastAz + 3.0) {
      if (!goingUp) {
        goingUp = true;
        repStart ??= DateTime.now();
        print("⬆️  Going UP (az: $az, lastAz: $lastAz, delta: ${az - lastAz})");
      }
    }

    // Detect downward movement = rep completed
    if (goingUp && az < lastAz - 3.0) {
      final now = DateTime.now();

      // Minimum 800ms between reps to avoid false detections
      if (lastRepTime != null && now.difference(lastRepTime!).inMilliseconds < 800) {
        print("⚠️  Rep too fast, ignored (${now.difference(lastRepTime!).inMilliseconds}ms since last rep)");
        goingUp = false;
        repStart = null;
        lastAz = az;
        return;
      }

      goingUp = false;
      reps++;
      lastRepTime = now;

      final duration = now.difference(repStart!).inMilliseconds;
      final tempo = _tempo(duration);

      print("⬇️  Going DOWN - REP #$reps completed! (tempo: $tempo, duration: ${duration}ms)");
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
      print("📈 ML output: curl_biceps=${(out[0] * 100).toStringAsFixed(1)}%, curl_marteau=${(out[1] * 100).toStringAsFixed(1)}%");

      final idx = out.indexOf(out.reduce((a, b) => a > b ? a : b));
      final ex = idx == 0 ? "curl_biceps" : "curl_marteau";

      // Store current prediction
      currentExercise = ex;
      currentConfidence = out[idx];

      print("🤖 ML Prediction: $ex (confidence: ${(out[idx] * 100).toStringAsFixed(1)}%)");
      _emitMetrics(exercise: ex, confidence: out[idx]);
    } catch (e) {
      print("❌ ML prediction failed: $e");
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
