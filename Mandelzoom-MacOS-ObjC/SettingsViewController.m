#import "SettingsViewController.h"
#import "AppDelegate.h"

@interface SettingsViewController ()

@property (nonatomic, weak) AppDelegate *appDelegate;
@property (nonatomic, strong) NSTextField *saveLocationLabel;
@property (nonatomic, strong) NSSlider *magnificationSlider;
@property (nonatomic, strong) NSTextField *magnificationLabel;
@property (nonatomic, strong) NSButton *showInfoPanelCheckbox;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Settings";
    self.view.frame = NSMakeRect(0, 0, 400, 300);

    self.appDelegate = (AppDelegate *)[NSApp delegate];

    // Save Location Label
    self.saveLocationLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 260, 360, 20)];
    self.saveLocationLabel.editable = NO;
    self.saveLocationLabel.bezeled = NO;
    self.saveLocationLabel.drawsBackground = NO;
    self.saveLocationLabel.stringValue = [NSString stringWithFormat:@"Current Save Location: %@", self.appDelegate.saveLocation];
    [self.view addSubview:self.saveLocationLabel];

    // Choose Save Location Button
    NSButton *chooseLocationButton = [NSButton buttonWithTitle:@"Choose Save Location..." target:self action:@selector(chooseSaveLocation:)];
    chooseLocationButton.frame = NSMakeRect(20, 220, 200, 25);
    [self.view addSubview:chooseLocationButton];

    // Show Current Save Location Button
    NSButton *showLocationButton = [NSButton buttonWithTitle:@"Show Current Save Location" target:self action:@selector(showCurrentSaveLocation:)];
    showLocationButton.frame = NSMakeRect(20, 180, 220, 25);
    [self.view addSubview:showLocationButton];
    
    // Magnification Level Label
    self.magnificationLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 130, 360, 20)];
    self.magnificationLabel.editable = NO;
    self.magnificationLabel.bezeled = NO;
    self.magnificationLabel.drawsBackground = NO;
    self.magnificationLabel.stringValue = [NSString stringWithFormat:@"Magnification Level: %ldx", self.appDelegate.magnificationLevel];
    [self.view addSubview:self.magnificationLabel];

    // Magnification Level Slider
    self.magnificationSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(20, 100, 360, 20)];
    self.magnificationSlider.minValue = 2;
    self.magnificationSlider.maxValue = 100;
    self.magnificationSlider.integerValue = self.appDelegate.magnificationLevel;
    [self.magnificationSlider setTarget:self];
    [self.magnificationSlider setAction:@selector(magnificationSliderChanged:)];
    [self.view addSubview:self.magnificationSlider];
    
    // Show Info Panel Checkbox
    self.showInfoPanelCheckbox = [NSButton checkboxWithTitle:@"Show Info Panel" target:self action:@selector(showInfoPanelCheckboxChanged:)];
    self.showInfoPanelCheckbox.frame = NSMakeRect(20, 50, 150, 25);
    self.showInfoPanelCheckbox.state = self.appDelegate.showInfoPanel ? NSControlStateValueOn : NSControlStateValueOff;
    [self.view addSubview:self.showInfoPanelCheckbox];
}

- (void)magnificationSliderChanged:(NSSlider *)sender {
    self.appDelegate.magnificationLevel = sender.integerValue;
    [self.appDelegate saveMagnificationLevelPreference];
    self.magnificationLabel.stringValue = [NSString stringWithFormat:@"Magnification Level: %ldx", self.appDelegate.magnificationLevel];
}

- (void)showInfoPanelCheckboxChanged:(NSButton *)sender {
    self.appDelegate.showInfoPanel = sender.state == NSControlStateValueOn;
    [self.appDelegate saveShowInfoPanelPreference];
    
    // Notify the MandelView to update its layout
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowInfoPanelSettingChanged" object:nil];
}

- (void)chooseSaveLocation:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
    openPanel.allowsMultipleSelection = NO;
    openPanel.title = @"Choose Save Location";
    openPanel.prompt = @"Choose";
    openPanel.directoryURL = [NSURL fileURLWithPath:self.appDelegate.saveLocation];

    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSURL *selectedURL = openPanel.URLs.firstObject;
            if (selectedURL) {
                self.appDelegate.saveLocation = selectedURL.path;
                [self.appDelegate saveSaveLocationPreference];
                self.saveLocationLabel.stringValue = [NSString stringWithFormat:@"Current Save Location: %@", self.appDelegate.saveLocation];

                // Show confirmation
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"Save Location Updated";
                alert.informativeText = [NSString stringWithFormat:@"Images will now be saved to:\n%@", self.appDelegate.saveLocation];
                [alert runModal];
            }
        }
    }];
}

- (void)showCurrentSaveLocation:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:self.appDelegate.saveLocation]];
}

@end


