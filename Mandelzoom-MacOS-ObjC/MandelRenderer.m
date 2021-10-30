//
//  MandelRenderer.m
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/4/21.
//
#import <Foundation/Foundation.h>
#import "MandelRenderer.h"

#include <complex.h>
#include <time.h>

//use of complex type from https://stackoverflow.com/questions/12980052/are-complex-numbers-already-defined-in-objective-c
@implementation MandelRenderer
{
    complex long double bl, tr;
    long double stepX, stepY;
    int THRESHOLD, MAXITERATIONS;
    UInt8 r,g,b,a;
    long double mouseDown, mouseUp;
    
    struct pixel {
        UInt8 aChannel;
        UInt8 rChannel;
        UInt8 gChannel;
        UInt8 bChannel;
    };
    
    struct pixel data[1000][1000];
}

-(void) setup {
    clock_t start, end;
    start = clock();
    complex long double bl = -2L - 2Li;
    complex long double tr = 2L + 2Li;
//    NSLog(@"bl -> %le, %le i", creal(bl), cimag(bl));
//    NSLog(@"tr -> %le, %le i", creal(tr), cimag(tr));
    stepX = fabsl(creal(tr) - creal(bl)) / 1000L;
    stepY = fabsl(cimag(tr) - cimag(bl)) / 1000L;
//    NSLog(@"stepX: %Le, stepY: %Le", stepX, stepY);
    THRESHOLD=10;
    MAXITERATIONS=1000;
    int xDataPos, yDataPos;
    for (xDataPos = 0; xDataPos < 1000; xDataPos++) {
        for (yDataPos = 0; yDataPos < 1000; yDataPos++) {
            long double x = creal(bl) + stepX * xDataPos;
            long double y = cimag(bl) + stepY * yDataPos;
            complex long double origNumVal = x + y * I;
            complex long double currNumVal = x + y * I;
            int iteration = 0;
            while (creal(currNumVal) * creal(currNumVal) + cimag(currNumVal) + cimag(currNumVal) <= THRESHOLD
                   && iteration < MAXITERATIONS) {
                iteration++;
                currNumVal = currNumVal * currNumVal + origNumVal;
            }
            struct pixel pxl;
            UInt8 colorDelta;
            switch(iteration) {
                case 0:
                    pxl.rChannel = 0;
                    pxl.gChannel = 0;
                    pxl.bChannel = 0;
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
                    pxl.gChannel = 255;
                    pxl.bChannel = 255;
                    break;
                case 9 ... 1000:
                    colorDelta = 255 - (85 * (9 - iteration));
                    pxl.rChannel = colorDelta;
                    pxl.gChannel = 255;
                    pxl.bChannel = 255;
                    break;
                default:
                    pxl.rChannel = 0;
                    pxl.gChannel = 0;
                    pxl.bChannel = 0;
                    pxl.aChannel = 0;
            }
            data[yDataPos][xDataPos] = pxl;
        }
    }
//    struct pixel px1 = data[0][0];
//    printf("px1 -> %ir %ig %ib %ia\n", px1.rChannel, px1.gChannel, px1.bChannel, px1.aChannel);
//    struct pixel px2 = data[999][999];
//    printf("px2 -> %ir %ig %ib %ia\n", px2.rChannel, px2.gChannel, px2.bChannel, px2.aChannel);
    end = clock();
    printf("that took %le seconds\n", ((double) end - start));
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
    CGColorRenderingIntent renderingIntent = kCGImageAlphaPremultipliedFirst;
//    CGColorRenderingIntent renderingIntent = kCGImageAlphaLast;
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

-(NSImage*) renderWithBox {
//    NSLog(@"*** in the renderWithBox method");
    NSImage *image = [self render];
    return image;
}

@end
