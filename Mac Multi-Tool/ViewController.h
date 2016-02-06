//
//  ViewController.h
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/4/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CNOutlineView.h"

@interface ViewController : NSViewController

@property (weak) IBOutlet CNOutlineView *diskView;
@property NSArray *disks;

@end

