//
//  CalendarData.h
//  Wagr
//
//  Copyright (c) 2015 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface CalendarData : NSObject

+ (NSString*) getFilePath;

- (void) recordCalendarData: (NSDate*)date wage:(double)wage timeWorked: (NSString*)timeWorked;
- (void) saveCalendarData;
- (UIDocumentInteractionController*) getDocumentInteractionController;
- (NSURL*) saveFileAndGetURL;
- (NSString*) loadDataFromFile: (NSString*) filePath;
@end
