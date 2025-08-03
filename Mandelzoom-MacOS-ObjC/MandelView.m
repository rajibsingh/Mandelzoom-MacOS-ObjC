//  MandelView.m
//  Mandelzoom-MacOS-ObjC

#import "MandelView.h"
#import "MandelRenderer.h"
#import <math.h>
#import "SelectionRectangleView.h"
#import "AppDelegate.h"

@implementation MandelView
{
    MandelRenderer *renderer;
    NSPoint mouseDownLoc, mouseUpLoc;
    complex long double initialBottomLeft;
    complex long double initialTopRight;
    BOOL isPanning;
    complex long double panStartBottomLeft;
    complex long double panStartTopRight;
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
    
    // Set up info panel
    [self setupInfoPanel];
    
    // Set up selection overlay view if not connected from storyboard
    if (!self.selectionOverlayView) {
        [self setupSelectionOverlayView];
    }
    
    // Set up mouse tracking for real-time coordinates
    [self setupMouseTracking];
    
    // Listen for settings changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged) name:@"ShowInfoPanelSettingChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(renderTimeSettingChanged) name:@"ShowRenderTimeSettingChanged" object:nil];
    
    // Listen for application launch
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self layoutImageView];
    [self updateRenderTimeLabelVisibility];
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
    [self updateInfoPanel];
    
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
    [self updateInfoPanel];
    
    if (self.selectionOverlayView) {
        self.selectionOverlayView.shouldDrawRectangle = NO;
        [self.selectionOverlayView setNeedsDisplay:YES];
    }
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)event {
    NSString *characters = [event characters];
    if ([characters length] > 0) {
        unichar character = [characters characterAtIndex:0];
        
        if (character == 27) { // Escape key
            [self resetToOriginalView];
        } else {
            [super keyDown:event]; // Pass other keys to superclass
        }
    }
}

- (void)mouseMoved:(NSEvent *)event {
    [self updateMouseCoordinates:event];
}

- (void)updateMouseCoordinates:(NSEvent *)event {
    if (!renderer || !self.imageView || !self.mouseXLabel || !self.mouseYLabel) return;
    
    NSPoint mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    
    // Check if mouse is within the image view bounds
    NSRect imageFrame = self.imageView.frame;
    if (!NSPointInRect(mouseLocation, imageFrame)) {
        self.mouseXLabel.stringValue = @"Mouse X: --";
        self.mouseYLabel.stringValue = @"Mouse Y: --";
        return;
    }
    
    // Convert mouse location to complex plane coordinates
    CGFloat relativeX = (mouseLocation.x - imageFrame.origin.x) / imageFrame.size.width;
    CGFloat relativeY = (mouseLocation.y - imageFrame.origin.y) / imageFrame.size.height;
    
    // Clamp to image bounds
    relativeX = fmax(0.0, fmin(1.0, relativeX));
    relativeY = fmax(0.0, fmin(1.0, relativeY));
    
    // Get current complex plane bounds
    complex long double currentBottomLeft = renderer.bottomLeft;
    complex long double currentTopRight = renderer.topRight;
    
    long double realSpan = creall(currentTopRight) - creall(currentBottomLeft);
    long double imagSpan = cimagl(currentTopRight) - cimagl(currentBottomLeft);
    
    // Convert to complex plane coordinates (note Y inversion)
    long double mouseReal = creall(currentBottomLeft) + relativeX * realSpan;
    long double mouseImag = cimagl(currentBottomLeft) + (1.0 - relativeY) * imagSpan;
    
    // Update labels
    self.mouseXLabel.stringValue = [NSString stringWithFormat:@"Mouse X: %.6Lf", mouseReal];
    self.mouseYLabel.stringValue = [NSString stringWithFormat:@"Mouse Y: %.6Lf", mouseImag];
}

-(void)mouseDown:(NSEvent *)event
{
    NSPoint clickLocation = [self convertPoint:[event locationInWindow]
                  fromView:nil];
    mouseDownLoc = clickLocation;
    NSLog(@"mouseDown x:%lf y:%lf", mouseDownLoc.x, mouseDownLoc.y);

    // Start panning mode
    isPanning = YES;
    
    // Store current view state for panning
    panStartBottomLeft = renderer.bottomLeft;
    panStartTopRight = renderer.topRight;
    NSLog(@"Starting pan mode");
}

-(void)mouseDragged:(NSEvent *)event
{
    if (isPanning) {
        NSPoint currentDragLoc = [self convertPoint:[event locationInWindow]
                                           fromView:nil];
        [self performPanningWithCurrentLoc:currentDragLoc];
    }
}

-(void)mouseUp: (NSEvent *)event
{
    NSPoint clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    mouseUpLoc = clickLocation;
    
    if (isPanning) {
        // Check if this was a click (small movement) or a drag.
        CGFloat dragDistance = sqrt(pow(mouseUpLoc.x - mouseDownLoc.x, 2) + pow(mouseUpLoc.y - mouseDownLoc.y, 2));
        
        if (dragDistance < 5) {
            // It was a click, so perform zoom.
            // Restore the original coordinates before zooming to avoid a small pan offset.
            renderer.bottomLeft = panStartBottomLeft;
            renderer.topRight = panStartTopRight;

            if ([event modifierFlags] & NSEventModifierFlagCommand) {
                // Command-click - zoom out.
                [self performSingleClickZoomOutAtPoint:mouseDownLoc];
            } else {
                // Regular click - zoom in.
                [self performSingleClickZoomAtPoint:mouseDownLoc];
            }
        }
        // If it was a drag, the panning is already done in mouseDragged.
        NSLog(@"Finished panning/clicking");
    }
    
    isPanning = NO;
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
    // Update tracking areas when frame changes
    if (self.trackingAreas.count > 0) {
        [self removeTrackingArea:self.trackingAreas.firstObject];
    }
    [self setupMouseTracking];
    
    [self layoutImageView];
}

- (void)layoutImageView {
    if (!self.imageView) return;
    
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    BOOL showInfoPanel = appDelegate.showInfoPanel;
    
    self.infoPanel.hidden = !showInfoPanel;
    
    // Get the container view bounds
    NSRect containerBounds = self.bounds;
    
    // Reserve space for info panel on the right side if it's visible
    CGFloat infoPanelWidth = showInfoPanel ? 250 : 0;
    CGFloat availableWidth = containerBounds.size.width - infoPanelWidth - (showInfoPanel ? 20 : 0); // 20px margin if panel is shown
    CGFloat availableHeight = containerBounds.size.height;
    
    // Calculate the square size using the smaller available dimension
    CGFloat minDimension = fmin(availableWidth, availableHeight);
    
    // Create square frame, left-aligned in available space
    NSRect imageFrame = NSMakeRect(
        (availableWidth - minDimension) / 2.0,  // Center in available width
        (availableHeight - minDimension) / 2.0, // Center vertically
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
    
    // Position info panel on the right side
    if (showInfoPanel) {
        [self positionInfoPanel];
    }
    
    // Position render time label in lower right corner of image view
    [self positionRenderTimeLabel];
    
    // Re-render at new size
    [self setImage];
}

- (void)settingsChanged {
    [self layoutImageView];
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

- (void)positionInfoPanel {
    if (!self.infoPanel) return;
    
    NSRect containerBounds = self.bounds;
    CGFloat infoPanelWidth = 230;
    CGFloat infoPanelHeight = 160; // Increased height for mouse coordinates
    
    // Position panel on the right side with margin
    NSRect panelFrame = NSMakeRect(
        containerBounds.size.width - infoPanelWidth - 10,  // 10px right margin
        containerBounds.size.height - infoPanelHeight - 10, // 10px top margin
        infoPanelWidth,
        infoPanelHeight
    );
    
    self.infoPanel.frame = panelFrame;
    
    // Position labels within the panel
    CGFloat labelHeight = 20;
    CGFloat margin = 10;
    CGFloat spacing = 5;
    
    self.xRangeLabel.frame = NSMakeRect(margin, infoPanelHeight - margin - labelHeight, infoPanelWidth - 2*margin, labelHeight);
    self.yRangeLabel.frame = NSMakeRect(margin, infoPanelHeight - margin - 2*labelHeight - spacing, infoPanelWidth - 2*margin, labelHeight);
    self.magnificationLabel.frame = NSMakeRect(margin, infoPanelHeight - margin - 3*labelHeight - 2*spacing, infoPanelWidth - 2*margin, labelHeight);
    self.mouseXLabel.frame = NSMakeRect(margin, infoPanelHeight - margin - 4*labelHeight - 3*spacing, infoPanelWidth - 2*margin, labelHeight);
    self.mouseYLabel.frame = NSMakeRect(margin, infoPanelHeight - margin - 5*labelHeight - 4*spacing, infoPanelWidth - 2*margin, labelHeight);
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
    [self updateRenderTimeLabelVisibility];
}

- (void)updateRenderTimeLabelVisibility {
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    self.renderTimeLabel.hidden = !appDelegate.showRenderTime;
    [self positionRenderTimeLabel];
}

- (void)renderTimeSettingChanged {
    [self updateRenderTimeLabelVisibility];
}

- (void)updateInfoPanel {
    if (!self.infoPanel || !renderer) return;
    
    // Get current complex plane bounds
    complex long double bottomLeft = renderer.bottomLeft;
    complex long double topRight = renderer.topRight;
    
    long double xMin = creall(bottomLeft);
    long double xMax = creall(topRight);
    long double yMin = cimagl(bottomLeft);
    long double yMax = cimagl(topRight);
    
    // Calculate magnification compared to initial view
    long double initialWidth = creall(initialTopRight) - creall(initialBottomLeft);
    long double currentWidth = xMax - xMin;
    long double magnification = initialWidth / currentWidth;
    
    // Update labels with formatted text
    self.xRangeLabel.stringValue = [NSString stringWithFormat:@"X: %.5Lf to %.5Lf", xMin, xMax];
    self.yRangeLabel.stringValue = [NSString stringWithFormat:@"Y: %.5Lf to %.5Lf", yMin, yMax];
    
    if (magnification >= 1000000) {
        self.magnificationLabel.stringValue = [NSString stringWithFormat:@"Mag: %.2LfM×", magnification / 1000000.0L];
    } else if (magnification >= 1000) {
        self.magnificationLabel.stringValue = [NSString stringWithFormat:@"Mag: %.2LfK×", magnification / 1000.0L];
    } else {
        self.magnificationLabel.stringValue = [NSString stringWithFormat:@"Mag: %.2Lf×", magnification];
    }
}

- (void)setupInfoPanel {
    if (!self.infoPanel) {
        // Create info panel container
        self.infoPanel = [[NSView alloc] init];
        self.infoPanel.wantsLayer = YES;
        self.infoPanel.layer.backgroundColor = [NSColor colorWithWhite:0.95 alpha:0.9].CGColor;
        self.infoPanel.layer.cornerRadius = 8.0;
        self.infoPanel.layer.borderWidth = 1.0;
        self.infoPanel.layer.borderColor = [NSColor lightGrayColor].CGColor;
        
        // Create labels
        self.xRangeLabel = [[NSTextField alloc] init];
        self.xRangeLabel.editable = NO;
        self.xRangeLabel.bezeled = NO;
        self.xRangeLabel.drawsBackground = NO;
        self.xRangeLabel.font = [NSFont monospacedSystemFontOfSize:11.0 weight:NSFontWeightRegular];
        self.xRangeLabel.textColor = [NSColor blackColor];
        self.xRangeLabel.alignment = NSTextAlignmentLeft;
        
        self.yRangeLabel = [[NSTextField alloc] init];
        self.yRangeLabel.editable = NO;
        self.yRangeLabel.bezeled = NO;
        self.yRangeLabel.drawsBackground = NO;
        self.yRangeLabel.font = [NSFont monospacedSystemFontOfSize:11.0 weight:NSFontWeightRegular];
        self.yRangeLabel.textColor = [NSColor blackColor];
        self.yRangeLabel.alignment = NSTextAlignmentLeft;
        
        self.magnificationLabel = [[NSTextField alloc] init];
        self.magnificationLabel.editable = NO;
        self.magnificationLabel.bezeled = NO;
        self.magnificationLabel.drawsBackground = NO;
        self.magnificationLabel.font = [NSFont monospacedSystemFontOfSize:11.0 weight:NSFontWeightRegular];
        self.magnificationLabel.textColor = [NSColor blackColor];
        self.magnificationLabel.alignment = NSTextAlignmentLeft;
        
        self.mouseXLabel = [[NSTextField alloc] init];
        self.mouseXLabel.editable = NO;
        self.mouseXLabel.bezeled = NO;
        self.mouseXLabel.drawsBackground = NO;
        self.mouseXLabel.font = [NSFont monospacedSystemFontOfSize:11.0 weight:NSFontWeightRegular];
        self.mouseXLabel.textColor = [NSColor darkGrayColor];
        self.mouseXLabel.alignment = NSTextAlignmentLeft;
        self.mouseXLabel.stringValue = @"Mouse X: --";
        
        self.mouseYLabel = [[NSTextField alloc] init];
        self.mouseYLabel.editable = NO;
        self.mouseYLabel.bezeled = NO;
        self.mouseYLabel.drawsBackground = NO;
        self.mouseYLabel.font = [NSFont monospacedSystemFontOfSize:11.0 weight:NSFontWeightRegular];
        self.mouseYLabel.textColor = [NSColor darkGrayColor];
        self.mouseYLabel.alignment = NSTextAlignmentLeft;
        self.mouseYLabel.stringValue = @"Mouse Y: --";
        
        // Add labels to panel
        [self.infoPanel addSubview:self.xRangeLabel];
        [self.infoPanel addSubview:self.yRangeLabel];
        [self.infoPanel addSubview:self.magnificationLabel];
        [self.infoPanel addSubview:self.mouseXLabel];
        [self.infoPanel addSubview:self.mouseYLabel];
        
        // Add panel to view
        [self addSubview:self.infoPanel];
    }
}

- (void)setupSelectionOverlayView {
    NSLog(@"Creating SelectionRectangleView programmatically");
    self.selectionOverlayView = [[SelectionRectangleView alloc] initWithFrame:self.bounds];
    self.selectionOverlayView.shouldDrawRectangle = NO;
    [self addSubview:self.selectionOverlayView];
}

- (void)setupMouseTracking {
    // Create a tracking area for the entire view
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] 
        initWithRect:self.bounds
        options:(NSTrackingMouseMoved | NSTrackingActiveInKeyWindow)
        owner:self
        userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)performPanningWithCurrentLoc:(NSPoint)currentLoc {
    // Calculate drag distance in pixels
    CGFloat deltaX = currentLoc.x - mouseDownLoc.x;
    CGFloat deltaY = currentLoc.y - mouseDownLoc.y;
    
    // Get the current image view size to calculate the scale
    NSSize imageSize = self.imageView.bounds.size;
    if (imageSize.width == 0 || imageSize.height == 0) return;
    
    // Calculate the current complex plane dimensions
    complex long double currentSpan = panStartTopRight - panStartBottomLeft;
    long double realSpan = creall(currentSpan);
    long double imagSpan = cimagl(currentSpan);
    
    // Convert pixel movement to complex plane movement
    // Note: Y is inverted because screen coordinates increase downward
    long double realDelta = -(deltaX / imageSize.width) * realSpan;
    long double imagDelta = (deltaY / imageSize.height) * imagSpan;
    
    complex long double offset = realDelta + imagDelta * I;
    
    // Update renderer coordinates
    renderer.bottomLeft = panStartBottomLeft + offset;
    renderer.topRight = panStartTopRight + offset;
    
    // Re-render the image
    [self setImage];
}

- (void)performSingleClickZoomAtPoint:(NSPoint)clickPoint {
    NSLog(@"Single click zoom at point (%f, %f)", clickPoint.x, clickPoint.y);
    
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    long double zoomFactor = appDelegate.magnificationLevel;
    
    // Convert click point to complex plane coordinates
    NSSize imageSize = self.imageView.bounds.size;
    if (imageSize.width == 0 || imageSize.height == 0) return;
    
    // Get current complex plane bounds
    complex long double currentBottomLeft = renderer.bottomLeft;
    complex long double currentTopRight = renderer.topRight;
    
    long double realSpan = creall(currentTopRight) - creall(currentBottomLeft);
    long double imagSpan = cimagl(currentTopRight) - cimagl(currentBottomLeft);
    
    // Convert click point from view coordinates to image coordinates
    NSRect imageFrame = self.imageView.frame;
    CGFloat relativeX = (clickPoint.x - imageFrame.origin.x) / imageFrame.size.width;
    CGFloat relativeY = (clickPoint.y - imageFrame.origin.y) / imageFrame.size.height;
    
    // Clamp to image bounds
    relativeX = fmax(0.0, fmin(1.0, relativeX));
    relativeY = fmax(0.0, fmin(1.0, relativeY));
    
    // Convert to complex plane coordinates (note Y inversion)
    long double clickReal = creall(currentBottomLeft) + relativeX * realSpan;
    long double clickImag = cimagl(currentBottomLeft) + (1.0 - relativeY) * imagSpan;
    complex long double clickComplex = clickReal + clickImag * I;
    
    NSLog(@"Click complex: %Lf + %Lfi", creall(clickComplex), cimagl(clickComplex));
    
    // Calculate new bounds for zoom centered on click point
    long double newRealSpan = realSpan / zoomFactor;
    long double newImagSpan = imagSpan / zoomFactor;
    
    long double newBottomLeftReal = clickReal - newRealSpan / 2.0L;
    long double newBottomLeftImag = clickImag - newImagSpan / 2.0L;
    long double newTopRightReal = clickReal + newRealSpan / 2.0L;
    long double newTopRightImag = clickImag + newImagSpan / 2.0L;
    
    // Update renderer coordinates
    renderer.bottomLeft = newBottomLeftReal + newBottomLeftImag * I;
    renderer.topRight = newTopRightReal + newTopRightImag * I;
    
    NSLog(@"New bounds: %Lf+%Lfi to %Lf+%Lfi", 
          creall(renderer.bottomLeft), cimagl(renderer.bottomLeft),
          creall(renderer.topRight), cimagl(renderer.topRight));
    
    // Re-render the image
    [self setImage];
}

- (void)performSingleClickZoomOutAtPoint:(NSPoint)clickPoint {
    NSLog(@"Command-click zoom out at point (%f, %f)", clickPoint.x, clickPoint.y);
    
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    long double zoomFactor = appDelegate.magnificationLevel;
    
    // Convert click point to complex plane coordinates
    NSSize imageSize = self.imageView.bounds.size;
    if (imageSize.width == 0 || imageSize.height == 0) return;
    
    // Get current complex plane bounds
    complex long double currentBottomLeft = renderer.bottomLeft;
    complex long double currentTopRight = renderer.topRight;
    
    long double realSpan = creall(currentTopRight) - creall(currentBottomLeft);
    long double imagSpan = cimagl(currentTopRight) - cimagl(currentBottomLeft);
    
    // Convert click point from view coordinates to image coordinates
    NSRect imageFrame = self.imageView.frame;
    CGFloat relativeX = (clickPoint.x - imageFrame.origin.x) / imageFrame.size.width;
    CGFloat relativeY = (clickPoint.y - imageFrame.origin.y) / imageFrame.size.height;
    
    // Clamp to image bounds
    relativeX = fmax(0.0, fmin(1.0, relativeX));
    relativeY = fmax(0.0, fmin(1.0, relativeY));
    
    // Convert to complex plane coordinates (note Y inversion)
    long double clickReal = creall(currentBottomLeft) + relativeX * realSpan;
    long double clickImag = cimagl(currentBottomLeft) + (1.0 - relativeY) * imagSpan;
    complex long double clickComplex = clickReal + clickImag * I;
    
    NSLog(@"Click complex: %Lf + %Lfi", creall(clickComplex), cimagl(clickComplex));
    
    // Calculate new bounds for zoom out centered on click point
    long double newRealSpan = realSpan * zoomFactor;
    long double newImagSpan = imagSpan * zoomFactor;
    
    long double newBottomLeftReal = clickReal - newRealSpan / 2.0L;
    long double newBottomLeftImag = clickImag - newImagSpan / 2.0L;
    long double newTopRightReal = clickReal + newRealSpan / 2.0L;
    long double newTopRightImag = clickImag + newImagSpan / 2.0L;
    
    // Update renderer coordinates
    renderer.bottomLeft = newBottomLeftReal + newBottomLeftImag * I;
    renderer.topRight = newTopRightReal + newTopRightImag * I;
    
    NSLog(@"New bounds: %Lf+%Lfi to %Lf+%Lfi", 
          creall(renderer.bottomLeft), cimagl(renderer.bottomLeft),
          creall(renderer.topRight), cimagl(renderer.topRight));
    
    // Re-render the image
    [self setImage];
}

- (void)resetToOriginalView {
    NSLog(@"Resetting to original view (Escape key pressed)");
    
    // Reset to initial coordinates
    renderer.bottomLeft = initialBottomLeft;
    renderer.topRight = initialTopRight;
    
    NSLog(@"Reset to bounds: %Lf+%Lfi to %Lf+%Lfi", 
          creall(renderer.bottomLeft), cimagl(renderer.bottomLeft),
          creall(renderer.topRight), cimagl(renderer.topRight));
    
    // Re-render the image
    [self setImage];
}

@end
