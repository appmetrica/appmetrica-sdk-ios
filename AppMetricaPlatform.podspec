Pod::Spec.new do |s|
  s.name = "AppMetricaPlatform"
  s.version = '5.7.1'
  s.summary = "AppMetricaPlatform offers essential tools for gathering platform and device information"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'

  s.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'GCC_PREPROCESSOR_DEFINITIONS' => 'AMA_BUILD_TYPE=\"source\"',
  }

  s.frameworks = 'Foundation', 'Security', 'UIKit'

  s.dependency 'AppMetricaLog', '= 5.7.1'
  s.dependency 'AppMetricaCoreUtils', '= 5.7.1'

  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,m}"
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
  
  s.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
end
