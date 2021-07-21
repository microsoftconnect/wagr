//
//  MAMComplianceDelegate.m
//  Wagr
//
//  Copyright (c) 2021 Microsoft. All rights reserved.
//

#import "MAMComplianceDelegate.h"
#import "UIUtil.h"
#import <UIKit/UIWindow.h>

@implementation MAMComplianceDelegate

#pragma mark - IntuneMAMComplianceDelegate

// Create and return an instance of the MAMComplianceDelegate
- (instancetype) init {
    MAMComplianceDelegate *instance = [super init];
    return instance;
}

/*
  This method is called when the Intune SDK has completed compliance remediation for an identity.
  If the identity has not been added to the app and is compliant, it should be added at this time.
  All values of IntuneMAMComplianceStatus will populate the error parameter with a localized error string.
  This method is guarenteed to be called after application:willFinishLaunchingWithOptions:

  @warning Delegate methods are not guarenteed to be called on the Main thread.

  @param "identity": The UPN of the identity for which compliance remediation was requested
  @param "status": The compliance status of identity
  @param "errMsg": A localized string describing the error encountered if the identity is not compliant.
  @param "errTitle": A localized title string for the error encountered if the identity is not compliant.
 */
- (void)identity:(NSString * _Nonnull)identity hasComplianceStatus:(IntuneMAMComplianceStatus)status withErrorMessage:(NSString * _Nonnull)errMsg andErrorTitle:(NSString * _Nonnull)errTitle {
    // We need to be on the main thread to do any UI related calls, so wrap all of this in
    // the mainQueue
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (status == IntuneMAMComplianceCompliant) {
            // Don't do anything. The AppDelegate will handle proper navigation to the main screen
            // already.
        } else if (status == IntuneMAMComplianceNotCompliant) {
            [[[UIApplication sharedApplication] keyWindow] setRootViewController:[UIUtil loginViewController]];
            [[UIUtil currentViewController] presentViewController:[UIUtil alertController:@"User Not Compliant" message:errMsg] animated:true completion:nil];
        } else if (status == IntuneMAMComplianceServiceFailure) {
            [[[UIApplication sharedApplication] keyWindow] setRootViewController:[UIUtil loginViewController]];
            [[UIUtil currentViewController] presentViewController:[UIUtil alertController:@"Service Failure" message:@"Please try again later."] animated:true completion:nil];
        } else if (status == IntuneMAMComplianceNetworkFailure) {
            [[[UIApplication sharedApplication] keyWindow] setRootViewController:[UIUtil loginViewController]];
            [[UIUtil currentViewController] presentViewController:[UIUtil alertController:@"Network Failure" message:@"Please try again later."] animated:true completion:nil];
        } else if (status == IntuneMAMComplianceInteractionRequired) {
            // When this is the case, the next time you call remediation, make sure that silent is set to NO.
            // In this app, silent is already set to NO when going through remediation. (see method remediateComplianceForIdentity in LoginViewController.m)
            [[[UIApplication sharedApplication] keyWindow] setRootViewController:[UIUtil loginViewController]];
            [[UIUtil currentViewController] presentViewController:[UIUtil alertController:@"User Interaction Required" message:@"Please try again."] animated:true completion:nil];
        } else { // If we're here, the status should be IntuneMAMComplianceUserCancelled.
            [[[UIApplication sharedApplication] keyWindow] setRootViewController:[UIUtil loginViewController]];
            [[UIUtil currentViewController] presentViewController:[UIUtil alertController:@"Canelled" message:@"The process was cancelled."] animated:true completion:nil];
        }
    }];
}
@end
