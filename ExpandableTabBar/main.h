//
//  main.h
//  concierge
//
//  Created by Brendan Dixon on 2/14/11.
//  Copyright 2011 cultured inspiration. All rights reserved.
//

#import "UIImage+CulturedInspiration.h"
#import "UIView+CulturedInspiration.h"

#pragma mark -
#pragma mark Macros

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#   define DEnter() DLog(@"ENTER")
#   define DExit() DLog(@"EXIT")
#else
#   define DLog(...)
#   define DEnter()
#   define DExit()
#endif

#define CITrace	DLog()

// ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
