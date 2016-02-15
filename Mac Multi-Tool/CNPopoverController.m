//
//  CNPopoverController.m
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/6/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import "CNPopoverController.h"

@interface CNPopoverController ()

@end

@implementation CNPopoverController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [_info setTextColor:[NSColor whiteColor]];
    [_info setFont:[NSFont fontWithName:@"Menlo" size:11]];
}

- (void)setText:(NSString *)text {
    [_info setString:text];
    
    //NSTextStorage *newStorage = [[NSTextStorage alloc] initWithString: text];
    //[_info.layoutManager replaceTextStorage: newStorage];
    
    //[_info setNeedsDisplay:YES];
}

- (void)setTitle:(NSString *)text {
    [_titleField setStringValue:[NSString stringWithFormat:@"Name: %@", text]];
}

@end
