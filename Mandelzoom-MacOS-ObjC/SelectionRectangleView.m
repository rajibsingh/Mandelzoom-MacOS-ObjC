
#import "SelectionRectangleView.h"

@implementation SelectionRectangleView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _shouldDrawRectangle = NO;
        _selectionRectToDraw = NSZeroRect;
    }
    return self;
}

// Ensure the view itself is transparent and doesn't draw a background
- (BOOL)isOpaque {
    return NO;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    if (self.shouldDrawRectangle && !NSEqualRects(self.selectionRectToDraw, NSZeroRect)) {
        // Set color for the rectangle
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.8] setStroke]; // White, slightly transparent

        NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.selectionRectToDraw];
        
        // Set up dashed line
        CGFloat dashes[] = {5.0, 3.0}; // 5 points on, 3 points off
        [path setLineDash:dashes count:2 phase:0.0];
        [path setLineWidth:1.0]; // Thin line
        
        [path stroke];
    }
}

// Override hitTest to allow clicks to pass through to the MandelView/ImageView below
// if we are not actively drawing a rectangle (or always, if desired)
- (NSView *)hitTest:(NSPoint)point {
    // If this view should not handle mouse events directly for selection,
    // let them pass through to the view below.
    // MandelView is handling the events, so this overlay should be "transparent" to mouse events.
    return nil; 
}

@end
