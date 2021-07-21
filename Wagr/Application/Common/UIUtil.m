//
//  UIUtil.m
//  Wagr
//
//  Copyright (c) 2021 Microsoft. All rights reserved.
//

#import "UIUtil.h"
#import <UIKit/UIApplication.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UIWindow.h>

@implementation UIUtil

#pragma mark - Get View Controller Helpers

/*
 We need this helper to make sure we get the current view controller to navigate screens properly.
 */
+ (UIViewController *) currentViewController {
    UIViewController *topController = [[[UIApplication sharedApplication] keyWindow] rootViewController];

    if (topController != nil) {
        UIViewController *presentedViewController = [topController presentedViewController];

        // Loop until there are no more view controllers to go to
        while (presentedViewController != nil) {
            topController = presentedViewController;
            presentedViewController = [topController presentedViewController];
        }
    }

    return topController;
}

/*
 This method returns the MainTabBarController
 */
+ (UIViewController *) mainTabBarController {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController *mainTabBarViewController = [storyBoard instantiateViewControllerWithIdentifier:@"MainTabBarController"];

    return mainTabBarViewController;
}

/*
 This method returns the LoginViewController
 */
+ (UIViewController *) loginViewController {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    UIViewController *loginViewController = [storyBoard instantiateViewControllerWithIdentifier:@"LoginViewController"];

    return loginViewController;
}

#pragma mark - Alert Popup Helper

/*
 This method returns an alert controller to use with a default 'OK' button
 */
+ (UIAlertController *) alertController:(NSString *)title message:(NSString *)message {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:1];
    UIAlertAction* closeAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:0
                                                          handler:nil];
    [alert addAction:closeAction];

    return alert;
}

@end
