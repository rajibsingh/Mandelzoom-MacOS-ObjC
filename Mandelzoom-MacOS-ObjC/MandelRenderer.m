//
//  MandelRenderer.m
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/4/21.
//

#import <Foundation/Foundation.h>
#import "MandelRenderer.h"

#include <complex.h>

//use of complex type from
//https://stackoverflow.com/questions/12980052/are-complex-numbers-already-defined-in-objective-c

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
    complex double tl = -2.5 + 1i;
    complex double br = -1 + 1i;
    stepX = creal(br) - creal(tl) / 1000;
    stepY = cimag(br) - cimag(tl) / 1000;
    THRESHOLD=10;
    MAXITERATIONS=100;
    int xDataPos,yDataPos;
    for (xDataPos = 0; xDataPos < 1000; xDataPos++) {
        for (yDataPos = 0; yDataPos < 1000; yDataPos++) {
            double x = creal(br) + stepX * xDataPos;
            double y = cimag(br) + stepY * yDataPos;
            int iteration = 0;
            while (x*x + y*y <= THRESHOLD && iteration < MAXITERATIONS) {
                double xtemp = x*x - y*y + creal(tl);
                y = 2*x*y + cimag(tl);
                x = xtemp;
                iteration++;
            }
            struct pixel pxl;
            pxl.rChannel = 0;
            pxl.gChannel = 0;
            pxl.bChannel = 0;
            pxl.aChannel = 255;
            UInt8 colorDelta;
            switch(iteration) {
                case 100:
                    break;
                case 1:
                    pxl.rChannel = 255;
                    pxl.gChannel = 255;
                    pxl.bChannel = 255;
                    break;
                case 2 ... 6:
                    colorDelta = 255 - (42 * (7 - iteration));
                    pxl.rChannel = 255;
                    pxl.gChannel = colorDelta;
                    pxl.bChannel = colorDelta;
                    break;
                case 7 ... 8:
                    colorDelta = 255 - (85 * (9 - iteration));
                    pxl.rChannel = colorDelta;
                    pxl.gChannel = colorDelta;
                    pxl.bChannel = 255;
                    break;
            }
            if (iteration > 0) {
                printf("caught a non zero iteration: %i\n", iteration);
                printf("%ir %ig %ib %ia\n", pxl.rChannel, pxl.gChannel, pxl.bChannel, pxl.aChannel);
            }
            data[xDataPos][yDataPos] = pxl;
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
