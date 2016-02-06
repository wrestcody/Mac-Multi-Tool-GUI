//
//  CNOutlineView.m
//  Mac Multi-Tool
//
//  Created by Kristopher Scruggs on 2/4/16.
//  Copyright © 2016 Corporate Newt Software. All rights reserved.
//

#import "CNOutlineView.h"

@implementation CNOutlineView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    
    // Only take effect for double clicks; remove to allow for single clicks
    if (theEvent.clickCount < 2) {
        return;
    }
    
    // Get the row on which the user clicked
    NSPoint localPoint = [self convertPoint:theEvent.locationInWindow
                                   fromView:nil];
    NSInteger row = [self rowAtPoint:localPoint];
    //NSInteger col = [self columnAtPoint:localPoint];
    
    // If the user didn't click on a row, we're done
    if (row < 0) {
        return;
    }
    
    // Get the view clicked on
    //NSCell *cell = [self preparedCellAtColumn:col row:row ];
    
    
    // If the field can be edited, pop the editor into edit mode
    /*if (view.textField.isEditable) {
        [[view window] makeFirstResponder:view.textField];
    }*/
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OutlineViewDoubleClick" object:self userInfo:[self itemAtRow:row]];
    //NSLog(@"Title: %@", cell.stringValue);
}

@end
