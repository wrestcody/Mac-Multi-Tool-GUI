//
//  DiskArbApp.h
//  DiskArbTest
//
//  Created by Kristopher Scruggs on 2/10/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "CNOutlineView.h"

enum {
    kDiskUnmountOptionDefault = 0x00000000,
    kDiskUnmountOptionForce = 0x00080000,
    kDiskUnmountOptionWhole = 0x00000001
};

@interface DiskUtilityController : NSViewController <NSUserNotificationCenterDelegate> {
    
}

@property (weak) IBOutlet CNOutlineView *diskView;
@property (weak) IBOutlet NSButton *verifyDiskButton;
@property (weak) IBOutlet NSButton *repairDiskButton;
@property (weak) IBOutlet NSButton *repairPermissionsButton;
@property IBOutlet NSTextView *outputText;

@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSArrayController *disksArrayController;

@property (assign) IBOutlet NSButton *ejectButton;
@property (assign) IBOutlet NSButton *mountButton;

@property (assign) IBOutlet NSTextField *diskNameField;
@property (assign) IBOutlet NSTextField *diskInfoField;
@property (assign) IBOutlet NSImageView *diskImageField;

@property (assign) IBOutlet NSTextField *mountPointText;
@property (assign) IBOutlet NSTextField *capacityText;
@property (assign) IBOutlet NSTextField *usedText;
@property (assign) IBOutlet NSTextField *uuidText;
@property (assign) IBOutlet NSTextField *typeText;
@property (assign) IBOutlet NSTextField *availableText;
@property (assign) IBOutlet NSTextField *deviceText;

@property (assign) IBOutlet NSTextField *mountPointPartitionMap;
@property (assign) IBOutlet NSTextField *usedLocation;
@property (assign) IBOutlet NSTextField *typeConnection;
@property (assign) IBOutlet NSTextField *availableChildren;

@property (assign) IBOutlet NSProgressIndicator *diskSize;


@property NSArray *disks;
@property NSRect selected;

//Work with this more later - right now just a placeholder.
@property BOOL currentlyWorking;

@end
