# GEMINI.md

This file provides guidance to Gemini when working with code in this repository.

## Project Overview
This is a macOS application written in Objective-C that generates and displays the Mandelbrot set with interactive zooming and panning. The application uses complex number mathematics to render the fractal, provides multiple user interaction methods for exploration, and includes a full-featured bookmarking system. It leverages both CPU-based multithreaded rendering and GPU acceleration with Metal for performance.

## Build Commands
- **Build and run**: Open `Mandelzoom-MacOS-ObjC.xcodeproj` in Xcode and use Cmd+R to build and run.
- **Build only**: Use Xcode's Product → Build (Cmd+B) or `xcodebuild` from the command line:
  ```bash
  xcodebuild -project Mandelzoom-MacOS-ObjC.xcodeproj -scheme Mandelzoom-MacOS-ObjC build
  ```
- **Clean build**: Product → Clean Build Folder (Cmd+Shift+K) in Xcode.

## Architecture Overview

### Core Components
1.  **MandelRenderer** (`MandelRenderer.h/m`): The mathematical engine that computes the Mandelbrot set.
    *   Supports both multithreaded CPU rendering (using GCD) and GPU-accelerated rendering (using Metal).
    *   Uses `complex long double` for high-precision CPU calculations.
    *   Features an adaptive iteration count based on the zoom level to balance detail and performance.

2.  **MandelView** (`MandelView.h/m`): A custom `NSView` subclass that manages the display and all user interaction.
    *   Handles mouse events for panning (drag), zooming (click and command-click), and keyboard events (Escape to reset).
    *   Displays the rendered fractal, an overlay info panel, and a render time label.
    *   Manages the `SelectionRectangleView` for visual feedback, although direct selection-box zooming is secondary to other interaction methods.

3.  **ViewController** (`ViewController.h/m`): The main view controller that hosts and manages the `MandelView`.

4.  **AppDelegate** (`AppDelegate.h/m`): The application delegate that manages the app lifecycle, menu bar, settings persistence (`NSUserDefaults`), and coordinates the presentation of various windows (Settings, Bookmarks).

5.  **Bookmark System**:
    *   **BookmarkManager** (`BookmarkManager.h/m`): A singleton that handles all CRUD (Create, Read, Update, Delete) operations for bookmarks, persisting them to a local file.
    *   **MandelbrotBookmark** (`MandelbrotBookmark.h/m`): The data model for a single bookmark, storing coordinates, title, description, and other metadata. Conforms to `NSSecureCoding`.
    *   **AddBookmarkViewController** (`AddBookmarkViewController.h/m`): A dedicated view controller for adding new bookmarks.
    *   **OpenBookmarkViewController** (`OpenBookmarkViewController.h/m`): A view controller for listing, opening, and deleting existing bookmarks.
    *   **ExportBookmarkViewController** (`ExportBookmarkViewController.h/m`): A view controller to select and export bookmarks to a JSON file.

6.  **Settings System**:
    *   **SettingsWindowController** (`SettingsWindowController.h/m`): Manages the window for the settings interface.
    *   **SettingsViewController** (`SettingsViewController.h/m`): Provides UI controls for application settings, including save location, click-zoom magnification level, and visibility of UI overlays.

7.  **MandelbrotShader.metal**: The Metal compute shader that contains the GPU implementation of the Mandelbrot set calculation, including optimizations like early bailout checks.

### Key Architecture Patterns
-   **MVC Pattern**: Standard macOS MVC with `ViewController` managing `MandelView` and `AppDelegate` coordinating different modules.
-   **Singleton**: Used for the `BookmarkManager` to provide a single point of access to bookmark data.
-   **Delegate Pattern**: Used extensively for communication between view controllers (e.g., `AddBookmarkViewControllerDelegate`, `OpenBookmarkViewControllerDelegate`).
-   **NSNotificationCenter**: Used to broadcast settings changes from the `SettingsViewController` to the `MandelView` to update the UI in real-time.
-   **Coordinate System Mapping**: Maps the complex mathematical coordinate system to the screen's pixel coordinates for rendering and interaction.
-   **Hybrid Rendering**: Automatically uses Metal for GPU acceleration if available, with a fallback to a multithreaded CPU implementation.

### Data Flow
1.  **Rendering**: User interacts with `MandelView` (mouse/keyboard) -> `MandelView` calculates new complex coordinate bounds -> `MandelRenderer` is called to compute the fractal with the new bounds (using CPU or GPU) -> The rendered `NSImage` is displayed in the `imageView` within `MandelView`.
2.  **Settings**: User changes a setting in `SettingsViewController` -> The change is saved to `NSUserDefaults` via `AppDelegate` -> A notification is posted via `NSNotificationCenter` -> `MandelView` observes the notification and updates its UI accordingly (e.g., hides/shows info panel).
3.  **Bookmarking**: User initiates a bookmark action from the menu -> `AppDelegate` presents the appropriate view controller (`AddBookmarkViewController`, etc.) -> The view controller interacts with `BookmarkManager` to perform the requested operation (add, load, delete) -> If a bookmark is opened, `MandelView` is updated with the new coordinates and re-renders.

## User Interface & Interaction
-   **Panning**: Drag the mouse to pan the view.
-   **Zooming**:
    -   Single-click to zoom in by a configurable factor.
    -   Command-click to zoom out.
-   **Reset View**: Press the `Escape` key to reset the view to the initial coordinates.
-   **Info Panel**: An overlay displays the current complex coordinate ranges, magnification level, and real-time mouse coordinates.
-   **Render Time**: An overlay shows the time taken for the last render.
-   **Bookmarks**: A full-featured bookmarking system is available in the "Bookmarks" menu to save, view, delete, export, and import favorite locations.
-   **Settings**: A dedicated settings window allows customization of save location, zoom level, and UI overlay visibility.

## Development Notes
-   The project uses `#include <complex.h>` with `long double` precision for CPU calculations to allow for deep zooming.
-   The Metal shader is written in the Metal Shading Language (MSL) and is optimized for performance.
-   All UI is created programmatically; Storyboards are used minimally for the main window setup.
-   The application is sandboxed, with entitlements for file access in the user's Downloads folder and for user-selected files (for bookmark import/export).

## Target Platform
-   macOS 12.2+ (as configured in project settings).
-   Uses AppKit/Cocoa and Metal frameworks.
-   No external dependencies beyond system frameworks.
