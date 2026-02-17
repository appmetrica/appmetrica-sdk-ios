Pod::Spec.new do |s|
  s.name = "AppMetricaIdentifiers"
  s.version = '6.2.0'
  s.summary = "AppMetrica utility modules that generates and provides identifiers"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  
  s.swift_versions = '5.9.0'

  s.frameworks = 'Foundation', 'UIKit'

  s.dependency 'AppMetricaLogSwift', '= 6.2.0'
  s.dependency 'AppMetricaStorageUtils', '= 6.2.0'
  s.dependency 'AppMetricaKeychain', '= 6.2.0'
  s.dependency 'AppMetricaSynchronization', '= 6.2.0'
  s.dependency 'AppMetricaPlatform', '= 6.2.0'
  
  s.header_dir = s.name
  s.source_files = [
      "#{s.name}/Sources/**/*.swift",
  ]
  
  s.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
end
