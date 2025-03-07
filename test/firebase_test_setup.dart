import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Callback = void Function(MethodCall call);

void setupFirebaseCoreMocks() {
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/firebase_core');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Firebase#initializeCore':
        return [
          {
            'name': 'default',
            'options': {
              'apiKey': 'testApiKey',
              'appId': 'testAppId',
              'messagingSenderId': 'testSenderId',
              'projectId': 'testProjectId',
            },
            'pluginConstants': {},
          }
        ];
      default:
        return null;
    }
  });
}

void setupFirebaseAuthMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

  setupFirebaseCoreMocks();

  const MethodChannel('plugins.flutter.io/firebase_core')
      .setMockMethodCallHandler((call) async {
    if (customHandlers != null) {
      customHandlers(call);
    }
    return null;
  });
}

Future<T> neverEndingFuture<T>() async {
  // ignore: literal_only_boolean_expressions
  while (true) {
    await Future.delayed(const Duration(minutes: 5));
  }
}
