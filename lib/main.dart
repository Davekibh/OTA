import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent/android_intent.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothScreen(),
    );
  }
}

class BluetoothScreen extends StatefulWidget {
  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? selectedDevice;
  File? selectedFile;
  double uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Devices'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _turnOnBluetooth();
            },
            child: Text('Turn On Bluetooth'),
          ),
          ElevatedButton(
            onPressed: () {
              _scanForDevices();
            },
            child: Text('Scan for Bluetooth Devices'),
          ),
          Expanded(
            child: FutureBuilder<List<BluetoothDevice>>(
              future: _scanForDevices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('No Bluetooth devices found.');
                } else {
                  List<BluetoothDevice> devices = snapshot.data!;
                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      BluetoothDevice device = devices[index];
                      return ListTile(
                        title: Text(device.name ?? 'Unknown Device'),
                        subtitle: Text(device.id.toString()),
                        onTap: () {
                          setState(() {
                            selectedDevice = device;
                          });
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              selectedFile = await _pickFile();
              if (selectedFile != null && selectedDevice != null) {
                _startOTAUpdate(selectedDevice!, selectedFile!);
              } else {
                // Inform the user to select a device and file
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Selection Error'),
                      content:
                          Text('Please select a device and a file for update.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: Text('Select File and Update'),
          ),
          LinearProgressIndicator(value: uploadProgress),
        ],
      ),
    );
  }

  void _turnOnBluetooth() {
    // Open Bluetooth settings using android_intent
    AndroidIntent intent = AndroidIntent(
      action: 'android.settings.BLUETOOTH_SETTINGS',
    );
    intent.launch();
  }

  Future<List<BluetoothDevice>> _scanForDevices() async {
    List<BluetoothDevice> devices = [];

    // Start scanning and listen for results
    await for (ScanResult result
        in flutterBlue.scan(timeout: Duration(seconds: 4))) {
      devices.add(result.device);
    }

    return devices;
  }

  Future<File?> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      return File(result.files.single.path!);
    } else {
      return null;
    }
  }

  void _startOTAUpdate(BluetoothDevice device, File file) async {
    // Simulate file upload progress (replace with actual OTA update logic)
    for (double progress = 0.0; progress <= 1.0; progress += 0.01) {
      await Future.delayed(Duration(milliseconds: 100));
      setState(() {
        uploadProgress = progress;
      });
    }

    // Notify the user that the update is complete
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Complete'),
          content: Text('The update was successfully sent to ${device.name}.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
