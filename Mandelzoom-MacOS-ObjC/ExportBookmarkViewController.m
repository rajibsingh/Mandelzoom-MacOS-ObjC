//
//  ExportBookmarkViewController.m
//  Mandelzoom-MacOS-ObjC
//

#import "ExportBookmarkViewController.h"
#import "BookmarkManager.h"

@implementation ExportBookmarkViewController

- (void)loadView {
    // Create the main view
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 950, 500)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self refreshBookmarks];
}

- (void)setupUI {
    self.view.frame = NSMakeRect(0, 0, 950, 500);
    
    // Title/instruction label
    self.instructionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 450, 910, 30)];
    self.instructionLabel.editable = NO;
    self.instructionLabel.bezeled = NO;
    self.instructionLabel.drawsBackground = NO;
    self.instructionLabel.stringValue = @"Select a bookmark to export:";
    self.instructionLabel.font = [NSFont systemFontOfSize:16 weight:NSFontWeightSemibold];
    [self.view addSubview:self.instructionLabel];
    
    // Table view with scroll view
    self.scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 100, 910, 340)];
    self.scrollView.hasVerticalScroller = YES;
    self.scrollView.borderType = NSBezelBorder;
    
    self.tableView = [[NSTableView alloc] init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.allowsMultipleSelection = NO;
    self.tableView.rowSizeStyle = NSTableViewRowSizeStyleMedium;
    
    // Create columns
    NSTableColumn *titleColumn = [[NSTableColumn alloc] initWithIdentifier:@"title"];
    titleColumn.title = @"Title";
    titleColumn.width = 140;
    titleColumn.minWidth = 100;
    [self.tableView addTableColumn:titleColumn];
    
    NSTableColumn *descriptionColumn = [[NSTableColumn alloc] initWithIdentifier:@"description"];
    descriptionColumn.title = @"Description";
    descriptionColumn.width = 200;
    descriptionColumn.minWidth = 150;
    [self.tableView addTableColumn:descriptionColumn];
    
    NSTableColumn *magnificationColumn = [[NSTableColumn alloc] initWithIdentifier:@"magnification"];
    magnificationColumn.title = @"Magnification";
    magnificationColumn.width = 110;
    magnificationColumn.minWidth = 90;
    [self.tableView addTableColumn:magnificationColumn];
    
    NSTableColumn *coordinatesColumn = [[NSTableColumn alloc] initWithIdentifier:@"coordinates"];
    coordinatesColumn.title = @"Coordinates";
    coordinatesColumn.width = 280;
    coordinatesColumn.minWidth = 250;
    [self.tableView addTableColumn:coordinatesColumn];
    
    NSTableColumn *dateColumn = [[NSTableColumn alloc] initWithIdentifier:@"date"];
    dateColumn.title = @"Date Created";
    dateColumn.width = 120;
    dateColumn.minWidth = 100;
    [self.tableView addTableColumn:dateColumn];
    
    self.scrollView.documentView = self.tableView;
    [self.view addSubview:self.scrollView];
    
    // Buttons
    self.cancelButton = [NSButton buttonWithTitle:@"Cancel" target:self action:@selector(cancel:)];
    self.cancelButton.frame = NSMakeRect(750, 30, 80, 32);
    [self.view addSubview:self.cancelButton];
    
    self.exportButton = [NSButton buttonWithTitle:@"Export" target:self action:@selector(exportBookmark:)];
    self.exportButton.frame = NSMakeRect(850, 30, 80, 32);
    self.exportButton.keyEquivalent = @"\\r"; // Enter key
    self.exportButton.enabled = NO;
    [self.view addSubview:self.exportButton];
}

- (void)refreshBookmarks {
    self.bookmarks = [[BookmarkManager sharedManager] getAllBookmarks];
    [self.tableView reloadData];
    
    if (self.bookmarks.count == 0) {
        self.instructionLabel.stringValue = @"No bookmarks available to export. Please create some bookmarks first.";
        self.exportButton.enabled = NO;
    } else {
        self.instructionLabel.stringValue = @"Select a bookmark to export:";
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.bookmarks.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row >= self.bookmarks.count) return nil;
    
    MandelbrotBookmark *bookmark = self.bookmarks[row];
    NSString *identifier = tableColumn.identifier;
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
    
    if (!cellView) {
        cellView = [[NSTableCellView alloc] init];
        cellView.identifier = identifier;
        
        NSTextField *textField = [[NSTextField alloc] init];
        textField.editable = NO;
        textField.bordered = NO;
        textField.backgroundColor = [NSColor clearColor];
        textField.font = [NSFont systemFontOfSize:13];
        
        cellView.textField = textField;
        [cellView addSubview:textField];
        
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [textField.leadingAnchor constraintEqualToAnchor:cellView.leadingAnchor constant:4],
            [textField.trailingAnchor constraintEqualToAnchor:cellView.trailingAnchor constant:-4],
            [textField.centerYAnchor constraintEqualToAnchor:cellView.centerYAnchor]
        ]];
    }
    
    if ([identifier isEqualToString:@"title"]) {
        cellView.textField.stringValue = bookmark.title;
    } else if ([identifier isEqualToString:@"description"]) {
        NSString *desc = bookmark.bookmarkDescription;
        if (desc.length > 0) {
            // Truncate long descriptions for table display
            if (desc.length > 40) {
                desc = [[desc substringToIndex:37] stringByAppendingString:@"..."];
            }
            cellView.textField.stringValue = desc;
        } else {
            cellView.textField.stringValue = @"—";
            cellView.textField.textColor = [NSColor tertiaryLabelColor];
        }
    } else if ([identifier isEqualToString:@"magnification"]) {
        double mag = bookmark.magnification;
        if (mag >= 1000000) {
            cellView.textField.stringValue = [NSString stringWithFormat:@"%.2fM×", mag / 1000000.0];
        } else if (mag >= 1000) {
            cellView.textField.stringValue = [NSString stringWithFormat:@"%.2fK×", mag / 1000.0];
        } else {
            cellView.textField.stringValue = [NSString stringWithFormat:@"%.2f×", mag];
        }
    } else if ([identifier isEqualToString:@"coordinates"]) {
        cellView.textField.stringValue = [NSString stringWithFormat:@"(%.4f, %.4f) to (%.4f, %.4f)", 
                                         bookmark.xMin, bookmark.yMin, bookmark.xMax, bookmark.yMax];
        cellView.textField.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular];
    } else if ([identifier isEqualToString:@"date"]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
        
        if (bookmark.dateCreated && [bookmark.dateCreated isKindOfClass:[NSDate class]]) {
            cellView.textField.stringValue = [formatter stringFromDate:bookmark.dateCreated];
        } else {
            cellView.textField.stringValue = @"—";
            cellView.textField.textColor = [NSColor tertiaryLabelColor];
        }
        cellView.textField.font = [NSFont systemFontOfSize:11];
    }
    
    return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = self.tableView.selectedRow;
    BOOL hasSelection = selectedRow >= 0 && selectedRow < self.bookmarks.count;
    
    self.exportButton.enabled = hasSelection;
}

#pragma mark - Actions

- (IBAction)exportBookmark:(id)sender {
    NSInteger selectedRow = self.tableView.selectedRow;
    if (selectedRow >= 0 && selectedRow < self.bookmarks.count) {
        MandelbrotBookmark *bookmark = self.bookmarks[selectedRow];
        
        if ([self.delegate respondsToSelector:@selector(exportBookmarkViewController:didExportBookmark:)]) {
            [self.delegate exportBookmarkViewController:self didExportBookmark:bookmark];
        }
    }
}

- (IBAction)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(exportBookmarkViewControllerDidCancel:)]) {
        [self.delegate exportBookmarkViewControllerDidCancel:self];
    }
}

@end