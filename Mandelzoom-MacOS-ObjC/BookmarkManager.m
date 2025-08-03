//
//  BookmarkManager.m
//  Mandelzoom-MacOS-ObjC
//

#import "BookmarkManager.h"

@interface BookmarkManager ()
@property (nonatomic, strong) NSMutableArray<MandelbrotBookmark *> *bookmarks;
@property (nonatomic, strong) NSString *bookmarksFilePath;
@end

@implementation BookmarkManager

+ (instancetype)sharedManager {
    static BookmarkManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BookmarkManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.bookmarks = [[NSMutableArray alloc] init];
        [self setupBookmarksFilePath];
        [self loadBookmarks];
    }
    return self;
}

- (void)setupBookmarksFilePath {
    NSArray *documentsDirectories = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [documentsDirectories firstObject];
    
    // Create app-specific directory
    NSString *appSupportDir = [documentsDirectory stringByAppendingPathComponent:@"Mandelzoom-MacOS-ObjC"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:appSupportDir]) {
        NSError *error;
        [fileManager createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Error creating app support directory: %@", error.localizedDescription);
        }
    }
    
    self.bookmarksFilePath = [appSupportDir stringByAppendingPathComponent:@"bookmarks.plist"];
    NSLog(@"Bookmarks file path: %@", self.bookmarksFilePath);
}

- (void)addBookmark:(MandelbrotBookmark *)bookmark {
    if (!bookmark) return;
    
    // Check for duplicate identifiers
    for (MandelbrotBookmark *existingBookmark in self.bookmarks) {
        if ([existingBookmark.uniqueIdentifier isEqualToString:bookmark.uniqueIdentifier]) {
            NSLog(@"Bookmark with identifier %@ already exists", bookmark.uniqueIdentifier);
            return;
        }
    }
    
    [self.bookmarks addObject:bookmark];
    [self saveBookmarks];
    NSLog(@"Added bookmark: %@", bookmark.title);
}

- (void)removeBookmark:(MandelbrotBookmark *)bookmark {
    if (!bookmark) return;
    [self removeBookmarkWithIdentifier:bookmark.uniqueIdentifier];
}

- (void)removeBookmarkWithIdentifier:(NSString *)identifier {
    if (!identifier) return;
    
    NSMutableArray *bookmarksToRemove = [[NSMutableArray alloc] init];
    for (MandelbrotBookmark *bookmark in self.bookmarks) {
        if ([bookmark.uniqueIdentifier isEqualToString:identifier]) {
            [bookmarksToRemove addObject:bookmark];
        }
    }
    
    for (MandelbrotBookmark *bookmark in bookmarksToRemove) {
        [self.bookmarks removeObject:bookmark];
        NSLog(@"Removed bookmark: %@", bookmark.title);
    }
    
    if (bookmarksToRemove.count > 0) {
        [self saveBookmarks];
    }
}

- (NSArray<MandelbrotBookmark *> *)getAllBookmarks {
    // Filter out any bookmarks with invalid date objects first
    NSMutableArray *validBookmarks = [[NSMutableArray alloc] init];
    NSMutableArray *corruptedBookmarks = [[NSMutableArray alloc] init];
    
    for (MandelbrotBookmark *bookmark in self.bookmarks) {
        if (bookmark.dateCreated && [bookmark.dateCreated isKindOfClass:[NSDate class]]) {
            @try {
                // Test if the date can be used in comparison (this will trigger the NSTaggedDate error if corrupted)
                [bookmark.dateCreated compare:[NSDate date]];
                [validBookmarks addObject:bookmark];
            }
            @catch (NSException *exception) {
                NSLog(@"Found corrupted bookmark with invalid date: %@ - %@", bookmark.title, exception.reason);
                [corruptedBookmarks addObject:bookmark];
            }
        } else {
            NSLog(@"Found bookmark with missing or invalid date: %@", bookmark.title);
            // Fix the date for bookmarks with missing dates
            bookmark.dateCreated = [NSDate date];
            [validBookmarks addObject:bookmark];
        }
    }
    
    // Remove corrupted bookmarks from storage
    if (corruptedBookmarks.count > 0) {
        NSLog(@"Removing %lu corrupted bookmarks", (unsigned long)corruptedBookmarks.count);
        for (MandelbrotBookmark *bookmark in corruptedBookmarks) {
            [self.bookmarks removeObject:bookmark];
        }
        [self saveBookmarks]; // Save the cleaned up list
    }
    
    // Return valid bookmarks sorted by date created (newest first)
    return [validBookmarks sortedArrayUsingComparator:^NSComparisonResult(MandelbrotBookmark *a, MandelbrotBookmark *b) {
        return [b.dateCreated compare:a.dateCreated];
    }];
}

- (MandelbrotBookmark *)getBookmarkWithIdentifier:(NSString *)identifier {
    if (!identifier) return nil;
    
    for (MandelbrotBookmark *bookmark in self.bookmarks) {
        if ([bookmark.uniqueIdentifier isEqualToString:identifier]) {
            return bookmark;
        }
    }
    return nil;
}

- (void)saveBookmarks {
    NSError *error;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.bookmarks 
                                         requiringSecureCoding:YES 
                                                         error:&error];
    
    if (error) {
        NSLog(@"Error archiving bookmarks: %@", error.localizedDescription);
        return;
    }
    
    BOOL success = [data writeToFile:self.bookmarksFilePath atomically:YES];
    if (success) {
        NSLog(@"Successfully saved %lu bookmarks", (unsigned long)self.bookmarks.count);
    } else {
        NSLog(@"Failed to save bookmarks to file");
    }
}

- (void)loadBookmarks {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.bookmarksFilePath]) {
        NSLog(@"No bookmarks file found, starting with empty list");
        return;
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:self.bookmarksFilePath];
    
    if (!data) {
        NSLog(@"Failed to load bookmarks data from file");
        return;
    }
    
    NSSet *allowedClasses = [NSSet setWithObjects:[NSMutableArray class], [MandelbrotBookmark class], nil];
    NSMutableArray *loadedBookmarks = [NSKeyedUnarchiver unarchivedObjectOfClasses:allowedClasses 
                                                                          fromData:data 
                                                                             error:&error];
    
    if (error) {
        NSLog(@"Error unarchiving bookmarks: %@", error.localizedDescription);
        return;
    }
    
    if (loadedBookmarks && [loadedBookmarks isKindOfClass:[NSMutableArray class]]) {
        self.bookmarks = loadedBookmarks;
        NSLog(@"Successfully loaded %lu bookmarks", (unsigned long)self.bookmarks.count);
    } else {
        NSLog(@"Failed to load bookmarks: invalid data format");
    }
}

- (NSUInteger)bookmarkCount {
    return self.bookmarks.count;
}

- (void)clearAllBookmarks {
    [self.bookmarks removeAllObjects];
    [self saveBookmarks];
    NSLog(@"Cleared all bookmarks");
}

@end