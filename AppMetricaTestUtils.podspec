Pod::Spec.new do |s|
  s.name = "AppMetricaTestUtils"
  s.version = '5.2.0'
  s.summary = "AMATestUtils offers a comprehensive set of convenient and reusable testing utilities designed to simplify unit testing for modules"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '11.0'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  
  s.frameworks = 'Foundation'
  
  #TODO: https://nda.ya.ru/t/MqweN1VA6niXzF
  s.dependency 'Kiwi', '~> 3.0.0'
  s.dependency 'AppMetricaCoreUtils', '~> 5.2'
  s.dependency 'AppMetricaStorageUtils', '~> 5.2'
  s.dependency 'AppMetricaNetwork', '~> 5.2'
  s.dependency 'AppMetricaHostState', '~> 5.2'
  
  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,m}"
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
end
