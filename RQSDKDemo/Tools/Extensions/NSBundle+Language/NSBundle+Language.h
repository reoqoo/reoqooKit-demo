//
//  NSBundle+Language.h
//  RQSDKDemo
//
//  Created by xiaojuntao on 12/9/2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (Language)
@property (class, readonly) NSNotificationName didChanngeLanguageNotificaitonName;
+ (nullable NSString *)assignLanguage;
+ (void)setAssignLanguage:(nullable NSString *)language;
@end

NS_ASSUME_NONNULL_END
