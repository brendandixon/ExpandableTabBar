//
//  UIView+CulturedInspiration.m
//  concierge
//
//  Created by Brendan Dixon on 2/20/11.
//  Copyright 2011 cultured inspiration. All rights reserved.
//

#import "UIView+CulturedInspiration.h"


@implementation UIView(CulturedInspiration)

- (void)removeSubviews {
  for (UIView* view in self.subviews.copy) {
    [view removeFromSuperview];
  }
}

@end
