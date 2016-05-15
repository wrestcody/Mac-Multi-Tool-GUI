//
//  AppDelegate.m
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/4/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import "AppDelegate.h"
#import "DiskUtilityController.h"
//#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)awakeFromNib {
    // Check what OS we're running on
    NSOperatingSystemVersion reqMinOS;
    reqMinOS.majorVersion = 10;
    reqMinOS.minorVersion = 9;
    reqMinOS.patchVersion = 0;
    
    NSOperatingSystemVersion currentOS = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSLog(@"Current OS: %ld.%ld.%ld", currentOS.majorVersion, currentOS.minorVersion, currentOS.patchVersion);
    
    
    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:reqMinOS]) {
        NSLog(@"Is at least 10.9.0");
    } else {
        NSLog(@"Is less than 10.9.0 - Incompatible");
    }
    
}

- (IBAction)diskMenuApp:(id)sender {
    NSLog(@"DiskMenuApp Clicked");
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    
    _toolbarTabsArray = [self toolbarItems];
    _toolbarTabsIdentifierArray = [NSMutableArray new];
    
    for (NSDictionary *dict in _toolbarTabsArray){
        [_toolbarTabsIdentifierArray addObject:dict[@"identifier"]];
    }
    
    _toolbar = [[NSToolbar alloc] initWithIdentifier:@"ScreenNameToolbarIdentifier"];
    _toolbar.allowsUserCustomization = YES;
    _toolbar.delegate = self;
    self.window.toolbar = _toolbar;
    
    
    //Try to save window's position
    //NSWindow *window = self.window; // the window in question
    [[self.window windowController] setShouldCascadeWindows:NO];      // Tell the controller to not cascade its windows.
    [self.window setFrameAutosaveName:[self.window representedFilename]];  // Specify the autosave name for the window.
    
    [self.window makeKeyAndOrderFront:nil];
    
    //Try to set disk utitily to the main window - just for the sake of doing it
    //until I get a decent amount of apps running...
    //Eventually - I want this loaded with prefs.
    [_toolbar setSelectedItemIdentifier:@"DiskUtilityController"];
    [self loadViewWithIdentifier:@"DiskUtilityController" withAnimation:YES];
    
    //This line loads nothing
    //[_toolbar setSelectedItemIdentifier:@""];
    
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"NSQuitAlwaysKeepsWindows"];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark -
#pragma mark Toolbar Functions

-(NSArray *)toolbarItems{
    NSArray *toolbarItemsArray = [NSArray arrayWithObjects:
                                  [NSDictionary dictionaryWithObjectsAndKeys:@"Disk Utility",@"title",@"disk_utility",@"icon",@"DiskUtilityController",@"class",@"DiskUtilityController",@"identifier", nil],
                                  nil];
    return  toolbarItemsArray;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    NSDictionary *itemInfo = nil;
    
    for (NSDictionary *dict in _toolbarTabsArray)
    {
        if([dict[@"identifier"] isEqualToString:itemIdentifier])
        {
            itemInfo = dict;
            break;
        }
    }
    
    NSAssert(itemInfo, @"Could not find preferences item: %@", itemIdentifier);
    
    NSImage *icon = [NSImage imageNamed:itemInfo[@"icon"]];
    if(!icon) {
        icon = [NSImage imageNamed:NSImageNamePreferencesGeneral];
    }
    
    
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    item.label = itemInfo[@"title"];
    item.image = icon;
    item.target = self;
    item.action = @selector(viewSelected:);
    
    return item;
}

-(void)viewSelected:(id)sender{
    
    NSToolbarItem *item = sender;
    [self loadViewWithIdentifier:item.itemIdentifier withAnimation:YES];
    
}

-(void)loadViewWithIdentifier:(NSString *)viewTabIdentifier
                withAnimation:(BOOL)shouldAnimate{
    NSLog(@"viewTabIdentifier %@",viewTabIdentifier);
    
    if ([_currentView isEqualToString:viewTabIdentifier]){
        return;
    }
    else
    {
        _currentView = viewTabIdentifier;
    }
    //Loop through the view array and find out the class to load
    
    NSDictionary *viewInfoDict = nil;
    for (NSDictionary *dict in _toolbarTabsArray){
        if ([dict[@"identifier"] isEqualToString:viewTabIdentifier]){
            viewInfoDict = dict;
            break;
        }
    }
    NSString *class = viewInfoDict[@"class"];
    
    if(NSClassFromString(class))
    {
        _currentViewController = [[NSClassFromString(class) alloc] init];
        
        //Old View
        //NSView * oldView = self.window.contentView;
        
        //New View
        NSView *newView = _currentViewController.view;
        
        NSRect windowRect = [NSWindow contentRectForFrameRect:[self.window frame] styleMask:[self.window styleMask]];;
        NSRect currentViewRect = newView.frame;
        float tbHeight = [self toolbarHeightForWindow:self.window];
        float tiHeight = [self titleBarHeightForWindow:self.window];
        
        windowRect.origin.y = windowRect.origin.y + (windowRect.size.height - currentViewRect.size.height - tbHeight);
        windowRect.size.height = currentViewRect.size.height + tbHeight + tiHeight;
        windowRect.size.width = currentViewRect.size.width;
        
        self.window.title = viewInfoDict[@"title"];
        [self.window setContentView:newView];
        [self.window setFrame:windowRect display:YES animate:shouldAnimate];
        
        // To create a window that can resize:
        // [window setStyleMask:[window styleMask] | NSResizableWindowMask];
        //
        // To create one that CANNOT resize:
        // [window setStyleMask:[window styleMask] & ~NSResizableWindowMask];
        
        //if (_currentViewController.shouldResize) {
            
        //}
        
        [self.window setStyleMask:[self.window styleMask] & ~NSResizableWindowMask];
        
    }
    else{
        NSAssert(false, @"Couldn't load %@", class);
    }
}

- (float)toolbarHeightForWindow:(NSWindow *)window {
    NSToolbar *toolbar;
    float toolbarHeight = 0.0;
    NSRect windowFrame;
    
    toolbar = [window toolbar];
    
    if(toolbar && [toolbar isVisible]) {
        windowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
        toolbarHeight = NSHeight(windowFrame) - NSHeight([[window contentView] frame]);
    }
    
    return toolbarHeight;
}

- (float) titleBarHeightForWindow:(NSWindow *)window {
    NSRect frame = NSMakeRect (0, 0, 100, 100);
    
    NSRect contentRect;
    contentRect = [NSWindow contentRectForFrameRect: frame
                                          styleMask: [window styleMask]];
    
    return (frame.size.height - contentRect.size.height);
    
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    NSLog(@"%s %@",__func__,_toolbarTabsIdentifierArray);
    return _toolbarTabsIdentifierArray;
    
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    NSLog(@"%s",__func__);
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    NSLog(@"%s",__func__);
    return [self toolbarDefaultItemIdentifiers:toolbar];
    //return nil;
}

@end
