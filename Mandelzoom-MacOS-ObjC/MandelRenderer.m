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
    complex long double bl_ivar, tr_ivar; 
    long double stepX_ivar, stepY_ivar; 
    int THRESHOLD_ivar, MAXITERATIONS_ivar; 
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
    long double stepX = fabsl(creal(tr) - creal(bl)) / 1000L;
    long double stepY = fabsl(cimag(tr) - cimag(bl)) / 1000L;
    int THRESHOLD=10; 
    int MAXITERATIONS=250;

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_apply(1000, queue, ^(size_t yDataPos_idx) {
        int yDataPos = (int)yDataPos_idx;

        for (int xDataPos = 0; xDataPos < 1000; xDataPos++) {
            long double x = creal(bl) + stepX * xDataPos;
            long double y = cimag(bl) + stepY * yDataPos; 
            
            complex long double origNumVal = x + y * I;
            complex long double currNumVal = x + y * I; 
            
            int iteration = 0;
            
            while (creal(currNumVal) * creal(currNumVal) + cimag(currNumVal) * cimag(currNumVal) <= THRESHOLD
                   && iteration < MAXITERATIONS) {
                iteration++;
                currNumVal = currNumVal * currNumVal + origNumVal;
            }
            
            struct pixel pxl;
            UInt8 colorDelta;

            // Color logic based on the original switch, attempting to preserve its behavior.
            // Points that reach MAXITERATIONS are colored by the `9 ... 250` rule in original code.
            if (iteration == MAXITERATIONS) {
                // This is a point considered "in the set" (bounded).
                // Original code's `case 9 ... 250:` covers `iteration = 250`.
                {
                    int val = 9 - iteration; 
                    colorDelta = (UInt8)(255 - (85 * val));
                    pxl.rChannel = colorDelta;
                    pxl.gChannel = 255;
                    pxl.bChannel = 255;
                }
            } else { // Point escaped (iteration < MAXITERATIONS)
                switch(iteration) {
                    case 0:
                        pxl.rChannel = 0; pxl.gChannel = 0; pxl.bChannel = 0;
                        break;
                    case 1:
                        pxl.rChannel = 255; pxl.gChannel = 255; pxl.bChannel = 255;
                        break;
                    case 2:
                    case 3:
                    case 4:
                    case 5:
                    case 6:
                        {
                            colorDelta = 255 - (42 * (7 - iteration));
                            pxl.rChannel = 255; pxl.gChannel = colorDelta; pxl.bChannel = colorDelta;
                        }
                        break;
                    case 7:
                    case 8:
                        {
                            colorDelta = 255 - (85 * (9 - iteration));
                            pxl.rChannel = colorDelta; pxl.gChannel = 255; pxl.bChannel = 255;
                        }
                        break;
                    default: // Covers 9 up to MAXITERATIONS - 1, and any other unhandled intermediate iteration counts.
                        {
                            int val = 9 - iteration;
                            colorDelta = (UInt8)(255 - (85 * val)); // This will wrap around for UInt8, creating color bands.
                            pxl.rChannel = colorDelta;
                            pxl.gChannel = 255;
                            pxl.bChannel = 255;
                        }
                        break;
                }
            }
            // Set alpha channel consistently to opaque for all pixels.
            pxl.aChannel = 255;
            
            data[yDataPos][xDataPos] = pxl;
        }
    }); 

    end = clock();
    printf("that took %f seconds\n", (float)(end - start)/CLOCKS_PER_SEC); 
}

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
                            provider,   
                            NULL,       
                            YES,        
                            renderingIntent);
    
    CGDataProviderRelease(provider); 
    CGColorSpaceRelease(colorSpaceRef); 

    NSImage *image = [[NSImage alloc] initWithCGImage:iref size:NSMakeSize(width, height)];
    CGImageRelease(iref); 

    return image;
}

-(NSImage*) renderWithBox {
    NSImage *image = [self render];
    return image;
}

@end
