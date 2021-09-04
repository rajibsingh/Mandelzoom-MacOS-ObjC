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

@interface MandelView : NSView
    @property (weak) IBOutlet NSImageView *imageView;


-(void) setImage;
-(void) refresh;
-(BOOL) acceptsFirstResponder;
-(void) mouseDown:(NSEvent *)event;
-(void) mouseUp:(NSEvent *)event;
@end

#endif /* MandelView_h */
