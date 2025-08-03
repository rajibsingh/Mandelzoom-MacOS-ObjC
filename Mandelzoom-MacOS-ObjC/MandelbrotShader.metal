//
//  MandelbrotShader.metal
//  Mandelzoom-MacOS-ObjC
//
//  Metal compute shader for high-performance Mandelbrot rendering on Apple Silicon
//

#include <metal_stdlib>
using namespace metal;

// Structure for passing parameters to the shader
struct MandelbrotParams {
    float2 bottomLeft;
    float2 topRight;
    uint width;
    uint height;
    uint maxIterations;
    float escapeRadius;
};

// Structure for output pixel data (RGBA)
struct PixelData {
    uchar4 color;
};

// Fast Mandelbrot iteration function optimized for GPU
inline uint mandelbrotIterations(float2 c, uint maxIter, float escapeRadiusSq) {
    // Early bailout: check main cardioid
    float x = c.x;
    float y = c.y;
    float q = (x - 0.25f) * (x - 0.25f) + y * y;
    if (q * (q + (x - 0.25f)) < 0.25f * y * y) {
        return maxIter; // In main cardioid
    }
    
    // Early bailout: check period-2 bulb
    if ((x + 1.0f) * (x + 1.0f) + y * y < 0.0625f) {
        return maxIter; // In period-2 bulb
    }
    
    float2 z = float2(0.0f, 0.0f);
    uint iteration = 0;
    
    // Unrolled first few iterations for better performance
    for (uint i = 0; i < maxIter && i < 8; i++) {
        float zx2 = z.x * z.x;
        float zy2 = z.y * z.y;
        float modulusSq = zx2 + zy2;
        
        if (modulusSq > escapeRadiusSq) {
            return i;
        }
        
        z = float2(zx2 - zy2 + c.x, 2.0f * z.x * z.y + c.y);
        iteration = i + 1;
    }
    
    // Continue with regular loop if needed
    for (uint i = 8; i < maxIter; i++) {
        float zx2 = z.x * z.x;
        float zy2 = z.y * z.y;
        float modulusSq = zx2 + zy2;
        
        if (modulusSq > escapeRadiusSq) {
            return i;
        }
        
        z = float2(zx2 - zy2 + c.x, 2.0f * z.x * z.y + c.y);
    }
    
    return maxIter;
}

// Optimized color calculation with smooth gradients
inline uchar4 calculateColor(uint iterations, uint maxIterations, float smoothValue) {
    if (iterations == maxIterations) {
        return uchar4(0, 0, 0, 255); // Black for interior
    }
    
    // Smooth iteration value for anti-aliasing
    float t = (float(iterations) + smoothValue) / 20.0f;
    t = min(t, 1.0f);
    
    uchar r, g, b;
    
    if (t < 0.15f) {
        // Very close to boundary - bright white
        r = g = b = 255;
    } else if (t < 0.3f) {
        // White to light blue transition
        float factor = (t - 0.15f) / 0.15f;
        r = g = uchar(255.0f - factor * 155.0f);
        b = 255;
    } else if (t < 0.6f) {
        // Light blue to medium blue
        float factor = (t - 0.3f) / 0.3f;
        r = uchar(100.0f - factor * 80.0f);
        g = uchar(100.0f - factor * 70.0f);
        b = 255;
    } else {
        // Medium blue to dark blue
        float factor = (t - 0.6f) / 0.4f;
        r = uchar(20.0f - factor * 20.0f);
        g = uchar(30.0f - factor * 30.0f);
        b = uchar(255.0f - factor * 100.0f);
    }
    
    return uchar4(r, g, b, 255);
}

// Main compute kernel - each thread calculates one pixel
kernel void mandelbrotKernel(device PixelData* output [[buffer(0)]],
                            constant MandelbrotParams& params [[buffer(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    
    // Check bounds
    if (gid.x >= params.width || gid.y >= params.height) {
        return;
    }
    
    // Calculate complex coordinate for this pixel
    float2 range = params.topRight - params.bottomLeft;
    float2 c = params.bottomLeft + float2(
        (float(gid.x) / float(params.width)) * range.x,
        (float(params.height - gid.y - 1) / float(params.height)) * range.y
    );
    
    // Calculate Mandelbrot iterations
    uint iterations = mandelbrotIterations(c, params.maxIterations, params.escapeRadius * params.escapeRadius);
    
    // Calculate smooth value for anti-aliasing (simplified for GPU)
    float smoothValue = 0.0f;
    if (iterations < params.maxIterations) {
        // Quick approximation for smoothing
        smoothValue = 1.0f - log2(log2(4.0f));
    }
    
    // Calculate color and store result
    uchar4 color = calculateColor(iterations, params.maxIterations, smoothValue);
    output[gid.y * params.width + gid.x].color = color;
}

// Tile-based kernel for better cache performance on large images
kernel void mandelbrotTiledKernel(device PixelData* output [[buffer(0)]],
                                 constant MandelbrotParams& params [[buffer(1)]],
                                 uint2 gid [[thread_position_in_grid]],
                                 uint2 threadgroup_size [[threads_per_threadgroup]]) {
    
    // Process multiple pixels per thread for better memory coalescing
    const uint pixelsPerThread = 4;
    uint startX = gid.x * pixelsPerThread;
    
    if (startX >= params.width || gid.y >= params.height) {
        return;
    }
    
    float2 range = params.topRight - params.bottomLeft;
    float stepX = range.x / float(params.width);
    
    for (uint i = 0; i < pixelsPerThread && (startX + i) < params.width; i++) {
        uint pixelX = startX + i;
        
        float2 c = params.bottomLeft + float2(
            (float(pixelX) / float(params.width)) * range.x,
            (float(params.height - gid.y - 1) / float(params.height)) * range.y
        );
        
        uint iterations = mandelbrotIterations(c, params.maxIterations, params.escapeRadius * params.escapeRadius);
        uchar4 color = calculateColor(iterations, params.maxIterations, 0.0f);
        
        output[gid.y * params.width + pixelX].color = color;
    }
}