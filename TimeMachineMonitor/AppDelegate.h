//
//  AppDelegate.h
//  TimeMachineMonitor
//
//  Created by David J Kerber on 7/20/13.
//  Copyright (c) 2013 David J Kerber. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) NSStatusItem *statusItem;
@property (strong) NSMenuItem *latestBackupMenuItem;
@property (strong) NSTimer *checkTimer ;
@property BOOL backupCurrent ;

@end
