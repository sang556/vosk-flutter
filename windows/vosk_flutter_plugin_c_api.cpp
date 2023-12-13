#include "include/vosk_flutter/vosk_flutter_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "vosk_flutter_plugin.h"

void VoskFlutterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  vosk_flutter::VoskFlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
