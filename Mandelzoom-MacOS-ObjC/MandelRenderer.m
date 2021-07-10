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
    
    int width = 1000;
    int height = 1000;
    
    int data[1000][1000];

    
    size_t bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, bufferLength, NULL);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = 4 * width;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,   // data provider
                                    NULL,       // decode
                                    YES,        // should interpolate
                                    renderingIntent);
    NSImage *image = [[NSImage alloc] initWithCGImage:iref size:NSMakeSize(width, height)];
    return image;
//    CGImageRef cgim = CGImageCreate(width, height, 8, bitsPerPixel, size_t bytesPerRow, cgColorSpace, CGBitmapInfo bitmapInfo, CGDataProviderRef provider, const CGFloat *decode, shouldInterpolate, CGColorRenderingIntent.defaultIntent());
//
//
//    NSImage* imageObj = [NSImage imageNamed:@"klarion"];
//    return imageObj;
    
}

@end
