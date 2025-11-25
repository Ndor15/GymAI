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
  DateTime? repStart;

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
    await ai.load();
    aiReady = true;
    print("✓ AI READY");
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
    if (!aiReady) return;

    // REP LOGIC
    _processReps(az);

    // IA BUFFER
    imuBuffer.add([ax, ay, az, gx, gy, gz]);
    if (imuBuffer.length == 125) {
      _runPrediction();
      imuBuffer.clear();
    }
  }

  void _processReps(double az) {
    if (az > lastAz + 0.25) {
      if (!goingUp) {
        goingUp = true;
        repStart ??= DateTime.now();
      }
    }

    if (goingUp && az < lastAz - 0.25) {
      goingUp = false;
      reps++;

      final repEnd = DateTime.now();
      final duration = repEnd.difference(repStart!).inMilliseconds;

      _emitMetrics(tempo: _tempo(duration));
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
    final out = ai.predict(imuBuffer);
    final idx = out.indexOf(out.reduce((a, b) => a > b ? a : b));
    final ex = idx == 0 ? "curl_biceps" : "curl_marteau";

    _emitMetrics(exercise: ex, confidence: out[idx]);
  }

  // --------------------------------------------------
  // EMIT UI UPDATE
  // --------------------------------------------------
  void _emitMetrics({
    String? exercise,
    String? tempo,
    double? confidence,
  }) {
    _metricsController.add(TrainingMetrics(
      reps: reps,
      tempo: tempo ?? "tempo normal",
      exercise: exercise ?? "détection...",
      confidence: confidence ?? 0,
    ));
  }
}
