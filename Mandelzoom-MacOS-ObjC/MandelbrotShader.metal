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
inline float mandelbrotIterations(float2 c, uint maxIter, float escapeRadiusSq, thread float& finalModulusSq) {
    // Early bailout: check main cardioid
    float x = c.x;
    float y = c.y;
    float q = (x - 0.25f) * (x - 0.25f) + y * y;
    if (q * (q + (x - 0.25f)) < 0.25f * y * y) {
        finalModulusSq = 0.0f;
        return float(maxIter); // In main cardioid
    }
    
    // Early bailout: check period-2 bulb
    if ((x + 1.0f) * (x + 1.0f) + y * y < 0.0625f) {
        finalModulusSq = 0.0f;
        return float(maxIter); // In period-2 bulb
    }
    
    float2 z = float2(0.0f, 0.0f);
    uint iteration = 0;
    float modulusSq = 0.0f;
    
    // Period detection variables
    float2 z_period = z;
    uint period_check = 8;
    uint period_iteration = 0;
    
    // Main iteration loop with period detection
    for (uint i = 0; i < maxIter; i++) {
        float zx2 = z.x * z.x;
        float zy2 = z.y * z.y;
        modulusSq = zx2 + zy2;
        
        if (modulusSq > escapeRadiusSq) {
            iteration = i;
            break;
        }
        
        z = float2(zx2 - zy2 + c.x, 2.0f * z.x * z.y + c.y);
        
        // Period detection: check if we've returned to a previous state
        period_iteration++;
        if (period_iteration >= period_check) {
            float2 diff = z - z_period;
            if (dot(diff, diff) < 1e-10f) {
                // Found a periodic cycle, point is in the set
                finalModulusSq = 0.0f;
                return float(maxIter);
            }
            z_period = z;
            period_check = min(period_check * 2, 256u); // Exponential backoff with cap
            period_iteration = 0;
        }
    }
    
    finalModulusSq = modulusSq;
    return float(iteration);
}

// Enhanced color calculation with prominent white boundaries
inline uchar4 calculateColor(float iterations, uint maxIterations, float modulusSq) {
    if (iterations >= float(maxIterations)) {
        return uchar4(0, 0, 0, 255); // Black for interior
    }
    
    // Enhanced smooth iteration calculation matching CPU version
    float smoothIteration = iterations + 1.0f - log2(0.5f * log2(modulusSq));
    
    // Use smaller divisor for more prominent white boundaries
    float t = smoothIteration / 12.0f;  // Reduced from 20.0f to 12.0f
    t = min(t, 1.0f);
    
    uchar r, g, b;
    
    if (t < 0.2f) {
        // Extended white boundary region - bright white
        r = g = b = 255;
    } else if (t < 0.35f) {
        // White to light blue transition
        float factor = (t - 0.2f) / 0.15f;
        r = g = uchar(255.0f - factor * 155.0f);
        b = 255;
    } else if (t < 0.65f) {
        // Light blue to medium blue
        float factor = (t - 0.35f) / 0.3f;
        r = uchar(100.0f - factor * 80.0f);
        g = uchar(100.0f - factor * 70.0f);
        b = 255;
    } else {
        // Medium blue to dark blue
        float factor = (t - 0.65f) / 0.35f;
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
    
    // Calculate Mandelbrot iterations with modulus squared
    float modulusSq;
    float iterations = mandelbrotIterations(c, params.maxIterations, params.escapeRadius * params.escapeRadius, modulusSq);
    
    // Calculate color and store result
    uchar4 color = calculateColor(iterations, params.maxIterations, modulusSq);
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
        
        float modulusSq;
        float iterations = mandelbrotIterations(c, params.maxIterations, params.escapeRadius * params.escapeRadius, modulusSq);
        uchar4 color = calculateColor(iterations, params.maxIterations, modulusSq);
        
        output[gid.y * params.width + pixelX].color = color;
    }
}