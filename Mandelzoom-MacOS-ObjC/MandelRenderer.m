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
#include <math.h>

//use of complex type from https://stackoverflow.com/questions/12980052/are-complex-numbers-already-defined-in-objective-c


@implementation MandelRenderer
{
    struct pixel {
        UInt8 aChannel;
        UInt8 rChannel;
        UInt8 gChannel;
        UInt8 bChannel;
    };
    
    struct pixel *data;
    int currentWidth;
    int currentHeight;
    complex long double _bottomLeft;
    complex long double _topRight;
}

@synthesize bottomLeft = _bottomLeft;
@synthesize topRight = _topRight;

- (instancetype)init {
    self = [super init];
    if (self) {
        // Default coordinates for the classic full Mandelbrot view
        _bottomLeft = -2.5L - 1.25L * I;
        _topRight = 1.0L + 1.25L * I;
        data = NULL;
        currentWidth = 0;
        currentHeight = 0;
    }
    return self;
}

-(double) setupWithWidth:(int)width height:(int)height {
    if (data && (width != currentWidth || height != currentHeight)) {
        free(data);
        data = NULL;
    }
    
    if (!data) {
        currentWidth = width;
        currentHeight = height;
        data = malloc(width * height * sizeof(struct pixel));
        if (!data) {
            NSLog(@"Error: Failed to allocate memory for pixel data");
            return 0.0;
        }
    }
    
    clock_t start, end;
    start = clock();
    
    complex long double bl_coord = self.bottomLeft;
    complex long double tr_coord = self.topRight;

    long double stepX = fabsl(creal(tr_coord) - creal(bl_coord)) / (long double)width;
    long double stepY = fabsl(cimag(tr_coord) - cimag(bl_coord)) / (long double)height;
    
    const long double ESCAPE_RADIUS_SQUARED = 256.0L;
    int MAXITERATIONS = 500;

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_apply(height, queue, ^(size_t yDataPos_idx) {
        int yDataPos = (int)yDataPos_idx;

        for (int xDataPos = 0; xDataPos < width; xDataPos++) {
            long double x0 = creal(bl_coord) + stepX * xDataPos;
            long double y0 = cimag(bl_coord) + stepY * yDataPos;
            
            complex long double c = x0 + y0 * I;
            complex long double z = 0.0L + 0.0L * I;

            int iteration = 0;
            long double modulus_squared = 0.0L;
            
            while (iteration < MAXITERATIONS) {
                long double z_re = creal(z);
                long double z_im = cimag(z);
                modulus_squared = z_re * z_re + z_im * z_im;
                if (modulus_squared > ESCAPE_RADIUS_SQUARED) {
                    break;
                }
                z = (z_re * z_re - z_im * z_im + creal(c)) + (2.0L * z_re * z_im + cimag(c)) * I;
                iteration++;
            }
            
            struct pixel pxl;

            if (iteration == MAXITERATIONS) {
                // Interior points: black
                pxl.rChannel = 0;
                pxl.gChannel = 0;
                pxl.bChannel = 0;
            } else {
                // Classic blue Mandelbrot coloring
                long double smooth_iteration = iteration + 1.0L - log2l(0.5L * log2l(modulus_squared));
                
                // Simple blue gradient based on iteration count
                long double t = smooth_iteration / 50.0L; // Scale for better gradient
                t = fminl(t, 1.0L);
                
                // Deep blue (0,0,128) to bright white (255,255,255)
                long double intensity = powl(t, 0.5L); // Gamma correction for better gradient
                
                pxl.rChannel = (UInt8)(intensity * 255.0L);
                pxl.gChannel = (UInt8)(intensity * 255.0L);
                pxl.bChannel = (UInt8)(128.0L + intensity * 127.0L); // Start from blue, go to white
            }
            
            pxl.aChannel = 255;
            data[yDataPos * width + xDataPos] = pxl;
        }
    });

    end = clock();
    double renderTime = (double)(end - start)/CLOCKS_PER_SEC;
    printf("Color calculation took %f seconds\n", renderTime);
    return renderTime;
}

-(NSImage*) render {
    return [self renderWithWidth:1000 height:1000];
}

-(NSImage*) renderWithWidth:(int)width height:(int)height {
    double renderTime;
    return [self renderWithWidth:width height:height renderTime:&renderTime];
}

-(NSImage*) renderWithWidth:(int)width height:(int)height renderTime:(double*)renderTime {
    double time = [self setupWithWidth:width height:height];
    if (renderTime) {
        *renderTime = time;
    }
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

- (void)dealloc {
    if (data) {
        free(data);
        data = NULL;
    }
}

@end