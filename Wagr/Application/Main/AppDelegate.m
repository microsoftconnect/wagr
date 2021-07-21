//
//  AppDelegate.m
//  Wagr
//
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "AppDelegate.h"
#import <MSAL/MSALPublicClientApplication.h>
#import <IntuneMAMSwift/IntuneMAMPolicyDelegate.h>
#import <IntuneMAMSwift/IntuneMAMPolicyManager.h>
#import <IntuneMAMSwift/IntuneMAMEnrollmentManager.h>
#import <IntuneMAMSwift/IntuneMAMSettings.h>
#import "MAMEnrollmentDelegate.h"
#import "MAMPolicyDelegate.h"
#import "MAMComplianceDelegate.h"
#import "UIUtil.h"

@interface AppDelegate ()

@property (nonatomic, strong) MAMEnrollmentDelegate* enrollmentDelegate;
@property (nonatomic, strong) MAMComplianceDelegate* complianceDelegate;
@property (nonatomic, strong) MAMPolicyDelegate* policyDelegate;

@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - Setting Up the App Delegate
/*
 Pay close attention to the smaller comments in each of the following methods.

 The first method is needed to handle MSAL responses.

 The other methods contain commands that is needed for MAM to work.

 Link for MSAL App Delegate setup: (step 3) https://github.com/AzureAD/microsoft-authentication-library-for-objc#configuring-msal
 */

// This method is required so that the app can understand how to handle MSAL responses.
- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [MSALPublicClientApplication handleMSALResponse:url
                                         sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]];
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Set the enrollment and compliance manager manager delegate.
    [self setIntuneDelegates];

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /*
     One option is to set the Client ID, Authority URI, and Redirect URI is in the info.plist file.

     However, it is entirely possible to set these settings at runtime.

     In order to do so, you would set these values:

     IntuneMAMSettings.aadClientIdOverride = @"...";
     IntuneMAMSettings.aadAuthorityUriOverride = @"...";
     IntuneMAMSettings.aadRedirectUriOverride = @"...";
     */
    // You must add your Client ID or it won't work!
    IntuneMAMSettings.aadClientIdOverride = @"...";
    IntuneMAMSettings.aadRedirectUriOverride = @"msauth.com.microsoft.wagr://auth";
    
    // Check to see if an account is enrolled and act accordingly.
    NSString *currentUser = [[IntuneMAMEnrollmentManager instance] enrolledAccount];

    // App Delegate is on the main thread, so there's no need to wrap UI calls in this:
    // [NSOperationQueue mainQueue]
    if ([currentUser length] != 0) {
        [[[UIApplication sharedApplication] keyWindow] setRootViewController:[UIUtil mainTabBarController]];
    } else{
        [[[UIApplication sharedApplication] keyWindow] setRootViewController:[UIUtil loginViewController]];
    }

    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark - MAM Delegates

// Sets the delegates of the MAM objects to our defined delegates.
// The Enrollment manager is for enrollment related activities.
// The Compliance manager is for the compliance and CA related activities.
// The Policy Manager is for policy related activities.
- (void)setIntuneDelegates {
    _enrollmentDelegate = [[MAMEnrollmentDelegate alloc] init:[[UIApplication sharedApplication] keyWindow].rootViewController];
    [IntuneMAMEnrollmentManager instance].delegate = _enrollmentDelegate;

    _complianceDelegate = [[MAMComplianceDelegate alloc] init];
    [IntuneMAMComplianceManager instance].delegate = _complianceDelegate;

    _policyDelegate = [[MAMPolicyDelegate alloc] init];
    [IntuneMAMPolicyManager instance].delegate = _policyDelegate;
}

#pragma mark - Data, Documents, & Store

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.microsoft.Wagr" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Wagr" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store.
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Wagr.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application).
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)log:(nonnull NSString *)message level:(IntuneMAMLogLevel)level {
    NSLog(@"APP Log Relay:%@",message);
}

@end
