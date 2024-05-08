Pod::Spec.new do |s|
  s.name = "AppMetricaFMDB"
  s.version = '5.3.3'
  s.summary = "AppMetrica's adaptation of the original FMDB, enhancing SQLite database interaction for iOS analytics and tracking."

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { 'August Mueller' => 'gus@flyingmeat.com' }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
    
  s.libraries = 'sqlite3'
  
  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,m}"
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"
  
  s.resource_bundles = { s.name => "#{s.name}/Sources/Resources/PrivacyInfo.xcprivacy" }
end
