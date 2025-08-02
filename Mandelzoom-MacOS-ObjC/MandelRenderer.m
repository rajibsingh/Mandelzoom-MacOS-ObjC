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

// h (hue): 0-360, s (saturation): 0-1, b (brightness): 0-1
static void hsbToRgb(long double h, long double s, long double v, UInt8 *r_out, UInt8 *g_out, UInt8 *b_out) {
    if (s == 0) { // Achromatic (grey)
        *r_out = *g_out = *b_out = (UInt8)(v * 255.0L);
        return;
    }

    long double hue_sector = floorl(h / 60.0L);
    long double hue_fractional = (h / 60.0L) - hue_sector;

    long double p = v * (1.0L - s);
    long double q = v * (1.0L - s * hue_fractional);
    long double t = v * (1.0L - s * (1.0L - hue_fractional));

    long double r_temp=0, g_temp=0, b_temp=0;

    switch ((int)hue_sector) {
        case 0: r_temp = v; g_temp = t; b_temp = p; break;
        case 1: r_temp = q; g_temp = v; b_temp = p; break;
        case 2: r_temp = p; g_temp = v; b_temp = t; break;
        case 3: r_temp = p; g_temp = q; b_temp = v; break;
        case 4: r_temp = t; g_temp = p; b_temp = v; break;
        default:r_temp = v; g_temp = p; b_temp = q; break; // case 5
    }
    *r_out = (UInt8)(r_temp * 255.0L);
    *g_out = (UInt8)(g_temp * 255.0L);
    *b_out = (UInt8)(b_temp * 255.0L);
}

@implementation MandelRenderer
{
    struct pixel {
        UInt8 aChannel;
        UInt8 rChannel;
        UInt8 gChannel;
        UInt8 bChannel;
    };
    
    struct pixel data[1000][1000];
    complex long double _bottomLeft;
    complex long double _topRight;
}

@synthesize bottomLeft = _bottomLeft;
@synthesize topRight = _topRight;

- (instancetype)init {
    self = [super init];
    if (self) {
        // Default coordinates for the initial full view
        _bottomLeft = -2.1L - 1.35L * I;
        _topRight = 0.6L + 1.35L * I;
    }
    return self;
}

-(void) setup {
    clock_t start, end;
    start = clock();
    
    complex long double bl_coord = self.bottomLeft;
    complex long double tr_coord = self.topRight;

    long double stepX = fabsl(creal(tr_coord) - creal(bl_coord)) / 1000L;
    long double stepY = fabsl(cimag(tr_coord) - cimag(bl_coord)) / 1000L;
    
    const long double ESCAPE_RADIUS_SQUARED = 256.0L;
    int MAXITERATIONS = 500;

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_apply(1000, queue, ^(size_t yDataPos_idx) {
        int yDataPos = (int)yDataPos_idx;

        for (int xDataPos = 0; xDataPos < 1000; xDataPos++) {
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
                pxl.rChannel = 0;
                pxl.gChannel = 0;
                pxl.bChannel = 0;
            } else {
                long double smooth_iteration = iteration + 1.0L - log2l(0.5L * log2l(modulus_squared));

                long double color_density = 0.055L;
                long double hue_0_to_1 = fmodl(smooth_iteration * color_density, 1.0L);
                
                if (hue_0_to_1 < 0.0L) {
                    hue_0_to_1 += 1.0L;
                }
                
                long double base_hue_degrees = hue_0_to_1 * 360.0L;
                long double hue_offset_degrees = 43.0L;
                long double final_hue_degrees = fmodl(base_hue_degrees + hue_offset_degrees, 360.0L);
                
                hsbToRgb(final_hue_degrees, 1.0L, 1.0L, &pxl.rChannel, &pxl.gChannel, &pxl.bChannel);
            }
            
            pxl.aChannel = 255;
            data[yDataPos][xDataPos] = pxl;
        }
    });

    end = clock();
    printf("Color calculation took %f seconds\n", (float)(end - start)/CLOCKS_PER_SEC);
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

@end
