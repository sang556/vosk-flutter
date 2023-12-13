import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'vosk_flutter_platform_interface.dart';

/// An implementation of [VoskFlutterPlatform] that uses method channels.
class MethodChannelVoskFlutter extends VoskFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('vosk_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
