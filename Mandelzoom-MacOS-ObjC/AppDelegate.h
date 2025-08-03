//
//  AppDelegate.h
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/3/21.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong) NSString *saveLocation;
@property (nonatomic, assign) NSInteger magnificationLevel;
@property (nonatomic, assign) BOOL showInfoPanel;
@property (nonatomic, assign) BOOL showRenderTime;

- (void)saveSaveLocationPreference;
- (void)saveMagnificationLevelPreference;
- (void)saveShowInfoPanelPreference;
- (void)saveShowRenderTimePreference;

@end

