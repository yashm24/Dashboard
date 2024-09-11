import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:desktop_serial_port_app/serial_port_service.dart';

class IOPage extends StatefulWidget {
  final String passedPortName;

  const IOPage({
    super.key,
    required this.passedPortName,
  });

  @override
  IOPageState createState() => IOPageState();
}

class IOPageState extends State<IOPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SerialPortService().initSerialPort(widget.passedPortName);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the scroll controller
    SerialPortService().dispose(); // Dispose the serial port service
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Read & Write',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF007AFF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context
                .go('/main-menu/${Uri.encodeComponent(widget.passedPortName)}');
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: ValueListenableBuilder<String>(
                valueListenable: SerialPortService().logNotifier,
                builder: (context, logValue, child) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController
                          .jumpTo(_scrollController.position.maxScrollExtent);
                    }
                  });

                  return Text(
                    logValue,
                    style: GoogleFonts.robotoMono(
                      textStyle: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
