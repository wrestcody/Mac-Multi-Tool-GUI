/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Subclass of NSTextFieldCell which can display text and an image simultaneously.
 */

#import "AAPLImageAndTextCell.h"

#define kImageOriginXOffset     3
#define kImageOriginYOffset     1

#define kTextOriginXOffset      2
#define kTextOriginYOffset      2
#define kTextHeightAdjust       4


@implementation AAPLImageAndTextCell

// -------------------------------------------------------------------------------
//	initTextCell:aString
// -------------------------------------------------------------------------------
- (id)initTextCell:(NSString *)aString
{
    self = [super initTextCell:aString];
	if (self != nil)
    {
        // we want a smaller font
        [self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
        // we want full opacity by default
        self.opacity = 1;
    }
	return self;
}

// -------------------------------------------------------------------------------
//	copyWithZone:zone
// -------------------------------------------------------------------------------
- (id)copyWithZone:(NSZone *)zone
{
    AAPLImageAndTextCell *cell = (AAPLImageAndTextCell *)[super copyWithZone:zone];
    cell.myImage = self.myImage;
    return cell;
}

// -------------------------------------------------------------------------------
//	titleRectForBounds:cellRect
//
//	Returns the proper bound for the cell's title while being edited
// -------------------------------------------------------------------------------
- (NSRect)titleRectForBounds:(NSRect)cellRect
{	
	// the cell has an image: draw the normal item cell
	NSSize imageSize;
	NSRect imageFrame;

	imageSize = [self.myImage size];
	NSDivideRect(cellRect, &imageFrame, &cellRect, 3 + imageSize.width, NSMinXEdge);

	imageFrame.origin.x += kImageOriginXOffset;
	imageFrame.origin.y -= kImageOriginYOffset;
	imageFrame.size = imageSize;
	
	imageFrame.origin.y += ceil((cellRect.size.height - imageFrame.size.height) / 2);
	
	NSRect newFrame = cellRect;
	newFrame.origin.x += kTextOriginXOffset;
	newFrame.origin.y += kTextOriginYOffset;
	newFrame.size.height -= kTextHeightAdjust;

	return newFrame;
}

// -------------------------------------------------------------------------------
//	editWithFrame:inView:editor:delegate:event
// -------------------------------------------------------------------------------
- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    //aRect = [self drawingRectForBounds:aRect];
    mIsEditingOrSelecting = YES;
	NSRect textFrame = [self titleRectForBounds:aRect];
	[super editWithFrame:textFrame inView:controlView editor:textObj delegate:anObject event:theEvent];
    mIsEditingOrSelecting = NO;
}

// -------------------------------------------------------------------------------
//	selectWithFrame:inView:editor:delegate:event:start:length
// -------------------------------------------------------------------------------
- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength
{
    //aRect = [self drawingRectForBounds:aRect];
    mIsEditingOrSelecting = YES;
	NSRect textFrame = [self titleRectForBounds:aRect];
	[super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
    mIsEditingOrSelecting = NO;
}

// -------------------------------------------------------------------------------
//	drawWithFrame:cellFrame:controlView
// -------------------------------------------------------------------------------
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect newCellFrame = cellFrame;
    
    if (self.myImage != nil)
    {
        NSSize imageSize;
        NSRect imageFrame;
        
        imageSize = [self.myImage size];
        NSDivideRect(newCellFrame, &imageFrame, &newCellFrame, imageSize.width, NSMinXEdge);
        if ([self drawsBackground])
        {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        
        imageFrame.origin.y += 2;
        imageFrame.size = imageSize;
        
        [self.myImage drawInRect:imageFrame
                      fromRect:NSZeroRect
                     operation:NSCompositeSourceOver
                      fraction:self.opacity
                respectFlipped:YES
                         hints:nil];
    }
    
    [super drawWithFrame:newCellFrame inView:controlView];
}

// -------------------------------------------------------------------------------
//	cellSize
// -------------------------------------------------------------------------------
- (NSSize)cellSize
{
    NSSize cellSize = [super cellSize];
    cellSize.width += (self.myImage ? [self.myImage size].width : 0) + 3;
    return cellSize;
}

#pragma mark - Vertically Center

- (NSRect)drawingRectForBounds:(NSRect)theRect
{
    // Get the parent's idea of where we should draw
    NSRect newRect = [super drawingRectForBounds:theRect];
    
    // When the text field is being
    // edited or selected, we have to turn off the magic because it screws up
    // the configuration of the field editor.  We sneak around this by
    // intercepting selectWithFrame and editWithFrame and sneaking a
    // reduced, centered rect in at the last minute.
    if (mIsEditingOrSelecting == NO)
    {
        // Get our ideal size for current text
        NSSize textSize = [self cellSizeForBounds:theRect];
        
        // Center that in the proposed rect
        float heightDelta = newRect.size.height - textSize.height;
        if (heightDelta > 0)
        {
            newRect.size.height -= heightDelta;
            newRect.origin.y += (heightDelta / 2);
        }
    }
    
    return newRect;
}

@end

