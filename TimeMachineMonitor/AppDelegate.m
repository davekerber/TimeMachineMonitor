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
    NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
    self.statusItem = [statusBar statusItemWithLength:NSSquareStatusItemLength];
    
    if([self statusItem]) {
        NSImage *theIconImage = [NSImage imageNamed:@"Icon1.png"] ;
        [self.statusItem setImage: theIconImage];
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
//        NSLog(@"%@", [self getLatestBackupTimeString]);
        NSLog(@"%@", [self latestBackupDate]);
    }
}



-(void) handleQuit:(id) sender {
    [NSApp terminate: self];
}

-(NSDate *) currentDate {
    return [NSDate date] ;
}

-(NSDate *) latestBackupDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM dd HH:mm:ss"];
    NSDate *lastBackupDate = [dateFormatter dateFromString:[self getLatestBackupTimeString]];
    
    NSCalendar *gregorian = [self calendar];
    NSDateComponents *calendarComponents =
    [gregorian components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:lastBackupDate];
    
    NSLog(@"%ld %ld %ld:%ld", [calendarComponents day], [calendarComponents month], [calendarComponents hour], [calendarComponents minute]);
    
    NSInteger currentMonth = [self getCurrentMonth];
    NSInteger currentYear = [self getCurrentYear];
    NSInteger lastBackupMonth = [calendarComponents month];
    NSInteger lastBackupYear = currentYear ;
    if(currentMonth < lastBackupMonth){
        lastBackupYear = currentYear - 1 ;
    }
    [calendarComponents setYear:lastBackupYear];
    NSDate *lastBackupDateWithYear = [[self calendar] dateFromComponents:calendarComponents];
    NSLog(@"Last backup with year %@", lastBackupDateWithYear);
    

    
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
    return [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
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

@end

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
