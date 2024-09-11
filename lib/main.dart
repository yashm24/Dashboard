import 'package:desktop_serial_port_app/routes.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Serial Port App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          textTheme: const TextTheme(
            displayMedium: TextStyle(color: Colors.red),
            bodyLarge: TextStyle(color: Colors.blue),
          ),
          primaryColor: const Color(0xFF6F35A5),
          scaffoldBackgroundColor: const Color(0xFF202020),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: const StadiumBorder(),
              maximumSize: const Size(double.infinity, 56),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF6F35A5),
            iconColor: Color(0xFF6F35A5),
            prefixIconColor: Color(0xFF6F35A5),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              borderSide: BorderSide.none,
            ),
          )),
      routerConfig: AppRouter.returnRouter,
    );
  }
}
