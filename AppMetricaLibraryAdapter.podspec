Pod::Spec.new do |s|
  s.name = "AppMetricaLibraryAdapter"
  s.version = '5.8.1'
  s.summary = "Universal adapter library for AppMetrica SDK to send ad impressions."

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS' => 'AMA_BUILD_TYPE=\"source\"',
  }

  s.frameworks = 'Foundation'

  s.dependency 'AppMetricaCore', '= 5.8.1'
  s.dependency 'AppMetricaCoreExtension', '= 5.8.1'

  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.swift"

  s.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
end
