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
        self.imageView.imageScaling = NSImageScaleProportionallyDown;
    }
}

-(void) setImage {
    if (!renderer) {
        [self awakeFromNib];
    }
    
    NSSize viewSize = _imageView.bounds.size;
    int resolution = [self calculateOptimalResolution:viewSize];
    
    _imageView.image = [renderer renderWithWidth:resolution height:resolution];
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
    
    _imageView.image = [renderer renderWithWidth:resolution height:resolution];
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
        self.selectionOverlayView.shouldDrawRectangle = YES;
        self.selectionOverlayView.selectionRectToDraw = NSMakeRect(mouseDownLoc.x, mouseDownLoc.y, 0, 0);
        [self.selectionOverlayView setNeedsDisplay:YES];
    }
}

-(void)mouseDragged:(NSEvent *)event
{
    if (!self.selectionOverlayView || !self.selectionOverlayView.shouldDrawRectangle) {
        return;
    }

    NSPoint currentDragLoc = [self convertPoint:[event locationInWindow]
                                       fromView:nil];
    
    CGFloat x1 = mouseDownLoc.x;
    CGFloat y1 = mouseDownLoc.y;
    CGFloat x2 = currentDragLoc.x;
    CGFloat y2 = currentDragLoc.y;

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
    
    _imageView.image = [renderer renderWithWidth:resolution height:resolution];
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

@end
