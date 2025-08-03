# GEMINI.md

This file provides guidance to Gemini when working with code in this repository.

## Project Overview
This is a macOS application written in Objective-C that generates and displays the Mandelbrot set with interactive zooming capabilities. The application uses complex number mathematics to render the fractal and provides a visual selection interface for zooming into specific regions. It also features GPU acceleration using Metal.

## Build Commands
- **Build and run**: Open `Mandelzoom-MacOS-ObjC.xcodeproj` in Xcode and use Cmd+R to build and run
- **Build only**: Use Xcode's Product → Build (Cmd+B) or `xcodebuild` from command line:
  ```bash
  xcodebuild -project Mandelzoom-MacOS-ObjC.xcodeproj -scheme Mandelzoom-MacOS-ObjC build
  ```
- **Clean build**: Product → Clean Build Folder (Cmd+Shift+K) in Xcode

## Architecture Overview

### Core Components
1.  **MandelRenderer** (`MandelRenderer.h/m`): The mathematical engine that computes Mandelbrot set iterations and generates the fractal image. It can use either a multi-threaded CPU implementation or a Metal-based GPU implementation. It uses `complex long double` for high precision calculations.

2.  **MandelView** (`MandelView.h/m`): A custom `NSView` subclass that manages the display and user interaction. It handles mouse events for zooming and panning, and coordinates with the `MandelRenderer` to update the fractal display.

3.  **SelectionRectangleView** (`SelectionRectangleView.h/m`): An overlay view that draws the selection rectangle during mouse drag operations for zoom selection.

4.  **ViewController** (`ViewController.h/m`): The main view controller that coordinates between the UI elements and the `MandelView`.

5.  **AppDelegate** (`AppDelegate.h/m`): The application delegate, which manages the application lifecycle and the menu bar.

6.  **MandelbrotShader.metal** (`MandelbrotShader.metal`): A Metal shader that contains the GPU implementation of the Mandelbrot set calculation.

### Key Architecture Patterns
- **MVC Pattern**: Standard macOS MVC with `ViewController` managing `MandelView` and coordinating with `MandelRenderer`.
- **Coordinate System Mapping**: A complex mathematical coordinate system is mapped to screen pixel coordinates for rendering and interaction.
- **Multithreaded Rendering**: `MandelRenderer` uses Grand Central Dispatch (GCD) to compute different regions of the fractal simultaneously on the CPU.
- **GPU Acceleration**: `MandelRenderer` can use Metal to perform the Mandelbrot calculations on the GPU for significantly improved performance.
- **Interactive Zooming and Panning**: Mouse events are used to define new complex coordinate bounds for zooming and panning.

### Data Flow
1.  User interacts with `MandelView` (mouse events).
2.  `MandelView` calculates new complex coordinate bounds based on the user interaction.
3.  `MandelRenderer` computes the fractal with the new bounds, using either the CPU or GPU.
4.  The rendered `NSImage` is displayed in the `imageView` within the `MandelView`.
5.  `SelectionRectangleView` provides visual feedback during selection.

## Development Notes
- The project uses complex number mathematics (`#include <complex.h>`) with `long double` precision.
- Rendering performance is optimized through multithreading (GCD) and GPU acceleration (Metal).
- The application maintains initial coordinate bounds for reset functionality.
- All UI interactions are handled through standard Cocoa patterns (IBOutlets, mouse events).
- The Metal shader is written in the Metal Shading Language.

## Target Platform
- macOS 12.2+ (as configured in project settings)
- Uses AppKit/Cocoa and Metal frameworks
- No external dependencies beyond system frameworks