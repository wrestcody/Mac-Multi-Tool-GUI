//
//  DiskUtilityController.m
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/6/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import "DiskUtilityController.h"
#import "CNPopoverController.h"

@interface DiskUtilityController () <NSPopoverDelegate>

@property (strong) NSPopover *myPopover;
@property (strong) CNPopoverController *popoverViewController;

@property (strong) NSWindow *detachedWindow;

@end

@implementation DiskUtilityController

- (id) init {
    if(self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil]) {
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [_diskView setDataSource:(id<NSOutlineViewDataSource>)self];
    [_diskView setDelegate:(id<NSOutlineViewDelegate>)self];
    
    //Set up for receiving double-click notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineViewDoubleClick:) name:@"OutlineViewDoubleClick" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineViewSelected:) name:@"OutlineViewSelected" object:nil];
    
    //_disks = [[CNDiskList sharedList] getOutlineViewList];
    _disks = [[CNDiskList sharedList] getAllDisksAndPartitionsList];
    
    NSLog(@"%@", [[[[_disks objectAtIndex:1] getChildren] objectAtIndex:2] getObjects]);
    
    
    
    
    //Setup our popover button
    _popoverViewController = [[NSClassFromString(@"CNPopoverController") alloc] init];
    
    NSRect frame = self.popoverViewController.view.bounds;
    NSUInteger styleMask = NSTitledWindowMask + NSClosableWindowMask;
    NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
    _detachedWindow = [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing:NSBackingStoreBuffered defer:YES];
    self.detachedWindow.contentViewController = self.popoverViewController;
    self.detachedWindow.releasedWhenClosed = NO;
    
    
    [_diskView reloadData];
}

- (void)createPopover
{
    if (self.myPopover == nil)
    {
        // create and setup our popover
        _myPopover = [[NSPopover alloc] init];
        
        // the popover retains us and we retain the popover,
        // we drop the popover whenever it is closed to avoid a cycle
        
        self.myPopover.contentViewController = self.popoverViewController;
        self.myPopover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        
        self.myPopover.animates = YES;
        
        // AppKit will close the popover when the user interacts with a user interface element outside the popover.
        // note that interacting with menus or panels that become key only when needed will not cause a transient popover to close.
        self.myPopover.behavior = NSPopoverBehaviorTransient;
        
        // so we can be notified when the popover appears or closes
        self.myPopover.delegate = self;
    }
}

- (void)outlineViewDoubleClick:(id)note {
    //Load the disk that we just double clicked.
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
    [self showPopoverAction:_diskView];
}

- (void)outlineViewSelected:(id)note {
    //_selected = NSMakePoint([[[note userInfo] objectForKey:@"X" ] floatValue], [[[note userInfo] objectForKey:@"Y" ] floatValue]);
    //_selected = [[note userInfo] rectValue];
}

// -------------------------------------------------------------------------------
//  showPopoverAction:sender
// -------------------------------------------------------------------------------
- (IBAction)showPopoverAction:(id)sender
{
    if (self.detachedWindow.visible == YES) {
        [self.detachedWindow close];
    }
    
    [self createPopover];
    
    //NSButton *targetButton = (NSButton *)sender;
    
    // configure the preferred position of the popover
    NSRectEdge prefEdge = 1;
    
    //[self.myPopover showRelativeToRect:targetButton.bounds ofView:sender preferredEdge:prefEdge];
    [self.myPopover showRelativeToRect:_selected ofView:sender preferredEdge:prefEdge];
}

#pragma mark -
#pragma mark Outline View Delegate Methods


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        // Root
        return [_disks objectAtIndex:index];
    }
    
    if ([item isKindOfClass:[CNDiskRep class]]) {
        return [item childAtIndex:index];
    }
    
    if ([item isKindOfClass:[NSArray class]]) {
        return [item objectAtIndex:index];
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass:[NSArray class]]) {
        return YES;
    }
    if ([item isKindOfClass:[CNDiskRep class]]) {
        if ([item hasChildren]) {
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        // Root
        return [_disks count];
    }
    
    if ([item isKindOfClass:[CNDiskRep class]] && [item hasChildren]) {
        return [[item getChildren] count];
    }
    
    if ([item isKindOfClass:[NSArray class]]) {
        return [item count];
    }
    
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn byItem:(nullable id)item {
    
    if ([item isKindOfClass:[CNDiskRep class]]) {
        
        //Check for nil and return if so
        if (![item objectForKey:[tableColumn identifier]]) {
            return nil;
        }
        
        NSColor *color = [NSColor blackColor];
        //Set up the text color
        if ([item isChild]) {
            color = [NSColor darkGrayColor];
        }
        
        //Set text color to blue if boot drive/partition
        if ([item isBoot] && [[tableColumn identifier] isEqualToString:@"Name"]) {
            color = [NSColor blueColor];
        }
        
        NSDictionary *attrs = @{ NSForegroundColorAttributeName : color };
        
        if ([[tableColumn identifier] isEqualToString:@"SizeReadable"] || [[tableColumn identifier] isEqualToString:@"DeviceIdentifier"]) {
            
            //Set pararaph style to align right, and rebuild attributes dictionary
            NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
            [paragrahStyle setAlignment:NSTextAlignmentRight];
            
            NSDictionary *attrs = @{
                                    NSForegroundColorAttributeName : color,
                                    NSParagraphStyleAttributeName : paragrahStyle
                                    };
            
            return [[NSAttributedString alloc] initWithString:[item objectForKey:[tableColumn identifier]] attributes:attrs];
        }
        
        //Just return whatever is left
        return [[NSAttributedString alloc] initWithString:[item objectForKey:[tableColumn identifier]] attributes:attrs];
    }
    
    return nil;
}

#pragma mark - NSPopoverDelegate

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverWillShowNotification notification is sent.
// This method will also be invoked on the popover.
// -------------------------------------------------------------------------------
- (void)popoverWillShow:(NSNotification *)notification
{
    NSPopover *popover = notification.object;
    if (popover != nil)
    {
        //... operate on that popover
    }
}

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverDidShowNotification notification is sent.
// This method will also be invoked on the popover.
// -------------------------------------------------------------------------------
- (void)popoverDidShow:(NSNotification *)notification
{
    // add new code here after the popover has been shown
}

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverWillCloseNotification notification is sent.
// This method will also be invoked on the popover.
// -------------------------------------------------------------------------------
- (void)popoverWillClose:(NSNotification *)notification
{
    NSString *closeReason = [notification.userInfo valueForKey:NSPopoverCloseReasonKey];
    if (closeReason)
    {
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        //
        // add new code here if you want to respond "before" the popover closes
        //
    }
}

// -------------------------------------------------------------------------------
// Invoked on the delegate when the NSPopoverDidCloseNotification notification is sent.
// This method will also be invoked on the popover.
// -------------------------------------------------------------------------------
- (void)popoverDidClose:(NSNotification *)notification
{
    NSString *closeReason = [notification.userInfo valueForKey:NSPopoverCloseReasonKey];
    if (closeReason)
    {
        // closeReason can be:
        //      NSPopoverCloseReasonStandard
        //      NSPopoverCloseReasonDetachToWindow
        //
        // add new code here if you want to respond "after" the popover closes
        //
    }
    
    // release our popover since it closed
    _myPopover = nil;
}

// -------------------------------------------------------------------------------
// Invoked on the delegate to give permission to detach popover as a separate window.
// -------------------------------------------------------------------------------
- (BOOL)popoverShouldDetach:(NSPopover *)popover
{
    return YES;
}

// -------------------------------------------------------------------------------
// Invoked on the delegate to when the popover was detached.
// Note: Invoked only if AppKit provides the window for this popover.
// -------------------------------------------------------------------------------
- (void)popoverDidDetach:(NSPopover *)popover
{
    NSLog(@"popoverDidDetach");
}

// -------------------------------------------------------------------------------
// Invoked on the delegate asked for the detachable window for the popover.
// -------------------------------------------------------------------------------
- (NSWindow *)detachableWindowForPopover:(NSPopover *)popover
{
    NSWindow *window = nil;
    return window;
}


@end
