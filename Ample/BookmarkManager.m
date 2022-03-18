//
//  BookmarkManager.m
//  Ample
//
//  Created by Kelvin Sherlock on 6/1/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import "BookmarkManager.h"
#import "Ample.h"

#import "Bookmark.h"
#import "DiskImage.h"
#import "Menu.h"


@interface BookmarkManager () {

    NSPersistentStoreCoordinator *_psc;
    NSManagedObjectContext *_moc;
    NSManagedObjectModel *_mom;
    NSPersistentStore *_store;
    
    NSFetchRequest *_defaultRequest;
    
    
    NSURL *_bookmarkDirectory;
    NSArrayController *_items;
    NSUInteger _newMenuGeneration;
    NSUInteger _currentMenuGeneration;
    
    Bookmark *_currentBookmark;
}

@end

@interface BookmarkManager (MenuDelegate) <NSMenuDelegate>
@end

@implementation BookmarkManager

static BookmarkManager *singleton = nil;

-(void)awakeFromNib {
    if (!singleton) {
        singleton = self;
        if (!_items) [self initMenus];
    }
}

+(instancetype)sharedManager {
    if (!singleton) singleton = [BookmarkManager new];
    return singleton;
}

-(instancetype)init {
    if (singleton) return singleton;


    if ((self = [super init])) {
        [self initCoreData];

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        
        [nc addObserver: self selector: @selector(willTerminate:) name: NSApplicationWillTerminateNotification object: nil];
        [nc addObserver: self selector: @selector(diskImageAdded:) name: kNotificationDiskImageAdded object: nil];


        _newMenuGeneration = 1;
        _currentMenuGeneration = 0;
    }

    
    //singleton = self;
    return self;
}

-(NSManagedObjectContext *)managedObjectContext {
    return _moc;
}

-(void)initCoreData {
    
    NSError *error;
    BOOL new = NO;

    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url = [bundle URLForResource: @"Ample" withExtension: @"momd"];
    _mom = [[NSManagedObjectModel alloc] initWithContentsOfURL: url];
    
    _psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: _mom];
    
    _moc = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
    [_moc setPersistentStoreCoordinator: _psc];
    
    //[_moc setMergePolicy: [NSMergePolicy rollbackMergePolicy]];
    
    url = SupportDirectory();
#if 0
    url = [url URLByAppendingPathComponent: @"Ample.db"];

    if (![url checkResourceIsReachableAndReturnError: &error])
        new = YES;

    
    _store = [_psc addPersistentStoreWithType: NSSQLiteStoreType
                              configuration: nil
                                        URL: url
                                    options: nil
                                      error: &error];
#else

    url = [url URLByAppendingPathComponent: @"Ample.xml"];

    if (![url checkResourceIsReachableAndReturnError: &error])
        new = YES;

    
    _store = [_psc addPersistentStoreWithType: NSXMLStoreType
                              configuration: nil
                                        URL: url
                                    options: nil
                                      error: &error];

    
#endif
    _defaultRequest = [Bookmark fetchRequest];
    [_defaultRequest setPredicate: [NSPredicate predicateWithFormat: @"automatic == TRUE"]];
    
    if (new) {
        [self convertLegacyBookmarks];
        [self convertLegacyDiskImages];
    }
    
}

-(void)willTerminate: (NSNotification *)notification {

    NSError *error;
    
    if (![_moc save: &error]) {
        NSLog(@"%@", error);
    }
}


-(void)convertLegacyBookmarks {
    
    //NSEntityDescription *e;

    //e = [NSEntityDescription entityForName: @"Bookmark" inManagedObjectContext: moc];

    NSURL *url = [self bookmarkDirectory];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;

    NSArray *files = [fm contentsOfDirectoryAtURL: url
                       includingPropertiesForKeys: nil
                                          options: NSDirectoryEnumerationSkipsHiddenFiles
                                            error: &error];
    
    NSDate *now = [NSDate date];
    for (NSURL *url in files) {


        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL: url];
        //NSData *data = [NSPropertyListSerialization dataWithPropertyList: dict format: NSPropertyListBinaryFormat_v1_0 options: 0 error: &error];

        Bookmark *b = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName: @"Bookmark" inManagedObjectContext: _moc];

        [b setName: [url lastPathComponent]];
        [b setDictionary: dict];
        //[b setData: data];
        [b setMachine: [dict objectForKey: @"machine"]];
        [b setCreated: now];
    }

    // default...

    url = [url URLByAppendingPathComponent: @".Default"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL: url];
    if (dict) {
        //NSData *data = [NSPropertyListSerialization dataWithPropertyList: dict format: NSPropertyListBinaryFormat_v1_0 options: 0 error: &error];

        NSString *name = [self uniqueBookmarkName: @"Default"];
        Bookmark *b = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName: @"Bookmark" inManagedObjectContext: _moc];

        [b setName: name];
        [b setAutomatic: YES];
        [b setDictionary: dict];
        //[b setData: data];
        [b setMachine: [dict objectForKey: @"machine"]];
        [b setCreated: now];
        
    }

    if (![_moc save: &error]) {
        NSLog(@"%@", error);
    }
}

-(void)convertLegacyDiskImages {

    NSError *error;
    NSURL *sd = SupportDirectory();
    NSURL *url = [sd URLByAppendingPathComponent: @"RecentDiskImages.plist"];
    
    NSArray *array = [NSArray arrayWithContentsOfURL: url];
    if (!array) return;

    for (NSDictionary *d in array) {
        
        NSManagedObject *o = [NSEntityDescription insertNewObjectForEntityForName: @"DiskImage" inManagedObjectContext: _moc];
        [o setValue: [d objectForKey: @"date"] forKey: @"added"];
        [o setValue: [d objectForKey: @"date"] forKey: @"accessed"];
        [o setValue: [d objectForKey: @"path"] forKey: @"path"];
        [o setValue: [d objectForKey: @"size"] forKey: @"size"];
    }

    if (![_moc save: &error]) {
        NSLog(@"%@", error);
    }
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


-(Bookmark *)defaultBookmark {

    NSFetchRequest *req;
    NSError *error;
    NSArray *array;
    Bookmark *b;

    req = [Bookmark fetchRequest];
    [req setPredicate: [NSPredicate predicateWithFormat: @"automatic == TRUE"]];
    array = [_moc executeFetchRequest: req error: &error];

    return [array firstObject];
}

-(NSDictionary *)loadDefault {
    Bookmark *b = [self defaultBookmark];
    return [b dictionary];
}

/* save as .Default */
-(NSError *)saveDefault: (NSDictionary *)bookmark {

    return nil;

#if 0
    /* check if it already exists */

    NSFetchRequest *req;
    NSError *error;
    NSArray *array;
    Bookmark *b;
    NSDate *now = [NSDate date];
    BOOL ok;

    req = [[NSFetchRequest alloc] initWithEntityName: @"Default"];
    array = [_moc executeFetchRequest: req error: &error];


    b = [array firstObject];
    if (b) {
        [b setModified: now];
    } else {
        b = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName: @"Default" inManagedObjectContext: _moc];

        [b setName: @"Default"];
        [b setCreated: now];
    }
    [b setDictionary: bookmark];
    [b setMachine: [bookmark objectForKey: @"machine"]];

    ok = [_moc save: &error];
    if (!ok) NSLog(@"%@", error);
    return error;

#if 0
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
#endif
#endif
}


-(NSError *)setAutomatic: (Bookmark *)bookmark {
    
    NSError *error = nil;
    NSFetchRequest *req = [Bookmark fetchRequest];
    [req setPredicate: [NSPredicate predicateWithFormat: @"automatic == TRUE"]];
    
    NSArray *array = [_moc executeFetchRequest: req error: &error];
    for (Bookmark *b in array) {
        if (b != bookmark) [b setAutomatic: NO];
    }
    [bookmark setAutomatic: YES];
    if (error) return error;
    [_moc save: &error];
    return error;
}

-(NSError *)saveBookmark: (NSDictionary *)bookmark name: (NSString *)name automatic: (BOOL)automatic {

    NSDate *now = [NSDate date];
    NSError *error;
    BOOL ok;

    Bookmark *b = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName: @"Bookmark" inManagedObjectContext: _moc];
    
    [b setName: name];
    [b setDictionary: bookmark];
    [b setMachine: [bookmark objectForKey: @"machine"]];
    [b setCreated: now];
    [b setAutomatic: automatic];
    
    ok = [b validateForInsert: &error];
    if (!ok) {
        // will be useful, eg "name is too long"
        // keys: NSValidationErrorObject, NSLocalizedDescription, NSValidationErrorKey, NSValidationErrorValue
        //NSLog(@"%@", error);
        [_moc deleteObject: b];
        return error;
    }
    
    
    ok = [_moc save: &error];
    if (!ok) {
        //NSLog(@"%@", error);
        [_moc deleteObject: b];
        error = [NSError errorWithDomain: @"Ample" code: 0 userInfo: @{ NSLocalizedDescriptionKey: @"Duplicate name" }];
        return error;
    }

    if (automatic) {
        [self setAutomatic: b];
    }


    return nil;
}

-(void)loadBookmarks {
    
    NSSortDescriptor *s = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES selector: @selector(caseInsensitiveCompare:)];

    
    _items = [NSArrayController new];
    [_items setManagedObjectContext: _moc];
    [_items setAvoidsEmptySelection: NO];
    [_items setAutomaticallyPreparesContent: YES];
    [_items setAutomaticallyRearrangesObjects: YES];
    [_items setEntityName: @"Bookmark"];
    [_items setSortDescriptors: @[ s ]];

    [_items fetch: nil];
}


/* extract the number from a trailing " (%d)" */
static int extract_number(NSString *s, NSInteger offset) {
    
    unichar buffer[32];
    NSInteger len = [s length] - offset;
    unichar c;
    int i;
    int n = 0;
    
    if (len < 4) return -1; /* " (1)"*/
    if (len > 8) return -1; /* " (99999)" */
    
    NSRange r = NSMakeRange(offset, len);
    [s getCharacters: buffer range: r];
    
    buffer[len] = 0;
    i = 0;
    if (buffer[i++] != ' ') return -1;
    if (buffer[i++] != '(') return -1;
    
    c = buffer[i++];
    if (c < '1' || c > '9') return -1;
    n = c - '0';
    
    for (;;) {
        c = buffer[i];
        if (c < '0' || c > '9') break;
        n = n * 10 + (c - '0');
        ++i;
    }

    if (buffer[i++] != ')') return -1;
    if (buffer[i++] != 0) return -1;

    return n;
}


-(NSString *)uniqueBookmarkName: (NSString *)name {
    
    NSInteger length = [name length];

    NSError *error = nil;
    NSPredicate *p = [NSPredicate predicateWithFormat: @"name BEGINSWITH %@", name];
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName: @"Bookmark"];
    [req setPredicate: p];

    NSArray *array = [_moc executeFetchRequest: req error: &error];
    if (![array count]) return name;

    uint64_t bits = 1; /* mark 0 as unavailable */
    NSInteger max = 0;
    BOOL exact = NO;
    for (Bookmark *b in array) {
        NSString *s = [b name];
        if ([name isEqualToString: s]) {
            exact = YES;
            continue;
        }
        int n = extract_number(s, length);
        if (n < 1) continue;
        if (n > max) max = n;
        if (n < 64)
            bits |= (1 << n);
    }
    if (!exact) return name;
    
    if (bits == (uint64_t)-1) {
        return [name stringByAppendingFormat: @" (%u)", (int)(max + 1)];
    }
    
#if 1
    int ix = 0;
    while (bits & 0x01) {
        ++ix;
        bits >>= 1;
    }
#else
    // this doesn't work correctly.
    int ix = __builtin_ffsll(~bits);
#endif
    return [name stringByAppendingFormat: @" (%u)", ix];


}


-(BOOL)addDiskImage: (NSObject *)pathOrURL {
    
    NSError *error;
    
    NSString *path = nil;
    NSURL *url = nil;
    if ([pathOrURL isKindOfClass: [NSString class]]) {
        path = (NSString *)pathOrURL;
    } else if ([pathOrURL isKindOfClass: [NSURL class]]){
        url = (NSURL *)pathOrURL;

        path = [NSString stringWithCString: [url fileSystemRepresentation] encoding: NSUTF8StringEncoding];
    }
    if (!path) return NO;

    NSFileManager *fm = [NSFileManager defaultManager];


    NSDictionary *attr = [fm attributesOfItemAtPath: path error: &error];
    if (error) {
        NSLog(@"%@ : %@", path, error);
        return NO;
    }
    
    NSNumber *size = [attr objectForKey: NSFileSize];

    NSDate *now = [NSDate date];
    
    NSPredicate *p = [NSPredicate predicateWithFormat: @"path = %@", path];
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName: @"DiskImage"];
    [req setPredicate: p];
    

    NSArray *array = [_moc executeFetchRequest: req error: &error];
    BOOL found = 0;
    for (NSManagedObject *o in array) {
        found = YES;
        [o setValue: now forKey: @"accessed"];
    }
    if (found) return NO;
    
    DiskImage *o = [NSEntityDescription insertNewObjectForEntityForName: @"DiskImage" inManagedObjectContext: _moc];
    
    
    [o setPath: path];
    [o setAdded: now];
    [o setAccessed: now];
    [o setSize: [size longLongValue]];
    [o updatePath];
    
    if (![_moc save: &error]) {
        NSLog(@"%@", error);
        [_moc deleteObject: o];
    }
    
    return YES;
}

-(void)diskImageAdded: (NSNotification *)notification {
    
    NSURL *url = [notification object];
    if (url) [self addDiskImage: url];
}

static NSString *kMenuContext = @"";

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == (__bridge void * _Nullable)(kMenuContext)) {

        //NSLog(@"observeValueForKeyPath %@", keyPath);
        
        _newMenuGeneration++;

        return;
    }

    [super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
}

-(void)initMenus {
    
    if (!_items) {
        [self loadBookmarks];
        [_items addObserver: self forKeyPath: @"arrangedObjects.name" options: 0 context: (__bridge void * _Nullable)(kMenuContext)];
        [_items addObserver: self forKeyPath: @"arrangedObjects.automatic" options: 0 context: (__bridge void * _Nullable)(kMenuContext)];
    }

}

-(IBAction)bookmarkMenu:(id)sender
{
}

-(Bookmark *)currentBookmark {
    return _currentBookmark;
}
-(void)setCurrentBookmark:(Bookmark *)currentBookmark {
    if (currentBookmark == _currentBookmark) return;
    _currentBookmark = currentBookmark;
    _newMenuGeneration++;
}

-(void)menuNeedsUpdate:(NSMenu *)menu {
    
    if (_currentMenuGeneration == _newMenuGeneration) return;
    _currentMenuGeneration = _newMenuGeneration;

    if (_currentBookmark && _updateMenuItem) {
        NSString *title = [NSString stringWithFormat: @"Update “%@”", [_currentBookmark name]];
        [_updateMenuItem setHidden: NO];
        [_updateMenuItem setTitle: title];
        [_updateMenuItem setRepresentedObject: _currentBookmark];
    } else {
        [_updateMenuItem setHidden: YES];
        [_updateMenuItem setRepresentedObject: nil];
    }
    
    

    NSArray *menus = [menu itemArray];
    for (NSMenuItem *item in [menus reverseObjectEnumerator]) {
        if ([item tag] == 0xdeadbeef) [_menu removeItem: item];
    }

    NSArray *array = [_items arrangedObjects];
    for (Bookmark *b in array) {

        NSString *title = [b name];
        NSMenuItem *item = [menu addItemWithTitle: title action: @selector(bookmarkMenu:) keyEquivalent: @""];
        [item setRepresentedObject: b];
        [item setTag: 0xdeadbeef];
        if ([b automatic]) {
            
            [item setOnStateImage: [NSImage imageNamed: NSImageNameStatusAvailable]];
            [item setState: NSOnState];
        }
        //if ([b automatic]) [item setAttributedTitle: ItalicMenuString([b name])];
        //[item setState: [b automatic] ? NSMixedState : NSOffState];
    }
    
}

@end


/* MacOS 12.1+ doesn't like class clusters in nibs -
 
 [General] This coder is expecting the replaced object 0x600000938f60 to be returned from
 NSClassSwapper.initWithCoder instead of <BookmarkManager: 0x600000905da0>

 */
@interface BookmarkManagerProxy : NSProxy {
    BookmarkManager *_target;
}
@end

@implementation BookmarkManagerProxy

-(id)init {
    _target = [BookmarkManager sharedManager];
    return self;
}

-(NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [_target methodSignatureForSelector: sel];
}

+(BOOL)respondsToSelector:(SEL)aSelector {
    return [BookmarkManager respondsToSelector: aSelector];
}
-(void)forwardInvocation:(NSInvocation *)invocation {
    if ([_target respondsToSelector: [invocation selector]]) {
        [invocation invokeWithTarget: _target];
    } else {
        [super forwardInvocation: invocation];
    }
}



@end
