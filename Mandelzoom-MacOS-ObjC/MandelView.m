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

-(void) setImage:(NSImage*) imageObj {
   NSLog(@"called setImage method in MandelView");
    _imageView.image = imageObj;
    MandelRenderer *renderer = [[MandelRenderer alloc] init];
    NSString *result = [renderer render];
    NSLog(result);
}

@end
