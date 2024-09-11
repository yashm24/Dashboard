import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> availablePorts = <String>[];

  @override
  void initState() {
    super.initState();
    initPorts();
  }

  void initPorts() {
    setState(() {
      availablePorts = SerialPort.availablePorts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Home",
          style: TextStyle(
            color: Colors.white, // Make font color white
            fontWeight: FontWeight.bold, // Make font bold
          ),
        ),
        backgroundColor: const Color(0xFF007AFF),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        icon: const Icon(Icons.refresh_sharp),
        label: const Text("Refresh"), // Added label for better accessibility
        onPressed: () {
          initPorts();
        },
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(8.0), // Added padding for better UI spacing
        child: Scrollbar(
          child: ListView.builder(
            itemCount: availablePorts.length,
            itemBuilder: (context, index) {
              final name = availablePorts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Card(
                  color: Colors.black87, // Darker background for the card
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Rounded corners
                  ),
                  elevation: 4.0, // Slight elevation for better visual depth
                  child: ListTile(
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    selectedColor: Colors.white,
                    selectedTileColor: const Color.fromARGB(255, 0, 0, 0),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    leading: const Icon(
                      Icons
                          .usb, // More relevant icon if it represents serial ports
                      color: Colors.white,
                    ),
                    onTap: () {
                      context.go('/main-menu/${Uri.encodeComponent(name)}');
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
