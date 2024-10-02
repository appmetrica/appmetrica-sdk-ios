Pod::Spec.new do |s|
  s.name = "AppMetricaEncodingUtils"
  s.version = '5.8.1'
  s.summary = "Provides a set of encoding and crypto utilities"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }
  
  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.frameworks = 'Foundation'

  s.dependency 'AppMetricaLog', '= 5.8.1'
  s.dependency 'AppMetricaPlatform', '= 5.8.1'
  s.dependency 'AppMetricaCoreUtils', '= 5.8.1'
  
  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,m}"
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
  
  s.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
end
