//
//  OpenBookmarkViewController.h
//  Mandelzoom-MacOS-ObjC
//
//  View controller for viewing and opening saved bookmarks
//

#import <Cocoa/Cocoa.h>
#import "MandelbrotBookmark.h"

NS_ASSUME_NONNULL_BEGIN

@class OpenBookmarkViewController;

@protocol OpenBookmarkViewControllerDelegate <NSObject>
- (void)openBookmarkViewController:(OpenBookmarkViewController *)controller 
                    didOpenBookmark:(MandelbrotBookmark *)bookmark;
- (void)openBookmarkViewControllerDidCancel:(OpenBookmarkViewController *)controller;
@end

@interface OpenBookmarkViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) id<OpenBookmarkViewControllerDelegate> delegate;
@property (nonatomic, strong) NSArray<MandelbrotBookmark *> *bookmarks;

@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSScrollView *scrollView;
@property (nonatomic, strong) IBOutlet NSTextField *detailsLabel;
@property (nonatomic, strong) IBOutlet NSButton *openButton;
@property (nonatomic, strong) IBOutlet NSButton *deleteButton;
@property (nonatomic, strong) IBOutlet NSButton *cancelButton;

- (IBAction)openBookmark:(id)sender;
- (IBAction)deleteBookmark:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)refreshBookmarks;

@end

NS_ASSUME_NONNULL_END