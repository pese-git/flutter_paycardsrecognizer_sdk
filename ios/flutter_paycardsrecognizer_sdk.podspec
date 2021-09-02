#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_paycardsrecognizer_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_paycardsrecognizer_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Flutter library for automatic recognition of bank card data using built-in camera on Android/IOS devices.'
  s.description      = <<-DESC
Flutter library for automatic recognition of bank card data using built-in camera on Android/IOS devices.
                       DESC
  s.homepage         = 'https://github.com/pese-git/flutter_paycardsrecognizer_sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sergey Penkovsky' => 'sergey.penkovsky@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'
  s.vendored_frameworks = 'PayCardsRecognizer.framework'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
