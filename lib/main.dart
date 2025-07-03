import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:inventario_app/auth/login_screen.dart';
import 'package:inventario_app/screens/home_screen.dart';
import 'package:inventario_app/controllers/inventory_alert_controller.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar configuración de notificaciones
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 🔔 Pedir permiso para notificaciones (Android 13+)
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // Iniciar monitoreo global de productos con bajo stock
  InventoryAlertController().startMonitoring();
  InventoryAlertController().lowStockProducts.addListener(() {
    final lowStock = InventoryAlertController().lowStockProducts.value;
    if (lowStock.isNotEmpty) {
      _sendLowStockNotification(lowStock);
    }
  });

  runApp(const MyApp());
}

Future<void> _sendLowStockNotification(List<String> products) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'low_stock_channel',
    'Alertas de Inventario',
    channelDescription: 'Notificaciones para productos con bajo stock',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  final NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    '¡Alerta de Stock!',
    'Productos con bajo stock: ${products.join(', ')}',
    platformDetails,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventario PEPS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
