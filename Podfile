platform :ios, '8.0'

source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

link_with 'Taylr'

pod 'ReactiveCocoa', '~> 2.4' # Update to 3.0 when ready

pod 'SugarRecord/CoreData', :git => 'https://github.com/tonyxiao/SugarRecord', :branch => 'swift-1.2'
pod 'Meteor', :git => 'https://github.com/tonyxiao/meteor-ios', :branch => 'dev'
pod 'SwiftyUserDefaults', '~> 1.1'
pod 'SwiftTryCatch', '~> 0.0.1'

pod 'SwipeView', '~> 1.3'
pod 'SDWebImage', '~> 3.7'
pod 'PKHUD', :git => 'https://github.com/tonyxiao/PKHUD' # Fork is needed to work around xcasset compilation issue inside pod
pod 'XLForm', '~> 2.2'

pod 'Cartography', '~> 0.5'
pod 'UICollectionViewLeftAlignedLayout', '~> 0.0.3'

#pod 'Spring', '~> 1.0'
#pod 'pop', '~> 1.0'
pod 'RBBAnimation', '~> 0.3.0'

pod 'EDColor', '~> 1.0'
pod 'DateTools', '~> 1.5'
pod 'FormatterKit/TimeIntervalFormatter', '~> 1.8'
pod 'TCMobileProvision', :git => 'https://github.com/tonyxiao/TCMobileProvision.git'
pod 'INTULocationManager', '~> 3.0'

# 3rd Party Service SDKs
pod 'Facebook-iOS-SDK', '3.22.0' # TODO: Upgrade me when ready
#pod 'CrashlyticsFramework', '~> 2.2'
#pod 'BugfenderSDK', :git => 'https://github.com/bugfender/BugfenderSDK-iOS.git', :tag => '0.3.2'
pod 'Analytics/Segmentio', :git => 'https://github.com/tonyxiao/analytics-ios.git'
pod 'Analytics/Mixpanel', :git => 'https://github.com/tonyxiao/analytics-ios.git'
pod 'Analytics/Amplitude', :git => 'https://github.com/tonyxiao/analytics-ios.git'
pod 'Heap', '~> 2.1'
#pod 'Analytics/Kahuna', :git => 'https://github.com/tonyxiao/analytics-ios.git'

# Debug only

pod 'Reveal-iOS-SDK', '~> 1.5', :configuration => ['Debug']
pod 'NSLogger', '~> 1.5', :configuration => ['Debug']

target :BackendTests do
  link_with 'BackendTests'
  pod 'Quick', '~> 0.3.0' # TODO: Upgrade after swift 2.0
  pod 'Nimble', '~> 0.4.0' # TODO: Upgrade after swift 2.0
end

target :Camera do
  link_with 'Camera'
  pod 'SCRecorder', '~> 2.4'
end

# Hacks
post_install do |installer|
    installer.project.targets.each do |target|
        # DateTools Hack https://github.com/MatthewYork/DateTools/issues/56 Disable localization in exchange for no crash
        if target.name == 'Pods-DateTools'
            target.build_configurations.each do |config|
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'DateToolsLocalizedStrings(key)=key'
            end
        end
    end
end

# Might be useful one day
#pod 'SwiftyJSON', '~> 2.1'
#pod 'ExSwift', '~> 0.1.9'
