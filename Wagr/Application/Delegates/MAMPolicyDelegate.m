//
//  MAMPolicyDelegate.m
//  Wagr
//
//  Copyright (c) 2020 Microsoft. All rights reserved.
//

#import "CalendarData.h"
#import "MAMPolicyDelegate.h"
#import <IntuneMAMSwift/IntuneMAMPolicyManager.h>

@interface MAMPolicyDelegate ()

@end

@implementation MAMPolicyDelegate

NSError *error;

#pragma mark - IntuneMAMPolicyDelegate

/*
  Called by the Intune SDK when the application should wipe data for the specified account user principal name (e.g. user@contoso.com).

 Returns TRUE if successful, FALSE if the account data could not be completely wiped.

 Returning FALSE will cause the SDK to completely wipe all the files and everything associated with the account. For this sample app, we will let the SDK wipe everything only if we can't remove the files.

 (use below link and scroll down to "Selective Wipe")
 Link: https://docs.microsoft.com/mem/intune/developer/app-sdk-ios#switch-identities
 */
- (BOOL) wipeDataForAccount:(NSString*_Nonnull)upn {
    if ([self deleteData:error]) {
        return YES;
    } else {
        NSLog(@"Wagr wipeDataForAccount: %@", error.localizedDescription);
        return NO;
    }
}

#pragma mark - Helper Method to Delete Data

- (BOOL) deleteData:(NSError*)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *fileUrl = [NSURL fileURLWithPath:[CalendarData getFilePath]];

    if (![fileManager fileExistsAtPath:[fileUrl absoluteString]] || [fileManager removeItemAtURL:fileUrl error:&error] ) {
        return YES;
    } else {
        return NO;
    }
}

@end
