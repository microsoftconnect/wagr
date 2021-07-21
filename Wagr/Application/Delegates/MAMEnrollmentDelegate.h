//
//  MAMEnrollmentDelegate.h
//  Wagr
//
//  Copyright © 2021 Microsoft. All rights reserved.
//

#import <IntuneMAMSwift/IntuneMAMEnrollmentDelegate.h>
#import <MSAL/MSALPublicClientApplication.h>
#import <UIKit/UIViewController.h>

@interface MAMEnrollmentDelegate : NSObject<IntuneMAMEnrollmentDelegate>

@property (nonatomic, strong, nullable) UIViewController *presentingViewController;

- (nonnull instancetype) init;
- (nonnull instancetype) init:(UIViewController *_Nonnull)viewController;

@end
