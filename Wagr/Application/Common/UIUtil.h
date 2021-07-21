//
//  UIUtil.h
//  Wagr
//
//  Copyright (c) 2021 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIAlertController.h>

@interface UIUtil : NSObject

+ (UIViewController *_Nonnull) currentViewController;
+ (UIViewController *_Nonnull) mainTabBarController;
+ (UIViewController *_Nonnull) loginViewController;
+ (UIAlertController *_Nonnull) alertController:(NSString *_Nonnull)title message:(NSString *_Nullable)message;

@end
