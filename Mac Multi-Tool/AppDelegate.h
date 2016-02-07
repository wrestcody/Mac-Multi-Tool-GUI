//
//  AppDelegate.h
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/4/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CNOutlineView.h"
#import "CNDiskList.h"
#import "CNDiskRep.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSToolbarDelegate>

@property (weak) IBOutlet NSWindow *window;

@property (nonatomic, retain) NSToolbar             *toolbar;
@property (nonatomic, retain) NSArray                 *toolbarTabsArray;
@property (nonatomic, retain) NSMutableArray        *toolbarTabsIdentifierArray;
@property (nonatomic, retain) NSString                *currentView;

@property (nonatomic, readonly) NSViewController    *currentViewController;

- (IBAction)diskMenuApp:(id)sender;

@end

