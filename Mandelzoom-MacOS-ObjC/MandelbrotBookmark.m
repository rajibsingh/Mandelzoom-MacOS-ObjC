//
//  MandelbrotBookmark.m
//  Mandelzoom-MacOS-ObjC
//

#import "MandelbrotBookmark.h"

@implementation MandelbrotBookmark

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithTitle:(NSString *)title
                  description:(NSString *)description
                         xMin:(double)xMin
                         xMax:(double)xMax
                         yMin:(double)yMin
                         yMax:(double)yMax {
    self = [super init];
    if (self) {
        self.title = title ?: @"Untitled Bookmark";
        self.bookmarkDescription = description ?: @"";
        self.xMin = xMin;
        self.xMax = xMax;
        self.yMin = yMin;
        self.yMax = yMax;
        self.dateCreated = [NSDate date];
        self.uniqueIdentifier = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.title = [coder decodeObjectOfClass:[NSString class] forKey:@"title"];
        self.bookmarkDescription = [coder decodeObjectOfClass:[NSString class] forKey:@"description"];
        self.xMin = [coder decodeDoubleForKey:@"xMin"];
        self.xMax = [coder decodeDoubleForKey:@"xMax"];
        self.yMin = [coder decodeDoubleForKey:@"yMin"];
        self.yMax = [coder decodeDoubleForKey:@"yMax"];
        self.dateCreated = [coder decodeObjectOfClass:[NSDate class] forKey:@"dateCreated"];
        self.uniqueIdentifier = [coder decodeObjectOfClass:[NSString class] forKey:@"uniqueIdentifier"];
        
        // Migrate old bookmarks without unique identifier
        if (!self.uniqueIdentifier) {
            self.uniqueIdentifier = [[NSUUID UUID] UUIDString];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.bookmarkDescription forKey:@"description"];
    [coder encodeDouble:self.xMin forKey:@"xMin"];
    [coder encodeDouble:self.xMax forKey:@"xMax"];
    [coder encodeDouble:self.yMin forKey:@"yMin"];
    [coder encodeDouble:self.yMax forKey:@"yMax"];
    [coder encodeObject:self.dateCreated forKey:@"dateCreated"];
    [coder encodeObject:self.uniqueIdentifier forKey:@"uniqueIdentifier"];
}

// Computed properties
- (double)centerX {
    return (self.xMin + self.xMax) / 2.0;
}

- (double)centerY {
    return (self.yMin + self.yMax) / 2.0;
}

- (double)width {
    return self.xMax - self.xMin;
}

- (double)height {
    return self.yMax - self.yMin;
}

- (double)magnification {
    // Calculate magnification compared to initial full view (-2.5 to 1.0 = width of 3.5)
    double initialWidth = 3.5;
    return initialWidth / self.width;
}

- (NSDictionary *)toDictionary {
    return @{
        @"title": self.title,
        @"description": self.bookmarkDescription,
        @"xMin": @(self.xMin),
        @"xMax": @(self.xMax),
        @"yMin": @(self.yMin),
        @"yMax": @(self.yMax),
        @"dateCreated": [self.dateCreated description],  // Convert NSDate to string for JSON compatibility
        @"uniqueIdentifier": self.uniqueIdentifier
    };
}

+ (instancetype)fromDictionary:(NSDictionary *)dictionary {
    MandelbrotBookmark *bookmark = [[MandelbrotBookmark alloc] initWithTitle:dictionary[@"title"]
                                                                 description:dictionary[@"description"]
                                                                        xMin:[dictionary[@"xMin"] doubleValue]
                                                                        xMax:[dictionary[@"xMax"] doubleValue]
                                                                        yMin:[dictionary[@"yMin"] doubleValue]
                                                                        yMax:[dictionary[@"yMax"] doubleValue]];
    
    if (dictionary[@"dateCreated"]) {
        bookmark.dateCreated = dictionary[@"dateCreated"];
    }
    if (dictionary[@"uniqueIdentifier"]) {
        bookmark.uniqueIdentifier = dictionary[@"uniqueIdentifier"];
    }
    
    return bookmark;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"MandelbrotBookmark: %@ (%.6f,%.6f) to (%.6f,%.6f) [%.1fx zoom]",
            self.title, self.xMin, self.yMin, self.xMax, self.yMax, self.magnification];
}

@end