
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SelectionRectangleView : NSView

@property (nonatomic, assign) NSRect selectionRectToDraw;
@property (nonatomic, assign) BOOL shouldDrawRectangle;

@end

NS_ASSUME_NONNULL_END
