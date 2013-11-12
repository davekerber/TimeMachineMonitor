//
//  AppDelegate.m
//  TimeMachineMonitor
//
//  Created by David J Kerber on 7/20/13.
//  Copyright (c) 2013 David J Kerber. All rights reserved.
//

#import "AppDelegate.h"
#import "ServiceManagement/SMLoginItem.h"
#import "NSDate+Compare.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self createStatusBarItem];
    [self runUpdate];
    [self listenForWakeUps];
    
    
    CFStringRef bundleName = (CFStringRef) @"com.agapered.TimeMachineMonitor" ;
    
    bool changeTook = SMLoginItemSetEnabled(bundleName, YES);
    
    
    
    
}

-(void) listenForWakeUps {
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(systemWokeUp:)
                                                               name: NSWorkspaceDidWakeNotification
                                                             object: nil];
}

- (void) systemWokeUp:(id) sender {
    NSLog(@"It Woke Up!");
    [self runUpdate];
}

-(void) runUpdate {
    [self checkIfBackupCurrent];
    [self updateDisplay];
    [self scheduleNextCheck];
}

-(NSDateComponents *) backupGapTolerance {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.hour = 12 ;
    components.minute = 0;
    
    return components;
}

-(void) createStatusBarItem {
    
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    self.statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
    
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@""];
    [theMenu setAutoenablesItems:NO];
    
    self.latestBackupMenuItem = [theMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
    
    [theMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *openTimeMachineItem = [theMenu addItemWithTitle:@"Open Time Machine" action:@selector(openTimeMachine:) keyEquivalent:@"t"];
    [openTimeMachineItem setKeyEquivalentModifierMask:NSCommandKeyMask];

    NSMenuItem *startBackup = [theMenu addItemWithTitle:@"Start Backup" action:@selector(startBackup:) keyEquivalent:@"b"];
    [openTimeMachineItem setKeyEquivalentModifierMask:NSCommandKeyMask];

    
    [theMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *quitMenuItem = [theMenu addItemWithTitle:@"Quit" action:@selector(handleQuit:) keyEquivalent:@"q"];
    [quitMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
    
    
    [self.statusItem setMenu:theMenu];
}

-(void) openTimeMachine: (id) sender {
    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/TimeMachine.prefPane"];
}

-(void) startBackup: (id) sender {
    NSTask *server = [NSTask new];
    [server setLaunchPath:@"/usr/bin/tmutil"];
    [server setArguments:@[@"startbackup"]];
    [server launch];
    [server waitUntilExit];
}

-(void) updateDisplay {
    [self updateIcons];
    [self updateLatestBackupTimeInMenu];
}

-(void) updateLatestBackupTimeInMenu {
    NSString *label = [NSString stringWithFormat:@"Latest Backup %@", [self formatDate:[self latestBackupDate]]];
    
    [self.latestBackupMenuItem setTitle:label];
}

-(void) scheduleNextCheck {
    [self.checkTimer invalidate];
    NSDate *dateForNextCheck = [self dateToCheckAgain];
    NSLog(@"Checking again at %@", dateForNextCheck);
    self.checkTimer = [[NSTimer alloc] initWithFireDate:dateForNextCheck interval:0 target:self selector: @selector(timerFired:) userInfo:nil repeats:NO];
    
    NSRunLoop * theRunLoop = [NSRunLoop currentRunLoop];
    [theRunLoop addTimer:self.checkTimer forMode:NSDefaultRunLoopMode];
}

-(void) timerFired:(NSTimer*) timer {
    NSLog(@"Timer Fired at %@", [NSDate date]);
    [self runUpdate];
}

-(void) updateIcons {
    NSImage *primaryImage = nil ;
    NSImage *alternateImage = nil ;
    NSString *tooltip = nil ;
    if( self.backupCurrent ){
        alternateImage = [NSImage imageNamed:@"plus1.png"];
        tooltip = @"All is well with your backups";
    } else {
        primaryImage = [NSImage imageNamed:@"cold_sweat.png"];
        alternateImage = [NSImage imageNamed:@"cold_sweat2.png"];
        tooltip = @"You need a backup!";
    }
    [alternateImage setTemplate:YES];
    [self.statusItem setImage:primaryImage];
    [self.statusItem setAlternateImage:alternateImage];
    [self.statusItem setToolTip: tooltip];
}

-(void) handleQuit:(id) sender {
    [NSApp terminate: self];
}

-(void) checkIfBackupCurrent {
    NSDate *latestBackup = [self latestBackupDate];
    NSDate *dateBackupMustBeAfter = [self dateBackupMustBeAfter];
    self.backupCurrent = [latestBackup isLaterThanOrEqualTo:dateBackupMustBeAfter];
    NSLog(@"Now is %@", [NSDate date]);
    NSLog(@"Latest Backup at %@ , must be backed up after %@", latestBackup, dateBackupMustBeAfter);
}

-(NSDate *) dateToCheckAgain {
    if( self.backupCurrent ){
        return [[self calendar] dateByAddingComponents:[self backupGapTolerance] toDate:[self latestBackupDate] options:0];
    } else {
        NSDateComponents *tenMinutes = [[NSDateComponents alloc] init];
        [tenMinutes setMinute:2];
        NSDate *later = [[self calendar] dateByAddingComponents:tenMinutes toDate:[NSDate date] options:0];
        return later ;
    }
}

-(NSDate *) dateBackupMustBeAfter {
    return [[self calendar] dateByAddingComponents:[self timeToLookBackward] toDate:[NSDate date] options:0];
}

-(NSDateComponents *) timeToLookBackward {
    NSDateComponents *timeToLookBackward = [self backupGapTolerance];
    if( timeToLookBackward.minute ){
        timeToLookBackward.minute = timeToLookBackward.minute * -1 ;
    }
    if( timeToLookBackward.hour ){
        timeToLookBackward.hour = timeToLookBackward.hour * -1 ;
    }
    return timeToLookBackward;
}

-(NSDate *) latestBackupDate {
    //TODO:  Check for no entries, or multiple entries
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:@"/Library/Preferences/com.apple.TimeMachine.plist"];
    
    NSArray *destinations = [dictionary objectForKey:@"Destinations"];
    NSDictionary *firstDestination = [destinations objectAtIndex:0];
    
    NSArray *snapshots = [firstDestination objectForKey:@"SnapshotDates"];

    NSDate *dateString = [snapshots lastObject];
    
    
//    NSDate *dateString = [firstDestination objectForKey:@"BACKUP_COMPLETED_DATE"]; //is a __NSTaggedDate
    NSDate *theDate = [[NSDate alloc] initWithTimeInterval:0 sinceDate:dateString];
    return theDate;
}

-(NSCalendar *) calendar {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [calendar setTimeZone:[NSTimeZone defaultTimeZone]];
    return calendar;
}

-(NSString *) formatDate:(NSDate*) date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM dd 'at' h:mm a"];
    [formatter setTimeZone:[NSTimeZone defaultTimeZone]];
    return [formatter stringFromDate: date];
}

@end

/*
 
 http://developer.apple.com/library/mac/#documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLoginItems.html
 - (BOOL)isAppSetToRunAtLogon {
 int ret = [UKLoginItemRegistry indexForLoginItemWithPath:[[NSBundle mainBundle] bundlePath]];
 return (ret >= 0);
 }
 
 - (void) runAtLogon
 {
 [UKLoginItemRegistry addLoginItemWithPath:[[NSBundle mainBundle] bundlePath] hideIt: NO];
 }
 
 - (void) removeFromLogon
 {
 [UKLoginItemRegistry removeLoginItemWithPath:[[NSBundle mainBundle] bundlePath]];
 }
 */
