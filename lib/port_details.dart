import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:go_router/go_router.dart';

class PortDetails extends StatelessWidget {
  final String portPassedName;
  const PortDetails({super.key, required this.portPassedName});

  @override
  Widget build(BuildContext context) {
    final String portName = portPassedName.replaceAll('-', '/');
    print('name of the port $portName');

    final SerialPort serialPort = SerialPort(portName);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF007AFF),
        title: Text(
          portName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate to the Main Menu with the correct port name
            context.go('/main-menu/${Uri.encodeComponent(portPassedName)}');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // 2 columns for better spacing
          childAspectRatio: 3, // Adjusts the height of each card
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _informationField(
                'Description', serialPort.description, Icons.description),
            _informationField(
                'Transport', serialPort.transport.toString(), Icons.usb),
            _informationField('USB Bus', serialPort.busNumber?.toString(),
                Icons.account_tree),
            _informationField('USB Device', serialPort.deviceNumber.toString(),
                Icons.devices),
            _informationField('Vendor ID',
                serialPort.vendorId?.toRadixString(16), Icons.label),
            _informationField(
                'Product ID',
                serialPort.productId?.toRadixString(16),
                Icons.production_quantity_limits),
            _informationField(
                'Manufacturer', serialPort.manufacturer, Icons.business),
            _informationField(
                'Product Name', serialPort.productName, Icons.label_important),
            _informationField('Serial Number', serialPort.serialNumber,
                Icons.confirmation_number),
            _informationField('MAC Address', serialPort.macAddress, Icons.wifi),
          ],
        ),
      ),
      backgroundColor: Colors.black, // Consistent background color with the app
    );
  }

  Widget _informationField(String label, String? value, IconData icon) {
    return Card(
      color: Colors.grey[900], // Consistent dark background color for the card
      elevation: 3, // Slight elevation for better visual separation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Rounded corners for the card
      ),
      child: Padding(
        padding: const EdgeInsets.all(
            12.0), // Increased padding for better readability
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    color: const Color(0xFF007AFF)), // Consistent icon color
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white, // White text color for label
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                value ?? 'N/A',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 14,
                  color:
                      Colors.white70, // Slightly lighter white color for value
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
