//
//  ViewController.m
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/4/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import "ViewController.h"
#import "CNDiskList.h"
#import "CNDiskRep.h"

@implementation ViewController

- (void) awakeFromNib {
    // set the Data Source and Delegate
    [_diskView setDataSource:(id<NSOutlineViewDataSource>)self];
    [_diskView setDelegate:(id<NSOutlineViewDelegate>)self];
    
    //Set up for receiving double-click notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"OutlineViewDoubleClick" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineViewDoubleClick:) name:@"OutlineViewDoubleClick" object:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    _disks = [[CNDiskList sharedList] getOutlineViewList];
    //_disks = [[CNDiskList sharedList] getVolumesViewList];
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)outlineViewDoubleClick:(id)note {
    //Load the disk that we just double clicked.
    _disks = [[CNDiskList sharedList] getDiskViewList:[note userInfo]];
    [_diskView reloadData];
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
        if ([item isBoot] && [[tableColumn identifier] isEqualToString:@"MediaName"]) {
            color = [NSColor blueColor];
        }
        
        NSDictionary *attrs = @{ NSForegroundColorAttributeName : color };

        if ([[tableColumn identifier] isEqualToString:@"Size"] || [[tableColumn identifier] isEqualToString:@"DeviceIdentifier"]) {
            
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


@end
