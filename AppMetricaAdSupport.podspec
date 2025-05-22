Pod::Spec.new do |s|
  s.name = "AppMetricaAdSupport"
  s.version = '5.12.0'
  s.summary = "Offers seamless access to advertising identifiers, leveraging AdSupport and AppTrackingTransparency for enhanced ad tracking and analytics."

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }
  
  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  
  s.swift_versions = '5.7'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.frameworks = 'Foundation', 'AdSupport', 'AppTrackingTransparency'

  s.dependency 'AppMetricaCore', '= 5.12.0'
  s.dependency 'AppMetricaCoreExtension', '= 5.12.0'
  
  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,m}"
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
  
  s.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
end
