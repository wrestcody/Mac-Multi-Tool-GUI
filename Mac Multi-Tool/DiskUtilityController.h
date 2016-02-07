//
//  DiskUtilityController.h
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/6/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CNOutlineView.h"
#import "CNDiskList.h"
#import "CNDiskRep.h"

@interface DiskUtilityController : NSViewController

@property (weak) IBOutlet CNOutlineView *diskView;
@property NSArray *disks;
@property NSRect selected;

@end
