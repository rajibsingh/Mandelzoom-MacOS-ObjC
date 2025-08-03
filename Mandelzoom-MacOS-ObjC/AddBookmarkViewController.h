//
//  AddBookmarkViewController.h
//  Mandelzoom-MacOS-ObjC
//
//  View controller for adding new bookmarks
//

#import <Cocoa/Cocoa.h>
#import "MandelbrotBookmark.h"

NS_ASSUME_NONNULL_BEGIN

@class AddBookmarkViewController;

@protocol AddBookmarkViewControllerDelegate <NSObject>
- (void)addBookmarkViewController:(AddBookmarkViewController *)controller 
                   didAddBookmark:(MandelbrotBookmark *)bookmark;
- (void)addBookmarkViewControllerDidCancel:(AddBookmarkViewController *)controller;
@end

@interface AddBookmarkViewController : NSViewController

@property (nonatomic, weak) id<AddBookmarkViewControllerDelegate> delegate;
@property (nonatomic, assign) double xMin;
@property (nonatomic, assign) double xMax;
@property (nonatomic, assign) double yMin;
@property (nonatomic, assign) double yMax;

@property (nonatomic, strong) IBOutlet NSTextField *titleTextField;
@property (nonatomic, strong) IBOutlet NSTextView *descriptionTextView;
@property (nonatomic, strong) IBOutlet NSTextField *coordinatesLabel;
@property (nonatomic, strong) IBOutlet NSTextField *magnificationLabel;
@property (nonatomic, strong) IBOutlet NSButton *addButton;
@property (nonatomic, strong) IBOutlet NSButton *cancelButton;

- (IBAction)addBookmark:(id)sender;
- (IBAction)cancel:(id)sender;

@end

NS_ASSUME_NONNULL_END