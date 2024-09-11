import 'package:go_router/go_router.dart';
import 'package:desktop_serial_port_app/homepage.dart';
import 'package:desktop_serial_port_app/io_page.dart';
import 'package:desktop_serial_port_app/port_details.dart';
import 'package:desktop_serial_port_app/main_menu.dart';
import 'package:desktop_serial_port_app/throttle_rpm.dart';
import 'package:desktop_serial_port_app/serial_port_service.dart';

class AppRouter {
  // Initialize SerialPortService instance
  static final SerialPortService serialPortService = SerialPortService();

  static final GoRouter returnRouter = GoRouter(
    initialLocation: "/",
    routes: [
      GoRoute(
        name: "Home",
        path: "/",
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        name: "IOPage",
        path: "/io_page/:name",
        builder: (context, state) {
          final String name = state.pathParameters['name']!;
          serialPortService.initSerialPort(name);
          return IOPage(passedPortName: name);
        },
      ),
      GoRoute(
        name: "Port",
        path: "/port-details/:name",
        builder: (context, state) {
          final String name = state.pathParameters['name']!;
          return PortDetails(portPassedName: name);
        },
      ),
      GoRoute(
        name: "MainMenu",
        path: "/main-menu/:name",
        builder: (context, state) {
          final String name = state.pathParameters['name']!;
          return MainMenuPage(passedPortName: name);
        },
      ),
      GoRoute(
        name: "ThrottleRPM",
        path: "/throttle-rpm/:name",
        builder: (context, state) {
          final String name = state.pathParameters['name']!;
          serialPortService.initSerialPort(name);
          return ThrottleRpmPage(passedPortName: name);
        },
      ),
    ],
  );
}
