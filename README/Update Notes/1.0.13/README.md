# reoqooKit 1.0.13 Update Note

### RQWebService
Connect to the RQIAPKit

### RQApi
None

### RQDeviceAddition
Fix some bugs

### RQCore
Fix some bugs
Connect to the RQIAPKit 

### RQIAPKit
New module for providing the In App Purchase function
This module is optional, you can specified in podfile like
'''
pod 'reoqooKit', :subspecs => ['Core', 'RQIAPKit']

// 'Core' is the Default Spec, if you don't need the 'RQIAPKit', just
pod 'reoqooKit'

Note: If you are not planing to provide the IAP function, please don't install RQIAPKit. Otherwise apple will refuse your App review.

'''
