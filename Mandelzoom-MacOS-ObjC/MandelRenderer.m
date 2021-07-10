//
//  MandelRenderer.m
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/4/21.
//

#import <Foundation/Foundation.h>
#import "MandelRenderer.h"

@implementation MandelRenderer
{
    double tl, br;
    int THRESHOLD, MAXITERATIONS;
}

-(void) setup {
    THRESHOLD=10;
    MAXITERATIONS=100;
}

-(NSImage*) render {
    NSImage* imageObj = [NSImage imageNamed:@"klarion"];
    return imageObj;
    
}

@end
