//
//  MandelRenderer.m
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/4/21.
//

#import <Foundation/Foundation.h>
#import "MandelRenderer.h"

#include <complex.h>

@implementation MandelRenderer
{
    complex double tl, br;
    double stepX, stepY;
    int THRESHOLD, MAXITERATIONS;
    UInt8 r,g,b,a;
    
    struct pixel {
        UInt8 rChannel;
        UInt8 gChannel;
        UInt8 bChannel;
        UInt8 aChannel;
    };
    
    struct pixel data[1000][1000];
}

-(void) setup {
    complex double tl = -2.5 + 1*I;
    complex double br = -1 + 1*I;
    stepX = creal(br) - creal(tl) / 10000;
    stepY = cimag(br) - cimag(tl) / 10000;
    THRESHOLD=10;
    MAXITERATIONS=100;
    int x,y;
    for (x = 0; x < 1000;x++) {
        for (y = 0; y < 1000; y++) {
            // get some result based on running a loop        
//            while (x*x + y*y ≤ 2*2 AND iteration < max_iteration) {
//                    xtemp := x*x - y*y + x0
//                    y := 2*x*y + y0
//                    x := xtemp
//                    iteration := iteration + 1
//            }
            r = 0;
            g = x;
            b = y;
            a = 255;
            struct pixel pxl = data[x][y];
            pxl.rChannel = r;
            pxl.gChannel = g;
            pxl.bChannel = b;
            pxl.aChannel = a;
            data[x][y] = pxl;
        }
    }
    struct pixel pxl = data[0][0];
    printf("%ir %ig %ib %ia", pxl.rChannel, pxl.gChannel, pxl.bChannel, pxl.aChannel);
    struct pixel px2 = data[999][999];
    printf("%ir %ig %ib %ia", px2.rChannel, px2.gChannel, px2.bChannel, px2.aChannel);
}

// got this code from https://stackoverflow.com/a/11719369/1922101
-(NSImage*) render {
    [self setup];
    int width = 1000;
    int height = 1000;
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
}

@end
