import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BeaconScannerPage extends StatefulWidget {
  const BeaconScannerPage({super.key});

  @override
  State<BeaconScannerPage> createState() => _BeaconScannerPageState();
}

class _BeaconScannerPageState extends State<BeaconScannerPage> {
  List<ScanResult> scanResults = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Request location permission
    PermissionStatus locationPermission = await Permission.location.request();

    // Request Bluetooth scan permission
    PermissionStatus bluetoothPermission = await Permission.bluetoothScan.request();

    if (locationPermission.isGranted && bluetoothPermission.isGranted) {
      print("Location and Bluetooth permissions granted.");
      _startScanning();
    } else {
      if (locationPermission.isDenied || bluetoothPermission.isDenied) {
        print("Location or Bluetooth permissions are denied.");
        _showPermissionError();
      } else if (locationPermission.isPermanentlyDenied ||
          bluetoothPermission.isPermanentlyDenied) {
        print("Location or Bluetooth permissions are permanently denied.");
        openAppSettings(); // This will open the app settings page
      }
    }
  }

  Future<void> _startScanning() async {
    // Start scanning for BLE devices
    FlutterBluePlus.startScan(timeout: Duration(seconds: 30));

    // Listen for scan results
    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results; // Update scanResults with new results
      });
      if (results.isNotEmpty) {
        print("Devices found: ${results.length}");
        results.forEach((result) {
          print('Device: ${result.device.platformName}, RSSI: ${result.rssi}');
        });
      } else {
        print("No devices found.");
      }
    });
  }

  void _showPermissionError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Permissions Required"),
          content: const Text(
            "This app requires location and Bluetooth permissions to detect beacons. Please enable them in settings.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bluetooth Beacons",style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.teal, // AppBar color
      ),
      body: scanResults.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.bluetooth, color: Colors.teal),
                    title: Text(
                      result.device.platformName.isNotEmpty
                          ? result.device.platformName
                          : "Unknown device",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      result.device.remoteId.toString(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Text(
                      '${result.rssi} dBm',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                );
              },
            )
          : const Center(child: CircularProgressIndicator(),),
    );
  }
}
