//
//  DiskArbApp.m
//  DiskArbTest
//
//  Created by Kristopher Scruggs on 2/10/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import "DiskUtilityController.h"
#import "Arbitration.h"
#import "Disk.h"
#import "AAPLImageAndTextCell.h"

@import ServiceManagement;
@import AppKit;

#pragma mark -

#define COLUMNID_NAME               @"Name"
#define IMAGE_PAD                   3

static NSSize imageSize;

#pragma mark -

@implementation DiskUtilityController

- (id)init {
    if (self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil]) {
        // Register default preferences - if they exist
        
        // Disk Arbitration
        RegisterDA();
        
        // App & Workspace Notification
        [self registerSession];
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    }
    
    return self;
}

#pragma mark - View Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    //Set our image size here
    imageSize = NSMakeSize(16, 16);
    
    [_outputText setFont:[NSFont fontWithName:@"Menlo" size:11]];
    
    _currentlyWorking = NO;
    
    
    [_diskView setDataSource:(id<NSOutlineViewDataSource>)self];
    [_diskView setDelegate:(id<NSOutlineViewDelegate>)self];
    
    //Set up for receiving double-click notifications
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineViewDoubleClick:) name:@"OutlineViewDoubleClick" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineViewSelected:) name:@"OutlineViewSelected" object:nil];
    
    //_disks = [[CNDiskList sharedList] getOutlineViewList];
    
    //_disks = [[CNDiskList sharedList] getAllDisksAndPartitionsList];
    
    //NSLog(@"%@", [[[[_disks objectAtIndex:0] getChildren] objectAtIndex:1] getObjects]);
    
    
    
    // Clear the text fields in the window
    [_mountPointText setStringValue:@""];
    [_capacityText setStringValue:@""];
    [_usedText setStringValue:@""];
    [_uuidText setStringValue:@""];
    [_typeText setStringValue:@""];
    [_availableText setStringValue:@""];
    [_deviceText setStringValue:@""];
    
    [_uuidText setSelectable:YES];
    
    //[_diskSize NSProgressIndicatorThickness]
    
    
    //Setup our popover button
    /*_popoverViewController = [[NSClassFromString(@"CNPopoverController") alloc] init];
    
    NSRect frame = self.popoverViewController.view.bounds;
    NSUInteger styleMask = NSTitledWindowMask + NSClosableWindowMask;
    NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
    _detachedWindow = [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing:NSBackingStoreBuffered defer:YES];
    self.detachedWindow.contentViewController = self.popoverViewController;
    self.detachedWindow.releasedWhenClosed = NO;*/
    
    
    [_diskView reloadData];
    //Load outlineview expanded.
    [_diskView expandItem:nil expandChildren:YES];
}

#pragma mark - OutlineView Click/Double-Click Methods

- (void)outlineViewDoubleClick:(id)note {
    /*//Load the disk that we just double clicked.
    //_disks = [[CNDiskList sharedList] getDiskViewList:[note userInfo]];
    //[_diskView reloadData];
    _selected = [[[note userInfo] objectForKey:@"Rect"] rectValue];
    CNDiskRep *diskForInfo = [[note userInfo] objectForKey:@"Item"];
    NSString *diskInfo = [[CNDiskList sharedList] getStringForDisk:diskForInfo];
    NSString *diskName = [diskForInfo objectForKey:@"Name"];
    if ([diskName isEqualToString:@""]) {
        diskName=@"None";
    }
    
    [_popoverViewController setText:diskInfo];
    [_popoverViewController setTitle:diskName];
    [self showPopoverAction:_diskView];*/
}

- (void)outlineViewSelected:(id)note {
    // Reload all our info
    [self respondToSelectedItem:_diskView];
}

#pragma mark - UI Methods

- (void)respondToSelectedItem:(NSOutlineView *)outlineView {
    id selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
    if ([selectedItem isKindOfClass:[Disk class]]) {
        // Let's enable/disable buttons based on disk info
        Disk *disk = selectedItem;
        [_ejectButton setEnabled:NO];
        [_mountButton setEnabled:NO];
        if ([disk isMounted]) {
            if (![[disk volumePath] isEqualToString:@"/"]) {
                [_ejectButton setEnabled:YES];
            }
        } else if ([disk isMountable]) {
            [_mountButton setEnabled:YES];
        } else if ([disk isWholeDisk] && ([disk isEjectable] || [disk isRemovable])) {
            BOOL anyMounted = NO;
            for (Disk *child in [disk children]) {
                // Find out if all disks are unmounted
                if ([child isMounted]) anyMounted = YES;
            }
            if (anyMounted) {
                [_ejectButton setEnabled:YES];
            } else {
                [_mountButton setEnabled:YES];
            }
        }
        
        // Grab info from disk
        // Setup top & bottom of window info
        if ([disk volumeName]) {
            [_diskNameField setStringValue:[disk volumeName]];
        } else if ([disk mediaName]) {
            [_diskNameField setStringValue:[disk mediaName]];
        }
        
        // Get the icon
        [_diskImageField setImage:disk.icon];
        
        // Build the info string - Size Connection FS
        NSString *fs = @"No File System";
        if ([disk volumeFS]) fs = [disk volumeFS];
        NSString *infoString = [NSString stringWithFormat:@"%@ - %@ - %@ (%@)", [disk formattedSize], [disk deviceProtocol], fs, disk.BSDName];
        [_diskInfoField setStringValue:infoString];
        
        if ([disk isWholeDisk]) {
            // Set our labels first, then the values
            [_mountPointPartitionMap setStringValue:@"Partition Map:"];
            [_usedLocation setStringValue:@"Location:"];
            [_typeConnection setStringValue:@"Connection:"];
            [_availableChildren setStringValue:@"Children:"];
            
            [_mountPointText setStringValue:[disk mediaContent] ?: @"Unknown"];
            [_capacityText setStringValue:[disk formattedSize] ?: @"Unknown"];
            [_typeText setStringValue:[disk deviceProtocol] ?: @"Unknown"];
            [_usedText setStringValue:[disk isInternal] ? @"Internal" : @"External"];
            [_uuidText setStringValue:@"N/A"]; // Empty string for whole disk
            [_availableText setStringValue:[NSString stringWithFormat:@"%lu", [disk.children count]]];
            
            [_diskSize setMaxValue:[[disk mediaSize] doubleValue]];
            [_diskSize setDoubleValue:0];
            [_diskSize incrementBy:[[disk mediaSize] doubleValue]];
            
        } else {
            // Set our labels first, then the values
            [_mountPointPartitionMap setStringValue:@"Mount Point:"];
            [_usedLocation setStringValue:@"Used:"];
            [_typeConnection setStringValue:@"Type:"];
            [_availableChildren setStringValue:@"Available:"];
            
            [_mountPointText setStringValue:[disk volumePath] ?: @"Not Mounted"];
            [_capacityText setStringValue:[disk formattedSize] ?: @"Unknown"];
            [_usedText setStringValue:[disk formattedUsedSpace] ?: @"Unknown"];
            [_typeText setStringValue:[disk volumeFS] ?: @"Unknown"];
            [_availableText setStringValue:[disk formattedFreeSpace] ?: @"Unknown"];
            [_uuidText setStringValue:disk.diskUUID ?: @"Unknown"];
            
            [_diskSize setMaxValue:[[disk mediaSize] doubleValue]];
            [_diskSize setDoubleValue:0];
            [_diskSize incrementBy:[[disk usedSpace] doubleValue]];
        }
        [_deviceText setStringValue:disk.BSDName ?: @"No BSD Name"];
    }
}

- (IBAction)mountDisk:(id)sender {
    id selectedItem = [_diskView itemAtRow:[_diskView selectedRow]];
    if ([selectedItem isKindOfClass:[Disk class]]) {
        Disk *disk = selectedItem;
        
        /*if ([disk isWholeDisk]) {
            NSLog(@"diskutil mountDisk %@", disk.BSDName);
        } else {
            NSLog(@"diskutil mount %@", disk.BSDName);
        }*/
        if ([disk isWholeDisk]) {
            [disk mountWhole];
        } else {
            [disk mount];
        }
    }
}

- (IBAction)ejectDisk:(id)sender {
    id selectedItem = [_diskView itemAtRow:[_diskView selectedRow]];
    if ([selectedItem isKindOfClass:[Disk class]]) {
        Disk *disk = selectedItem;
        
        if (!disk) return;
        
        if ([disk isWholeDisk] && [disk isEjectable]) {
            [self performEject:disk];
        } else {
            [disk unmountWithOptions: disk.isWholeDisk ?  kDiskUnmountOptionWhole : kDiskUnmountOptionDefault];
        }
        /*if ([disk isWholeDisk]) {
            NSLog(@"diskutil unmountDisk %@", disk.BSDName);
        } else {
            NSLog(@"diskutil unmount %@", disk.BSDName);
        }*/
    }
}

- (void)performEject:(Disk *)disk {
    BOOL waitForChildren = NO;
    
    NSArray *disks;
    if (disk.isWholeDisk && disk.isLeaf)
        disks = [NSArray arrayWithObject:disk];
    else
        disks = disk.children;
    
    for (Disk *aDisk in disks) {
        if (aDisk.isMountable && aDisk.isMounted) {
            /*[[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_childDidAttemptUnmountBeforeEject:)
                                                         name:@"DADiskDidAttemptUnmountNotification"
                                                       object:aDisk];*/
            [aDisk unmountWithOptions:0];
            waitForChildren = YES;
        }
    }
    
    if (!waitForChildren) {
        if (disk.isEjectable)
            [disk eject];
    }
}


#pragma mark - Outline View Delegate Methods


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        // Root
        return [diskArray objectAtIndex:index];
    }
    
    if ([item isKindOfClass:[Disk class]]) {
        Disk *disk = item;
        return [disk.children objectAtIndex:index];
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass:[NSArray class]]) {
        return YES;
    }
    if ([item isKindOfClass:[Disk class]]) {
        Disk *disk = item;
        if ([disk.children count] > 0) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        // Root
        return [diskArray count];
    }
    
    /*if ([item isKindOfClass:[Disk class]] && [item hasChildren]) {
        return [[item getChildren] count];
    }*/
    
    if ([item isKindOfClass:[Disk class]]) {
        Disk *disk = item;
        return [disk.children count];
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn byItem:(nullable id)item {
    
    if ([item isKindOfClass:[Disk class]]) {
        
        // Setup some variables
        
        Disk *disk = item;
        NSColor *color = [NSColor blackColor];
        NSString *diskName = @"";
        
        // Color accordingly:
        // Boot drive = Blue
        // Whole disk = Black
        // Parition   = Dark Gray
        
        if ([[disk volumePath] isEqualToString:@"/"]) {
            color = [NSColor blueColor];
        } else if ([disk isMounted]) {
            color = [NSColor blackColor];
        } else if ([disk isWholeDisk]) {
            BOOL anyMounted = NO;
            for (Disk *child in [disk children]) {
                // Find out if all disks are unmounted
                if ([child isMounted]) anyMounted = YES;
            }
            if (!anyMounted) color = [NSColor darkGrayColor];
        } else {
            color = [NSColor darkGrayColor];
        }
        
        // Get a name for our disk
        // If whole disk - mediaName
        // if not, volumeName
        
        if ([disk volumeName]) {
            diskName = [disk volumeName];
        } else if ([disk mediaName]) {
            diskName = [disk mediaName];
        }
        
        // Setup our string and return it
        
        NSDictionary *attrs = @{ NSForegroundColorAttributeName : color };
        return [[NSAttributedString alloc] initWithString:diskName attributes:attrs];
    }
    
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if ([item isKindOfClass:[Disk class]]) {
        Disk *currentDisk = item;
        if ((tableColumn == nil) || [[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
            NSImage *tempImage = [currentDisk.icon copy];
            
            NSImage *diskImage = [self imageResize:tempImage newSize:imageSize];
            // We know that the cell at this column is our image and text cell, so grab it
            AAPLImageAndTextCell *imageAndTextCell = (AAPLImageAndTextCell *)cell;
            // Set the image here since the value returned from outlineView:objectValueForTableColumn:... didn't specify the image part...
            imageAndTextCell.myImage = diskImage;
            if ([currentDisk isWholeDisk]) {
                imageAndTextCell.opacity = 1;
            } else {
                if ([currentDisk isMounted]) {
                    imageAndTextCell.opacity = 0.9;
                } else {
                    imageAndTextCell.opacity = 0.4;
                }
            }
        }
    // For all the other columns, we don't do anything.
    }
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    return imageSize.height + IMAGE_PAD;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
   shouldSelectItem:(id)item {
    return !_currentlyWorking;
}

#pragma mark - Resize NSImage

- (NSImage *)imageResize:(NSImage*)anImage newSize:(NSSize)newSize {
    NSImage *sourceImage = anImage;
    //[sourceImage setScalesWhenResized:YES];
    
    // Report an error if the source isn't a valid image
    if (![sourceImage isValid]){
        NSLog(@"Invalid Image");
    } else {
        NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
        [smallImage lockFocus];
        [sourceImage setSize: newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}


#pragma mark - Notification Methods

- (void)diskAppeared:(NSNotification *)notification {
    Disk *disk = notification.object;
    
    //NSLog(@"Volume Path: %@", disk.volumePath);
    //NSLog(@"Disk Appeared: %@", disk.BSDName);
    NSLog(@"Description: %@", disk.description);

    //NSLog(@"Disks Count - %lu", (unsigned long)[allDisks count]);
    //NSLog(@"Disks:\n%@", diskArray);
    
    [_diskView reloadData];
    [self respondToSelectedItem:_diskView];
}

- (void)diskDisappeared:(NSNotification *)notification {
    Disk *disk = notification.object;
    
   // NSLog(@"Disk Disappeared - %@", disk.BSDName);
    
    [disk disappeared];
    
    [_diskView reloadData];
    [self respondToSelectedItem:_diskView];
}

- (void)volumeMountNotification:(NSNotification *) notification {
    /*Disk *disk = [Disk getDiskForUserInfo:notification.userInfo];
    
    if (disk) {
        //NSLog(@"Disk: '%@' mounted at '%@'", disk.BSDName, disk.volumePath);
    }*/
    
    [_diskView reloadData];
    [self respondToSelectedItem:_diskView];
    
}

- (void)volumeUnmountNotification:(NSNotification *) notification {
    /*Disk *disk = [Disk getDiskForUserInfo:notification.userInfo];
    
    if (disk) {
        //NSLog(@"Disk: '%@' unmounted from '%@'", disk.BSDName, disk.volumePath);
    }*/
    
    [_diskView reloadData];
    [self respondToSelectedItem:_diskView];
}

#pragma mark - Private Methods

- (void)registerSession {
    // App Level Notification
    NSNotificationCenter *acenter = [NSNotificationCenter defaultCenter];
    
    [acenter addObserver:self selector:@selector(diskAppeared:) name:@"diskAppearedNotification" object:nil];
    [acenter addObserver:self selector:@selector(diskDisappeared:) name:@"diskDisappearedNotification" object:nil];
    
    // Workspace Level Notification
    NSNotificationCenter *wcenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    
    [wcenter addObserver:self selector:@selector(volumeMountNotification:) name:NSWorkspaceDidMountNotification object:nil];
    [wcenter addObserver:self selector:@selector(volumeUnmountNotification:) name:NSWorkspaceDidUnmountNotification object:nil];
}

- (void)unregisterSession {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}



@end
