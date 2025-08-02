//  MandelView.m
//  Mandelzoom-MacOS-ObjC

#import <Foundation/Foundation.h>
#import "MandelView.h"
#import "MandelRenderer.h"
#import <math.h>
#import "SelectionRectangleView.h"

@implementation MandelView
{
    MandelRenderer *renderer;
    NSPoint mouseDownLoc, mouseUpLoc;
    complex long double initialBottomLeft;
    complex long double initialTopRight;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if (!renderer) {
        renderer = [[MandelRenderer alloc] init];
        initialBottomLeft = renderer.bottomLeft;
        initialTopRight = renderer.topRight;
    }
    if (self.selectionOverlayView) {
        self.selectionOverlayView.shouldDrawRectangle = NO;
    }
    
    // Ensure image view is set up for centering
    if (self.imageView) {
        self.imageView.imageAlignment = NSImageAlignCenter;
        self.imageView.imageScaling = NSImageScaleNone; // We'll handle sizing manually
    }
    
    // Set up frame change notifications
    [self setPostsFrameChangedNotifications:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(frameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:self];
    
    // Set up render time label
    [self setupRenderTimeLabel];
    
    // Set up selection overlay view if not connected from storyboard
    if (!self.selectionOverlayView) {
        [self setupSelectionOverlayView];
    }
    
    // Initial layout
    [self layoutImageView];
}

-(void) setImage {
    if (!renderer) {
        [self awakeFromNib];
    }
    
    NSSize viewSize = _imageView.bounds.size;
    int resolution = [self calculateOptimalResolution:viewSize];
    
    double renderTime;
    _imageView.image = [renderer renderWithWidth:resolution height:resolution renderTime:&renderTime];
    [self updateRenderTimeDisplay:renderTime];
    
    if (self.selectionOverlayView) {
        self.selectionOverlayView.shouldDrawRectangle = NO;
        [self.selectionOverlayView setNeedsDisplay:YES];
    }
}

-(void) refresh {
    NSLog(@"*** refresh method (Resetting Zoom)");
    if (!renderer) {
        [self awakeFromNib];
    }
    renderer.bottomLeft = initialBottomLeft;
    renderer.topRight = initialTopRight;
    
    NSSize viewSize = _imageView.bounds.size;
    int resolution = [self calculateOptimalResolution:viewSize];
    
    double renderTime;
    _imageView.image = [renderer renderWithWidth:resolution height:resolution renderTime:&renderTime];
    [self updateRenderTimeDisplay:renderTime];
    
    if (self.selectionOverlayView) {
        self.selectionOverlayView.shouldDrawRectangle = NO;
        [self.selectionOverlayView setNeedsDisplay:YES];
    }
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

-(void)mouseDown:(NSEvent *)event
{
    NSPoint clickLocation = [self convertPoint:[event locationInWindow]
                  fromView:nil];
    mouseDownLoc = clickLocation;
    NSLog(@"mouseDown x:%lf y:%lf", mouseDownLoc.x, mouseDownLoc.y);

    if (self.selectionOverlayView) {
        // Convert coordinates from MandelView to SelectionRectangleView coordinate system
        NSPoint overlayPoint = [self.selectionOverlayView convertPoint:mouseDownLoc fromView:self];
        NSLog(@"Starting selection overlay at (%f, %f) -> (%f, %f)", mouseDownLoc.x, mouseDownLoc.y, overlayPoint.x, overlayPoint.y);
        self.selectionOverlayView.shouldDrawRectangle = YES;
        self.selectionOverlayView.selectionRectToDraw = NSMakeRect(overlayPoint.x, overlayPoint.y, 0, 0);
        [self.selectionOverlayView setNeedsDisplay:YES];
    } else {
        NSLog(@"ERROR: selectionOverlayView is nil!");
    }
}

-(void)mouseDragged:(NSEvent *)event
{
    if (!self.selectionOverlayView || !self.selectionOverlayView.shouldDrawRectangle) {
        return;
    }

    NSPoint currentDragLoc = [self convertPoint:[event locationInWindow]
                                       fromView:nil];
    
    // Convert both points to SelectionRectangleView coordinate system
    NSPoint overlayStart = [self.selectionOverlayView convertPoint:mouseDownLoc fromView:self];
    NSPoint overlayEnd = [self.selectionOverlayView convertPoint:currentDragLoc fromView:self];
    
    CGFloat x1 = overlayStart.x;
    CGFloat y1 = overlayStart.y;
    CGFloat x2 = overlayEnd.x;
    CGFloat y2 = overlayEnd.y;

    self.selectionOverlayView.selectionRectToDraw = NSMakeRect(fmin(x1, x2), fmin(y1, y2), fabsl(x2 - x1), fabsl(y2 - y1));
    [self.selectionOverlayView setNeedsDisplay:YES];
}

-(void)mouseUp: (NSEvent *)event
{
    if (self.selectionOverlayView) {
        self.selectionOverlayView.shouldDrawRectangle = NO;
        [self.selectionOverlayView setNeedsDisplay:YES];
    }

    NSPoint clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    mouseUpLoc = clickLocation;
    
    if (fabsl(mouseDownLoc.x - mouseUpLoc.x) < 5 || fabsl(mouseDownLoc.y - mouseUpLoc.y) < 5) {
        NSLog(@"Selection too small, not zooming.");
        return;
    }

    NSLog(@"mouseUp x:%lf y:%lf. Zooming.", mouseUpLoc.x, mouseUpLoc.y);

    if (!renderer) {
        NSLog(@"Error: Renderer not initialized in mouseUp!");
        return;
    }

    CGFloat viewWidth = self.bounds.size.width;
    CGFloat viewHeight = self.bounds.size.height;

    complex long double current_bl = renderer.bottomLeft;
    complex long double current_tr = renderer.topRight;

    long double current_bl_real = creall(current_bl);
    long double current_tr_real = creall(current_tr);
    long double current_bl_imag = cimagl(current_bl);
    long double current_tr_imag = cimagl(current_tr);

    long double complexPlaneWidth = current_tr_real - current_bl_real;
    long double complexPlaneHeight = current_tr_imag - current_bl_imag;

    long double sel_minPixelX = fminl(mouseDownLoc.x, mouseUpLoc.x);
    long double sel_maxPixelX = fmaxl(mouseDownLoc.x, mouseUpLoc.x);
    long double sel_minPixelY_view = fminl(mouseDownLoc.y, mouseUpLoc.y);
    long double sel_maxPixelY_view = fmaxl(mouseDownLoc.y, mouseUpLoc.y);
    
    complex long double new_bl_cand, new_tr_cand;
    
    new_bl_cand = (current_bl_real + (sel_minPixelX / viewWidth) * complexPlaneWidth) +
                  (current_bl_imag + ((viewHeight - sel_maxPixelY_view) / viewHeight) * complexPlaneHeight) * I;
                  
    new_tr_cand = (current_bl_real + (sel_maxPixelX / viewWidth) * complexPlaneWidth) +
                  (current_bl_imag + ((viewHeight - sel_minPixelY_view) / viewHeight) * complexPlaneHeight) * I;
    
    long double new_cand_width = creall(new_tr_cand) - creall(new_bl_cand);
    long double new_cand_height = cimagl(new_tr_cand) - cimagl(new_bl_cand);

    if (new_cand_width <= 0 || new_cand_height <= 0) {
        NSLog(@"Invalid zoom selection (zero or negative width/height).");
        return;
    }
    
    if (new_cand_width > new_cand_height) {
        long double diff = new_cand_width - new_cand_height;
        new_bl_cand = creall(new_bl_cand) + (cimagl(new_bl_cand) - diff / 2.0L) * I;
        new_tr_cand = creall(new_tr_cand) + (cimagl(new_tr_cand) + diff / 2.0L) * I;
    } else if (new_cand_height > new_cand_width) {
        long double diff = new_cand_height - new_cand_width;
        new_bl_cand = (creall(new_bl_cand) - diff / 2.0L) + cimagl(new_bl_cand) * I;
        new_tr_cand = (creall(new_tr_cand) + diff / 2.0L) + cimagl(new_tr_cand) * I;
    }

    renderer.bottomLeft = new_bl_cand;
    renderer.topRight = new_tr_cand;
    
    NSSize viewSize = _imageView.bounds.size;
    int resolution = [self calculateOptimalResolution:viewSize];
    
    double renderTime;
    _imageView.image = [renderer renderWithWidth:resolution height:resolution renderTime:&renderTime];
    [self updateRenderTimeDisplay:renderTime];
}

- (int)calculateOptimalResolution:(NSSize)viewSize {
    if (viewSize.width <= 0 || viewSize.height <= 0) {
        return 1000; // Default fallback
    }
    
    // Use the smaller dimension to maintain 1:1 aspect ratio
    int minDimension = (int)fmin(viewSize.width, viewSize.height);
    
    // Ensure minimum quality and reasonable performance
    if (minDimension < 300) {
        return 300;
    } else if (minDimension > 2000) {
        return 2000; // Cap for performance
    }
    
    return minDimension;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)frameDidChange:(NSNotification *)notification {
    [self layoutImageView];
}

- (void)layoutImageView {
    if (!self.imageView) return;
    
    // Get the container view bounds
    NSRect containerBounds = self.bounds;
    
    // Calculate the square size using the smaller dimension
    CGFloat minDimension = fmin(containerBounds.size.width, containerBounds.size.height);
    
    // Create square frame centered in the container
    NSRect imageFrame = NSMakeRect(
        (containerBounds.size.width - minDimension) / 2.0,  // Center horizontally
        (containerBounds.size.height - minDimension) / 2.0, // Center vertically
        minDimension,
        minDimension
    );
    
    // Update image view frame
    self.imageView.frame = imageFrame;
    
    // Update selection overlay to match image view frame
    if (self.selectionOverlayView) {
        self.selectionOverlayView.frame = imageFrame;
        NSLog(@"Updated selection overlay frame to: %@", NSStringFromRect(imageFrame));
    }
    
    // Position render time label in lower right corner of image view
    [self positionRenderTimeLabel];
    
    // Re-render at new size
    [self setImage];
}

- (void)setupRenderTimeLabel {
    if (!self.renderTimeLabel) {
        self.renderTimeLabel = [[NSTextField alloc] init];
        self.renderTimeLabel.editable = NO;
        self.renderTimeLabel.bezeled = NO;
        self.renderTimeLabel.drawsBackground = YES;
        self.renderTimeLabel.backgroundColor = [NSColor colorWithWhite:0.0 alpha:0.7]; // Semi-transparent black background
        self.renderTimeLabel.textColor = [NSColor whiteColor];
        self.renderTimeLabel.font = [NSFont systemFontOfSize:11.0]; // Slightly larger
        self.renderTimeLabel.alignment = NSTextAlignmentCenter;
        self.renderTimeLabel.stringValue = @"";
        
        // Add some padding
        self.renderTimeLabel.layer.cornerRadius = 3.0;
        self.renderTimeLabel.wantsLayer = YES;
        
        [self addSubview:self.renderTimeLabel];
    }
}

- (void)positionRenderTimeLabel {
    if (!self.renderTimeLabel || !self.imageView) return;
    
    NSRect imageFrame = self.imageView.frame;
    NSSize labelSize = [self.renderTimeLabel.stringValue sizeWithAttributes:@{
        NSFontAttributeName: self.renderTimeLabel.font
    }];
    
    // Position in lower right corner of image view with 8pt margin and padding
    NSRect labelFrame = NSMakeRect(
        imageFrame.origin.x + imageFrame.size.width - labelSize.width - 16,
        imageFrame.origin.y + 8,
        labelSize.width + 8,
        labelSize.height + 4
    );
    
    self.renderTimeLabel.frame = labelFrame;
}

- (void)updateRenderTimeDisplay:(double)renderTime {
    if (!self.renderTimeLabel) {
        [self setupRenderTimeLabel];
    }
    
    self.renderTimeLabel.stringValue = [NSString stringWithFormat:@"%.3fs", renderTime];
    [self positionRenderTimeLabel];
}

- (void)setupSelectionOverlayView {
    NSLog(@"Creating SelectionRectangleView programmatically");
    self.selectionOverlayView = [[SelectionRectangleView alloc] initWithFrame:self.bounds];
    self.selectionOverlayView.shouldDrawRectangle = NO;
    [self addSubview:self.selectionOverlayView];
}

@end
