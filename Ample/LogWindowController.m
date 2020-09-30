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

static NSURL *MameURL(void) {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSBundle *bundle = [NSBundle mainBundle];
        
    if ([defaults boolForKey: kUseCustomMame]) {
        NSString *path = [defaults stringForKey: kMamePath];
        if (![path length]) return [NSURL fileURLWithPath: path];
    }
    
    return [bundle URLForAuxiliaryExecutable: @"mame64"];

    return nil;
}

+(id)controllerForArgs: (NSArray *)args {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSURL *url = MameURL();

    if (!url) {
        NSAlert *alert = [NSAlert new];

        [alert setMessageText: @"Unable to find MAME executable path"];
        [alert runModal];
        return nil;
    }
    

    NSTask *task = [NSTask new];
    [task setExecutableURL: url];
    [task setArguments: args];

    if (![defaults boolForKey: kUseCustomMame]) {
        // run in Application Support/Ample.
        [task setCurrentDirectoryURL: SupportDirectory()];
    }
    
    return [LogWindowController controllerForTask: task];

    
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
        NSURL *url = [task executableURL];
        NSString *path = [NSString stringWithCString: [url fileSystemRepresentation] encoding: NSUTF8StringEncoding];
        NSLog(@"NSTask error. Path = %@ error = %@", path, error);
        [self appendString: path];
        [self appendString: [error description]];
        return error;
    }
    _task = task;
    NSString *title = [NSString stringWithFormat: @"Ample Log - %u", [task processIdentifier]];
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
    
    if (ok && [[NSUserDefaults standardUserDefaults] boolForKey: kAutoCloseLogWindow]) {
        
        [[self window] close];
        //[LogWindows removeObject: self]; // close sends WindowWillClose notification.
    }
}

#pragma mark - NSWindowDelegate


-(void)windowWillClose:(NSNotification *)notification {
    [LogWindows removeObject: self];
}

@end
