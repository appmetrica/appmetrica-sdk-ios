Pod::Spec.new do |s|
  s.name = "AppMetrica_Protobuf"
  s.version = '5.1.0'
  s.summary = "AppMetrica protobuf-c"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  
  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,c}"
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
end
