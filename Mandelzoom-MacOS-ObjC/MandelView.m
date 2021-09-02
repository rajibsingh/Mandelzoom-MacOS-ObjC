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
    NSLog(@"x:%le y:%le", x, y);
    NSLog(@"hey we captured a mouseDown event");
 

}

@end
