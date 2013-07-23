//
//  NSDate+Compare.h
//  TimeMachineMonitor
//
//  Created by David J Kerber on 7/21/13.
//  Copyright (c) 2013 David J Kerber. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Compare)

-(BOOL) isLaterThanOrEqualTo:(NSDate*)date;
-(BOOL) isEarlierThanOrEqualTo:(NSDate*)date;
-(BOOL) isLaterThan:(NSDate*)date;
-(BOOL) isEarlierThan:(NSDate*)date;
//- (BOOL)isEqualToDate:(NSDate *)date; already part of the NSDate API

@end