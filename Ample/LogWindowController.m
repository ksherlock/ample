//
//  LogWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/29/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "Ample.h"
#import "LogWindowController.h"

static NSMutableSet *LogWindows;

@interface LogWindowController ()
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation LogWindowController {
    NSTask *_task;
    NSFileHandle *_handle;
    NSFont *_font;

    BOOL _close;
    BOOL _eof;
}

+(void)initialize {
    LogWindows = [NSMutableSet set];
}

-(NSString *)windowNibName {
    return @"LogWindow";
}


+(id)controllerForTask: (NSTask *)task close: (BOOL)close {
    LogWindowController *controller = [[LogWindowController alloc] initWithWindowNibName: @"LogWindow"];
    [controller runTask: task close: close];
    return controller;
}


+(id)controllerForArgs: (NSArray *)args close: (BOOL)close {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSURL *url = MameURL();

    if (!url) {
        NSAlert *alert = [NSAlert new];

        [alert setMessageText: @"Unable to find MAME executable path"];
        [alert runModal];
        return nil;
    }
    
    NSTask *task = [NSTask new];
    
    if (@available(macOS 10.13, *)) {
        [task setExecutableURL: url];
        [task setCurrentDirectoryURL: MameWorkingDirectory()];
    } else {
        [task setLaunchPath: MamePath()];
        [task setCurrentDirectoryPath: MameWorkingDirectoryPath()];
    }
    
    [task setArguments: args];
    
    if ([defaults boolForKey: kUseLogWindow] == NO) {

        NSAlert *alert = nil;
        if (@available(macOS 10.13, *)) {
            NSError *error = nil;

            [task launchAndReturnError: &error];
            if (error) {
                alert = [NSAlert alertWithError: error];
            }
        } else {
            @try {
                [task launch];
            } @catch (NSException *exception) {

                alert = [NSAlert new];
                [alert setMessageText: [exception reason]];
            }
        }
        if (alert) [alert runModal];
        return nil;
    }
    
    
    return [LogWindowController controllerForTask: task close: close];

}

+(id)controllerForArgs: (NSArray *)args {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL close = [defaults boolForKey: kAutoCloseLogWindow];
    return [self controllerForArgs: args close: close];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [LogWindows addObject: self];

    _font = [NSFont userFixedPitchFontOfSize: 0];
    
}

-(void)appendString: (NSString *)string
{
    if ([string length])
    {
        // needs explicit color attribute for proper dark mode support.
        NSDictionary *attr = @{
            NSForegroundColorAttributeName: [NSColor textColor],
            NSFontAttributeName: _font,
        };
        NSAttributedString *astr = [[NSAttributedString alloc] initWithString: string attributes: attr];
        [[_textView textStorage] appendAttributedString: astr];
    }
}

-(void)appendAttributedString: (NSAttributedString *)string {
    
    if ([string length]) {
        [[_textView textStorage] appendAttributedString: string];
    }
}

-(NSError *)runTask: (NSTask *)task close: (BOOL)close {
    
    
    if (_task) return nil;
    _close = close;
    _eof = NO;

    NSPipe *pipe = [NSPipe pipe];
    
    // window not yet loaded until [self window] called.

    const char *path = nil;
    const char *wd = nil;
    
    
    [task setStandardError: pipe];
    [task setStandardOutput: pipe];
    if (@available(macOS 10.13, *)) {
        NSError *error = nil;
        path = [[task executableURL] fileSystemRepresentation];
        wd = [[task currentDirectoryURL] fileSystemRepresentation];

        [task launchAndReturnError: &error];
        if (error) {
            NSLog(@"NSTask error. Path = %s error = %@", path, error);
            return error;
        }
    } else {
        path = [[task launchPath] fileSystemRepresentation];
        wd = [[task currentDirectoryPath] fileSystemRepresentation];
        @try {
            [task launch];
        } @catch (NSException *exception) {

            NSLog(@"NSTask exception.  Path = %s exception = %@", path, exception);
            return nil; // ?
        }
    }

    _task = task;
    NSString *title = [NSString stringWithFormat: @"Ample Log - %u", [task processIdentifier]];
    [[self window] setTitle: title];
    _handle = [pipe fileHandleForReading];

    if (path) [self appendString: [NSString stringWithFormat: @"MAME path: %s\n", path]];
    if (wd) [self appendString: [NSString stringWithFormat: @"Working Directory: %s\n", wd]];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];


    [nc addObserver: self
           selector: @selector(taskComplete:)
               name: NSTaskDidTerminateNotification
             object: _task];
    [nc addObserver: self
           selector: @selector(readComplete:)
               name: NSFileHandleReadCompletionNotification
             object: _handle];
    
    [_handle readInBackgroundAndNotify];

    [[self window] setDocumentEdited: YES];
    return nil;
}


#pragma mark -
#pragma mark Notifications
-(void)readComplete:(NSNotification *)notification
{
    // read complete, queue up another.
    NSDictionary *dict = [notification userInfo];
    NSData *data = [dict objectForKey: NSFileHandleNotificationDataItem];

    if ([data length])
    {
        NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        
        [self appendString: string];
        
        [_handle readInBackgroundAndNotify];
    } else {
        [self appendString: @"\n"]; // -listmedia sometimes causes display issues.
        _eof = YES;
        //[_textView setNeedsDisplay: YES]; // -listmedia sometimes weird.
    }
}

-(void)taskCompleteHack {

}

/* hask! task complete may occur while output still being processed. add a delay to compensate. */
-(void)taskComplete: (NSNotification *)notification
{
    if (!_eof) {
        [self performSelector: @selector(taskComplete:) withObject: notification afterDelay: 0.5];
        return;
    }

    BOOL ok = NO;
    NSTaskTerminationReason reason;
    int status;
    NSString *string = nil;
    
    reason = [_task terminationReason];
    status = [_task terminationStatus];
    
    if (reason == NSTaskTerminationReasonExit)
    {
        
        if (status == 0)
        {
            //string = @"\n\n[Success]\n\n";
            ok = YES;
        }
        else string = @"\n\n[An error occurred]\n\n";
    }
    else
    {
        string = [NSString stringWithFormat: @"\n\n[Caught signal %d (%s)]\n\n", status, strsignal(status)];
    }
    if (string) {
        NSDictionary *attr = @{
            NSForegroundColorAttributeName: [NSColor systemRedColor],
            NSFontAttributeName: _font,
        };
        NSAttributedString *astr = [[NSAttributedString alloc] initWithString: string attributes: attr];
        [self appendAttributedString: astr];
    }

    _handle = nil;
    _task = nil;
    
    [[self window] setDocumentEdited: NO];
    
    if (ok && _close) {
        [[self window] close];
    }
}

#pragma mark - NSWindowDelegate


-(void)windowWillClose:(NSNotification *)notification {
    [LogWindows removeObject: self];
}

#pragma mark - IBActions

- (IBAction)clearLog:(id)sender {
    NSAttributedString *empty = [NSAttributedString new];
    [[_textView textStorage] setAttributedString: empty];
}


@end
