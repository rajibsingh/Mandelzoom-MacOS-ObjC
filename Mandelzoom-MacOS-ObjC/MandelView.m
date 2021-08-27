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

@end
