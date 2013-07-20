//
//  AppDelegate.m
//  TimeMachineMonitor
//
//  Created by David J Kerber on 7/20/13.
//  Copyright (c) 2013 David J Kerber. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
//    NSStatusItem *statusItem;

    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    self.statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
    
    if([self statusItem]) {
//        NSLog(@"%@", [self statusItem]);
        NSImage *theIconImage = [NSImage imageNamed:@"Icon1.png"] ;
        [self.statusItem setImage: theIconImage];
//        [[self statusItem] setTitle:@"My Item"];
        NSLog(@"%@", theIconImage);
        [self.statusItem setToolTip:@"My Tooltip!"];
        
        NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@""];
        [theMenu setAutoenablesItems:NO];

        [theMenu addItemWithTitle:@"One" action:nil keyEquivalent:@""];
        [theMenu addItemWithTitle:@"Two" action:nil keyEquivalent:@""];
        [theMenu addItemWithTitle:@"Three" action:nil keyEquivalent:@""];
        [theMenu addItem:[NSMenuItem separatorItem]];
        NSMenuItem *tItem = [theMenu addItemWithTitle:@"Quit" action:@selector(handleQuit:) keyEquivalent:@"q"];
        [tItem setKeyEquivalentModifierMask:NSCommandKeyMask];
        
        [self.statusItem setMenu:theMenu];
    }
 
    
    
}

-(void) handleQuit:(id) sender {
    [NSApp terminate: self];
}

@end
