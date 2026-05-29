import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/foundation.dart';

/// Manages BLE connections to smart health devices (thermometers, BP cuffs, scales).
class BluetoothService {
  BluetoothService._();
  static final BluetoothService instance = BluetoothService._();

  final StreamController<List<ScanResult>> _scanResultsController =
      StreamController<List<ScanResult>>.broadcast();
  final List<ScanResult> _results = [];
  StreamSubscription? _scanSubscription;
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;

  Stream<List<ScanResult>> get scanResultsStream => _scanResultsController.stream;
  bool get isScanning => _isScanning;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<bool> isAvailable() async {
    try {
      return await FlutterBluePlus.isSupported;
    } catch (e) {
      return false;
    }
  }

  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isScanning) return;
    _results.clear();
    _isScanning = true;

    try {
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _results
          ..clear()
          ..addAll(results);
        _scanResultsController.add(List.unmodifiable(_results));
      });

      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (e) {
      debugPrint('BLE scan error: $e');
    } finally {
      _isScanning = false;
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _isScanning = false;
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      return true;
    } catch (e) {
      debugPrint('BLE connect error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
  }

  Future<List<dynamic>> getServices() async {
    if (_connectedDevice == null) return [];
    try {
      return await _connectedDevice!.discoverServices();
    } catch (e) {
      return [];
    }
  }

  void dispose() {
    stopScan();
    disconnect();
    _scanResultsController.close();
  }
}
