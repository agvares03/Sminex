# Uncomment the next line to define a global platform for your project
# platform :ios, '8.0'

target 'Sminex' do
    
    platform :ios, '9.1'
    
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'UIScreenExtension', :git => 'https://github.com/marchv/UIScreenExtension'
    pod 'SwiftyXMLParser', :git => 'https://github.com/yahoojapan/SwiftyXMLParser.git'
    pod 'Alamofire', '~> 4.7'
    pod 'Firebase/Messaging'
    pod 'Firebase/Core'
    pod 'Firebase/Analytics'
    pod 'ExpyTableView'
    pod 'FSPagerView'
    pod 'DeviceKit', '~> 1.3'
    pod 'Arcane'
    pod 'Gloss'
    pod 'YandexMobileMetrica'
    pod 'AFDateHelper'
    pod 'SimpleImageViewer'
    pod 'CropViewController'
    pod 'AKMaskField'
end

# Workaround for Cocoapods issue #7606
post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
end
