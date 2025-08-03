#import "SettingsWindowController.h"
#import "SettingsViewController.h"

@interface SettingsWindowController ()

@end

@implementation SettingsWindowController

- (instancetype)init {
    self = [super initWithWindow:nil];
    if (self) {
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 400, 200) styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
        [window center];
        window.title = @"Settings";
        self.window = window;
        self.contentViewController = [[SettingsViewController alloc] init];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

@end
