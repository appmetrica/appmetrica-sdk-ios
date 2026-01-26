Pod::Spec.new do |s|
  s.name = "AppMetricaCore"
  s.version = '6.0.0'
  s.summary = "Powerful and flexible module offering a wide range of tracking and analytics tools for your application"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  
  s.swift_versions = '5.9.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  
  s.frameworks = 'UIKit', 'Foundation', 'CoreLocation', 'CoreGraphics', 'SystemConfiguration'
  s.libraries = 'z', 'sqlite3', 'c++'

  s.dependency 'AppMetricaLog', '= 6.0.0'
  s.dependency 'AppMetricaNetwork', '= 6.0.0'
  s.dependency 'AppMetricaCoreUtils', '= 6.0.0'
  s.dependency 'AppMetricaHostState', '= 6.0.0'
  s.dependency 'AppMetricaProtobufUtils', '= 6.0.0'
  s.dependency 'AppMetricaPlatform', '= 6.0.0'
  s.dependency 'AppMetricaStorageUtils', '= 6.0.0'
  s.dependency 'AppMetricaEncodingUtils', '= 6.0.0'
  s.dependency 'AppMetricaProtobuf', '= 6.0.0'
  s.dependency 'AppMetricaFMDB', '= 6.0.0'
  s.dependency 'AppMetricaKeychain', '= 6.0.0'
  s.dependency 'AppMetricaIdentifiers', '= 6.0.0'
  
  s.header_dir = s.name
  s.source_files = [
      "#{s.name}/Sources/**/*.{h,m,c}",
      'AppMetricaCoreExtension/Sources/include/**/*.h',
  ]
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
  
  s.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
end
