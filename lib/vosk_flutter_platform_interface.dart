import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'vosk_flutter_method_channel.dart';

abstract class VoskFlutterPlatform extends PlatformInterface {
  /// Constructs a VoskFlutterPlatform.
  VoskFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static VoskFlutterPlatform _instance = MethodChannelVoskFlutter();

  /// The default instance of [VoskFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelVoskFlutter].
  static VoskFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VoskFlutterPlatform] when
  /// they register themselves.
  static set instance(VoskFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
