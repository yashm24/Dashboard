import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainMenuPage extends StatelessWidget {
  final String passedPortName;

  const MainMenuPage({super.key, required this.passedPortName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Main Menu',
          style: TextStyle(
            color: Colors.white, // Consistent white color for title text
            fontWeight: FontWeight.bold, // Consistent bold font weight
          ),
        ),
        backgroundColor: const Color(0xFF007AFF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.go('/'); // Navigate back to the homepage
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2,
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                _buildMenuCard(
                  context,
                  icon: Icons.developer_board,
                  title: 'I/O Page',
                  routeName: '/io_page/${Uri.encodeComponent(passedPortName)}',
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.usb,
                  title: 'Port Details',
                  routeName:
                      '/port-details/${Uri.encodeComponent(passedPortName)}',
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.speed,
                  title: 'Melexis Dashboard',
                  routeName:
                      '/throttle-rpm/${Uri.encodeComponent(passedPortName)}',
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor:
          Colors.black, // Consistent background color with the homepage
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String routeName}) {
    return Card(
      color: Colors.grey[900], // Dark background color for the card
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(10.0), // Rounded corners for the card
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(10.0), // Match the card's rounded corners
        splashColor: const Color(0xFF007AFF)
            .withOpacity(0.2), // Splash color for feedback
        onTap: () {
          context.go(routeName);
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon,
                  size: 50,
                  color: const Color(0xFF007AFF)), // Consistent icon color
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Consistent text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
