import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kuchbhi/pages/auth_page.dart';
import 'package:kuchbhi/pages/home_page.dart';
import 'package:kuchbhi/screens/splash.dart';
import 'firebase_options.dart';

// Initialize Firebase Messaging
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

// Initialize Local Notifications
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up Firebase Messaging and Local Notifications
  await setupFirebaseMessaging();
  await setupLocalNotifications();

  runApp(const App());
}

// Set up Firebase Messaging
Future<void> setupFirebaseMessaging() async {
  // Request permission for notifications (required for iOS)
  await _firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get the FCM token
  final token = await _firebaseMessaging.getToken();
  print('FCM Token: $token'); // Debugging: Print the FCM token

  // Listen for messages while the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a message while in the foreground: ${message.notification?.title}');
    showLocalNotification(
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
    );
  });

  // Handle when the app is opened from a notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('App opened from a notification: ${message.notification?.title}');
    // Navigate to a specific screen or perform other actions
  });
}

// Set up Local Notifications
Future<void> setupLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// Show Local Notification
Future<void> showLocalNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await _flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlutterChat',
      theme: ThemeData().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 63, 17, 177)),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          if (snapshot.hasData) {
            return HomePage();
          }

          return AuthPage();
        },
      ),
    );
  }
}