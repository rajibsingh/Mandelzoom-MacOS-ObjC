//
//  AppDelegate.m
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/3/21.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "MandelView.h"
#import "SettingsWindowController.h"
#import "BookmarkManager.h"
#import "MandelbrotBookmark.h"

@interface AppDelegate ()

@property (nonatomic, strong) SettingsWindowController *settingsWindowController;
@property (nonatomic, strong) NSWindowController *addBookmarkWindowController;
@property (nonatomic, strong) NSWindowController *openBookmarkWindowController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self loadSaveLocationPreference];
    [self loadMagnificationLevelPreference];
    [self loadShowInfoPanelPreference];
    [self loadShowRenderTimePreference];
    [self setupMenuBar];
}

- (void)loadSaveLocationPreference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedLocation = [defaults stringForKey:@"SaveLocation"];
    
    if (savedLocation && [[NSFileManager defaultManager] fileExistsAtPath:savedLocation]) {
        self.saveLocation = savedLocation;
    } else {
        // Default to Downloads directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
        self.saveLocation = [paths firstObject];
    }
}

- (void)saveSaveLocationPreference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.saveLocation forKey:@"SaveLocation"];
    [defaults synchronize];
}

- (void)loadMagnificationLevelPreference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger savedLevel = [defaults integerForKey:@"MagnificationLevel"];
    if (savedLevel >= 2 && savedLevel <= 100) {
        self.magnificationLevel = savedLevel;
    } else {
        self.magnificationLevel = 2; // Default value
    }
}

- (void)saveMagnificationLevelPreference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.magnificationLevel forKey:@"MagnificationLevel"];
    [defaults synchronize];
}

- (void)loadShowInfoPanelPreference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"ShowInfoPanel"]) {
        self.showInfoPanel = [defaults boolForKey:@"ShowInfoPanel"];
    } else {
        self.showInfoPanel = YES; // Default to showing the panel
    }
}

- (void)saveShowInfoPanelPreference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.showInfoPanel forKey:@"ShowInfoPanel"];
    [defaults synchronize];
}

- (void)loadShowRenderTimePreference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"ShowRenderTime"]) {
        self.showRenderTime = [defaults boolForKey:@"ShowRenderTime"];
    } else {
        self.showRenderTime = YES; // Default to showing the render time
    }
}

- (void)saveShowRenderTimePreference {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:self.showRenderTime forKey:@"ShowRenderTime"];
    [defaults synchronize];
}

- (void)setupMenuBar {
    NSMenu *mainMenu = [[NSMenu alloc] init];
    
    // Create Application menu (this is required for macOS)
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] init];
    
    // Add Settings menu item
    NSMenuItem *settingsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Settings..." action:@selector(showSettings:) keyEquivalent:@","];
    settingsMenuItem.target = self;
    [appMenu addItem:settingsMenuItem];
    
    // Add separator
    [appMenu addItem:[NSMenuItem separatorItem]];
    
    // Add Quit menu item to app menu
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit Mandelzoom-MacOS-ObjC"
                                                          action:@selector(terminate:)
                                                   keyEquivalent:@"q"];
    quitMenuItem.target = NSApp;
    [appMenu addItem:quitMenuItem];
    
    [appMenuItem setSubmenu:appMenu];
    [mainMenu addItem:appMenuItem];
    
    // Create File menu
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] init];
    fileMenuItem.title = @"File";
    
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    
    // Add Save Image menu item
    NSMenuItem *saveImageItem = [[NSMenuItem alloc] initWithTitle:@"Save Image..." 
                                                           action:@selector(saveImage:) 
                                                    keyEquivalent:@"s"];
    saveImageItem.target = self;
    [fileMenu addItem:saveImageItem];
    
    [fileMenuItem setSubmenu:fileMenu];
    [mainMenu addItem:fileMenuItem];
    
    // Create Bookmarks menu
    NSMenuItem *bookmarksMenuItem = [[NSMenuItem alloc] init];
    bookmarksMenuItem.title = @"Bookmarks";
    
    NSMenu *bookmarksMenu = [[NSMenu alloc] initWithTitle:@"Bookmarks"];
    
    // Add Bookmark menu item
    NSMenuItem *addBookmarkItem = [[NSMenuItem alloc] initWithTitle:@"Add Bookmark..." 
                                                             action:@selector(addBookmark:) 
                                                      keyEquivalent:@"b"];
    addBookmarkItem.target = self;
    [bookmarksMenu addItem:addBookmarkItem];
    
    // Open Bookmark menu item
    NSMenuItem *openBookmarkItem = [[NSMenuItem alloc] initWithTitle:@"Open Bookmark..." 
                                                              action:@selector(openBookmark:) 
                                                       keyEquivalent:@"o"];
    openBookmarkItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    openBookmarkItem.target = self;
    [bookmarksMenu addItem:openBookmarkItem];
    
    [bookmarksMenuItem setSubmenu:bookmarksMenu];
    [mainMenu addItem:bookmarksMenuItem];
    
    [NSApp setMainMenu:mainMenu];
}

- (IBAction)showSettings:(id)sender {
    if (!self.settingsWindowController) {
        self.settingsWindowController = [[SettingsWindowController alloc] init];
    }
    [self.settingsWindowController.window makeKeyAndOrderFront:sender];
}

- (IBAction)saveImage:(id)sender {
    // Get the current window and find the MandelView
    NSWindow *keyWindow = [NSApp keyWindow];
    if (!keyWindow) return;
    
    ViewController *viewController = (ViewController *)keyWindow.contentViewController;
    if (!viewController || ![viewController isKindOfClass:[ViewController class]]) return;
    
    MandelView *mandelView = viewController.mandelView;
    if (!mandelView) return;
    
    [self saveImageFromMandelView:mandelView];
}

- (void)saveImageFromMandelView:(MandelView *)mandelView {
    if (!mandelView.imageView.image) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"No Image to Save";
        alert.informativeText = @"Please wait for the Mandelbrot image to finish rendering.";
        [alert runModal];
        return;
    }
    
    // Use configured save location
    NSString *saveDirectory = self.saveLocation;
    
    // Create filename with timestamp
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd_HH-mm-ss";
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    NSString *filename = [NSString stringWithFormat:@"Mandelbrot_%@.png", timestamp];
    NSString *filePath = [saveDirectory stringByAppendingPathComponent:filename];
    
    // Convert NSImage to PNG data
    NSImage *image = mandelView.imageView.image;
    CGImageRef cgImage = [image CGImageForProposedRect:NULL context:NULL hints:NULL];
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    NSData *pngData = [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    
    // Save to file
    BOOL success = [pngData writeToFile:filePath atomically:YES];
    
    // Show result to user
    NSAlert *alert = [[NSAlert alloc] init];
    if (success) {
        alert.messageText = @"Image Saved Successfully";
        alert.informativeText = [NSString stringWithFormat:@"Saved as: %@", filename];
    } else {
        alert.messageText = @"Failed to Save Image";
        alert.informativeText = @"There was an error saving the image to the Downloads folder.";
    }
    [alert runModal];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - Bookmark Actions

- (IBAction)addBookmark:(id)sender {
    // Get the current window and find the MandelView
    NSWindow *keyWindow = [NSApp keyWindow];
    if (!keyWindow) return;
    
    ViewController *viewController = (ViewController *)keyWindow.contentViewController;
    if (!viewController || ![viewController isKindOfClass:[ViewController class]]) return;
    
    MandelView *mandelView = viewController.mandelView;
    if (!mandelView) return;
    
    // Get current coordinates from the MandelView's renderer
    MandelRenderer *renderer = [mandelView valueForKey:@"renderer"];
    if (!renderer) return;
    
    complex long double bottomLeft = renderer.bottomLeft;
    complex long double topRight = renderer.topRight;
    
    // Create and show the Add Bookmark window
    AddBookmarkViewController *addBookmarkVC = [[AddBookmarkViewController alloc] init];
    addBookmarkVC.delegate = self;
    addBookmarkVC.xMin = creall(bottomLeft);
    addBookmarkVC.xMax = creall(topRight);
    addBookmarkVC.yMin = cimagl(bottomLeft);
    addBookmarkVC.yMax = cimagl(topRight);
    
    NSWindow *window = [[NSWindow alloc] initWithContentRect:addBookmarkVC.view.frame
                                                   styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"Add Bookmark";
    window.contentViewController = addBookmarkVC;
    [window center];
    
    self.addBookmarkWindowController = [[NSWindowController alloc] initWithWindow:window];
    [self.addBookmarkWindowController.window makeKeyAndOrderFront:self];
}

- (IBAction)openBookmark:(id)sender {
    OpenBookmarkViewController *openBookmarkVC = [[OpenBookmarkViewController alloc] init];
    openBookmarkVC.delegate = self;
    
    NSWindow *window = [[NSWindow alloc] initWithContentRect:openBookmarkVC.view.frame
                                                   styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"Open Bookmark";
    window.contentViewController = openBookmarkVC;
    [window center];
    
    self.openBookmarkWindowController = [[NSWindowController alloc] initWithWindow:window];
    [self.openBookmarkWindowController.window makeKeyAndOrderFront:self];
}

#pragma mark - AddBookmarkViewControllerDelegate

- (void)addBookmarkViewController:(AddBookmarkViewController *)controller didAddBookmark:(MandelbrotBookmark *)bookmark {
    [[BookmarkManager sharedManager] addBookmark:bookmark];
    [self.addBookmarkWindowController.window close];
    self.addBookmarkWindowController = nil;
    
    // Show auto-dismissing success message
    [self showAutoHidingBookmarkConfirmation:bookmark.title];
}

- (void)addBookmarkViewControllerDidCancel:(AddBookmarkViewController *)controller {
    [self.addBookmarkWindowController.window close];
    self.addBookmarkWindowController = nil;
}

- (void)showAutoHidingBookmarkConfirmation:(NSString *)bookmarkTitle {
    // Create a simple window to show the confirmation
    NSWindow *confirmationWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 120)
                                                                styleMask:NSWindowStyleMaskBorderless
                                                                  backing:NSBackingStoreBuffered
                                                                    defer:NO];
    
    confirmationWindow.backgroundColor = [NSColor colorWithWhite:0.0 alpha:0.8];
    confirmationWindow.level = NSFloatingWindowLevel;
    confirmationWindow.hasShadow = YES;
    
    // Create content view
    NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 120)];
    confirmationWindow.contentView = contentView;
    
    // Add title label
    NSTextField *titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 70, 360, 24)];
    titleLabel.stringValue = @"Bookmark Added";
    titleLabel.font = [NSFont systemFontOfSize:18 weight:NSFontWeightSemibold];
    titleLabel.textColor = [NSColor whiteColor];
    titleLabel.backgroundColor = [NSColor clearColor];
    titleLabel.editable = NO;
    titleLabel.bezeled = NO;
    titleLabel.alignment = NSTextAlignmentCenter;
    [contentView addSubview:titleLabel];
    
    // Add message label
    NSTextField *messageLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 30, 360, 40)];
    messageLabel.stringValue = [NSString stringWithFormat:@"Bookmark \"%@\" has been saved successfully.", bookmarkTitle];
    messageLabel.font = [NSFont systemFontOfSize:14];
    messageLabel.textColor = [NSColor whiteColor];
    messageLabel.backgroundColor = [NSColor clearColor];
    messageLabel.editable = NO;
    messageLabel.bezeled = NO;
    messageLabel.alignment = NSTextAlignmentCenter;
    messageLabel.maximumNumberOfLines = 2;
    messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [contentView addSubview:messageLabel];
    
    // Center the window on screen
    NSRect screenFrame = [NSScreen mainScreen].frame;
    NSRect windowFrame = confirmationWindow.frame;
    windowFrame.origin.x = (screenFrame.size.width - windowFrame.size.width) / 2;
    windowFrame.origin.y = (screenFrame.size.height - windowFrame.size.height) / 2 + 100; // Slightly above center
    [confirmationWindow setFrame:windowFrame display:YES];
    
    // Show the window
    [confirmationWindow makeKeyAndOrderFront:nil];
    
    // Auto-hide after 2 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [confirmationWindow orderOut:nil];
    });
}

#pragma mark - OpenBookmarkViewControllerDelegate

- (void)openBookmarkViewController:(OpenBookmarkViewController *)controller didOpenBookmark:(MandelbrotBookmark *)bookmark {
    [self.openBookmarkWindowController.window close];
    self.openBookmarkWindowController = nil;
    
    // Navigate to the bookmark coordinates
    [self navigateToBookmark:bookmark];
}

- (void)openBookmarkViewControllerDidCancel:(OpenBookmarkViewController *)controller {
    [self.openBookmarkWindowController.window close];
    self.openBookmarkWindowController = nil;
}

- (void)navigateToBookmark:(MandelbrotBookmark *)bookmark {
    // Get the current window and find the MandelView
    NSWindow *keyWindow = [NSApp keyWindow];
    if (!keyWindow) return;
    
    ViewController *viewController = (ViewController *)keyWindow.contentViewController;
    if (!viewController || ![viewController isKindOfClass:[ViewController class]]) return;
    
    MandelView *mandelView = viewController.mandelView;
    if (!mandelView) return;
    
    // Get the renderer and set new coordinates
    MandelRenderer *renderer = [mandelView valueForKey:@"renderer"];
    if (!renderer) return;
    
    // Set the new coordinates
    complex long double newBottomLeft = bookmark.xMin + bookmark.yMin * I;
    complex long double newTopRight = bookmark.xMax + bookmark.yMax * I;
    
    renderer.bottomLeft = newBottomLeft;
    renderer.topRight = newTopRight;
    
    // Trigger a re-render
    [mandelView setImage];
    
    NSLog(@"Navigated to bookmark: %@", bookmark.title);
}

@end
