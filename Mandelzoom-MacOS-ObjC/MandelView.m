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
    
    // Listen for application launch
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
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

    // Check if Option/Alt key is held for selection mode, otherwise pan mode
    isPanning = !([event modifierFlags] & NSEventModifierFlagOption);
    
    if (isPanning) {
        // Store current view state for panning
        panStartBottomLeft = renderer.bottomLeft;
        panStartTopRight = renderer.topRight;
        NSLog(@"Starting pan mode");
    } else {
        // Selection mode
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
}

-(void)mouseDragged:(NSEvent *)event
{
    NSPoint currentDragLoc = [self convertPoint:[event locationInWindow]
                                       fromView:nil];
    
    if (isPanning) {
        // Pan mode: update the complex plane coordinates based on drag distance
        [self performPanningWithCurrentLoc:currentDragLoc];
    } else {
        // Selection mode: update selection rectangle
        if (!self.selectionOverlayView || !self.selectionOverlayView.shouldDrawRectangle) {
            return;
        }

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
}

-(void)mouseUp: (NSEvent *)event
{
    NSPoint clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    mouseUpLoc = clickLocation;
    
    if (isPanning) {
        // Check if this was just a click (small movement) vs actual panning
        CGFloat dragDistance = sqrt(pow(mouseUpLoc.x - mouseDownLoc.x, 2) + pow(mouseUpLoc.y - mouseDownLoc.y, 2));
        if (dragDistance < 5) {
            // Check for command-click (zoom out) vs regular click (zoom in)
            if ([event modifierFlags] & NSEventModifierFlagCommand) {
                // Command-click - zoom out 2x at the clicked point
                [self performSingleClickZoomOutAtPoint:mouseDownLoc];
            } else {
                // Regular click - zoom in 2x at the clicked point
                [self performSingleClickZoomAtPoint:mouseDownLoc];
            }
        }
        NSLog(@"Finished panning/clicking");
        return;
    }
    
    // Selection mode
    if (self.selectionOverlayView) {
        self.selectionOverlayView.shouldDrawRectangle = NO;
        [self.selectionOverlayView setNeedsDisplay:YES];
    }
    
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
    [self positionRenderTimeLabel];
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
