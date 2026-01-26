Pod::Spec.new do |s|
  s.name = "AppMetricaTestUtils"
  s.version = '6.0.0'
  s.summary = "AMATestUtils offers a comprehensive set of convenient and reusable testing utilities designed to simplify unit testing for modules"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'

  s.swift_versions = '5.9.0'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  
  s.frameworks = 'Foundation'
  
  #TODO: https://nda.ya.ru/t/MqweN1VA6niXzF
  s.dependency 'AppMetricaKiwi', '~> 3.0.2'
  s.dependency 'AppMetricaCoreUtils', '= 6.0.0'
  s.dependency 'AppMetricaStorageUtils', '= 6.0.0'
  s.dependency 'AppMetricaNetwork', '= 6.0.0'
  s.dependency 'AppMetricaHostState', '= 6.0.0'
  s.dependency 'AppMetricaKeychain', '= 6.0.0'
  
  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,m}"
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
end
