//
//  SettingsViewController.h
//  Wagr
//
//  Copyright (c) 2021 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField * _Nullable userName;
@property (weak, nonatomic) IBOutlet UILabel * _Nullable wage;

+(double)  getHourlyWage;

@end
