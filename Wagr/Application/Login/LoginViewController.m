//
//  LoginViewController.m
//  Wagr
//
//  Copyright (c) 2021 Microsoft. All rights reserved.
//

#import "LoginViewController.h"
#import "MAMEnrollmentDelegate.h"
#import "UIUtil.h"
#import <IntuneMAMSwift/IntuneMAMComplianceManager.h>
#import <IntuneMAMSwift/IntuneMAMEnrollmentManager.h>
#import <IntuneMAMSwift/IntuneMAMSettings.h>
#import <MSAL/MSALAADAuthority.h>
#import <MSAL/MSALAccount.h>
#import <MSAL/MSALError.h>
#import <MSAL/MSALInteractiveTokenParameters.h>
#import <MSAL/MSALPublicClientApplication.h>
#import <MSAL/MSALResult.h>
#import <MSAL/MSALWebviewParameters.h>

@implementation LoginViewController

// The button that will log the user in.
- (IBAction)logInBtn:(id)sender {
    // Call the method to log into MSAL and MAM.
    [self MSALandMAMLogin];
}

#pragma mark - MSAL & MAM Login

#pragma mark MSAL Login

// The method that calls into MSAL and then MAM
- (void)MSALandMAMLogin {
    /*
     This is all the MSAL related setup.

     After doing all the setup for MSAL, it will then call MAM in the completion block.

     Below is a link that talks about setting up MSAL for login.

     For this example, we're using a single identity.

     We don't save the accessToken, but we do save the identifier as that would be needed for other functionality like signing out.

     Link: https://github.com/AzureAD/microsoft-authentication-library-for-objc/blob/dev/README.md#objective-c
     */
    NSError *msalError = nil;

    MSALPublicClientApplicationConfig *config = [[MSALPublicClientApplicationConfig alloc]
                                                 initWithClientId:IntuneMAMSettings.aadClientIdOverride
                                                 redirectUri:IntuneMAMSettings.aadRedirectUriOverride
                                                 authority:nil];

    /*
     IF YOU ARE IMPLEMENTING CONDITIONAL ACCESS (CA) IN YOUR APP, PLEASE PAY ATTENTION TO THE FOLLOWING...
     */
    // This is needed for CA!
    // This line adds an option to the MSAL token request so that MSAL knows that CA may be active.
    // Without this, MSAL won't know that CA could be activated.
    // In the event that CA is activated and this line isn't in place, the auth flow will fail.
    config.clientApplicationCapabilities = @[@"protapp"];

    MSALPublicClientApplication *wagrMSALPublicClientApplication = [[MSALPublicClientApplication alloc] initWithConfiguration:config error:&msalError];

    // This lets MSAL know which view controller to base the webview stuff from.
    MSALWebviewParameters *webViewParameters = [[MSALWebviewParameters alloc] initWithAuthPresentationViewController:self];
    webViewParameters.webviewType = MSALWebviewTypeWKWebView;

    // add comments for the scopes
    NSArray<NSString *> *scopes = @[@"user.read", @"Calendars.Read"];

    // Token parameters to use when getting a token from MSAL.
    MSALInteractiveTokenParameters *interactiveParams = [[MSALInteractiveTokenParameters alloc] initWithScopes:scopes webviewParameters:webViewParameters];

    // Let's MSAL know what kind of prompt to use for the interactive auth flow
    //interactiveParams.promptType = MSALPromptTypeSelectAccount;

    // The completion block of code that is called when the MSAL application object is finished with the flow with MSAL.
    // It will return an error into the completion block if it fails.
    // Handle logic for what happens after interacting with MSAL in the completion block.
    // Example, CA logic
    MSALCompletionBlock wagrMSALCompletionBlock = [self myMSALCompletionBlock];

    // The acquire token call with MSAL
    [wagrMSALPublicClientApplication acquireTokenWithParameters:interactiveParams completionBlock:wagrMSALCompletionBlock];
}

#pragma mark MAM Login
// The MAM login and enrollment happens in here, so after the MSAL login method is called.
- (MSALCompletionBlock)myMSALCompletionBlock {
    MSALCompletionBlock wagrMSALCompletionBlock = ^(MSALResult *result, NSError *error) {
        if (!error)
        {
            NSLog(@"Sign in for %@ was successful", result.account.username);

            // This will initiate the register and enroll precess for MAM.
            // Link: https://docs.microsoft.com/mem/intune/developer/app-sdk-ios#apps-that-already-use-adal-or-msal
            [[IntuneMAMEnrollmentManager instance] registerAndEnrollAccount:result.account.username];
        }
        // If CA is active, MSAL will respond back with this error.
        else if (error.code == MSALErrorServerProtectionPoliciesRequired) {
            // Check the error
            NSLog(@"MSAL Error: %@", error.localizedDescription);
            NSLog(@"Protection Policies Required Because CA is Active");
            NSLog(@"Begin IntuneMAM Remediation...");

            // MSAL stores the User ID in the userInfo dictionary under MSALDisplayableUserIdKey.
            // Access that in order to call the compliance manager with the correct UserId credentials as the identity.
            [[IntuneMAMComplianceManager instance] remediateComplianceForIdentity:error.userInfo[MSALDisplayableUserIdKey] silent:NO];
        }
        // This error happens when the given Client ID wasn't authorized.
        // This could happen if you didn't properly set your Client ID in the AppDelegate.
        else if (error.code == MSALInternalErrorUnauthorizedClient) {
            // Check the error
            NSLog(@"MSAL Error: %@", error.localizedDescription);
            [self presentViewController:[UIUtil alertController:@"ClientID Error" message:@"Your client ID was not found"] animated:true completion:nil];
        }
        // This error happens when the user cancels the login flow.
        else if (error.code == MSALErrorUserCanceled) {
            // Check the error.
            NSLog(@"MSAL Error: %@", error.localizedDescription);
            [self presentViewController:[UIUtil alertController:@"User Canceled" message:error.localizedDescription] animated:true completion:nil];
        }
        // This error is an MSAL internal error.
        else if (error.code == MSALErrorInternal) {
            // Check the error.
            NSLog(@"MSAL Internal Error: %@", error.localizedDescription);
            [self presentViewController:[UIUtil alertController:@"MSAL Error" message:error.localizedDescription] animated:true completion:nil];
        }
        else
        {
            // Check the error.
            NSLog(@"MSAL Error: %@", error.localizedDescription);
            [self presentViewController:[UIUtil alertController:@"MSAL Error" message:error.localizedDescription] animated:true completion:nil];
        }
    };
    return wagrMSALCompletionBlock;
}

@end
