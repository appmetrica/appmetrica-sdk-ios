Pod::Spec.new do |s|
  s.name = "AppMetricaLogSwift"
  s.version = '5.11.1'
  s.summary = "AppMetricaLog offers modules the capability to log messages at various levels"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  
  s.swift_versions = '5.7'

  s.frameworks = 'Foundation'

  s.dependency 'AppMetricaLog', '= 5.11.1'
  
  s.header_dir = s.name
  s.source_files = [
      "#{s.name}/Sources/**/*.swift",
  ]
  
  s.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
end
