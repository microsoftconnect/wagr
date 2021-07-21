//
//  DateUtility.h
//  Wagr
//
//  Copyright (c) 2021 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateUtility : NSObject

+(NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

@end
