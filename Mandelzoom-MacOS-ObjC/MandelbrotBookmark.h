//
//  MandelbrotBookmark.h
//  Mandelzoom-MacOS-ObjC
//
//  Represents a saved Mandelbrot view bookmark with coordinates and metadata
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MandelbrotBookmark : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *bookmarkDescription;
@property (nonatomic, assign) double xMin;
@property (nonatomic, assign) double xMax;
@property (nonatomic, assign) double yMin;
@property (nonatomic, assign) double yMax;
@property (nonatomic, strong) NSDate *dateCreated;
@property (nonatomic, strong) NSString *uniqueIdentifier;

// Computed properties
@property (nonatomic, readonly) double centerX;
@property (nonatomic, readonly) double centerY;
@property (nonatomic, readonly) double width;
@property (nonatomic, readonly) double height;
@property (nonatomic, readonly) double magnification;

- (instancetype)initWithTitle:(NSString *)title
                  description:(NSString *)description
                         xMin:(double)xMin
                         xMax:(double)xMax
                         yMin:(double)yMin
                         yMax:(double)yMax;

- (NSDictionary *)toDictionary;
+ (instancetype)fromDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END