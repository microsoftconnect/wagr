//
//  MAMComplianceDelegate.h
//  Wagr
//
//  Copyright (c) 2021 Microsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IntuneMAMSwift/IntuneMAMComplianceManager.h>

@interface MAMComplianceDelegate : NSObject<IntuneMAMComplianceDelegate>

- (nonnull instancetype) init;

@end
