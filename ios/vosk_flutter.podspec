#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint vosk_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'vosk_flutter'
  s.version          = '0.0.1'
  s.summary          = 'vosk离线语音识别插件（支持Android/iOS）'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'lske888@163.com' }
  s.source           = { :path => '.' }
  #s.source_files = 'Classes/**/*'
  s.source_files  = "Classes", "Classes/**/*.{h,m}"
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.ios.vendored_frameworks = 'Classes/libvosk.xcframework'
  s.vendored_frameworks = 'libvosk.xcframework'

  # 使用 use_frameworks!
  s.static_framework = true

  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
