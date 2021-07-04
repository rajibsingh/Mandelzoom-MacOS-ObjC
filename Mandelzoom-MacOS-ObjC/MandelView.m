//
//  MandelView.m
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/4/21.
//

#import <Foundation/Foundation.h>
#import "MandelView.h"

@implementation MandelView

-(void) setImage:(NSImage*) imageObj {
   NSLog(@"called print method in MandelView");
//    NSImage* imageObj = [NSImage imageNamed:@"klarion"];
    _imageView.image = imageObj;
}

@end
