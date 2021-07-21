//
//  SettingsViewController.m
//  Wagr
//
//  Copyright (c) 2021 Microsoft. All rights reserved.
//

#import "SettingsViewController.h"
#import "UIUtil.h"
#import <IntuneMAMSwift/IntuneMAMAppConfig.h>
#import <IntuneMAMSwift/IntuneMAMAppConfigManager.h>
#import <IntuneMAMSwift/IntuneMAMDiagnosticConsole.h>
#import <IntuneMAMSwift/IntuneMAMEnrollmentManager.h>
#import <IntuneMAMSwift/IntuneMAMSettings.h>
#import <MSAL/MSALPublicClientApplication.h>
#import <MSAL/MSALSignoutParameters.h>
#import <MSAL/MSALWebviewParameters.h>

@implementation SettingsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // This calls the method that handles the MAM app config settings.
    [self mamAppConfig];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _userName.text = @"John Doe";
}

#pragma mark - MAM App Configuration

+(double)getHourlyWage {
    NSNumber *tempWage = [[[IntuneMAMAppConfigManager instance] appConfigForIdentity:[IntuneMAMEnrollmentManager instance].enrolledAccount] numberValueForKey:@"Wage" queryType:IntuneMAMNumberMax];

    if (tempWage) {
        return [tempWage doubleValue];
    } else {
        return 7.5;
    }
}

-(void)mamAppConfig {
    // NOTE: You have to use these exact keys in the app configuration settings that you set in the portal
    /*
     This method enacts MAM app config values in the app.

     You have to first setup the key/value pairs in the portal, then you use the commands as they were used below to pull the values into the app.

     For more info: https://docs.microsoft.com/mem/intune/developer/app-sdk-ios#enable-targeted-configuration-appmam-app-config-for-your-ios-applications
     */

    // This creates the AppConfig object to use.
    id<IntuneMAMAppConfig> appConfig = [[IntuneMAMAppConfigManager instance] appConfigForIdentity:[IntuneMAMEnrollmentManager instance].enrolledAccount];

    // This queries the app configuration settings in the portal and uses the passed in string as the key to return the value.
    NSString *tempUserName = nil;
    if ([appConfig hasConflict:@"UserName"]) {
        [self presentViewController:[UIUtil alertController:@"Multiple Names" message:@"The UserName config has multiple entries and is conflicting. The name will be set to the default value"] animated:YES completion:nil];
    } else {
        tempUserName = [appConfig stringValueForKey:@"UserName" queryType:IntuneMAMStringAny];
    }

    // The method (getHourlyWage) contains a call that does the same thing as above, except this expects a number.
    // Also, we will be using IntuneMAMNumberMax as the queryType because we know it is a number
    // and because we want the largest value in case there's multiple entries.
    // We also have to make sure to set the text field. The below statement handles all that.
    _wage.text = [NSString stringWithFormat:@"%.2f", [[self class] getHourlyWage]];

    // These if statements just checks to make sure that the appropriate key has a value.
    // If it returns nil, we will leave the text field as is.
    if (tempUserName) {
        _userName.text = tempUserName;
    }
}

#pragma mark - Links & Buttons

- (IBAction)onDocumentationLinkPressed:(id)sender {
    // The link to the documentation for the Intune iOS App SDK.
    // Link: https://docs.microsoft.com/intune/app-sdk-ios
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://docs.microsoft.com/intune/app-sdk-ios"] options:@{} completionHandler:nil];
}

- (IBAction)onFAQLinkPressed:(id)sender {
    // The link to the FAQ for the Intune iOS App SDK.
    // Link: https://docs.microsoft.com/intune/app-sdk-ios#faqs
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://docs.microsoft.com/intune/app-sdk-ios#faqs"] options:@{} completionHandler:nil];
}

#pragma mark The MAM Diagnostic Console (for troubleshooting MAM)

- (IBAction)onMAMDiagnosticConsoleBtnPressed:(UIButton *)sender {
    // Immediately displays the Intune Diagnostic Console.
    /*
    The Intune SDK for iOS 9.0.3+ supports the ability to add a diagnostics console within the mobile app for testing policies and logging errors. IntuneMAMDiagnosticConsole.h defines the IntuneMAMDiagnosticConsole class interface, which developers can use to display the Intune diagnostic console. This allows end users or developers during test to collect and share Intune logs to help diagnose any issue they may have. This API is optional for integrators.
     */
    // For more info: https://docs.microsoft.com/mem/intune/developer/app-sdk-ios#how-can-i-troubleshoot-my-app
    [IntuneMAMDiagnosticConsole displayDiagnosticConsole];
}

#pragma mark Deregister The Account (logout)

- (IBAction)onLogoutBtnPressed:(id)sender {
    

    // We need the enrolled account UPN for both the SDK and MSAL
    NSString *enrolledAccount = [IntuneMAMEnrollmentManager instance].enrolledAccount;

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

    MSALWebviewParameters *webParameters = [[MSALWebviewParameters alloc] initWithAuthPresentationViewController:self];

    // These are the web view parameters that are used when signing out. They are similar to MSALInteractiveTokenParameters,
    // except these are for signing out.
    MSALSignoutParameters *signoutParameters = [[MSALSignoutParameters alloc] initWithWebviewParameters:webParameters];
    signoutParameters.signoutFromBrowser = NO;

    MSALSignoutCompletionBlock wagrMSALSignOutCompletionBlock = [self myMSALSignOutCompletionBlock];

    /*
     Deregistering a user notifies the SDK that the user will no longer use the application, and the SDK can stop any of the periodic events for that user account. It also triggers an app unenroll and selective wipe if necessary.
     */
    // For more info: https://docs.microsoft.com/mem/intune/developer/app-sdk-ios#why-does-the-user-need-to-be-deregistered
    [[IntuneMAMEnrollmentManager instance] deRegisterAndUnenrollAccount:enrolledAccount withWipe:YES];

    /*
     After making sure you have the application object ready to go, we call the sign out method for MSAL.
     For more info: https://github.com/AzureAD/microsoft-authentication-library-for-objc#objective-c-9
     */

    [wagrMSALPublicClientApplication signoutWithAccount:account signoutParameters:signoutParameters completionBlock:wagrMSALSignOutCompletionBlock];
}

- (MSALSignoutCompletionBlock) myMSALSignOutCompletionBlock {
    MSALSignoutCompletionBlock wagrMSALSignOutCompletionBlock = ^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"MSALSignoutCompletionBlock: Signout successful");
        } else {
            // Signout failed
            NSLog(@"MSALSignoutCompletionBlock Signout Error: %@", error.localizedDescription);
        }
    };
    return wagrMSALSignOutCompletionBlock;
}

@end
