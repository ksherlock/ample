//
//  DownloadWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/2/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "Ample.h"
#import "DownloadWindowController.h"
#import "Menu.h"


enum {
    kTagZip = 1,
    kTag7z = 2,
};

@interface DownloadExtensionTransformer: NSValueTransformer
@end

@implementation DownloadExtensionTransformer

+(void)load {
    [NSValueTransformer setValueTransformer: [DownloadExtensionTransformer new] forName: @"FormatTransformer"];

}

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

-(id)transformedValue:(id)value {
    // string to number.
    if ([@"zip" isEqualToString: value])
        return @(kTagZip);
    if ([@"7z" isEqualToString: value])
        return @(kTag7z);
    return @0;
}

-(id)reverseTransformedValue:(id)value {
    // number back to string.
    switch ([value intValue]) {
        case kTagZip: return @"zip";
        case kTag7z: return @"7z";
        default: return @"";
    }
}

+(unsigned)stringToNumber: (NSString *)string {
    if ([@"zip" isEqualToString: string])
        return kTagZip;
    if ([@"7z" isEqualToString: string])
        return kTag7z;
    return 0;
}

+(NSString *)numberToString: (unsigned)number {
    switch (number) {
        case kTagZip: return @"zip";
        case kTag7z: return @"7z";
        default: return @"";
    }
}

@end

enum {
    ItemMissing = 0,
    ItemFound,
    ItemDownloading,
    ItemDownloaded,
    ItemCanceled,
    ItemError
};

@interface DownloadItem : NSObject

@property NSString *name;
@property NSError *error;
@property NSString *pathName;
@property NSURLSessionDownloadTask *task;
@property NSURL *localURL;

@property NSUInteger status;
@property NSUInteger index;


-(void)cancelDownload;
-(void)beginDownloadWithTask:(NSURLSessionDownloadTask *)task;
-(void)completeWithError: (NSError *)error;
-(NSString *)statusDescription;
@end



@interface DownloadWindowController ()
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSPopUpButton *formatButton;
@property (weak) IBOutlet NSTextField *downloadField;
@property NSString *downloadExtension;

@end

@implementation DownloadWindowController {
    
    NSArray *_items;
    NSURL *_romFolder;
    NSURL *_defaultDownloadURL;
    NSURL *_downloadURL;

    NSURLSession *_session;
    NSMutableDictionary *_taskIndex;
    NSUserDefaults *_defaults;
}

+(instancetype)sharedInstance {
    static DownloadWindowController *me = nil;
    if (!me) {
        me = [self new];
    }
    return me;
}

+ (void)restoreWindowWithIdentifier:(nonnull NSUserInterfaceItemIdentifier)identifier state:(nonnull NSCoder *)state completionHandler:(nonnull void (^)(NSWindow * _Nullable, NSError * _Nullable))completionHandler {
    NSLog(@"restore rom manager window");

    NSWindowController *controller = [DownloadWindowController sharedInstance];
    NSWindow *w = [controller window];
    [w restoreStateWithCoder: state];
    completionHandler(w, nil);
}


#if 0
- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    
}
#endif

-(NSString *)windowNibName {
    return @"DownloadWindow";
}

-(void)windowWillLoad {
    _defaults = [NSUserDefaults standardUserDefaults];
    
    // set here so binding works.
    NSString *s = [_defaults stringForKey: kDownloadExtension];
    if (![s length]) s = [_defaults stringForKey: kDefaultDownloadExtension];
    
    _downloadExtension = s;
}

- (void)windowDidLoad {
    [super windowDidLoad];
#if 0
    NSWindow *window = [self window];
    // disabled for now ... restoration happens before defaults are loaded.
    [window setRestorable: YES];
    [window setRestorationClass: [self class]];
#endif
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    NSError *error = nil;
    NSBundle *bundle = [NSBundle mainBundle];
    NSFileManager *fm = [NSFileManager defaultManager];

    NSURL *url = [bundle URLForResource: @"roms" withExtension: @"plist"];
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL: url];
    
    NSURL *sd = SupportDirectory();

    _romFolder = [sd URLByAppendingPathComponent: @"roms"];
    
    [fm createDirectoryAtURL: _romFolder withIntermediateDirectories: YES attributes: nil error: &error];

    // so blank URL isn't overwritten.
    NSString *s = [_defaults stringForKey: kDefaultDownloadURL];
    _defaultDownloadURL = [NSURL URLWithString: s];
    [_downloadField setPlaceholderString: s];
    
    s = [_defaults stringForKey: kDownloadURL];
    if ([s length]) {
        [_downloadField setStringValue: s];
        _downloadURL = [NSURL URLWithString: s];
    } else {
        _downloadURL = _defaultDownloadURL;
    }
    
    [self initializeExtensionMenu];
    

    NSArray *roms = [d objectForKey: @"roms"];
    [self setCurrentROM: @""];
    [self setCurrentCount: 0];
    [self setTotalCount: [roms count]];
    [self setErrorCount: 0];
    

    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity: [roms count]];
    unsigned ix = 0;
    for (NSString *name in roms) {
        
        DownloadItem *item  = [DownloadItem new];
        [item setName: name];
        [item setIndex: ix++];

        [tmp addObject: item];
    }
    _items = tmp;
    [self refreshROMs: nil];
 
    //[_tableView reloadData];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration: config delegate: self delegateQueue: nil];
    _taskIndex = [NSMutableDictionary dictionaryWithCapacity: [_items count]];
    
    //[self download];
}



#if 0
-(void)validateURL: (NSString *)url {
    NSURL *v;
    
    if (![url length]) {
        _effectiveURL = [NSURL URLWithString: _downloadURL];
        [_downloadField setTextColor: nil];
        return;
    }
    
    v = [NSURL URLWithString: url];
    if (v) {
        _effectiveURL = v;
        [_downloadField setTextColor: nil];
    } else {
        _effectiveURL = [NSURL URLWithString: _downloadURL];
        [_downloadField setTextColor: [NSColor redColor]];
    }
}
#endif

-(void)downloadItem: (DownloadItem *)item {

    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration: config delegate: self delegateQueue: nil];
    }
    
    NSURLSessionDownloadTask *task;
    NSString *s = [item name];
    NSString *path = [s stringByAppendingPathExtension: _downloadExtension];
    NSURL *url = [_downloadURL URLByAppendingPathComponent: path];
    
    task = [_session downloadTaskWithURL: url];
    
    [item beginDownloadWithTask: task];
    [_taskIndex setObject: item forKey: task];

    [task resume];
    
}

-(void)download {
    
    // run in thread?
    //unsigned count = 0;

    for (DownloadItem *item in _items) {
            
        NSURLSessionDownloadTask *task;
        NSString *s = [item name];
        NSString *path = [s stringByAppendingPathExtension: _downloadExtension];
        NSURL *url = [_downloadURL URLByAppendingPathComponent: path];
        
        task = [_session downloadTaskWithURL: url];
        [_taskIndex setObject: item forKey: task];
        
        [item setTask: task];

        [task resume];

        //++count;
        //if (count >= 2) break;
    }
    [self setActive: YES];
    
}

-(DownloadItem *)clickedItem {
    NSInteger row = [_tableView clickedRow];
    if (row < 0 || row >= [_items count]) return nil;
    return [_items objectAtIndex: row];
}
-(void)redrawRow: (NSUInteger)row {
    
    //NSRect r = [_tableView rectOfRow: row];
    //[_tableView setNeedsDisplayInRect: r];
    
    NSIndexSet *rIx = [NSIndexSet indexSetWithIndex: row];
    NSIndexSet *cIx = [NSIndexSet indexSetWithIndex: 0];
    
    [_tableView reloadDataForRowIndexes: rIx columnIndexes: cIx];
}


-(void)initializeExtensionMenu {
    
    unsigned tag;
    // mark default download extension.
    NSString *defaultExt = [_defaults stringForKey: kDefaultDownloadExtension];
    tag = [DownloadExtensionTransformer stringToNumber: defaultExt];
    
    NSMenuItem *item = [[_formatButton menu] itemWithTag: tag];
    if (item) {
        [item setAttributedTitle: ItalicMenuString([item title])];
    }

#if 0
    // handled via binding.
    NSString *ext = [_defaults stringForKey: kDownloadExtension];
    if ([ext length]) {
        ix = [DownloadExtensionTransformer stringToNumber: ext];
    }

    [_formatButton selectItemWithTag: tag];
#endif
}

#pragma mark - IBActions

-(IBAction)cancelAll:(id)sender {

    for (DownloadItem *item in _items) {
        [item cancelDownload];
    }

    [_session invalidateAndCancel];
    _session = nil;
    [_taskIndex removeAllObjects];
    [self setCurrentCount: 0];
    [self setActive: NO];

    [_tableView reloadData];
    //[_tableView setNeedsDisplay: YES]; // doesn't work...
}

- (IBAction)downloadMissing:(id)sender {

    BOOL delta = NO;
    for (DownloadItem *item in _items) {
        NSURL *url = [item localURL];
        id task = [item task];
        if (!url && !task) {
            [self downloadItem: item];
            delta = YES;
        }
    }
    
    if (delta) {
        [self setActive: YES];
        [_tableView reloadData];
    }
}
- (IBAction)showRomFolder:(id)sender {
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];

    [ws openURL: _romFolder];
}

-(IBAction)refreshROMs: (id)sender {
    
    NSString *romdir = [SupportDirectoryPath() stringByAppendingPathComponent: @"roms"];
    NSFileManager *fm = [NSFileManager defaultManager];

    for (DownloadItem *item in _items) {
        NSString *name = [item name];
        NSString *s = [romdir stringByAppendingPathComponent: name];
        NSString *path;
        path = [s stringByAppendingPathExtension: @"zip"];
        if ([fm fileExistsAtPath: path]) {
            [item setStatus: ItemFound];
            [item setLocalURL: [NSURL fileURLWithPath: path]];
            continue;
        }

        path = [s stringByAppendingPathExtension: @"7z"];
        if ([fm fileExistsAtPath: path]) {
            [item setStatus: ItemFound];
            [item setLocalURL: [NSURL fileURLWithPath: path]];
            continue;
        }


    }
    // only needed if items aren't bound.
    [_tableView reloadData];
}

- (IBAction)showInFinder:(id)sender {
    DownloadItem *item = [self clickedItem];
    if (!item) return;
    NSURL *url = [item localURL];
    if (!url) return;

    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    [ws activateFileViewerSelectingURLs: @[url]];
}

- (IBAction)download:(id)sender {
    DownloadItem *item = [self clickedItem];
    if (!item) return;

    [self downloadItem: item];
    [self setActive: YES];
    [self redrawRow: [item index]];
}
- (IBAction)cancel:(id)sender {
    DownloadItem *item = [self clickedItem];
    if (!item) return;

    [item cancelDownload];
    [self redrawRow: [item index]];
}

// binding screws up with placeholder.
-(IBAction)downloadURLChanged: (NSTextField *)sender {
    NSString *value;
    value = [sender stringValue];
    if (![value length]) {
        [_defaults removeObjectForKey: kDownloadURL];
        _downloadURL = _defaultDownloadURL;
        return;
    }
//    [self validateURL: value];
    [_defaults setValue: value forKey: kDownloadURL];
    _downloadURL = [NSURL URLWithString: value];
}
- (IBAction)downloadExtensionChanged:(id)sender {
    [_defaults setValue: _downloadExtension forKey: kDownloadExtension];
}

#pragma mark - NSURLSessionDelegate

static NSInteger TaskStatusCode(NSURLSessionTask *task) {
    NSURLResponse *response = [task response];
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        return [(NSHTTPURLResponse *)response statusCode];
    }
    return -1;
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {


    if (error) NSLog(@"Download error: %@", error);

    NSInteger statusCode = TaskStatusCode(task);
    if (!error && statusCode != 200) {
        // treat as an error.
        NSDictionary *info = @{
            NSURLErrorKey: [[task originalRequest] URL],
            NSLocalizedDescriptionKey: [NSHTTPURLResponse localizedStringForStatusCode: statusCode],
        };
        error = [NSError errorWithDomain: NSURLErrorDomain code: NSURLErrorFileDoesNotExist userInfo: info];
    }

    
    // not sure if strictly necessary but this happens in a background thread
    // and these are used in KVO binding.  Also, main thread only
    // means no race conditions.
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if (error) {
            [self setErrorCount: self->_errorCount + 1];
        } else {
            [self setCurrentCount: self->_currentCount + 1];
        }
        NSMutableDictionary *taskIndex = self->_taskIndex;
        DownloadItem *item = [taskIndex objectForKey: task];
        [taskIndex removeObjectForKey: task];

        if ([taskIndex count] == 0) {
            [self setActive: NO];
        }
        
        if (item) {
            [item completeWithError: error];
            NSUInteger row = [item index];
            
            [self redrawRow: row];
        }
    });
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)task didFinishDownloadingToURL:(nonnull NSURL *)location {

    
//    NSLog(@"%@", task);
//    NSLog(@"%@", [task response]);
    
    if (TaskStatusCode(task) != 200) return;
    

    // need to move to the destination directory...
    // file deleted after this function returns, so can't move asynchronously.
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *src = [[task originalRequest] URL];
    NSURL *dest = [_romFolder URLByAppendingPathComponent: [src lastPathComponent]];
    NSError *error = nil;
    
    [fm moveItemAtURL: location toURL: dest error: &error];

    DownloadItem *item = [_taskIndex objectForKey: task];
    [item setLocalURL: dest];

    /*
    dispatch_async(dispatch_get_main_queue(), ^(void){


        [item setLocalURL: dest];
    }
    */
    NSLog(@"%@", src);
}

@end

@implementation DownloadWindowController (Table)

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_items count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    return [_items objectAtIndex: row];
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
 
    DownloadItem *item = [_items objectAtIndex: row];
    DownloadTableCellView *v = [tableView makeViewWithIdentifier: @"DownloadCell" owner: self];
    
    NSTextField *tf;
    NSColor *redColor = [NSColor systemRedColor];
    
    tf = [v textField];
    [[v textField] setObjectValue: [item name]];
    
    if ([item localURL]) {
        [tf setTextColor: nil];
    } else {
        [tf setTextColor: redColor];
    }
    
    tf = [v statusTextField];
    [tf setObjectValue: [item statusDescription]];
    if ([item error]) {
        [tf setTextColor: redColor];
    } else {
        [tf setTextColor: nil];
        //if ([tableView isRowSelected: row]){
            //[tf setTextColor: [NSColor whiteColor]];
        //}
    }

    if ([item task]) {
        [[v activity] startAnimation: nil];
    } else {
        [[v activity] stopAnimation: nil];
    }
    
    
    return v;
}


@end


@implementation DownloadTableCellView

@end

@implementation DownloadItem

-(void)beginDownloadWithTask:(NSURLSessionDownloadTask *)task {
    _task = task;
    _error = nil;
    if (task) _status = ItemDownloading;
}

-(void)cancelDownload {
    if (!_task) return;
    [_task cancel];
    _task = nil;
    _status = ItemCanceled;
}

-(void)completeWithError: (NSError *)error {
    _task = nil;
    if (error) {
        _error = error;
        _status = ItemError;
    } else {
        // what if there was an error moving it?
        _error = nil;
        _status = ItemDownloaded;
    }
}

-(NSString *)statusDescription {

    static NSString *Names[] = {
        @"ROM missing",
        @"ROM found",
        @"Downloading…",
        @"Downloaded",
        @"Canceled",
        @"Error"
    };
    if (_error) return [_error localizedDescription];

    if (_status > sizeof(Names)/sizeof(Names[0])) return @"Unknown";
    return Names[_status];
}

@end



@implementation DownloadWindowController (Menu)

enum {
    kOpenInFinder = 1,
    kDownload,
    kCancel,
};

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    
    if ([menuItem action] == @selector(downloadExtensionChanged:)) return YES;

    NSInteger row = [_tableView clickedRow];
    if (row < 0) return NO;
    DownloadItem *item = [_items objectAtIndex: row];
    
    NSUInteger status = [item status];
    switch([menuItem tag]) {
        case kOpenInFinder:
            return status == ItemFound || status == ItemDownloaded;
            break;
        case kDownload:
            return YES;
            //return status == ItemMissing || status == ItemError || status == ItemCanceled;
            break;
        case kCancel:
            return status == ItemDownloading;
            break;
            
    }
    return NO;
}

@end
