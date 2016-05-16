//
//  DiskArbApp.m
//  DiskArbTest
//
//  Created by Kristopher Scruggs on 2/10/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import "DiskUtilityController.h"
#import "Arbitration.h"
#import "AAPLImageAndTextCell.h"
#import "STPrivilegedTask.h"

@import ServiceManagement;
@import AppKit;

#pragma mark -

#define COLUMNID_NAME               @"Name"
#define IMAGE_PAD                   3

static NSSize imageSize;

#pragma mark -

@implementation DiskUtilityController

@synthesize _shouldResize;

- (id)init {
    if (self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil]) {
        
        // Don't resize this window
        _shouldResize = YES;
        
        // Register default preferences - if they exist
        _currentDisk = nil;
        _runningTask = NO;
        [_taskRunning setUsesThreadedAnimation:YES];
        _tasksToRun = [[NSMutableArray alloc] init];
        
        // Disk Arbitration
        RegisterDA();
        
        // App & Workspace Notification
        [self registerSession];
        
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    }
    
    return self;
}

- (BOOL)shouldResize {
    return _shouldResize;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(privilegedTaskFinished:) name:STPrivilegedTaskDidTerminateNotification object:nil];

    
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
    if (!_runningTask) {
        // Reload all our info
        [self respondToSelectedItem:_diskView];
    }
}

#pragma mark - UI Methods

- (void)respondToSelectedItem:(NSOutlineView *)outlineView {
    
    [_rebuildKextCacheButton setEnabled:YES];
   
    id selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
    if ([selectedItem isKindOfClass:[Disk class]]) {
        // Let's enable/disable buttons based on disk info
        Disk *disk = selectedItem;
        _currentDisk = disk;
        [_repairDiskButton setEnabled:YES];
        [_verifyDiskButton setEnabled:YES];
        [_ejectButton setEnabled:NO];
        [_mountButton setEnabled:NO];
        [_repairPermissionsButton setEnabled:NO];
        if ([disk isMounted]) {
            if (![[disk volumePath] isEqualToString:@"/"]) {
                [_ejectButton setEnabled:YES];
            } else {
                [_repairPermissionsButton setEnabled:YES];
                [_repairDiskButton setEnabled:NO];
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

-(IBAction)rebuildKextCache:(id)sender {
    NSLog(@"Rebuild Kext Cache");
    // We need to run a couple terminal commands to get this done
    // rm -r /System/Library/Caches/com.apple.kext.caches
    // touch /System/Library/Extensions
    // kextcache -update-volume /
    //
    //One after the other - and all with admin privs.
    
    //Disable buttons
    //[self disableButtons];
    
    //[self appendOutput:@"Rebuilding kext cache...\n"];
    
    // rm -r /System/Library/Caches/com.apple.kext/caches
    NSString *path = @"/bin/rm";
    NSArray *args = [NSArray arrayWithObjects:@"-r", @"/System/Library/Caches/com.apple.kext.caches", nil];
    [_tasksToRun addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"Path", args, @"Args", @"Removing /System/Library/Caches/com.apple.kext.caches...\n", @"Start Message", nil]];
    
    // touch /System/Library/Extensions
    path = @"/usr/bin/touch";
    args = [NSArray arrayWithObjects:@"/System/Library/Extensions", nil];
    [_tasksToRun addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"Path", args, @"Args", @"Touching /System/Library/Extensions...\n", @"Start Message", nil]];
    
    // kextcache -update-volume /
    path = @"/usr/sbin/kextcache";
    args = [NSArray arrayWithObjects:@"-update-volume", @"/", nil];
    [_tasksToRun addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"Path", args, @"Args", @"Rebuilding Kext Cache...\n", @"Start Message", @"Complete.\n\n\n", @"End Message", nil]];
    
    [self launchNextTask];
}

-(IBAction)repairPermissions:(id)sender {
    NSLog(@"Repair Permissions");
    if (_currentDisk != nil && [_currentDisk volumePath]) {
        NSLog(@"Disk: %@", [_currentDisk volumePath]);
        //Build our privileged task for verifying disk
        
        //Disable buttons
        //[self disableButtons];
        
        //[self appendOutput:@"Repairing permissions...\n"];
        
        //[self launchPTWithPath:@"/usr/libexec/repair_packages" arguments:[NSArray arrayWithObjects:@"--repair", @"--standard-pkgs", @"--volume", [_currentDisk volumePath], nil]];*/
        NSString *path = @"/usr/libexec/repair_packages";
        NSArray *args = [NSArray arrayWithObjects:@"--repair", @"--standard-pkgs", @"--volume", [_currentDisk volumePath], nil];
        [_tasksToRun addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"Path", args, @"Args", @"Complete.\n\n\n", @"End Message", @"Repairing permissions...\n", @"Start Message", nil]];
        [self launchNextTask];
    }
}

-(IBAction)verifyDisk:(id)sender {
    NSLog(@"Verify Disk");
    if (_currentDisk != nil) {
        NSLog(@"Disk: %@", _currentDisk.BSDName);
        //Build our privileged task for verifying disk
        
        NSString *task = @"verifyVolume";
        if ([_currentDisk isWholeDisk]) {
            task = @"verifyDisk";
        }
        
        //Disable buttons
        //[self disableButtons];
        
        //[self launchPTWithPath:@"/usr/sbin/diskutil" arguments:[NSArray arrayWithObjects:task, _currentDisk.BSDName, nil]];
        
        NSString *path = @"/usr/sbin/diskutil";
        NSArray *args = [NSArray arrayWithObjects:task, _currentDisk.BSDName, nil];
        [_tasksToRun addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"Path", args, @"Args", @"Complete.\n\n\n", @"End Message", nil]];
        [self launchNextTask];
    }
}

-(IBAction)repairDisk:(id)sender {
    NSLog(@"Repair Disk");
    if (_currentDisk != nil) {
        NSLog(@"Disk: %@", _currentDisk.BSDName);
        //Build our privileged task for repairing disk
        
        NSString *task = @"repairVolume";
        if ([_currentDisk isWholeDisk]) {
            task = @"repairDisk";
        }
        
        //Disable buttons
        //[self disableButtons];
        
        //[self launchPTWithPath:@"/usr/sbin/diskutil" arguments:[NSArray arrayWithObjects:task, _currentDisk.BSDName, nil]];
        
        NSString *path = @"/usr/sbin/diskutil";
        NSArray *args = [NSArray arrayWithObjects:task, _currentDisk.BSDName, nil];
        [_tasksToRun addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"Path", args, @"Args", @"Complete.\n\n\n", @"End Message", nil]];
        [self launchNextTask];
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
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(_childDidAttemptUnmountBeforeEject:)
                                                         name:@"DADiskDidAttemptUnmountNotification"
                                                       object:aDisk];
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
    return !_runningTask;
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

- (void)_childDidAttemptUnmountBeforeEject:(NSNotification *) notification {
    Disk *disk = notification.object;
    
    //Check if disk is whole disk or not.
    Disk *parent = disk.isWholeDisk ? disk : disk.parent;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DADiskDidAttemptUnmountNotification" object:disk];
    
    //confirm child unmounted...
    
    if (disk.isMounted) {
        // Unmount of child failed.
        [self appendOutput:[NSString stringWithFormat:@"Failed to unmount disk: %@\n", parent.BSDName]];
        [self appendOutput:[NSString stringWithFormat:@"Canceled due to mounted child: %@\n", disk.BSDName]];
        
        //NSMutableDictionary *info = (NSMutableDictionary *)[notification userInfo];
        
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"DADiskDidAttemptEjectNotification" object:disk userInfo:info];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DADiskDidAttemptEjectNotification" object:disk userInfo:nil];
    }
    
    // Child from notification is unmounted, check for remaining children to unmount
    
    for (Disk *child in parent.children) {
        if (child.isMounted)
            return;			// Still waiting for child
    }
    
    // Need to test if parent is ejectable because we enable "Eject" for a disk
    // that has children that can be unmounted (ala Disk Utility)
    
    if (parent.isEjectable)
        [parent eject];
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

- (void)launchNextTask {
    if (!_runningTask) {
        //We're not doing anything yet - so let's start a task
        if ([_tasksToRun count] > 0) {
            //There indeed ARE tasks to run :D
            NSString *path = [[_tasksToRun objectAtIndex:0] objectForKey:@"Path"];
            NSArray *args = [[_tasksToRun objectAtIndex:0] objectForKey:@"Args"];
            [self launchPTWithPath:path arguments:args];
        }
        //No tasks - we're done.
    }
    //Currently running tasks - nothing to do yet.
}

- (void)launchPTWithPath:(NSString *)path arguments:(NSArray *)args {
    //Build our privileged task
    STPrivilegedTask *privilegedTask = [[STPrivilegedTask alloc] init];
    [privilegedTask setLaunchPath:path];
    [privilegedTask setArguments:args];
    
    //Launch our privileged task
    _runningTask=YES;
    [_taskRunning setHidden:NO];
    [_taskRunning startAnimation:nil];
    [self disableButtons];
    
    OSStatus err = [privilegedTask launch];
    if (err != errAuthorizationSuccess) {
        if (err == errAuthorizationCanceled) {
            NSLog(@"User cancelled");
            [self appendOutput:@"\nUser Canceled.\n\n\n"];
            [_taskRunning setHidden:YES];
            [_taskRunning stopAnimation:nil];
            [self respondToSelectedItem:_diskView];
            _runningTask = NO;
            
            //Remove all tasks since we failed to authent.
            if ([_tasksToRun count] > 0) {
                [_tasksToRun removeAllObjects];
            }
        } else {
            NSLog(@"Something went wrong");
            [self appendOutput:@"\nSomething Went Wrong :(\n\n\n"];
            [_taskRunning setHidden:YES];
            [_taskRunning stopAnimation:nil];
            [self respondToSelectedItem:_diskView];
            _runningTask = NO;
            
            //Remove current task due to error - and move to the next.
            if ([_tasksToRun count] > 0) {
                [_tasksToRun removeObjectAtIndex:0];
                [self launchNextTask];
            }
        }
    } else {
        NSLog(@"%@ successfully launched", path);
        
        //Check for a launch message...
        if ([[_tasksToRun objectAtIndex:0] objectForKey:@"Start Message"]) {
            [self appendOutput:[[_tasksToRun objectAtIndex:0] objectForKey:@"Start Message"]];
        }
    
        //Get output in background
        NSFileHandle *readHandle = [privilegedTask outputFileHandle];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getOutputData:) name:NSFileHandleReadCompletionNotification object:readHandle];
        [readHandle readInBackgroundAndNotify];
    }
}

- (void)getOutputData:(NSNotification *)aNotification {
    //get data from notification
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    
    //make sure there's actual data
    if ([data length]) {
        // do something with the data
        
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self appendOutput:output];
        
        // go read more data in the background
        [[aNotification object] readInBackgroundAndNotify];
    } else {
        // do something else
    }
}

- (void)appendOutput:(NSString *)output {
    NSString *outputWithNewLine = [output stringByAppendingString:@""];
    
    //Smart Scrolling
    BOOL scroll = (NSMaxY(_outputText.visibleRect) == NSMaxY(_outputText.bounds));
    
    //Append string to textview
    [_outputText.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:outputWithNewLine]];
    
    if (scroll) [_outputText scrollRangeToVisible:NSMakeRange(_outputText.string.length, 0)];
}

- (void)privilegedTaskFinished:(NSNotification *)aNotification {
    // add 3 blank lines of output and end task.
    if ([[_tasksToRun objectAtIndex:0] objectForKey:@"End Message"]) {
        [self appendOutput:[[_tasksToRun objectAtIndex:0] objectForKey:@"End Message"]];
    }
    [_taskRunning setHidden:YES];
    [_taskRunning stopAnimation:nil];
    [self respondToSelectedItem:_diskView];
    _runningTask = NO;
    
    //Remove the finished task and
    //try to launch the next task if it exists
    if ([_tasksToRun count] > 0) {
        [_tasksToRun removeObjectAtIndex:0];
        [self launchNextTask];
    }
}

- (void)disableButtons {
    [_repairPermissionsButton setEnabled:NO];
    [_rebuildKextCacheButton setEnabled:NO];
    [_repairDiskButton setEnabled:NO];
    [_verifyDiskButton setEnabled:NO];
    [_ejectButton setEnabled:NO];
    [_mountButton setEnabled:NO];
}



@end
