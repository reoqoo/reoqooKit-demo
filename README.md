
# reoqooKit Demo

## Installation
### Cocoapods
```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '13.0'
use_frameworks!

target 'MyApp' do
  pod 'reoqooKit'
end
```

## Usage
### Initialize
```
// As you see in the `AppDelegate.swift`
/// - appName: the App Name that provide by `reoqooKit`, you can find it in our developer site
/// - pkgName: the value has no effect for now, we recommend passing the `Bundle.main.bundleIdentifier`
/// - appID: the AppID that provide by `reoqooKit`, you can find it in our developer site
/// - appToken: the AppToken that provide by `reoqooKit`, you can find it in our developer site
/// - language: the language that you want reoqooKit present
/// - versionPrefix: the Version Prefix that provide by `reoqooKit`, you can find it in our developer site
/// - privacyPolicyURL: the URL that let reoqooKit jump to Your privacy introduce site
/// - userAggrementURL: the URL that let reoqooKit jump to Your user aggrement site
/// - requestHost: this is use for reoqooKit develop, just passing `.default`
/// - superVipId: this is very important, please check it in the framework API: `RQCore.Agent.swift` struct `InitialInfo`
let initialInfo = InitialInfo.init(appName: appName, pkgName: Bundle.main.bundleIdentifier!, appID: appID, appToken: appToken, language: IVLanguageCode.current, versionPrefix: "8.1", privacyPolicyURL: privacyPolicyURL, userAggrementURL: userAggrementURL, requestHost: .default, superVipId: nil)

/// Initialize the reoqooKit and set the Delegate 
RQCore.Agent.shared.initialze(initialInfo: initialInfo, delegate: RQSDKDelegate.shared, launchOptions: launchOptions)

/// Set the watermark when presenting in the surveillance picture, and both using in capture/record surveillance frames.
RQCore.Agent.shared.watermarkImage = UIColor.red.pureImage(size: .init(width: 135, height: 36))

/// Set `DeviceAddition` work flow delegate
RQDeviceAddition.Agent.shared.delegate = RQSDKDelegate.shared

```
