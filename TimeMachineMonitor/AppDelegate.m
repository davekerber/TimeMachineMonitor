//
//  AppDelegate.m
//  TimeMachineMonitor
//
//  Created by David J Kerber on 7/20/13.
//  Copyright (c) 2013 David J Kerber. All rights reserved.
//

#import "AppDelegate.h"
#import "NSDate+Compare.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self createStatusBarItem];
    [self checkIfBackupCurrent];
    [self updateDisplay];
    [self scheduleNextCheck];
    

    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(makeWake:)
                                                               name: NSWorkspaceDidWakeNotification
                                                             object: nil];
}

- (void) makeWake:(id) sender {
    NSLog(@"It Woke Up!");
}

-(NSDateComponents *) backupGapTolerance {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.hour = 0 ;
    components.minute = 2;
    
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
    
    [theMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *quitMenuItem = [theMenu addItemWithTitle:@"Quit" action:@selector(handleQuit:) keyEquivalent:@"q"];
    [quitMenuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
    
    
    [self.statusItem setMenu:theMenu];
}

-(void) openTimeMachine: (id) sender {
    [[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/TimeMachine.prefPane"];
}

-(void) updateDisplay {
    [self updateIcons];
    [self updateLatestBackupTimeInMenu];
}

-(void) updateLatestBackupTimeInMenu {
    NSString *label = [NSString stringWithFormat:@"Latest Backup %@", [self formatDate:[self latestBackupDate]]]
    ;
    
    [self.latestBackupMenuItem setTitle:label];
}

-(void) scheduleNextCheck {
    NSDate *dateForNextCheck = [self dateToCheckAgain];
    NSLog(@"Checking again at %@", dateForNextCheck);
    NSTimer *timer = [[NSTimer alloc] initWithFireDate:dateForNextCheck interval:0 target:self selector: @selector(timerFired:) userInfo:nil repeats:NO];
    
    NSRunLoop * theRunLoop = [NSRunLoop currentRunLoop];
    [theRunLoop addTimer:timer forMode:NSDefaultRunLoopMode];
}

-(void) timerFired:(NSTimer*) timer {
    NSLog(@"Timer Fired at %@", [NSDate date]);
    [self checkIfBackupCurrent];
    [self updateDisplay];
    [self scheduleNextCheck];
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
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    NSDate *lastBackupDate = [dateFormatter dateFromString:[self getLatestBackupTimeString]];
    
    NSCalendar *gregorian = [self calendar];
    NSDateComponents *calendarComponents =
    [gregorian components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:lastBackupDate];
    
    
    NSInteger currentMonth = [self getCurrentMonth];
    NSInteger currentYear = [self getCurrentYear];
    NSInteger lastBackupMonth = [calendarComponents month];
    NSInteger lastBackupYear = currentYear ;
    if(currentMonth < lastBackupMonth){
        lastBackupYear = currentYear - 1 ;
    }
    [calendarComponents setYear:lastBackupYear];
    NSDate *lastBackupDateWithYear = [[self calendar] dateFromComponents:calendarComponents];
    
    return lastBackupDateWithYear ;
}

-(NSInteger) getCurrentMonth {
    return [[self calendarComponents:NSMonthCalendarUnit fromDate:[NSDate date]] month];
}

-(NSInteger) getCurrentYear {
    return [[self calendarComponents:NSYearCalendarUnit fromDate:[NSDate date]] year];
}

-(NSDateComponents *) calendarComponents:(NSUInteger)components fromDate:(NSDate*)date {
    return [[self calendar] components:components fromDate:date];
}

-(NSCalendar *) calendar {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [calendar setTimeZone:[NSTimeZone defaultTimeZone]];
    return calendar;
}

-(NSString*) getLatestBackupTimeString {
    NSTask *server = [NSTask new];
    [server setLaunchPath:@"/bin/sh"];
    [server setArguments:[NSArray arrayWithObjects:@"-c", @"grep 'com\\.apple\\.backupd.*Backup\\scompleted\\ssuccessfully' /var/log/system.log | tail -n 1 | cut -d ' ' -f1 -f2 -f3", nil]];
    NSPipe *outputPipe = [NSPipe pipe];
    [server setStandardInput:[NSPipe pipe]];
    [server setStandardOutput:outputPipe];
    [server launch];
    [server waitUntilExit];

    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    return [outputString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(NSString *) formatDate:(NSDate*) date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM dd 'at' h:mm a"];
    [formatter setTimeZone:[NSTimeZone defaultTimeZone]];
    return [formatter stringFromDate: date];
}

@end

/** 
 This has the last backup time in it
open  /Library/Preferences/com.apple.TimeMachine.plist
*/

/**
 Command to get the last successfuly backup time:
 grep 'com\.apple\.backupd.*Backup\scompleted\ssuccessfully' /var/log/system.log | tail -n 1 | cut -d ' ' -f1 -f2 -f3
*/

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
