Pod::Spec.new do |s|
  s.name = "AppMetricaHostState"
  s.version = '5.1.0'
  s.summary = "AppMetricaHostState facilitates accessing the state of the host application for other modules"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.frameworks = 'Foundation', 'UIKit'

  s.dependency 'AppMetricaLog', '~> 5.1'
  s.dependency 'AppMetricaCoreUtils', '~> 5.1'
  
  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,m}"
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
end
