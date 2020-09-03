//
//  DownloadWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 9/2/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "Ample.h"
#import "DownloadWindowController.h"

@interface DownloadWindowController ()

@end

@implementation DownloadWindowController {
    
    NSArray *_roms;
    NSURL *_romFolder;
    NSURL *_sourceURL;
    NSURLSession *_session;
    NSMutableSet *_tasks;
}

-(NSString *)windowNibName {
    return @"DownloadWindow";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    NSError *error = nil;
    NSBundle *bundle = [NSBundle mainBundle];
    NSFileManager *fm = [NSFileManager defaultManager];

    NSURL *url = [bundle URLForResource: @"roms" withExtension: @"plist"];
    
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL: url];
    
    NSURL *sd = SupportDirectory();
    _romFolder = [sd URLByAppendingPathComponent: @"roms"];
    
    [fm createDirectoryAtURL: _romFolder withIntermediateDirectories: YES attributes: nil error: &error];


    _roms = [d objectForKey: @"roms"];
    [self setCurrentROM: @""];
    [self setCurrentCount: 0];
    [self setTotalCount: [_roms count]];
    [self setErrorCount: 0];
    _sourceURL = [NSURL URLWithString: @"https://archive.org/download/mame0224_rom"]; // hardcoded....
    
    
    [self download];
}

-(void)download {
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration: config delegate: self delegateQueue: nil];
    _tasks = [NSMutableSet setWithCapacity: [_roms count]];

    // run in thread?
    //unsigned count = 0;
    for (NSString *s in _roms) {
            
        NSURLSessionDownloadTask *task;
        NSString *path = [s stringByAppendingString: @".7z"]; // hardcoded.
        NSURL *url = [_sourceURL URLByAppendingPathComponent: path];
        
        task = [_session downloadTaskWithURL: url];
        [_tasks addObject: task];
        [task resume];
        
        //++count;
        //if (count >= 2) break;
    }
    [self setActive: YES];
    
}

-(IBAction)cancel:(id)sender {
    
    for (NSURLSessionTask *task in _tasks) {
        [task cancel];
    }
    [_session invalidateAndCancel];
    _session = nil;
    _tasks = nil;
    [self setCurrentCount: 0];
    [self setActive: NO];
    
}


#pragma mark - NSURLSessionDelegate

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {


    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        if (error)
            [self setErrorCount: self->_errorCount + 1];
        else
            [self setCurrentCount: self->_currentCount + 1];
        [self->_tasks removeObject: task];
        if (![self->_tasks anyObject]) {
            [self setActive: NO];
        }
    });
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {


    // need to move to the destination directory...
    // file deleted after this function returns, so can't move asynchronously.
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *src = [[downloadTask originalRequest] URL];
    NSURL *dest = [_romFolder URLByAppendingPathComponent: [src lastPathComponent]];
    NSError *error = nil;
    
    [fm moveItemAtURL: location toURL: dest error: &error];

    NSLog(@"%@", src);
}
@end

