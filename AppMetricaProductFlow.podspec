Pod::Spec.new do |s|
  s.name = "AppMetricaProductFlow"
  s.version = '6.5.0'
  s.summary = "Reports product flow events for offers and product acquisition flows in vertical applications"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'

  s.swift_versions = '5.9.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.frameworks = 'Foundation'

  s.dependency 'AppMetricaCore', '= 6.5.0'
  s.dependency 'AppMetricaCoreExtension', '= 6.5.0'
  s.dependency 'AppMetricaCoreUtils', '= 6.5.0'
  s.dependency 'AppMetricaProtobufUtils', '= 6.5.0'
  s.dependency 'AppMetricaSynchronization', '= 6.5.0'
  s.dependency 'SwiftProtobuf', '~> 1.30'

  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,m,c,swift}"

  s.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
end
