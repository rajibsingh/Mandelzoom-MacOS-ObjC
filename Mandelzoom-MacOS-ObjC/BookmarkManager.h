//
//  BookmarkManager.h
//  Mandelzoom-MacOS-ObjC
//
//  Manages persistence and retrieval of Mandelbrot bookmarks
//

#import <Foundation/Foundation.h>
#import "MandelbrotBookmark.h"

NS_ASSUME_NONNULL_BEGIN

@interface BookmarkManager : NSObject

+ (instancetype)sharedManager;

// Bookmark management
- (void)addBookmark:(MandelbrotBookmark *)bookmark;
- (void)removeBookmark:(MandelbrotBookmark *)bookmark;
- (void)removeBookmarkWithIdentifier:(NSString *)identifier;
- (NSArray<MandelbrotBookmark *> *)getAllBookmarks;
- (MandelbrotBookmark * _Nullable)getBookmarkWithIdentifier:(NSString *)identifier;

// Persistence
- (void)saveBookmarks;
- (void)loadBookmarks;

// Utility
- (NSUInteger)bookmarkCount;
- (void)clearAllBookmarks;

@end

NS_ASSUME_NONNULL_END