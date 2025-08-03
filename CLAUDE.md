# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a macOS application written in Objective-C that generates and displays the Mandelbrot set with interactive zooming capabilities. The application uses complex number mathematics to render the fractal and provides a visual selection interface for zooming into specific regions. It features both CPU-based multithreaded rendering and GPU acceleration using Metal compute shaders for optimal performance on Apple Silicon.

## Build Commands
- **Build and run**: Open `Mandelzoom-MacOS-ObjC.xcodeproj` in Xcode and use Cmd+R to build and run
- **Build only**: Use Xcode's Product → Build (Cmd+B) or `xcodebuild` from command line:
  ```bash
  xcodebuild -project Mandelzoom-MacOS-ObjC.xcodeproj -scheme Mandelzoom-MacOS-ObjC build
  ```
- **Clean build**: Product → Clean Build Folder (Cmd+Shift+K) in Xcode

## Architecture Overview

### Core Components
1. **MandelRenderer** (`MandelRenderer.h/m`): The mathematical engine that computes Mandelbrot set iterations and generates the fractal image. Features:
   - Complex long double precision for CPU calculations
   - Metal GPU acceleration with automatic fallback to CPU
   - Multithreaded CPU rendering using GCD
   - Optimized color gradient calculations

2. **MandelView** (`MandelView.h/m`): Custom NSView subclass that manages display and user interaction. Features:
   - Mouse selection for zoom rectangles (Option+drag)
   - Panning support (drag without modifier keys)
   - Single-click zoom in and Command+click zoom out
   - Real-time mouse coordinate display
   - Info panel with zoom level and coordinate ranges
   - Render time display overlay
   - Escape key to reset to original view

3. **Bookmark System**: Complete bookmark management for saving and restoring Mandelbrot views:
   - **MandelbrotBookmark** (`MandelbrotBookmark.h/m`): Data model representing saved views with coordinates, metadata, and computed properties
   - **BookmarkManager** (`BookmarkManager.h/m`): Singleton manager for bookmark persistence and retrieval with NSUserDefaults storage
   - **AddBookmarkViewController** (`AddBookmarkViewController.h/m`): Dialog for creating new bookmarks with title, description, and coordinate display
   - **OpenBookmarkViewController** (`OpenBookmarkViewController.h/m`): Table view interface for browsing, selecting, and deleting saved bookmarks
   - **ExportBookmarkViewController** (`ExportBookmarkViewController.h/m`): Interface for selecting and exporting bookmarks to file

4. **ViewController** (`ViewController.h/m`): Main view controller that coordinates between the UI elements and the Mandelbrot view.

5. **AppDelegate** (`AppDelegate.h/m`): Application delegate that manages:
   - Settings persistence using NSUserDefaults
   - Menu bar setup with Settings and Bookmarks submenus
   - Save image functionality
   - Bookmark menu actions and dialogs
   - Application-wide preferences (magnification level, info panel visibility, render time display)

6. **Settings System**:
   - **SettingsWindowController** (`SettingsWindowController.h/m`): Window controller for the settings interface
   - **SettingsViewController** (`SettingsViewController.h/m`): View controller with settings controls including:
     - Save location selection
     - Magnification level slider (2x-100x)
     - Info panel visibility checkbox
     - Render time display checkbox

7. **MandelbrotShader.metal**: Metal compute shader optimized for GPU rendering on Apple Silicon with:
   - Early bailout optimizations for main cardioid and period-2 bulb
   - Unrolled iteration loops for performance
   - Smooth color gradients with anti-aliasing
   - Tiled kernel variant for better memory performance

### Key Architecture Patterns
- **MVC Pattern**: Standard macOS MVC with ViewController managing MandelView and coordinating with MandelRenderer
- **Coordinate System Mapping**: Complex mathematical coordinate system mapped to screen pixel coordinates for rendering and interaction
- **Hybrid Rendering**: Automatic selection between Metal GPU acceleration and multithreaded CPU fallback
- **Settings Architecture**: Centralized settings in AppDelegate with NSUserDefaults persistence and NSNotificationCenter for real-time updates
- **Bookmark System**: Singleton BookmarkManager with delegate pattern for UI controllers and NSCoding for persistence
- **Interactive Zooming**: Multiple zoom modes (selection rectangle, click zoom, pan) with mathematical precision

### Data Flow
1. User interacts with MandelView (mouse events, keyboard shortcuts) or bookmark system
2. MandelView calculates new complex coordinate bounds based on interaction type or loaded bookmark
3. MandelRenderer automatically selects optimal rendering path (GPU vs CPU)
4. For GPU: Metal compute shader processes pixels in parallel on Apple Silicon
5. For CPU: GCD-based multithreaded rendering with optimized algorithms
6. Rendered NSImage is displayed in the imageView with overlay information
7. Settings and bookmark changes propagate via NSNotificationCenter and delegate patterns to update UI elements
8. BookmarkManager handles persistence of saved views to NSUserDefaults with automatic serialization

## User Interface Features
- **Interactive Navigation**: 
  - Option+drag: Selection rectangle zoom
  - Drag: Pan the view
  - Click: 2x zoom in at point
  - Command+click: 2x zoom out at point
  - Escape: Reset to original full view
- **Bookmark Management**:
  - **Add Bookmark**: Save current view coordinates with custom title and description
  - **Open Bookmarks**: Browse saved bookmarks in a table view with details and deletion options
  - **Export Bookmarks**: Select and export bookmarks to JSON file for sharing or backup
  - **Menu Integration**: Bookmark actions accessible via dedicated Bookmarks menu
- **Info Panel**: Displays current X/Y ranges, magnification level, and real-time mouse coordinates
- **Render Time Display**: Shows rendering performance in lower-right corner
- **Settings Window**: Accessible via app menu with persistent preferences
- **Image Export**: Save current view as PNG with timestamp

## Development Notes
- The project uses complex number mathematics (`#include <complex.h>`) with long double precision for CPU calculations
- Metal shaders use `float2` for GPU calculations with automatic precision management
- Rendering performance is optimized through Metal GPU acceleration and GCD multithreading
- The application maintains initial coordinate bounds for reset functionality
- All UI interactions are handled through standard Cocoa patterns (IBOutlets, mouse events, notifications)
- Settings persistence uses NSUserDefaults with immediate synchronization
- The current branch is `bookmarks` with recent bookmark management system implementation

## Performance Optimizations
- **Metal GPU Acceleration**: Compute shaders leverage Apple Silicon for parallel pixel computation
- **CPU Multithreading**: GCD-based parallel processing when GPU unavailable
- **Early Bailout**: Mathematical optimizations skip unnecessary iterations
- **Memory Management**: Efficient pixel buffer handling and reuse
- **Dynamic Resolution**: Resolution adapts to view size for optimal performance/quality balance

## Target Platform
- macOS 12.2+ (as configured in project settings)
- Uses AppKit/Cocoa and Metal frameworks
- Optimized for Apple Silicon with fallback support for Intel Macs
- No external dependencies beyond system frameworks