require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "GoogleSdkAutocomplete"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  # GooglePlaces 10.x requires iOS 16+
  s.platforms    = { :ios => "16.0" }
  s.source       = { :git => "https://github.com/lucaslevin/react-native-google-sdk-autocomplete.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift,cpp}"
  s.private_header_files = "ios/**/*.h"

  s.dependency "GooglePlaces", "~> 10.0"

  install_modules_dependencies(s)
end
