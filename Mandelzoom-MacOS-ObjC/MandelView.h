//
//  MandelView.h
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/4/21.
//
#import <Cocoa/Cocoa.h>
#import "MandelRenderer.h"

#ifndef MandelView_h
#define MandelView_h

@class SelectionRectangleView;

@interface MandelView : NSView
    @property (strong) IBOutlet NSImageView *imageView;
    @property (strong) IBOutlet SelectionRectangleView *selectionOverlayView;
    @property (strong) NSTextField *renderTimeLabel;

-(void) setImage;
-(void) refresh;
@end

#endif /* MandelView_h */
