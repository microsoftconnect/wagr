//
//  DataViewController.m
//  Wagr
//
//  Copyright (c) 2021 Microsoft. All rights reserved.
//

#import "CalendarData.h"
#import "DataViewController.h"
#import "UIUtil.h"
#import <IntuneMAMSwift/IntuneMAMPolicyManager.h>

@interface DataViewController()

@property (nonatomic) UIToolbar *doneToolbar;
@property (nonatomic, strong) CalendarData *calendarData;
@property (nonatomic, strong) UIDocumentInteractionController* controller;

@end

@implementation DataViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    _saveButton.hidden = ![self checkIfSaveToIsAllowed];
    _openButton.hidden = ![self checkIfOpenFromIsAllowed];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    // Initialize the calendar data object
    self.calendarData = [[CalendarData alloc] init];
    }

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeDoneToolbar];
}

- (void)makeDoneToolbar
{
    self.doneToolbar = [[UIToolbar alloc]initWithFrame:CGRectZero];
    self.doneToolbar.barStyle = UIBarStyleDefault;
    self.doneToolbar.items = [NSArray arrayWithObjects:
                          [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                       target:nil action:nil],
                          [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone
                                                         target:self.view   action:@selector(endEditing:)],
                          nil];
    [self.doneToolbar sizeToFit];
}

#pragma mark - Plot Data Source Methods


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}

#pragma mark - MAM Save-To and Open-From Policy
/*
 Intune lets IT admins select which storage locations a managed app can save data to or open data from.

 The below methods demonstrates how to call the methods.

 In this example, we are querying the Local Drive/Storage location which is storage on the device itself.

 Link for more info: https://docs.microsoft.com/mem/intune/developer/app-sdk-ios#implement-save-as-and-open-from-controls
 */

/*
 This method checks if the policy exists and then checks if save-to is allowed for the location. If it's successful,
 it will return YES. If the policy doesn't exist or if save-to is not allowed, it will present an alert controller.
 */
- (BOOL) checkIfSaveToIsAllowed {
    if ([[IntuneMAMPolicyManager instance] policy] &&
        [[[IntuneMAMPolicyManager instance] policy] isSaveToAllowedForLocation:IntuneMAMSaveLocationLocalDrive withAccountName:nil]) {
        return YES;
    } else {
        return NO;
    }
}

/*
 This method checks if the policy exists and then checks if open-from is allowed for the location. If it's successful,
 it will return YES. If the policy doesn't exist or if open-from is not allowed, it will present an alert controller.
 */
- (BOOL) checkIfOpenFromIsAllowed {
    if ([[IntuneMAMPolicyManager instance] policy] &&
        [[[IntuneMAMPolicyManager instance] policy] isOpenFromAllowedForLocation:IntuneMAMOpenLocationLocalStorage withAccountName:nil]) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - MAM Save-To and Open-From Policy Check UI Buttons
/*
 These methods will perform the save-to/open-from operations.
 */

// This method will save the data to local storage.
- (IBAction)onSaveToButtonPressed:(UIButton *)sender {
    _savedFileURL = [self.calendarData saveFileAndGetURL];

    [self presentViewController:[UIUtil alertController:@"Success" message:@"The file was successfully saved"] animated:true completion:nil];
}

// This method will load the calendar data that is saved to local storage and then display it
- (IBAction)onOpenFromButtonPressed:(UIButton *)sender {
    NSString *savedData = [self.calendarData loadDataFromFile:_savedFileURL.path];
    if (savedData) {
        [self presentViewController:[UIUtil alertController:@"Displaying Saved Data" message:[NSString stringWithFormat:@"%@",savedData]] animated:true completion:nil];
    } else {
        [self presentViewController:[UIUtil alertController:@"Error Loading Data" message:@"There was an error when loading the saved data"] animated:true completion:nil];
    }
}

#pragma mark Share Button

// This method will share the data.csv file.
// This method was implemented in the original Wagr.
- (IBAction)onShareButtonPressed:(id)sender {
    if  ([self checkIfSaveToIsAllowed]) {
        self.controller = [self.calendarData getDocumentInteractionController];
        [self.controller setDelegate:self];
        [self.controller presentOpenInMenuFromRect:self.shareButton.frame inView:self.view animated:YES];
    } else {
        [self presentViewController:[UIUtil alertController:@"Action Not Allowed" message:@"Your administrator does not allow saving to local storage which is required to share data."] animated:true completion:nil];
    }
}


@end
