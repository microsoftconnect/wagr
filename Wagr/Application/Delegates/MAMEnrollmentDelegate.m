//
//  MAMEnrollmentDelegate.m
//  Wagr
//
//  Copyright © 2021 Microsoft. All rights reserved.
//

#import "MAMEnrollmentDelegate.h"
#import "UIUtil.h"
#import <IntuneMAMSwift/IntuneMAMEnrollmentManager.h>
#import <IntuneMAMSwift/IntuneMAMEnrollmentStatus.h>
#import <IntuneMAMSwift/IntuneMAMSettings.h>
#import <MSAL/MSALDefinitions.h>
#import <MSAL/MSALPublicClientApplication.h>
#import <MSAL/MSALSignoutParameters.h>
#import <MSAL/MSALWebviewParameters.h>

@implementation MAMEnrollmentDelegate

- (instancetype) init {
    MAMEnrollmentDelegate *instance = [super init];
    if (instance) {
        instance.presentingViewController = nil;
    }
    return instance;
}

/*
 To be able to change the view, the class should be initialzed with the curent view controller. Then this view controller can move to the desired view based on the enrollment success.

 @param viewController - the view controller this class should use when triggered
 */
- (instancetype) init:(UIViewController *)viewController {
    MAMEnrollmentDelegate *instance = [super init];
    if (instance) {
        instance.presentingViewController = viewController;
    }
    return instance;
}

#pragma mark - IntuneMAMEnrollmentDelegate
/*
 These are the methods that will be called by MAM at various times.

 Click on the link below for more information.

 IntuneMAMEnrollmentDelegate.h Description: https://docs.microsoft.com/mem/intune/developer/app-sdk-ios#status-result-and-debug-notifications
 */

/*
  Called when an enrollment request operation is completed.

  @param "status": status object containing debug information
 */
// Go to the link above "IntuneMAMEnrollmentDelegate.h Description" for more info.
- (void) enrollmentRequestWithStatus:(IntuneMAMEnrollmentStatus *)status {
    if (status.didSucceed){
        // If enrollment was successful, change from the current view (which should have been initialized with the class) to the desired page on the app.
        NSLog(@"Login successful");

        if (self.presentingViewController != nil) {
            // We need to be on the main thread to do any UI related calls, so wrap all of this in
            // the mainQueue
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[[UIApplication sharedApplication] keyWindow] setRootViewController:[UIUtil mainTabBarController]];
            }];
        } else {
            NSLog(@"Warning: EnrollmentDelegate initialized without a view controller before attempting enrollment.");

            // We need to be on the main thread to do any UI related calls, so wrap all of this in
            // the mainQueue
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[[UIApplication sharedApplication] keyWindow] setRootViewController:[UIUtil mainTabBarController]];
            }];
        }
    } else if (status.statusCode == IntuneMAMEnrollmentStatusAuthRequired) {
        // This error code is saying that the operation failed because the SDK could not access the token.
        // Log failure error status and code.
        NSLog(@"enrollment result for identity %@ with status code %ld", status.identity, (unsigned long)status.statusCode);
        NSLog(@"Debug Message: %@", status.errorString);

        [[IntuneMAMEnrollmentManager instance] loginAndEnrollAccount:status.identity];
    } else {
        // In the case of any other failure, log failure error status and code.
        NSLog(@"enrollment result for identity %@ with status code %ld", status.identity, (unsigned long)status.statusCode);
        NSLog(@"Debug Message: %@", status.errorString);

        // Present the user with an alert asking them to sign in again.
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:status.errorString preferredStyle:1];

        if (self.presentingViewController != nil) {
            [self.presentingViewController presentViewController:alert animated:true completion:nil];
        } else {
            NSLog(@"Warning: EnrollmentDelegate initialized without a view controller before attempting enrollment.");

            // We need to be on the main thread to do any UI related calls, so wrap all of this in
            // the mainQueue
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[UIUtil currentViewController] presentViewController:alert animated:true completion:nil];
            }];
        }
    }
}

/*
   Called when a MAM policy request operation is completed.

   @param "status": status object containing debug information
 */
// Go to the link above "IntuneMAMEnrollmentDelegate.h Description" for more info.
- (void) policyRequestWithStatus:(IntuneMAMEnrollmentStatus*)status
{
    NSLog(@"Policy check-in result for identity %@ with status code %ld", status.identity, (unsigned long)status.statusCode);
    NSLog(@"Debug Message: %@", status.errorString);
}


/*
   Called when a un-enroll request operation is completed.

   @Note: when a user is un-enrolled, the user is also de-registered with the SDK

   @param "status": status object containing debug information
 */
// Go to the link above "IntuneMAMEnrollmentDelegate.h Description" for more info.
- (void) unenrollRequestWithStatus:(IntuneMAMEnrollmentStatus *)status {
    if (status.didSucceed) {
        NSLog(@"MAM Unenrollment Successful");
        // We need to be on the main thread to do any UI related calls, so wrap all of this in
        // the mainQueue
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[[UIApplication sharedApplication] keyWindow] setRootViewController:[UIUtil loginViewController]];
        }];

        // We need the account UPN for MSAL
        NSString *enrolledAccount = status.identity;

        /*
         MSAL needs the application object to perform the sign out. Below creates the same exact application object that's documented and created in LoginViewController.m. If you want more information on it, go to that file for detailed comments and documentation.
         */
        NSError *msalError = nil;

        MSALPublicClientApplicationConfig *config = [[MSALPublicClientApplicationConfig alloc]
                                                     initWithClientId:IntuneMAMSettings.aadClientIdOverride
                                                     redirectUri:IntuneMAMSettings.aadRedirectUriOverride
                                                     authority:nil];

        config.clientApplicationCapabilities = @[@"protapp"];

        MSALPublicClientApplication *wagrMSALPublicClientApplication = [[MSALPublicClientApplication alloc] initWithConfiguration:config error:&msalError];

        MSALAccount *account = [wagrMSALPublicClientApplication accountForUsername:enrolledAccount error:&msalError];

        MSALWebviewParameters *webParameters = [[MSALWebviewParameters alloc] initWithAuthPresentationViewController:[[UIApplication sharedApplication] keyWindow].rootViewController];

        // These are the web view parameters that are used when signing out. They are similar to MSALInteractiveTokenParameters,
        // except these are for signing out.
        MSALSignoutParameters *signoutParameters = [[MSALSignoutParameters alloc] initWithWebviewParameters:webParameters];
        signoutParameters.signoutFromBrowser = NO;

        /*
         After making sure you have the application object ready to go, we call the sign out method for MSAL.
         For more info: https://github.com/AzureAD/microsoft-authentication-library-for-objc#objective-c-9
         */

        [wagrMSALPublicClientApplication signoutWithAccount:account signoutParameters:signoutParameters completionBlock:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                NSLog(@"MSALSignoutCompletionBlock: Signout successful");
                // We need to be on the main thread to do any UI related calls, so wrap all of this in
                // the mainQueue
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [[UIUtil currentViewController] presentViewController:[UIUtil alertController:@"Successfully Signed Out" message:@"Close and reopen the app to sign in again."] animated:true completion:nil];
                }];
            } else {
                // Signout failed
                NSLog(@"MSALSignoutCompletionBlock Signout Error: %@", error.localizedDescription);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [[UIUtil currentViewController] presentViewController:[UIUtil alertController:@"MSAL Signout Error" message:error.localizedDescription] animated:true completion:nil];
                }];
            }
        }];
    } else {
        NSLog(@"Unenrollment result for identity %@ with status code %ld", status.identity, (unsigned long)status.statusCode);
        NSLog(@"Debug Message: %@", status.errorString);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[UIUtil currentViewController] presentViewController:[UIUtil alertController:@"MAM Unenrollment Error" message:status.errorString] animated:true completion:nil];
        }];
    }
}

@end

