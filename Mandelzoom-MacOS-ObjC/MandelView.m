//
//  MandelView.m
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/4/21.
//

#import <Foundation/Foundation.h>
#import "MandelView.h"
#import "MandelRenderer.h"

@implementation MandelView
{
    MandelRenderer *renderer;
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

//- (BOOL)acceptsFirstResponder
//{
//    return YES;
//}

-(void)mouseDown:(NSEvent *)event
{
    NSPoint clickLocation;
 
    // convert the mouse-down location into the view coords
    clickLocation = [self convertPoint:[event locationInWindow]
                  fromView:nil];
    double x = clickLocation.x;
    double y = clickLocation.y;
    NSLog(@"*** mouseDown event");
    NSLog(@"x:%le y:%le", x, y);
}

-(void)mouseUp: (NSEvent *)event
{
    // convert the mouse-down location into the view coords
    NSPoint clickLocation = [self convertPoint:[event locationInWindow]
                     fromView:nil];
    double x = clickLocation.x;
    double y = clickLocation.y;
    NSLog(@"*** mouseUp x:%le y:%le", x, y);
}

@end
