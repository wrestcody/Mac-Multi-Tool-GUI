//
//  CNPopoverController.h
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/6/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CNPopoverController : NSViewController

@property IBOutlet NSTextView *info;
@property IBOutlet NSTextField *titleField;

- (void)setText:(NSString *)text;
- (void)setTitle:(NSString *)text;

@end
