//
//  CalendarData.m
//  Wagr
//
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import "CalendarData.h"
#import "DateUtility.h"
@import UIKit;

@implementation CalendarData
    NSMutableDictionary *calendarDictionary;
    
//@synthesize calendarDictionary;

- (id) init{
    [self loadCalendarData];
    return self;
}

+ (NSString *) getFilePath {
    return [NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), @"data.csv"];
}

- (void) loadCalendarData{
    
    //Find calendar data in plist file and load to calendar dictionary.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [directoryPaths objectAtIndex:0];
    NSString *userDataPath = [documentsPath stringByAppendingPathComponent:@"UserData.plist"];
    
    //look for plist in documents, if not there, retrieve from mainBundle
    if (![fileManager fileExistsAtPath:userDataPath]){
        userDataPath = [[NSBundle mainBundle] pathForResource:@"UserData" ofType:@"plist"];
    }
    
    NSData *userData = [fileManager contentsAtPath:userDataPath];
    NSError *error;
    NSPropertyListFormat format;
    NSMutableDictionary *userDataDictionary = (NSMutableDictionary *)[NSPropertyListSerialization propertyListWithData:userData options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
    
    
    calendarDictionary = [userDataDictionary objectForKey:@"calendar"];
    
}

- (void) loadCalendarDataFromFile{

    //Find calendar data in plist file and load to calendar dictionary.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [directoryPaths objectAtIndex:0];
    NSString *userDataPath = [documentsPath stringByAppendingPathComponent:@"UserData.plist"];

    //look for plist in documents, if not there, retrieve from mainBundle
    if (![fileManager fileExistsAtPath:userDataPath]){
        userDataPath = [[NSBundle mainBundle] pathForResource:@"UserData" ofType:@"plist"];
    }

    NSData *userData = [fileManager contentsAtPath:userDataPath];
    NSError *error;
    NSPropertyListFormat format;
    NSMutableDictionary *userDataDictionary = (NSMutableDictionary *)[NSPropertyListSerialization propertyListWithData:userData options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];


    calendarDictionary = [userDataDictionary objectForKey:@"calendar"];

}

- (void) recordCalendarData: (NSDate*)date wage:(double)wage timeWorked: (NSString*)timeWorked {
    //When stop button is pressed, record new data to plist
    //date is NSString in format yyyymmdd
    //hours and wage are NSNumbers representing hours worked, and wage per hour
    //NOTE: 1 wage per day. Currently new wage will not override.
    
    NSArray *hoursAndMinutes = [timeWorked componentsSeparatedByString: @":"];
    if([hoursAndMinutes count]!=2){
        hoursAndMinutes = [timeWorked componentsSeparatedByString: @" "];
    }
    double hours = [hoursAndMinutes[0] doubleValue] + [hoursAndMinutes[1] doubleValue]/60;

    //add array back to calendar
    
    NSMutableArray *newData = [NSMutableArray arrayWithObjects: [NSNumber numberWithDouble:hours], [NSNumber numberWithDouble:wage], nil];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";
    NSDate *todaysDate = [NSDate date];
    NSString* dateString = [dateFormatter stringFromDate:todaysDate];
    [calendarDictionary setObject:newData forKey:dateString];
}

- (void) saveCalendarData {
    //Save calendar back to plist in documents
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [directoryPaths objectAtIndex:0];
    NSString *userDataPath = [documentsPath stringByAppendingPathComponent:@"UserData.plist"];
    NSDictionary *userData = [NSDictionary dictionaryWithObject:calendarDictionary forKey: @"calendar"];
    
    
    NSError *error;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:userData format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    [plistData writeToFile:userDataPath atomically:YES];
}

- (NSString*) getFileForExport {
    //convert data to a file for excel.

    NSMutableString* fileData = [NSMutableString stringWithString:@""];

    for(id key in calendarDictionary) {
        id value = [calendarDictionary objectForKey:key];
        [fileData appendString:key];
        [fileData appendString:@", "];
        NSString* hours = [value[0] descriptionWithLocale:nil];
        [fileData appendString:hours];
        [fileData appendString:@", "];
        NSString* wage = [value[1] descriptionWithLocale:nil];
        [fileData appendString:wage];
        [fileData appendString:@"\n"];
    }

    NSError *error;
    NSString *filePath = [CalendarData getFilePath];
    
    [fileData writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    return filePath;
}

- (UIDocumentInteractionController*) getDocumentInteractionController {
    NSString* filePath = [self getFileForExport];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    UIDocumentInteractionController* controller= [UIDocumentInteractionController interactionControllerWithURL:url];
    return controller;
}

- (NSURL*) saveFileAndGetURL {
    NSString* filePath = [self getFileForExport];
    return [NSURL fileURLWithPath:filePath];
}

- (NSString*) loadDataFromFile: (NSString*) filePath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *fileContents;
    if ([fileManager fileExistsAtPath:filePath]){
        fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    }else{
        return nil;
    }
    
    NSArray *rows = [fileContents componentsSeparatedByString: @"\n"];
    NSString *dataToBePrinted = @"";

    for(NSString* row in rows){
        NSArray *seperatedRow = [row componentsSeparatedByString:@","];
        // Check for the terminal row which will only have "row" as the only element.
        if (seperatedRow.count != 1) {
            dataToBePrinted = [dataToBePrinted stringByAppendingString:@"\nEntry\n"];
            dataToBePrinted = [dataToBePrinted stringByAppendingString:[NSString stringWithFormat:@"Date, Time, & Time Zone:%@\n", seperatedRow[0]]];
            dataToBePrinted = [dataToBePrinted stringByAppendingString:[NSString stringWithFormat:@"Hours Worked:%@\n", seperatedRow[1]]];
            dataToBePrinted = [dataToBePrinted stringByAppendingString:[NSString stringWithFormat:@"Pay Rate:%.2f\n", ([seperatedRow[2] floatValue]/100)]];
        }
    }

    return dataToBePrinted;
}

@end
