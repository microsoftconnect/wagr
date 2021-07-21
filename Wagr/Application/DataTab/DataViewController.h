//
//  DataViewController.h
//  Wagr
//
//  Copyright (c) 2021 Microsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataViewController : UIViewController<UIDocumentInteractionControllerDelegate>

@property NSURL *savedFileURL;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *openButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
- (IBAction)onShareButtonPressed:(UIButton *)sender;

@end
