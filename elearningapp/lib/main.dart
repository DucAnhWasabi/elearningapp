import 'package:firebase_core/firebase_core.dart'; // Đã bỏ comment
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // IMPORT QUAN TRỌNG
import 'features/auth/presentation/login_screen.dart'; // Sẽ tạo ở Bước 4
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- CẤU HÌNH WINDOWS (QUAN TRỌNG) ---
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Khởi tạo database factory cho Desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // -------------------------------------

  // Khởi tạo Firebase với cấu hình vừa tạo
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IT E-Learning App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue[900]!),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      // Tạm thời trỏ thẳng vào LoginScreen để test
      home: const LoginScreen(),
    );
  }
}