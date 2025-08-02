
#import "SelectionRectangleView.h"

@implementation SelectionRectangleView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _shouldDrawRectangle = NO;
        _selectionRectToDraw = NSZeroRect;
        _dashPhase = 0.0;
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
        // Set color for the rectangle - use white for visibility
        [[NSColor whiteColor] setStroke];

        NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.selectionRectToDraw];
        
        // Set up marching ants dashed line
        CGFloat dashes[] = {6.0, 4.0}; // 6 points on, 4 points off
        [path setLineDash:dashes count:2 phase:self.dashPhase];
        [path setLineWidth:1.5]; // Slightly thicker for visibility
        
        [path stroke];
        
        // Add a black outline for better contrast
        [[NSColor blackColor] setStroke];
        NSBezierPath *outlinePath = [NSBezierPath bezierPathWithRect:self.selectionRectToDraw];
        CGFloat outlineDashes[] = {6.0, 4.0};
        [outlinePath setLineDash:outlineDashes count:2 phase:self.dashPhase + 5.0]; // Offset phase
        [outlinePath setLineWidth:1.5];
        [outlinePath stroke];
    }
}

- (void)setShouldDrawRectangle:(BOOL)shouldDrawRectangle {
    _shouldDrawRectangle = shouldDrawRectangle;
    
    if (shouldDrawRectangle) {
        [self startMarchingAnts];
    } else {
        [self stopMarchingAnts];
    }
}

- (void)startMarchingAnts {
    if (!self.animationTimer) {
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                               target:self
                                                             selector:@selector(animateDashes)
                                                             userInfo:nil
                                                              repeats:YES];
    }
}

- (void)stopMarchingAnts {
    if (self.animationTimer) {
        [self.animationTimer invalidate];
        self.animationTimer = nil;
        self.dashPhase = 0.0;
    }
}

- (void)animateDashes {
    self.dashPhase += 1.0;
    if (self.dashPhase >= 10.0) {
        self.dashPhase = 0.0;
    }
    [self setNeedsDisplay:YES];
}

- (void)dealloc {
    [self stopMarchingAnts];
}

// Override hitTest to allow clicks to pass through to the MandelView/ImageView below
- (NSView *)hitTest:(NSPoint)point {
    return nil; 
}

@end
