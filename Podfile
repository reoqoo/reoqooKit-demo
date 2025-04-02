# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'RQSDKDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for RQSDKDemo

  pod 'CombineCocoa', '0.4.1'  # 为UIKit系列控件提供 Publisher
  pod 'CombineExt', '1.8.0'  # 为 SwiftCombine 提供扩展功能
  pod 'R.swift', '7.8.0'
  pod 'Realm',        '10.50.1' # 数据库
  pod 'RealmSwift',   '10.50.1' # 数据库
  pod 'RxSwift', '6.9.0'
  # Realm + RxSwift https://github.com/RxSwiftCommunity/RxRealm/issues/207
  pod 'RxRealm', :git => 'https://github.com/jopache/RxRealm.git'
  pod 'RTRootNavigationController', '0.8.1'
  pod 'AFNetworking',   '4.0.1'
  pod 'SDWebImage',     '5.18.2'
  pod 'lottie-ios',     '4.5.1'
  pod 'SSZipArchive', '2.4.3'
  pod 'MJRefresh', '3.7.9'
  pod 'CZImagePreviewer', '1.2.1'
  pod 'MBProgressHUD', '1.2.0'
  pod 'Codextended', '0.3.0'
  pod 'CryptoSwift', '1.8.4'
  pod 'EmptyDataSet-Swift', '5.0.0'
  pod 'FMDB'
  pod 'Kingfisher', '8.3.1'
  pod 'QTEventBus', '0.4.1'
  pod 'SnapKit', '5.7.1'
  pod 'SwiftyJSON', '5.0.2'
  pod 'Popover', '1.3.0'
  pod 'Then', '3.0.0'

  pod 'reoqooKit'

end

# 安装完pods库后执行的指令
post_install do |installer|
  # 修改pods项目配置
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 编译最低版本 13.0
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
