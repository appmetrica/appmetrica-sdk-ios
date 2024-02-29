Pod::Spec.new do |s|
  s.name = "AppMetricaAnalytics"
  s.version = '5.1.0'
  s.summary = "Serves as the comprehensive suite for advanced mobile analytics, encompassing core tracking, web interactions, crash reporting, and ad support functionalities, ensuring a holistic analysis and optimization platform for iOS applications."

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  
  s.dependency 'AppMetricaCore', '~> 5.1'
  s.dependency 'AppMetricaAdSupport', '~> 5.1'
  s.dependency 'AppMetricaWebKit', '~> 5.1'
  s.dependency 'AppMetricaCrashes', '~> 5.1'
end
