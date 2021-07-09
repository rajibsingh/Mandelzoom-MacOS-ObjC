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

-(NSString*) render {
    NSString *result = [[NSString alloc] initWithString:@"666"];
    return result;
}

@end
