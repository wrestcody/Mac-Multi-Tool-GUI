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
    
    if (theEvent.clickCount < 2) {
        return;
    }
    
    // Get the row on which the user clicked
    NSPoint localPoint = [self convertPoint:theEvent.locationInWindow
                                   fromView:nil];
    NSInteger row = [self rowAtPoint:localPoint];
    NSInteger col = [self columnAtPoint:localPoint];
    
    // If the user didn't click on a row, we're done
    if (row < 0) {
        return;
    }
    
    /*if (theEvent.clickCount < 2) {
        
        NSRect outline = [self frameOfOutlineCellAtRow:row];
        
        //NSDictionary *point = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:outline.x], @"X",[NSNumber numberWithFloat:outline.y], @"Y", nil];
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"OutlineViewSelected" object:self userInfo:[NSValue valueWithRect:outline]];
        return;
    }*/
    
    
    NSRect outline = [self frameOfCellAtColumn:col row:row];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OutlineViewDoubleClick" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRect:outline], @"Rect", [self itemAtRow:[self selectedRow]], @"Item", nil]];
    //NSLog(@"Title: %@", cell.stringValue);
}

@end
