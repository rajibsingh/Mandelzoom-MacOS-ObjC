//
//  ViewController.h
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/3/21.
//

#import <Cocoa/Cocoa.h>
#import "MandelView.h"

@interface ViewController : NSViewController
@property (weak) IBOutlet NSTextFieldCell *statusLabel;
@property (weak) IBOutlet NSImageView *imageView;
@property (strong) IBOutlet MandelView *mandelView;


@end

