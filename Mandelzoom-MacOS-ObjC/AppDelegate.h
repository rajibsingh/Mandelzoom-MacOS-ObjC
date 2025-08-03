//
//  AppDelegate.h
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/3/21.
//

#import <Cocoa/Cocoa.h>
#import "AddBookmarkViewController.h"
#import "OpenBookmarkViewController.h"
#import "ExportBookmarkViewController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, AddBookmarkViewControllerDelegate, OpenBookmarkViewControllerDelegate, ExportBookmarkViewControllerDelegate>

@property (nonatomic, strong) NSString *saveLocation;
@property (nonatomic, assign) NSInteger magnificationLevel;
@property (nonatomic, assign) BOOL showInfoPanel;
@property (nonatomic, assign) BOOL showRenderTime;

- (void)saveSaveLocationPreference;
- (void)saveMagnificationLevelPreference;
- (void)saveShowInfoPanelPreference;
- (void)saveShowRenderTimePreference;

// Bookmark methods
- (IBAction)addBookmark:(id)sender;
- (IBAction)openBookmark:(id)sender;

@end

