Pod::Spec.new do |s|
  s.name = "AppMetricaProtobuf"
  s.version = '5.8.0'
  s.summary = "AppMetrica's adaptation of the original protobuf-c, tailored for efficient analytics data handling on iOS."

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = "Dave Benson"
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  
  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,c}"
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
  
  s.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
end
