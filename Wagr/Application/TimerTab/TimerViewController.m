//
//  ViewController.m
//  Wagr
//
//  Copyright (c) 2021 Microsoft. All rights reserved.
//

#import "SettingsViewController.h"
#import "TimerViewController.h"

@interface TimerViewController()

@property NSTimeInterval pauseTimeInterval;
@property NSTimeInterval elapsedTime;
@property BOOL timerRunning;
@property double moneyEarned;
@property double hourlyWage;

@end

@implementation TimerViewController

@synthesize calendarData;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _timerRunning = NO;
    _pauseTimeInterval = 0;
    calendarData = [[CalendarData alloc] init];

    _hourlyWage = [SettingsViewController getHourlyWage];
    
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM"];
    
    self.monthLabel.text = [[formatter stringFromDate:now] uppercaseString];
    
    [formatter setDateFormat:@"d"];
    self.dayLabel.text = [formatter stringFromDate:now];
    
    self.clockButton.layer.borderWidth=1.0f;
    self.clockButton.layer.borderColor=[[UIColor blueColor] CGColor];
    self.clockButton.layer.cornerRadius = 12;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)onClockButtonPressed:(UIButton *)sender {
    if (!_timerRunning){
        [UIView performWithoutAnimation:^{
            [self.clockButton setTitle:@"Clock Out" forState:UIControlStateNormal];
        }];
        
        _timerRunning = YES;
        
        self.startDate = [NSDate date] ;
        self.startDate = [self.startDate dateByAddingTimeInterval:((-1)*(_pauseTimeInterval))];
        self.timeWorkedTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/10.0 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    }
    else{
        [UIView performWithoutAnimation:^{
            [self.clockButton setTitle:@"Clock In" forState:UIControlStateNormal];
        }];
        
        
        _timerRunning = NO;
        [self.calendarData recordCalendarData:self.startDate wage:_hourlyWage timeWorked:self.timeWorkedLabel.text];
        [self.calendarData saveCalendarData];
        [self.timeWorkedTimer invalidate];
        self.timeWorkedTimer = nil;
        
        [self updateUI];
        self.timeWorkedLabel.text = [self.timeWorkedLabel.text stringByReplacingOccurrencesOfString:@" "
                                                                                         withString:@":"];
    }
}

- (void) updateUI {
    [self updateTimer];
    [self updateMoneyEarned];
}

-(void) updateTimer {
    
    NSDate *currentDate = [NSDate date];
    
    _elapsedTime = [currentDate timeIntervalSinceDate:self.startDate];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:_elapsedTime];
    
    //Format the date to show Hours and Minutes.
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    
    //Format the Seconds label.
    NSDateFormatter *dateFormatterSeconds = [[NSDateFormatter alloc] init];
    [dateFormatterSeconds setDateFormat:@"ss"];
    [dateFormatterSeconds setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
    
    //Turn the timestamp from the timer into a string.
    NSString *timeString = [dateFormatter stringFromDate:timerDate];
    NSString *secondsString = [dateFormatterSeconds stringFromDate:timerDate];
    self.timeWorkedLabel.text = timeString;
    self.timeWorkedSecondsLabel.text = secondsString;
    _pauseTimeInterval = _elapsedTime;
    
    //If the time is odd, remove the : from the time, creating a blinking : effect.
    if ([[dateFormatterSeconds stringFromDate:timerDate] integerValue] % 2) {
        self.timeWorkedLabel.text = [self.timeWorkedLabel.text stringByReplacingOccurrencesOfString:@":"
                                                                                         withString:@" "];
    }
}

-(void) updateMoneyEarned {
    double wagePerSecond = _hourlyWage / 3600.0;
    
    _moneyEarned = (wagePerSecond * _elapsedTime);
    
    self.moneyMadeLabel.text = [NSString stringWithFormat:@"%.2f", (_moneyEarned)];
}

@end
