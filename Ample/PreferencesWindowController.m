//
//  PreferencesWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 8/31/2020.
//  Copyright © 2020 Kelvin Sherlock. All rights reserved.
//

#import "Ample.h"
#import "PreferencesWindowController.h"

#import <Security/Security.h>


@interface PreferencesWindowController ()
@property (weak) IBOutlet NSTextField *pathField;
@property (weak) IBOutlet NSTextField *wdField;
@property (weak) IBOutlet NSButton *fixButton;

@end

@implementation PreferencesWindowController

-(NSString *)windowNibName {
    return @"Preferences";
}

- (void)windowDidLoad {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    [self validateMamePath: [defaults stringForKey: kMamePath]];
    [self validateMameWD: [defaults stringForKey: kMameWorkingDirectory]];

    /* check vmnet_helper permissions */
    
    int needs_fixin = [self checkHelperPermissions: nil];
    [_fixButton setEnabled: needs_fixin > 0];
}

-(void)validateMamePath: (NSString *)path {
    NSFileManager * fm = [NSFileManager defaultManager];

    if ([path length] == 0 || [fm isExecutableFileAtPath: path]) {
        [_pathField setTextColor: nil];
    } else {
        [_pathField setTextColor: [NSColor systemRedColor]];
    }
}

-(void)validateMameWD: (NSString *)path {
    NSFileManager * fm = [NSFileManager defaultManager];
    BOOL directory = YES;
    
    if ([path length] == 0) {
        [_wdField setTextColor: nil];
        return;
    }
    
    if ([fm fileExistsAtPath: path isDirectory: &directory] && directory) {
        [_wdField setTextColor: nil];
        return;

    }
    [_wdField setTextColor: [NSColor systemRedColor]];
}

- (IBAction)pathChanged:(id)sender {

    NSString *path = [sender stringValue];
    
    [self validateMamePath: path];

}
- (IBAction)wdChanged:(id)sender {

    NSString *path = [sender stringValue];
    
    [self validateMameWD: path];
}

// -1 - error
// 1 - needs help
// 0 - a-ok
-(int)checkHelperPermissions: (NSString *)path {

    static const unsigned Mask = S_ISUID | S_ISGID;
    if (!path) {
        NSBundle *bundle = [NSBundle mainBundle];
        path = [bundle pathForAuxiliaryExecutable: @"vmnet_helper"];
    }
    if (!path) return -1;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSDictionary *attr = [fm attributesOfItemAtPath: path error: &error];
    
    if (error) return -1;

    NSNumber *owner = [attr objectForKey: NSFileOwnerAccountID];
    NSNumber *perm = [attr objectForKey: NSFilePosixPermissions];
    if ([owner longValue] == 0 && ([perm unsignedIntValue] & Mask) == Mask) return 0;
    return 1;
}

- (IBAction)fixPerms:(id)sender {

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForAuxiliaryExecutable: @"vmnet_helper"];
    if (!path) return;
    
    
#if 0
    // this requires an entitlement and sanboxing and Apple's permission.
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    
    [ws requestAuthorizationOfType:NSWorkspaceAuthorizationTypeSetAttributes
                 completionHandler: ^(NSWorkspaceAuthorization *a, NSError *e){
        if (e || !a) return;

        NSError *error = nil;
        NSDictionary *attr = @{
            NSFileOwnerAccountID: @0, /* root */
            NSFileGroupOwnerAccountID: @20, /* staff */
//            NSFilePosixPermissions: @0106755 /* 755 + setuid + setgid */
        };


        
        NSFileManager *fm = [NSFileManager fileManagerWithAuthorization: a];
        [fm setAttributes: attr ofItemAtPath: path error: &error];
        if (error) {
            NSLog(@"%@", error);
//            NSAlert *a = [NSAlert alertWithError: error];
//            [a runModal];
        }
        else {
            [self->_fixButton setEnabled: NO];
        }
        
    }];
#endif

    // AuthorizationExecuteWithPrivileges - deprecated in 10.7
    // https://github.com/sveinbjornt/STPrivilegedTask
    // XMJobBless + launchd stuff - the preferred way to do it...
    // https://developer.apple.com/library/archive/samplecode/BetterAuthorizationSample/Introduction/Intro.html
    // https://developer.apple.com/library/archive/samplecode/SMJobBless/Listings/ReadMe_txt.html#//apple_ref/doc/uid/DTS40010071-ReadMe_txt-DontLinkElementID_3
    //
    // really should be a launchd service but that's for another time...
   
    AuthorizationRef myAuthorizationRef = 0;
    OSStatus myStatus = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &myAuthorizationRef);
    if (myStatus) return;

    AuthorizationItem myItems[1] = {{0}};
    myItems[0].name = kAuthorizationRightExecute;
    myItems[0].valueLength = 0;
    myItems[0].value = NULL;
    myItems[0].flags = 0;
    AuthorizationRights myRights = {0};
    myRights.count = sizeof(myItems) / sizeof(myItems[0]);
    myRights.items = myItems;
    AuthorizationFlags myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed |
                                 kAuthorizationFlagExtendRights | kAuthorizationFlagPreAuthorize;
    myStatus = AuthorizationCopyRights(myAuthorizationRef, &myRights,
                                                             kAuthorizationEmptyEnvironment, myFlags, NULL);

    if (!myStatus) {
        FILE *fp = NULL;
        static char buffer[4096];
        const char *cp = [path fileSystemRepresentation];
        const char* args_chown[] = {"root", cp , NULL};
        const char* args_chmod[] = {"+s", cp, NULL};
        
        // well ... the second command executes a lot more consistently when the (optional) fp is provided and the we fgets the buffer.
        myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, "/usr/sbin/chown", kAuthorizationFlagDefaults, (char**)args_chown, &fp);
        fgets(buffer, sizeof(buffer), fp);
        fclose(fp);
//        fprintf(stderr, "myStatus = %d\ndata: %s\n", myStatus, buffer);

        myStatus = AuthorizationExecuteWithPrivileges(myAuthorizationRef, "/bin/chmod", kAuthorizationFlagDefaults, (char**)args_chmod, &fp);
        fgets(buffer, sizeof(buffer), fp);
        fclose(fp);
//        fprintf(stderr, "myStatus = %d\ndata: %s\n", myStatus, buffer);

    }
    AuthorizationFree(myAuthorizationRef, kAuthorizationFlagDestroyRights);
    
    int needs_fixin = [self checkHelperPermissions: path];
    [_fixButton setEnabled: needs_fixin > 0];
}


@end
