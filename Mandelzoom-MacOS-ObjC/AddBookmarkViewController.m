//
//  AddBookmarkViewController.m
//  Mandelzoom-MacOS-ObjC
//

#import "AddBookmarkViewController.h"
#import "BookmarkManager.h"

@implementation AddBookmarkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self updateCoordinateInfo];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    // Set up tab navigation after the window is fully loaded
    [self setupTabNavigation];
    // Set initial focus
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view.window makeFirstResponder:self.titleTextField];
    });
}

- (void)setupUI {
    self.view.frame = NSMakeRect(0, 0, 520, 380);
    
    // Title label
    NSTextField *titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 330, 100, 20)];
    titleLabel.editable = NO;
    titleLabel.bezeled = NO;
    titleLabel.drawsBackground = NO;
    titleLabel.stringValue = @"Title:";
    titleLabel.font = [NSFont systemFontOfSize:13];
    [self.view addSubview:titleLabel];
    
    // Title text field
    self.titleTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 330, 370, 22)];
    self.titleTextField.placeholderString = @"Enter bookmark title";
    [self.view addSubview:self.titleTextField];
    
    // Description label
    NSTextField *descriptionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 270, 100, 20)];
    descriptionLabel.editable = NO;
    descriptionLabel.bezeled = NO;
    descriptionLabel.drawsBackground = NO;
    descriptionLabel.stringValue = @"Description:";
    descriptionLabel.font = [NSFont systemFontOfSize:13];
    [self.view addSubview:descriptionLabel];
    
    // Description text field (multi-line)
    self.descriptionTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 190, 370, 80)];
    self.descriptionTextField.placeholderString = @"Enter description (optional)";
    self.descriptionTextField.font = [NSFont systemFontOfSize:13];
    self.descriptionTextField.editable = YES;
    self.descriptionTextField.selectable = YES;
    self.descriptionTextField.bezeled = YES;
    self.descriptionTextField.bezelStyle = NSTextFieldSquareBezel;
    self.descriptionTextField.focusRingType = NSFocusRingTypeDefault;
    
    // Enable multi-line text
    NSTextFieldCell *cell = (NSTextFieldCell *)self.descriptionTextField.cell;
    cell.wraps = YES;
    cell.scrollable = NO;
    
    [self.view addSubview:self.descriptionTextField];
    
    // Coordinates label
    NSTextField *coordsLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 150, 100, 20)];
    coordsLabel.editable = NO;
    coordsLabel.bezeled = NO;
    coordsLabel.drawsBackground = NO;
    coordsLabel.stringValue = @"Coordinates:";
    coordsLabel.font = [NSFont systemFontOfSize:13];
    [self.view addSubview:coordsLabel];
    
    self.coordinatesLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 150, 370, 20)];
    self.coordinatesLabel.editable = NO;
    self.coordinatesLabel.bezeled = NO;
    self.coordinatesLabel.drawsBackground = NO;
    self.coordinatesLabel.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular];
    [self.view addSubview:self.coordinatesLabel];
    
    // Magnification label
    NSTextField *magLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 120, 100, 20)];
    magLabel.editable = NO;
    magLabel.bezeled = NO;
    magLabel.drawsBackground = NO;
    magLabel.stringValue = @"Magnification:";
    magLabel.font = [NSFont systemFontOfSize:13];
    [self.view addSubview:magLabel];
    
    self.magnificationLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(130, 120, 370, 20)];
    self.magnificationLabel.editable = NO;
    self.magnificationLabel.bezeled = NO;
    self.magnificationLabel.drawsBackground = NO;
    self.magnificationLabel.font = [NSFont systemFontOfSize:13];
    [self.view addSubview:self.magnificationLabel];
    
    // Buttons
    self.cancelButton = [NSButton buttonWithTitle:@"Cancel" target:self action:@selector(cancel:)];
    self.cancelButton.frame = NSMakeRect(300, 30, 80, 32);
    [self.view addSubview:self.cancelButton];
    
    self.addButton = [NSButton buttonWithTitle:@"Add Bookmark" target:self action:@selector(addBookmark:)];
    self.addButton.frame = NSMakeRect(390, 30, 120, 32);
    self.addButton.keyEquivalent = @"\r"; // Enter key
    [self.view addSubview:self.addButton];
    
    // Initial setup will be completed in viewDidAppear
}

- (void)setupTabNavigation {
    // Set up the tab navigation chain
    self.titleTextField.nextKeyView = self.descriptionTextField;
    self.descriptionTextField.nextKeyView = self.addButton;
    self.addButton.nextKeyView = self.cancelButton;
    self.cancelButton.nextKeyView = self.titleTextField;
    
    // Set the window's initial first responder
    self.view.window.initialFirstResponder = self.titleTextField;
}

- (void)updateCoordinateInfo {
    // Update coordinates display
    self.coordinatesLabel.stringValue = [NSString stringWithFormat:@"X: %.6f to %.6f, Y: %.6f to %.6f", 
                                        self.xMin, self.xMax, self.yMin, self.yMax];
    
    // Calculate and display magnification
    double width = self.xMax - self.xMin;
    double initialWidth = 3.5; // Full Mandelbrot view width
    double magnification = initialWidth / width;
    
    if (magnification >= 1000000) {
        self.magnificationLabel.stringValue = [NSString stringWithFormat:@"%.2fM×", magnification / 1000000.0];
    } else if (magnification >= 1000) {
        self.magnificationLabel.stringValue = [NSString stringWithFormat:@"%.2fK×", magnification / 1000.0];
    } else {
        self.magnificationLabel.stringValue = [NSString stringWithFormat:@"%.2f×", magnification];
    }
}

- (IBAction)addBookmark:(id)sender {
    NSString *title = [self.titleTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *description = [self.descriptionTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Debug logging
    NSLog(@"Add Bookmark - Title: '%@', Description: '%@'", title, description);
    
    if (title.length == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Title Required";
        alert.informativeText = @"Please enter a title for the bookmark.";
        alert.alertStyle = NSAlertStyleWarning;
        [alert runModal];
        [self.view.window makeFirstResponder:self.titleTextField];
        return;
    }
    
    MandelbrotBookmark *bookmark = [[MandelbrotBookmark alloc] initWithTitle:title
                                                                 description:description
                                                                        xMin:self.xMin
                                                                        xMax:self.xMax
                                                                        yMin:self.yMin
                                                                        yMax:self.yMax];
    
    if ([self.delegate respondsToSelector:@selector(addBookmarkViewController:didAddBookmark:)]) {
        [self.delegate addBookmarkViewController:self didAddBookmark:bookmark];
    }
}

- (IBAction)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(addBookmarkViewControllerDidCancel:)]) {
        [self.delegate addBookmarkViewControllerDidCancel:self];
    }
}

@end