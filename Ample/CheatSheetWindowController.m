//
//  CheatSheetWindowController.m
//  Ample
//
//  Created by Kelvin Sherlock on 1/14/2021.
//  Copyright © 2021 Kelvin Sherlock. All rights reserved.
//

#import "CheatSheetWindowController.h"

#import <WebKit/WebKit.h>

@interface CheatSheetWindowController ()
@property (weak) IBOutlet WKWebView *webView;

@end

@interface CheatSheetWindowController (NavigationDelegate) <WKNavigationDelegate>
@end

@implementation CheatSheetWindowController

-(NSString *)windowNibName {
    return @"CheatSheet";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [_webView setHidden: YES];
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url = [bundle URLForResource: @"CheatSheet" withExtension: @"html"];
    [[[_webView configuration] preferences] setValue: @YES forKey: @"developerExtrasEnabled"];
    [_webView loadFileURL: url allowingReadAccessToURL: url];

}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    // delay to prevent flash in dark mode.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0/8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [webView setHidden: NO];
    });

}


@end
