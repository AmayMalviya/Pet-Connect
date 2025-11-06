import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// This function needs to be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("Handling a background message: \${message.messageId}");
  // You can process the message here.
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Request permission for iOS and web
    await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Set up foreground notification presentation options
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads-up notification
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsDarwin);
    await _localNotifications.initialize(initializationSettings);

    // Handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: \${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: \${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Set the background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get and save the initial FCM token
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await _fcm.getAPNSToken();
      if (apnsToken != null) {
        saveFCMToken();
      } else {
        print('APNS token not available yet. FCM token will not be saved.');
      }
    } else {
      saveFCMToken();
    }

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen((token) {
      _saveToken(token);
    }).onError((error) {
      print('Error refreshing FCM token: $error');
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'your_channel_id', // id
            'Your Channel Name', // title
            channelDescription: 'your channel description', // description
            icon: android.smallIcon,
            // other properties...
          ),
        ),
      );
    }
  }

  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }

  Future<void> saveFCMToken() async {
    final token = await getFCMToken();
    await _saveToken(token);
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('user_id', userId);
        print('FCM token saved successfully!');
      } catch (e) {
        print('Error saving FCM token: $e');
      }
    }
  }
}
