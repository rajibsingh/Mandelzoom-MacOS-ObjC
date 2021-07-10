//
//  ViewController.m
//  Mandelzoom-MacOS-ObjC
//
//  Created by Rajib Singh on 7/3/21.
//

#import "ViewController.h"
#import "MandelView.h"


@implementation ViewController
- (IBAction)buttonAction:(id)sender {
    printf("button clicked");
    printf("%s", sender);
    _statusLabel.stringValue = @"clicked";
    [_mandelView refresh];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [_mandelView setImage];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}



@end
