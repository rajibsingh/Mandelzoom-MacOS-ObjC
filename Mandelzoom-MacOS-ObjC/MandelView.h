//
//  MandelView.h
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/4/21.
//
#import <Cocoa/Cocoa.h>

#ifndef MandelView_h
#define MandelView_h

@interface MandelView : NSView
    @property (weak) IBOutlet NSImageView *imageView;

    -(void) print;
@end

#endif /* MandelView_h */
