//
//  OpenBookmarkViewController.m
//  Mandelzoom-MacOS-ObjC
//

#import "OpenBookmarkViewController.h"
#import "BookmarkManager.h"

@implementation OpenBookmarkViewController

- (void)loadView {
    // Create the main view
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 900, 600)];
}

- (void)viewDidLoad {
    NSLog(@"OpenBookmarkViewController viewDidLoad called");
    [super viewDidLoad];
    NSLog(@"About to call setupUI");
    [self setupUI];
    NSLog(@"setupUI completed, about to refresh bookmarks");
    [self refreshBookmarks];
    NSLog(@"viewDidLoad completed");
}

- (void)setupUI {
    NSLog(@"setupUI starting");
    self.view.frame = NSMakeRect(0, 0, 900, 600);
    NSLog(@"View frame set");
    
    // Title label
    NSTextField *titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 560, 200, 20)];
    titleLabel.editable = NO;
    titleLabel.bezeled = NO;
    titleLabel.drawsBackground = NO;
    titleLabel.stringValue = @"Saved Bookmarks";
    titleLabel.font = [NSFont systemFontOfSize:16 weight:NSFontWeightSemibold];
    [self.view addSubview:titleLabel];
    
    // Table view with scroll view
    self.scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 150, 860, 400)];
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
    titleColumn.width = 180;
    titleColumn.minWidth = 120;
    [self.tableView addTableColumn:titleColumn];
    
    NSTableColumn *descriptionColumn = [[NSTableColumn alloc] initWithIdentifier:@"description"];
    descriptionColumn.title = @"Description";
    descriptionColumn.width = 200;
    descriptionColumn.minWidth = 150;
    [self.tableView addTableColumn:descriptionColumn];
    
    NSTableColumn *magnificationColumn = [[NSTableColumn alloc] initWithIdentifier:@"magnification"];
    magnificationColumn.title = @"Magnification";
    magnificationColumn.width = 100;
    magnificationColumn.minWidth = 80;
    [self.tableView addTableColumn:magnificationColumn];
    
    NSTableColumn *coordinatesColumn = [[NSTableColumn alloc] initWithIdentifier:@"coordinates"];
    coordinatesColumn.title = @"Coordinates";
    coordinatesColumn.width = 220;
    coordinatesColumn.minWidth = 180;
    [self.tableView addTableColumn:coordinatesColumn];
    
    NSTableColumn *dateColumn = [[NSTableColumn alloc] initWithIdentifier:@"date"];
    dateColumn.title = @"Date Created";
    dateColumn.width = 160;
    dateColumn.minWidth = 140;
    [self.tableView addTableColumn:dateColumn];
    
    self.scrollView.documentView = self.tableView;
    [self.view addSubview:self.scrollView];
    
    // Details label
    self.detailsLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 80, 860, 60)];
    self.detailsLabel.editable = NO;
    self.detailsLabel.bezeled = NO;
    self.detailsLabel.drawsBackground = NO;
    self.detailsLabel.font = [NSFont systemFontOfSize:12];
    self.detailsLabel.textColor = [NSColor secondaryLabelColor];
    self.detailsLabel.stringValue = @"Select a bookmark to view details";
    self.detailsLabel.maximumNumberOfLines = 3;
    self.detailsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.view addSubview:self.detailsLabel];
    
    // Buttons
    self.cancelButton = [NSButton buttonWithTitle:@"Cancel" target:self action:@selector(cancel:)];
    self.cancelButton.frame = NSMakeRect(620, 20, 80, 32);
    [self.view addSubview:self.cancelButton];
    
    self.deleteButton = [NSButton buttonWithTitle:@"Delete" target:self action:@selector(deleteBookmark:)];
    self.deleteButton.frame = NSMakeRect(710, 20, 80, 32);
    self.deleteButton.enabled = NO;
    [self.view addSubview:self.deleteButton];
    
    self.openButton = [NSButton buttonWithTitle:@"Open" target:self action:@selector(openBookmark:)];
    self.openButton.frame = NSMakeRect(800, 20, 80, 32);
    self.openButton.keyEquivalent = @"\r"; // Enter key
    self.openButton.enabled = NO;
    [self.view addSubview:self.openButton];
}

- (void)refreshBookmarks {
    NSLog(@"refreshBookmarks starting");
    self.bookmarks = [[BookmarkManager sharedManager] getAllBookmarks];
    NSLog(@"Got %lu bookmarks, about to reload table", (unsigned long)self.bookmarks.count);
    [self.tableView reloadData];
    NSLog(@"Table reloaded");
    
    if (self.bookmarks.count == 0) {
        self.detailsLabel.stringValue = @"No bookmarks saved yet";
    }
    NSLog(@"refreshBookmarks ending");
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
            if (desc.length > 50) {
                desc = [[desc substringToIndex:47] stringByAppendingString:@"..."];
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
        cellView.textField.stringValue = [NSString stringWithFormat:@"(%.3f, %.3f) to (%.3f, %.3f)", 
                                         bookmark.xMin, bookmark.yMin, bookmark.xMax, bookmark.yMax];
        cellView.textField.font = [NSFont monospacedSystemFontOfSize:10 weight:NSFontWeightRegular];
    } else if ([identifier isEqualToString:@"date"]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        
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
    
    self.openButton.enabled = hasSelection;
    self.deleteButton.enabled = hasSelection;
    
    if (hasSelection) {
        MandelbrotBookmark *bookmark = self.bookmarks[selectedRow];
        self.detailsLabel.stringValue = [NSString stringWithFormat:@"Description: %@", 
                                        bookmark.bookmarkDescription.length > 0 ? bookmark.bookmarkDescription : @"No description"];
    } else {
        self.detailsLabel.stringValue = @"Select a bookmark to view details";
    }
}

#pragma mark - Actions

- (IBAction)openBookmark:(id)sender {
    NSInteger selectedRow = self.tableView.selectedRow;
    if (selectedRow >= 0 && selectedRow < self.bookmarks.count) {
        MandelbrotBookmark *bookmark = self.bookmarks[selectedRow];
        
        if ([self.delegate respondsToSelector:@selector(openBookmarkViewController:didOpenBookmark:)]) {
            [self.delegate openBookmarkViewController:self didOpenBookmark:bookmark];
        }
    }
}

- (IBAction)deleteBookmark:(id)sender {
    NSInteger selectedRow = self.tableView.selectedRow;
    if (selectedRow >= 0 && selectedRow < self.bookmarks.count) {
        MandelbrotBookmark *bookmark = self.bookmarks[selectedRow];
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Delete Bookmark";
        alert.informativeText = [NSString stringWithFormat:@"Are you sure you want to delete the bookmark \"%@\"?", bookmark.title];
        alert.alertStyle = NSAlertStyleWarning;
        [alert addButtonWithTitle:@"Delete"];
        [alert addButtonWithTitle:@"Cancel"];
        
        NSModalResponse response = [alert runModal];
        if (response == NSAlertFirstButtonReturn) {
            [[BookmarkManager sharedManager] removeBookmark:bookmark];
            [self refreshBookmarks];
        }
    }
}

- (IBAction)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(openBookmarkViewControllerDidCancel:)]) {
        [self.delegate openBookmarkViewControllerDidCancel:self];
    }
}

@end