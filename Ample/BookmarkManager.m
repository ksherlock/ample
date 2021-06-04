//
//  BookmarkManager.m
//  Ample
//
//  Created by Kelvin Sherlock on 6/1/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import "BookmarkManager.h"
#import "Ample.h"

@interface BookmarkManager () {
    NSArray<NSURL *> *_urls;
    NSURL *_bookmarkDirectory;
}

@end

@implementation BookmarkManager

static BookmarkManager *singleton = nil;

-(void)awakeFromNib {
    if (!singleton) singleton = self;
}

+(instancetype)sharedManager {
    if (!singleton) singleton = [BookmarkManager new];
    return singleton;
}

-(instancetype)init {
    if (singleton) return singleton;
    return [super init];
}

-(NSURL *)bookmarkDirectory {
    
    if (_bookmarkDirectory) return _bookmarkDirectory;
    NSFileManager *fm = [NSFileManager defaultManager];

    NSURL *url = SupportDirectory();
    url = [url URLByAppendingPathComponent: @"Bookmarks"];
    NSError *error = nil;
    [fm createDirectoryAtURL: url withIntermediateDirectories: YES attributes: nil error: &error];
    if (error) NSLog(@"%@", error);
    _bookmarkDirectory = url;
    return url;
}

/* disallow leading .
 * disallow : or / characters.
 */
-(BOOL)validateName: (NSString *)name {
    
    enum { kMaxLength = 128 };
    unichar buffer[kMaxLength];
    NSUInteger length = [name length];
    if (length == 0 || length > kMaxLength) return NO;
    [name getCharacters: buffer range: NSMakeRange(0, length)];
    if (buffer[0] == '.') return NO;
    for (unsigned i = 0; i < length; ++i) {
        unichar c = buffer[i];
        if (c == ':' || c == '/') return NO;
    }
    return YES;
}


-(NSDictionary *)loadDefault {
    NSURL *url = [self bookmarkDirectory];
    url = [url URLByAppendingPathComponent: @".Default"];
    
    NSDictionary *d;
    
    if (@available(macOS 10.13, *)) {
        NSError *error = nil;
        d = [NSDictionary dictionaryWithContentsOfURL: url error: &error];
        if (!d) NSLog(@"Error loading %@: %@", url, error);
    } else {
        d = [NSDictionary dictionaryWithContentsOfURL: url];
        if (!d) NSLog(@"Error loading %@", url);
    }
    return d;
}

/* save as .Default */
-(BOOL)saveDefault: (NSDictionary *)bookmark {

    NSURL *url = [self bookmarkDirectory];
    url = [url URLByAppendingPathComponent: @".Default"];

    NSError *error = nil;
    BOOL ok = NO;
    if (@available(macOS 10.13, *)) {
        ok = [bookmark writeToURL: url error: &error];
        if (!ok) NSLog(@"%@", error);
    } else {
        ok = [bookmark writeToURL: url atomically: YES];
    }
    return ok;
}

-(BOOL)saveBookmark: (NSDictionary *)bookmark name: (NSString *)name {
    
    NSError *error;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList: bookmark
                                                              format: NSPropertyListXMLFormat_v1_0
                                                             options: 0
                                                               error: &error];
    
    
    
    NSURL *base = [self bookmarkDirectory];
    
    NSURL *url = [base URLByAppendingPathComponent: name];
    
    BOOL ok = [data writeToURL: url options: NSDataWritingWithoutOverwriting error: &error];

    if (!ok) {
        for (unsigned i = 1 ; i < 100; ++i) {
            NSString *tmp = [name stringByAppendingFormat: @"(%d)", i];
            [base URLByAppendingPathComponent: tmp];

            ok = [data writeToURL: url options: NSDataWritingWithoutOverwriting error: &error];
            if (ok) {
                name = tmp;
                break;
            }
        }
    }
    if (!ok) return NO;
    
    if (!_menu) return YES; // ?
    
    NSUInteger ix = [_urls indexOfObjectPassingTest: ^BOOL(NSURL *object, NSUInteger index, BOOL *stop){
        NSString *path = [object lastPathComponent];
        return [name caseInsensitiveCompare: path] == NSOrderedAscending;
    }];

    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle: name action: @selector(loadBookmark:) keyEquivalent: @""];
    [item setRepresentedObject: url];
    
    if (ix == NSNotFound) {
        _urls = [_urls arrayByAddingObject: url];
        [_menu addItem: item];
    } else {
        
        NSInteger n = [_menu numberOfItems];
        [_menu insertItem: item atIndex: n - [_urls count] + ix];
        NSMutableArray *tmp = [_urls mutableCopy];

        [tmp insertObject: url atIndex: ix];
    }

    return YES;
}

-(NSDictionary *)loadBookmarkFromURL: (NSURL *)url {
    
    NSDictionary *d;
    
    if (@available(macOS 10.13, *)) {
        NSError *error = nil;
        d = [NSDictionary dictionaryWithContentsOfURL: url error: &error];
        if (!d) NSLog(@"Error loading %@: %@", url, error);
    } else {
        d = [NSDictionary dictionaryWithContentsOfURL: url];
        if (!d) NSLog(@"Error loading %@", url);
    }
    return d;
}


-(void)loadBookmarks {
    
    NSURL *url = [self bookmarkDirectory];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSError *error = nil;

    NSArray *files = [fm contentsOfDirectoryAtURL: url
                       includingPropertiesForKeys: nil
                                          options: NSDirectoryEnumerationSkipsHiddenFiles
                                            error: &error];
    
    // bleh, has to create 2 new NSStrings for every comparison
    files = [files sortedArrayUsingComparator: ^(NSURL *a, NSURL *b){
        NSString *aa = [a lastPathComponent];
        NSString *bb = [b lastPathComponent];
        return [aa caseInsensitiveCompare: bb];
    }];
    
    
    _urls = files;
}

-(void)updateMenu {
    
    NSArray *menus = [_menu itemArray];
    for (NSMenuItem *item in [menus reverseObjectEnumerator]) {
        if ([item tag] == 0xdeadbeef) [_menu removeItem: item];
    }
    for (NSURL *url in _urls) {
        NSString *title = [url lastPathComponent]; // [[url lastPathComponent] stringByDeletingPathExtension];

        NSMenuItem *item = [_menu addItemWithTitle: title action: @selector(loadBookmark:) keyEquivalent: @""];
        [item setRepresentedObject: url];
        [item setTag: 0xdeadbeef];
    }
}

@end
