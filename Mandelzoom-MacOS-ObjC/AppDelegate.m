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

@interface AppDelegate ()

@property (nonatomic, strong) SettingsWindowController *settingsWindowController;

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


@end
