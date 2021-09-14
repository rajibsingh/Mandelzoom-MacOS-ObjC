//  MandelView.m
//  Mandelzoom-MacOS-ObjC

#import <Foundation/Foundation.h>
#import "MandelView.h"
#import "MandelRenderer.h"

@implementation MandelView
{
    MandelRenderer *renderer;
    NSPoint mouseDownLoc, mouseUpLoc;
}

//-(void) setUp {
//    *renderer = [[MandelRenderer alloc] init];
//}

-(void) setImage {
//    NSImage* imageObj = [NSImage imageNamed:@"klarion"];
//    _imageView.image = imageObj;
//    _imageView.image = [renderer render];
    [self refresh];
}

-(void) refresh {
    NSLog(@"*** refresh method");
    MandelRenderer *renderer = [[MandelRenderer alloc] init];
    _imageView.image = [renderer render];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

-(void)mouseDown:(NSEvent *)event
{
    // convert the mouse-down location into the view coords
    NSPoint clickLocation = [self convertPoint:[event locationInWindow]
                  fromView:nil];
    mouseDownLoc = clickLocation;
    NSLog(@"mouseDown x:%lf y:%lf", mouseDownLoc.x, mouseDownLoc.y);
}

-(void)mouseUp: (NSEvent *)event
{
    // convert the mouse-down location into the view coords
    NSPoint clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    mouseUpLoc = clickLocation;
    NSLog(@"*** draw a box from %f, %f to %f, %f", mouseDownLoc.x, mouseDownLoc.y, mouseUpLoc.x, mouseUpLoc.y);
}

@end
