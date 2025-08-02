# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a macOS application written in Objective-C that generates and displays the Mandelbrot set with interactive zooming capabilities. The application uses complex number mathematics to render the fractal and provides a visual selection interface for zooming into specific regions.

## Build Commands
- **Build and run**: Open `Mandelzoom-MacOS-ObjC.xcodeproj` in Xcode and use Cmd+R to build and run
- **Build only**: Use Xcode's Product → Build (Cmd+B) or `xcodebuild` from command line:
  ```bash
  xcodebuild -project Mandelzoom-MacOS-ObjC.xcodeproj -scheme Mandelzoom-MacOS-ObjC build
  ```
- **Clean build**: Product → Clean Build Folder (Cmd+Shift+K) in Xcode

## Architecture Overview

### Core Components
1. **MandelRenderer** (`MandelRenderer.h/m`): The mathematical engine that computes Mandelbrot set iterations and generates the fractal image. Uses complex long double precision for calculations and implements multithreaded rendering for performance.

2. **MandelView** (`MandelView.h/m`): Custom NSView subclass that manages the display and user interaction. Handles mouse events for selection rectangle drawing and coordinates zoom operations with the renderer.

3. **SelectionRectangleView** (`SelectionRectangleView.h/m`): Overlay view that draws the selection rectangle during mouse drag operations for zoom selection.

4. **ViewController** (`ViewController.h/m`): Main view controller that coordinates between the UI elements and the Mandelbrot view.

### Key Architecture Patterns
- **MVC Pattern**: Standard macOS MVC with ViewController managing MandelView and coordinating with MandelRenderer
- **Coordinate System Mapping**: Complex mathematical coordinate system mapped to screen pixel coordinates for rendering and interaction
- **Multithreaded Rendering**: MandelRenderer uses multiple threads to compute different regions of the fractal simultaneously
- **Interactive Zooming**: Mouse selection rectangles are converted to new complex coordinate bounds for zooming

### Data Flow
1. User interacts with MandelView (mouse events)
2. MandelView calculates new complex coordinate bounds
3. MandelRenderer computes fractal with new bounds using multithreading
4. Rendered NSImage is displayed in the imageView
5. SelectionRectangleView provides visual feedback during selection

## Development Notes
- The project uses complex number mathematics (`#include <complex.h>`) with long double precision
- Rendering performance is optimized through multithreading and efficient HSB to RGB color conversion
- The application maintains initial coordinate bounds for reset functionality
- All UI interactions are handled through standard Cocoa patterns (IBOutlets, mouse events)
- The current branch `ai-experimentation` contains recent multithreading improvements

## Target Platform
- macOS 12.2+ (as configured in project settings)
- Uses AppKit/Cocoa frameworks
- No external dependencies beyond system frameworks