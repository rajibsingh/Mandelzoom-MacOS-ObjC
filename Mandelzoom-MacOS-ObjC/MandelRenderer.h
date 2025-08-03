//
//  MandelRenderer.h
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/4/21.
//

#ifndef MandelRenderer_h
#define MandelRenderer_h

#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#include <complex.h>

@interface MandelRenderer : NSObject
@property (nonatomic, assign) complex long double bottomLeft;
@property (nonatomic, assign) complex long double topRight;

// Metal GPU acceleration properties
@property (nonatomic, strong) id<MTLDevice> metalDevice;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLComputePipelineState> computePipeline;
@property (nonatomic, assign) BOOL useGPUAcceleration;

-(NSImage*) render;
-(NSImage*) renderWithWidth:(int)width height:(int)height;
-(NSImage*) renderWithWidth:(int)width height:(int)height renderTime:(double*)renderTime;
@end

#endif /* MandelRenderer_h */
