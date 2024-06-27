Pod::Spec.new do |s|
  s.name = "AppMetricaCrashes"
  s.version = '5.7.0'
  s.summary = "Provides essential utilities for efficient crash and error handling and reporting"
  
  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }
  
  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  
  s.frameworks = 'Foundation'

  s.dependency 'AppMetricaCore', '= 5.7.0'
  s.dependency 'AppMetricaCoreExtension', '= 5.7.0'
  s.dependency 'AppMetricaCoreUtils', '= 5.7.0'
  s.dependency 'AppMetricaHostState', '= 5.7.0'
  s.dependency 'AppMetricaProtobufUtils', '= 5.7.0'
  s.dependency 'AppMetricaLog', '= 5.7.0'
  s.dependency 'AppMetricaPlatform', '= 5.7.0'
  s.dependency 'AppMetricaStorageUtils', '= 5.7.0'
  s.dependency 'AppMetricaEncodingUtils', '= 5.7.0'

  s.dependency 'KSCrash/Recording', '~> 1.17.0'
  s.dependency 'KSCrash/Recording/Tools'
  
  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,m,c}"
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
  s.preserve_paths = "#{s.name}/helper"
  
  s.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
end
