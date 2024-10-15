//
//  NSBundle+Language.m
//  RQSDKDemo
//
//  Created by xiaojuntao on 12/9/2023.
//

#import "NSBundle+Language.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

// https://www.jianshu.com/p/6255d2dfab2d

static NSString *const Reoqoo_AssignLanguage = @"Reoqoo_AssignLanguage";

@interface BundleEx : NSBundle
@end

@implementation BundleEx

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {

    // 手动指定的语言
    NSString *currentLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:Reoqoo_AssignLanguage];

    // 如果 指定的语言为空, 即表示使用系统语言
    if (currentLanguage == nil || currentLanguage.length == 0) {
        return [super localizedStringForKey:key value:value table:tableName];
    }

    // 每次需要从语言包查询语言键值对的时候，都按照当前语言取出当前语言包
    NSBundle *currentLanguageBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:currentLanguage ofType:@"lproj"]];

    // 下面return中普通 bundle 在调用 localizedStringForKey: 方法时不会循环调用，虽然我们重写了 mainBundle 单例的 localizedStringForKey: 方法，但是我们只修改了 mainBundle 单例的isa指针指向，
    // 也就是说只有 mainBundle 单例在调用 localizedStringForKey: 方法时会走本方法，而其它普通 bundle 不会。
    return currentLanguageBundle ? [currentLanguageBundle localizedStringForKey:key value:value table:tableName] : [super localizedStringForKey:key value:value table:tableName];
}

@end

@implementation NSBundle (Language)

+ (NSString *)didChanngeLanguageNotificaitonName {
    return @"Reoqoo.didChanngeLanguageNotificaitonName";
}

+ (void)load {
    static dispatch_once_t onceToken;

    // 保证只修改一次 mainBundle 单例的isa指针指向
    dispatch_once(&onceToken, ^{
        // 让 mainBundle 单例的isa指针指向 BundleEx 类
        object_setClass([NSBundle mainBundle], [BundleEx class]);
    });
}

+ (NSString *)assignLanguage {
    return [[NSUserDefaults standardUserDefaults] objectForKey:Reoqoo_AssignLanguage];
}

+ (void)setAssignLanguage:(NSString *)language {
    // 将当前手动设置的语言存起来
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:Reoqoo_AssignLanguage];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [NSNotificationCenter.defaultCenter postNotificationName:NSBundle.didChanngeLanguageNotificaitonName object:nil];
}

@end
