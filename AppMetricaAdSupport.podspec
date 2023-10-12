Pod::Spec.new do |s|
  s.name = "AppMetricaAdSupport"
  s.version = '5.0.0'
  s.summary = "AppMetricaAdSupport provides advertising information"

  s.homepage = 'https://appmetrica.io'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = { "AppMetrica" => "admin@appmetrica.io" }
  s.source = { :git => "https://github.com/appmetrica/appmetrica-sdk-ios.git", :tag=>s.version.to_s }
  
  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'
  
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.frameworks = 'Foundation', 'AdSupport', 'AppTrackingTransparency'

  s.dependency 'AppMetricaCore', '~> 5.0'
  s.dependency 'AppMetricaCoreExtension', '~> 5.0'
  
  s.header_dir = s.name
  s.source_files = "#{s.name}/Sources/**/*.{h,m}"
  s.public_header_files = "#{s.name}/Sources/include/**/*.h"

  s.compiler_flags = '-Wshadow-ivar', '-Werror', '-Wbool-conversion',
  '-Wconstant-conversion', '-Wdeprecated-objc-isa-usage',
  '-Werror=incompatible-pointer-types',
  '-Wreturn-type', '-Wswitch', '-Wparentheses', '-Wsign-compare',
  '-Wuninitialized', '-Wunused-function', '-Wunused-label', '-Wunused-value',
  '-Wunused-variable', '-Wconversion', '-Wenum-conversion', '-Wint-conversion',
  '-Wdocumentation'

end
