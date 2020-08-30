//
//  LogWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/29/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "LogWindowController.h"

static NSMutableSet *LogWindows;

@interface LogWindowController ()
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation LogWindowController {
    NSTask *_task;
    NSFileHandle *_handle;
}

+(void)initialize {
    LogWindows = [NSMutableSet set];
}

-(NSString *)windowNibName {
    return @"LogWindow";
}


+(id)controllerForTask: (NSTask *)task {
    LogWindowController *controller = [[LogWindowController alloc] initWithWindowNibName: @"LogWindow"];
    [controller runTask: task];
    return controller;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [LogWindows addObject: self];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)appendString: (NSString *)string
{
    if ([string length])
    {
        [[[_textView textStorage] mutableString] appendString: string];
    }
}

-(NSError *)runTask: (NSTask *)task {
    
    
    if (_task) return nil;

    NSError *error = nil;
    NSPipe *pipe = [NSPipe pipe];

    [task setStandardError: pipe];
    [task setStandardOutput: pipe];
    [task launchAndReturnError: &error];
    

    if (error) {
        NSLog(@"launchAction: %@", error);
        [self appendString: [error description]];
        return error;
    }
    _task = task;
    NSString *title = [NSString stringWithFormat: @"Log Window - %u", [task processIdentifier]];
    [[self window] setTitle: title];
    _handle = [pipe fileHandleForReading];
    
    
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
    }
    
}

-(void)taskComplete: (NSNotification *)notification
{
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
            string = @"\n\n[Success]\n\n";
            ok = YES;
        }
        else string = @"\n\n[An error occurred]\n\n";
    }
    else
    {
        string = @"\n\n[Caught signal]\n\n";
        
    }
    
    [self appendString: string];
    
    _handle = nil;
    _task = nil;
    
    [[self window] setDocumentEdited: NO];
    
    if (ok && [[NSUserDefaults standardUserDefaults] boolForKey: @"AutoCloseLogWindow"]) {
        
        [[self window] close];
        //[LogWindows removeObject: self]; // close sends WindowWillClose notification.
    }
}

#pragma mark - NSWindowDelegate


-(void)windowWillClose:(NSNotification *)notification {
    [LogWindows removeObject: self];
}

@end
