# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'RQSDKDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for RQSDKDemo

  pod 'CombineCocoa', '0.4.1'  # 为UIKit系列控件提供 Publisher
  pod 'CombineExt'  # 为 SwiftCombine 提供扩展功能
  pod 'R.swift'
  pod 'Realm',        '10.50.1' # 数据库
  pod 'RealmSwift',   '10.50.1' # 数据库
  pod 'RxSwift'
  # Realm + RxSwift https://github.com/RxSwiftCommunity/RxRealm/issues/207
  pod 'RxRealm', :git => 'https://github.com/jopache/RxRealm.git'
  pod 'curl'
  pod 'RTRootNavigationController'
  pod 'AFNetworking',   '~> 4.0.1'
  pod 'SDWebImage',     '~> 5.18.2'
  pod 'lottie-ios',     '3.4.1'
  pod 'SSZipArchive'
  pod 'MJRefresh'
  pod 'CZImagePreviewer'
  pod 'MBProgressHUD'
  pod 'Codextended'
  pod 'CryptoSwift'
  pod 'EmptyDataSet-Swift'
  pod 'FMDB'
  pod 'Kingfisher',     '8.0.3'
  pod 'QTEventBus'
  pod 'SnapKit'
  pod 'SwiftyJSON'
  pod 'Popover'
  pod 'Then'

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
