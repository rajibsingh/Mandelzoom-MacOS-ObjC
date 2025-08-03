//
//  AppDelegate.m
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/3/21.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "MandelView.h"

@interface AppDelegate ()


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self loadSaveLocationPreference];
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

- (void)setupMenuBar {
    NSMenu *mainMenu = [[NSMenu alloc] init];
    
    // Create Application menu (this is required for macOS)
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] init];
    
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
    
    // Create Settings menu
    NSMenuItem *settingsMenuItem = [[NSMenuItem alloc] init];
    settingsMenuItem.title = @"Settings";
    
    NSMenu *settingsMenu = [[NSMenu alloc] initWithTitle:@"Settings"];
    
    // Add Save Location menu item
    NSMenuItem *saveLocationItem = [[NSMenuItem alloc] initWithTitle:@"Choose Save Location..." 
                                                              action:@selector(chooseSaveLocation:) 
                                                       keyEquivalent:@""];
    saveLocationItem.target = self;
    [settingsMenu addItem:saveLocationItem];
    
    // Add separator
    [settingsMenu addItem:[NSMenuItem separatorItem]];
    
    // Add Show Current Save Location item
    NSMenuItem *showLocationItem = [[NSMenuItem alloc] initWithTitle:@"Show Current Save Location" 
                                                              action:@selector(showCurrentSaveLocation:) 
                                                       keyEquivalent:@""];
    showLocationItem.target = self;
    [settingsMenu addItem:showLocationItem];
    
    [settingsMenuItem setSubmenu:settingsMenu];
    [mainMenu addItem:settingsMenuItem];
    
    [NSApp setMainMenu:mainMenu];
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

- (IBAction)chooseSaveLocation:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.title = @"Choose Save Location";
    openPanel.prompt = @"Choose";
    openPanel.directoryURL = [NSURL fileURLWithPath:self.saveLocation];
    
    [openPanel beginSheetModalForWindow:[NSApp keyWindow] completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL *selectedURL = openPanel.URLs.firstObject;
            if (selectedURL) {
                self.saveLocation = selectedURL.path;
                [self saveSaveLocationPreference];
                
                // Show confirmation
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Save Location Updated";
                alert.informativeText = [NSString stringWithFormat:@"Images will now be saved to:\n%@", self.saveLocation];
                [alert runModal];
            }
        }
    }];
}

- (IBAction)showCurrentSaveLocation:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Current Save Location";
    alert.informativeText = [NSString stringWithFormat:@"Images are currently saved to:\n%@", self.saveLocation];
    alert.alertStyle = NSAlertStyleInformational;
    
    // Add button to show in Finder
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Show in Finder"];
    
    NSInteger response = [alert runModal];
    if (response == NSAlertSecondButtonReturn) {
        // Show in Finder
        [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:self.saveLocation]];
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
