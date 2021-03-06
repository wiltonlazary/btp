//
//  EventAction.m
//  btp
//
//  This file is part of BTP.                                                       
//
//  BTP is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  BTP is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with BTP.  If not, see <http://www.gnu.org/licenses/>.
//
//  Copyright 2009 Project DoD Inc. All rights reserved.


#import "EventAction.h"


@implementation EventAction


@synthesize eventWindow;

- (id) init
{
	NSRect mainScreenRect = [[NSScreen mainScreen] frame];
	center.x = mainScreenRect.size.width / 2;
	center.y = mainScreenRect.size.height / 2;
	
	memset(downKeys, 0, MAX_KEY_SIZE);
	memset(upKeys, 0, MAX_KEY_SIZE);
	
	downKeysCount = 0;
	upKeysCount = 0;
	
	return self;
}


- (void) dealloc
{
    [super dealloc];
}


- (void) cleanAction
{
	memset(downKeys, 0, MAX_KEY_SIZE);
	memset(upKeys, 0, MAX_KEY_SIZE);
	
	downKeysCount = 0;
	upKeysCount = 0;
}


- (void) sendCenterClick: (NSInteger) seconds
{
        Boolean isSameProcess = FALSE;
        ProcessSerialNumber focusWindow;

        /* This should stop us from blasting input out to other windows. */
        GetFrontProcess(&focusWindow);
        SameProcess(&eventWindow, &focusWindow, &isSameProcess);

        if (!(isSameProcess))
                return;

        CGInhibitLocalEvents(TRUE);

        CGPostMouseEvent(center, TRUE, 2, FALSE, TRUE);
        usleep(seconds);
        CGPostMouseEvent(center, TRUE, 2, FALSE, FALSE);

        CGInhibitLocalEvents(FALSE);
}


- (void) go
{
		int i;
		pid_t process_pid;
		AXUIElementRef window;

		//CGInhibitLocalEvents(TRUE);
	
		GetProcessPID(&eventWindow, &process_pid);
		window = AXUIElementCreateApplication(process_pid);

        if (downKeysCount)
        {
            for (i = 0; i < downKeysCount; i++)
				AXUIElementPostKeyboardEvent(window, 0, (CGKeyCode)downKeys[i], true);
        }

        if (upKeysCount)
        {
            for (i = 0; i < upKeysCount; i++)
				AXUIElementPostKeyboardEvent(window, 0, (CGKeyCode)upKeys[i], false);
        }

        //CGInhibitLocalEvents(FALSE);
}



/* This is the say the API _should_ work, but does not.
- (void) go
{
	NSInteger i;
	Boolean pressShift = FALSE;
	Boolean pressAlt = FALSE;
	Boolean pressControl = FALSE;
	
	CGInhibitLocalEvents(TRUE);
	
	if (downKeysCount)
	{	
	    for (i = 0; i < downKeysCount; i++)
	    {
			if (downKeys[i] == 56)
			{
				pressShift = TRUE;
				continue;
			}

			if (downKeys[i] == 58)
			{
				pressAlt = TRUE;
				continue;
			}
			
			if (downKeys[i] == 59)
			{
				pressControl = TRUE;
				continue;
			}
			
			CGEventRef tmpEvent = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)downKeys[i], true);
			
		    if (tmpEvent)
		    {
				CGEventSetFlags(tmpEvent, 0);
				
				if (pressShift)
				{
					NSLog(@"SHIFT DOWN");
					CGEventSetFlags(tmpEvent, CGEventGetFlags(tmpEvent) | kCGEventFlagMaskShift);
				}
				
				if (pressAlt)
				{
					NSLog(@"ALT DOWN");
					CGEventSetFlags(tmpEvent, CGEventGetFlags(tmpEvent) | kCGEventFlagMaskAlternate);
				}
				
				if (pressControl)
				{
					NSLog(@"CTRL DOWN");
					CGEventSetFlags(tmpEvent, CGEventGetFlags(tmpEvent) | kCGEventFlagMaskControl);
				}
				
				//CGEventPost(kCGSessionEventTap, tmpEvent);
				NSLog(@"KEY DOWN: %d", downKeys[i]);
				CGEventPostToPSN(&eventWindow, tmpEvent);
			    CFRelease(tmpEvent);
		    }
			
			pressShift = FALSE;
			pressAlt = FALSE;
			pressControl = FALSE;
	    }
	}
	
	if (upKeysCount)
	{
	    for (i = 0; i < upKeysCount; i++)
	    {
			if (upKeys[i] == 56)
			{
				pressShift = TRUE;
				continue;
			}
				
			if (upKeys[i] == 58)
			{
				pressAlt = TRUE;
				continue;
			}
				
			if (upKeys[i] == 59)
			{
				pressControl = TRUE;
				continue;
			}				

			CGEventRef tmpEvent = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)upKeys[i], false);
				
			if (tmpEvent)
			{
				CGEventSetFlags(tmpEvent, 0);
				
				if (pressShift)
					CGEventSetFlags(tmpEvent, CGEventGetFlags(tmpEvent) | kCGEventFlagMaskShift);
				
				if (pressAlt)
					CGEventSetFlags(tmpEvent, CGEventGetFlags(tmpEvent) | kCGEventFlagMaskAlternate);
				
				if (pressControl)
					CGEventSetFlags(tmpEvent, CGEventGetFlags(tmpEvent) | kCGEventFlagMaskControl);

				
				//CGEventPost(kCGSessionEventTap, tmpEvent);
				CGEventPostToPSN(&eventWindow, tmpEvent);
				CFRelease(tmpEvent);
			}
			
			pressShift = FALSE;
			pressAlt = FALSE;
			pressControl = FALSE;

	    }
	}
	
	CGInhibitLocalEvents(FALSE);
}
*/

- (void) addActionDown: (CGKeyCode) key
{
	downKeys[downKeysCount] = key;
	downKeysCount++; 
}


- (void) addActionUp: (CGKeyCode) key
{
	upKeys[upKeysCount] = key;
	upKeysCount++; 
}


- (void) sendInput: (NSString *) input
{
	int i;
	
	/* Find each character, look its mapping up, and add that key
	   for a down and up press, run the go method, and back to the
	   start of the loop with a cleanAction. */
	for (i = 0; i < [input length]; i++)
	{
		[self cleanAction];

		if ([[[input substringFromIndex: i] substringToIndex: 1] compare: @"_"] == NSOrderedSame)
		{
			[self addActionDown: 56];
			[self addActionDown: [self getLetterMapping: @"-"]];
			[self addActionUp: [self getLetterMapping: @"-"]];
			[self addActionUp: 56];
		}
		else
		{
		    [self addActionDown: [self getLetterMapping: [[input substringFromIndex: i] substringToIndex: 1]]];
		    [self addActionUp: [self getLetterMapping: [[input substringFromIndex: i] substringToIndex: 1]]];
		}
		
		[self go];
	}
}


/* This function is not safe to call from more than one thread. */
- (CGKeyCode) getLetterMapping: (NSString *) matchLetter
{
	NSUInteger i;
	CGKeyCode value = 0;
	NSMutableArray *characters = [NSMutableArray arrayWithObjects:
								  @"a", @"s", @"d", @"f", @"h", @"g", @"z", @"x",
								  @"c", @"v", @"X", @"b", @"q", @"w", @"e", @"r",
								  @"y", @"t", @"1", @"2", @"3", @"4", @"6", @"5",
								  @"=", @"9", @"7", @"-", @"8", @"0", @"]", @"o",
								  @"u", @"[", @"i", @"p", @"\n",      @"l", @"j",
								  @"'", @"k", @";", @"\\",      @",", @"/", @"n",
								  @"m", @".", @"\t",      @" ", @"`", @"\b",
								  @"X", @"\e", nil];
	
    for (i = 0; i < [characters count]; i++)
	{
		if ([matchLetter compare: [characters objectAtIndex: i]] == NSOrderedSame)
		{
			value = (CGKeyCode)i;
			break;
		}
    }
	
	return value;
}


@end
