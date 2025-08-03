//
//  MandelRenderer.m
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/4/21.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <simd/simd.h>
#import "MandelRenderer.h"

#include <complex.h>
#include <time.h>
#include <math.h>

//use of complex type from https://stackoverflow.com/questions/12980052/are-complex-numbers-already-defined-in-objective-c


@implementation MandelRenderer
{
    struct pixel {
        UInt8 rChannel;
        UInt8 gChannel;
        UInt8 bChannel;
        UInt8 aChannel;
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
        
        // Initialize Metal for GPU acceleration
        [self setupMetal];
    }
    return self;
}

- (void)setupMetal {
    // Get the default Metal device (M1 Max GPU)
    self.metalDevice = MTLCreateSystemDefaultDevice();
    
    if (self.metalDevice) {
        self.commandQueue = [self.metalDevice newCommandQueue];
        [self setupComputePipeline];
        self.useGPUAcceleration = YES;
        NSLog(@"Metal GPU acceleration enabled on: %@", self.metalDevice.name);
    } else {
        self.useGPUAcceleration = NO;
        NSLog(@"Metal GPU acceleration not available, falling back to CPU");
    }
}

- (void)setupComputePipeline {
    NSError *error = nil;
    
    // Load the Metal shader library
    id<MTLLibrary> library = [self.metalDevice newDefaultLibrary];
    if (!library) {
        NSLog(@"Failed to load Metal shader library");
        self.useGPUAcceleration = NO;
        return;
    }
    
    // Get the compute function
    id<MTLFunction> mandelbrotFunction = [library newFunctionWithName:@"mandelbrotTiledKernel"];
    if (!mandelbrotFunction) {
        NSLog(@"Failed to load mandelbrotTiledKernel function");
        self.useGPUAcceleration = NO;
        return;
    }
    
    // Create compute pipeline state
    self.computePipeline = [self.metalDevice newComputePipelineStateWithFunction:mandelbrotFunction
                                                                           error:&error];
    if (!self.computePipeline) {
        NSLog(@"Failed to create compute pipeline: %@", error.localizedDescription);
        self.useGPUAcceleration = NO;
        return;
    }
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
    
    // Use GPU acceleration if available, otherwise fall back to CPU
    if (self.useGPUAcceleration && self.computePipeline) {
        [self renderWithMetalGPU:width height:height];
    } else {
        [self renderWithCPU:width height:height];
    }
    
    end = clock();
    double renderTime = (double)(end - start)/CLOCKS_PER_SEC;
    
    // Calculate adaptive iteration count for logging
    long double width_span = fabsl(creall(self.topRight) - creall(self.bottomLeft));
    long double zoom_factor = 3.5L / width_span;
    long double adaptive_iterations = 500 * (1.0L + log10l(fmaxl(zoom_factor, 1.0L)) * 0.5L);
    int iterations_used = (int)fmaxl(100, fminl(adaptive_iterations, 2000));
    
    printf("Render (%s) took %f seconds [%dx%d, %d iterations, %.1Lfx zoom]\n",
           self.useGPUAcceleration ? "GPU" : "CPU", renderTime, width, height, 
           iterations_used, zoom_factor);
    return renderTime;
}

- (void)renderWithMetalGPU:(int)width height:(int)height {
    // Metal parameters structure
    struct {
        simd_float2 bottomLeft;
        simd_float2 topRight;
        uint32_t width;
        uint32_t height;
        uint32_t maxIterations;
        float escapeRadius;
    } params;
    
    params.bottomLeft = simd_make_float2((float)creall(self.bottomLeft), (float)cimagl(self.bottomLeft));
    params.topRight = simd_make_float2((float)creall(self.topRight), (float)cimagl(self.topRight));
    params.width = width;
    params.height = height;
    // Adaptive iteration count based on zoom level
    long double width_span = fabsl(creall(self.topRight) - creall(self.bottomLeft));
    long double base_iterations = 500;
    long double zoom_factor = 3.5L / width_span; // 3.5 is initial width
    
    // Scale iterations logarithmically with zoom
    long double adaptive_iterations = base_iterations * (1.0L + log10l(fmaxl(zoom_factor, 1.0L)) * 0.5L);
    
    // Cap at reasonable limits: min 100, max 2000
    params.maxIterations = (uint32_t)fmaxl(100, fminl(adaptive_iterations, 2000));
    params.escapeRadius = 2.0f;
    
    // Create Metal buffers
    size_t outputBufferSize = width * height * sizeof(struct pixel);
    id<MTLBuffer> outputBuffer = [self.metalDevice newBufferWithBytes:data
                                                               length:outputBufferSize
                                                              options:MTLResourceStorageModeShared];
    
    id<MTLBuffer> paramsBuffer = [self.metalDevice newBufferWithBytes:&params
                                                               length:sizeof(params)
                                                              options:MTLResourceStorageModeShared];
    
    // Create command buffer and encoder
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLComputeCommandEncoder> encoder = [commandBuffer computeCommandEncoder];
    
    // Set up compute pass
    [encoder setComputePipelineState:self.computePipeline];
    [encoder setBuffer:outputBuffer offset:0 atIndex:0];
    [encoder setBuffer:paramsBuffer offset:0 atIndex:1];
    
    // Optimize threadgroup size based on image size and compute pipeline
    NSUInteger maxThreadsPerGroup = self.computePipeline.maxTotalThreadsPerThreadgroup;
    NSUInteger threadsPerSIMDGroup = self.computePipeline.threadExecutionWidth;
    
    // Use smaller threadgroups for better occupancy on complex computations
    NSUInteger threadgroupWidth = MIN(16, width);
    NSUInteger threadgroupHeight = MIN(maxThreadsPerGroup / threadgroupWidth, height);
    
    // Ensure threadgroup size is multiple of SIMD width for efficiency
    threadgroupWidth = (threadgroupWidth + threadsPerSIMDGroup - 1) / threadsPerSIMDGroup * threadsPerSIMDGroup;
    
    MTLSize threadgroupSize = MTLSizeMake(threadgroupWidth, threadgroupHeight, 1);
    
    // Calculate threadgroup count based on image size and threadgroup size  
    MTLSize threadgroupCount = MTLSizeMake(
        (width + threadgroupSize.width - 1) / threadgroupSize.width,
        (height + threadgroupSize.height - 1) / threadgroupSize.height,
        1
    );
    
    // Dispatch compute threadgroups
    [encoder dispatchThreadgroups:threadgroupCount threadsPerThreadgroup:threadgroupSize];
    [encoder endEncoding];
    
    // Execute and wait for completion
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    // Copy results back to CPU memory
    memcpy(data, outputBuffer.contents, outputBufferSize);
}


- (void)renderWithCPU:(int)width height:(int)height {
    complex long double bl_coord = self.bottomLeft;
    complex long double tr_coord = self.topRight;

    long double stepX = fabsl(creal(tr_coord) - creal(bl_coord)) / (long double)width;
    long double stepY = fabsl(cimag(tr_coord) - cimag(bl_coord)) / (long double)height;
    
    const long double ESCAPE_RADIUS_SQUARED = 4.0L;  // Standard escape radius^2
    
    // Adaptive iteration count based on zoom level
    long double width_span = fabsl(creall(tr_coord) - creall(bl_coord));
    long double base_iterations = 500;
    long double zoom_factor = 3.5L / width_span; // 3.5 is initial width
    
    // Scale iterations logarithmically with zoom
    long double adaptive_iterations = base_iterations * (1.0L + log10l(fmaxl(zoom_factor, 1.0L)) * 0.5L);
    
    // Cap at reasonable limits: min 100, max 2000
    int MAXITERATIONS = (int)fmaxl(100, fminl(adaptive_iterations, 2000));

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

    dispatch_apply(height, queue, ^(size_t yDataPos_idx) {
        int yDataPos = (int)yDataPos_idx;

        for (int xDataPos = 0; xDataPos < width; xDataPos++) {
            long double x0 = creal(bl_coord) + stepX * xDataPos;
            long double y0 = cimag(bl_coord) + stepY * yDataPos;
            
            complex long double c = x0 + y0 * I;
            complex long double z = 0.0L + 0.0L * I;
            
            int iteration = 0;
            long double modulus_squared = 0.0L;
            
            // Early bailout: check main cardioid and period-2 bulb
            long double c_re = creal(c);
            long double c_im = cimag(c);
            
            // Main cardioid check
            long double q = (c_re - 0.25L) * (c_re - 0.25L) + c_im * c_im;
            if (q * (q + (c_re - 0.25L)) < 0.25L * c_im * c_im) {
                // Point is in main cardioid, definitely in set
                iteration = MAXITERATIONS;
            } else if ((c_re + 1.0L) * (c_re + 1.0L) + c_im * c_im < 0.0625L) {
                // Point is in period-2 bulb, definitely in set
                iteration = MAXITERATIONS;
            } else {
                // Period detection variables
                complex long double z_period = z;
                int period_check = 8;
                int period_iteration = 0;
                
                while (iteration < MAXITERATIONS) {
                    long double z_re = creal(z);
                    long double z_im = cimag(z);
                    long double z_re_sq = z_re * z_re;
                    long double z_im_sq = z_im * z_im;
                    modulus_squared = z_re_sq + z_im_sq;
                    
                    if (modulus_squared > ESCAPE_RADIUS_SQUARED) {
                        break;
                    }
                    
                    // Reuse pre-calculated squares
                    z = (z_re_sq - z_im_sq + creal(c)) + (2.0L * z_re * z_im + cimag(c)) * I;
                    iteration++;
                    
                    // Period detection: check if we've returned to a previous state
                    period_iteration++;
                    if (period_iteration >= period_check) {
                        if (cabsl(z - z_period) < 1e-10L) {
                            // Found a periodic cycle, point is in the set
                            iteration = MAXITERATIONS;
                            break;
                        }
                        z_period = z;
                        period_check *= 2; // Exponential backoff
                        period_iteration = 0;
                    }
                }
            }
            
            struct pixel pxl;

            if (iteration == MAXITERATIONS) {
                // Interior points: black
                pxl.rChannel = 0;
                pxl.gChannel = 0;
                pxl.bChannel = 0;
            } else {
                // Classic Mandelbrot coloring with prominent white boundary
                long double smooth_iteration = iteration + 1.0L - log2l(0.5L * log2l(modulus_squared));
                
                // Scale for color mapping - use smaller divisor for more prominent white band
                long double t = smooth_iteration / 20.0L;
                t = fminl(t, 1.0L);
                
                if (t < 0.15L) {
                    // Very close to boundary - bright white
                    pxl.rChannel = 255;
                    pxl.gChannel = 255;
                    pxl.bChannel = 255;
                } else if (t < 0.3L) {
                    // White to light blue transition
                    long double factor = (t - 0.15L) / 0.15L; // 0 to 1
                    pxl.rChannel = (UInt8)(255.0L - factor * 155.0L); // 255 to 100
                    pxl.gChannel = (UInt8)(255.0L - factor * 155.0L); // 255 to 100
                    pxl.bChannel = 255; // Keep blue at max
                } else if (t < 0.6L) {
                    // Light blue to medium blue
                    long double factor = (t - 0.3L) / 0.3L; // 0 to 1
                    pxl.rChannel = (UInt8)(100.0L - factor * 80.0L);  // 100 to 20
                    pxl.gChannel = (UInt8)(100.0L - factor * 70.0L);  // 100 to 30
                    pxl.bChannel = 255; // Keep blue at max
                } else {
                    // Medium blue to dark blue
                    long double factor = (t - 0.6L) / 0.4L; // 0 to 1
                    pxl.rChannel = (UInt8)(20.0L - factor * 20.0L);   // 20 to 0
                    pxl.gChannel = (UInt8)(30.0L - factor * 30.0L);   // 30 to 0
                    pxl.bChannel = (UInt8)(255.0L - factor * 100.0L); // 255 to 155
                }
            }
            
            pxl.aChannel = 255;
            data[yDataPos * width + xDataPos] = pxl;
        }
    });
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