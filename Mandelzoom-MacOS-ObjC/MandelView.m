//  MandelView.m
//  Mandelzoom-MacOS-ObjC

#import <Foundation/Foundation.h>
#import "MandelView.h"
#import "MandelRenderer.h"

@implementation MandelView
{
    MandelRenderer *renderer;
    long double mouseDownLocX, mouseDownLocY, mouseUpLocX, mouseUpLocY;
    NSPoint *mouseDownLoc, *mouseUpLoc;
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
    NSPoint clickLocation;
 
    // convert the mouse-down location into the view coords
    clickLocation = [self convertPoint:[event locationInWindow]
                  fromView:nil];
    double x = clickLocation.x;
    double y = clickLocation.y;
    mouseDownLocX = x;
    mouseDownLocY = y;
    NSLog(@"*** mouseDown event");
    NSLog(@"x:%lf y:%lf", x, y);
}

-(void)mouseUp: (NSEvent *)event
{
    // convert the mouse-down location into the view coords
    NSPoint clickLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    mouseUpLocX = clickLocation.x;
    mouseUpLocY = clickLocation.y;
    NSLog(@"*** draw a box from %Lf, %Lf to %Lf, %Lf", mouseDownLocX, mouseDownLocY, mouseUpLocX, mouseUpLocY);
    mouseDownLocX = 0;
    mouseDownLocY = 0;
}

@end
