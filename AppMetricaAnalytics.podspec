Pod::Spec.new do |s|
  s.name = "AppMetricaAnalytics"
  s.version = '5.11.2'
  s.summary = "Comprehensive suite for mobile analytics, including tracking, web interactions, crash reporting, and advertising functionalities."

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  
  s.swift_versions = '5.7'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  
  s.dependency 'AppMetricaCore', '= 5.11.2'
  s.dependency 'AppMetricaAdSupport', '= 5.11.2'
  s.dependency 'AppMetricaWebKit', '= 5.11.2'
  s.dependency 'AppMetricaCrashes', '= 5.11.2'
  s.dependency 'AppMetricaScreenshot', '= 5.11.2'
end
