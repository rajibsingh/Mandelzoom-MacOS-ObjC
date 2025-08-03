//
//  ExportBookmarkViewController.h
//  Mandelzoom-MacOS-ObjC
//
//  View controller for selecting and exporting a bookmark
//

#import <Cocoa/Cocoa.h>
#import "MandelbrotBookmark.h"

NS_ASSUME_NONNULL_BEGIN

@class ExportBookmarkViewController;

@protocol ExportBookmarkViewControllerDelegate <NSObject>
- (void)exportBookmarkViewController:(ExportBookmarkViewController *)controller 
                    didExportBookmark:(MandelbrotBookmark *)bookmark;
- (void)exportBookmarkViewControllerDidCancel:(ExportBookmarkViewController *)controller;
@end

@interface ExportBookmarkViewController : NSViewController

@property (nonatomic, weak) id<ExportBookmarkViewControllerDelegate> delegate;

@property (nonatomic, strong) IBOutlet NSScrollView *scrollView;
@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSTextField *instructionLabel;
@property (nonatomic, strong) IBOutlet NSButton *exportButton;
@property (nonatomic, strong) IBOutlet NSButton *cancelButton;

@property (nonatomic, strong) NSArray<MandelbrotBookmark *> *bookmarks;

- (IBAction)exportBookmark:(id)sender;
- (IBAction)cancel:(id)sender;

@end

NS_ASSUME_NONNULL_END