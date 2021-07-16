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
    double tl, br, stepX, stepY;
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
    THRESHOLD=10;
    MAXITERATIONS=100;
    int x,y;
    for (x = 0; x < 1000;x++) {
        for (y = 0; y < 1000; y++) {
            r = r % 2;
            if (r == 1) {
                r = 255;
            }
            g = g % 2;
            if (g == 1) {
                g = 255;
            }
            b = 0;
            a = 255;
            struct pixel pxl = data[x][y];
            pxl.rChannel = r;
            pxl.gChannel = g;
            pxl.bChannel = b;
            pxl.aChannel = a;
            data[x][y] = pxl;
        }
    }
    struct pixel pxl = data[2][1];
    printf("%ir %ig %ib %ia", pxl.rChannel, pxl.gChannel, pxl.bChannel, pxl.aChannel);
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
