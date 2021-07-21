//
//  ViewController.h
//  Wagr
//
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "CalendarData.h"
#import <UIKit/UIKit.h>

@interface TimerViewController : UIViewController

@property CalendarData *calendarData;

@property (weak, nonatomic) IBOutlet UIButton *onClockButtonPressed;
@property (weak, nonatomic) IBOutlet UIButton *clockButton;

@property (weak, nonatomic) IBOutlet UILabel *moneyMadeLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeWorkedLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeWorkedSecondsLabel;

@property (strong, nonatomic) NSTimer *timeWorkedTimer; // Store the timer that fires after a certain time
@property (strong, nonatomic) NSDate *startDate; // Stores the date of the click on the start button


@end
