//
//  UIImage+CulturedInspiration.h
//  concierge
//
//  Created by Brendan Dixon on 2/20/11.
//  Copyright 2011 cultured inspiration. All rights reserved.
//
//  See http://idevrecipes.com/2011/01/04/how-does-the-twitter-iphone-app-implement-a-custom-tab-bar/
//  See also http://stackoverflow.com/questions/1355480/preventing-a-uitabbar-from-applying-a-gradient-to-its-icon-images
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


@interface UIImage(CulturedInspiration)

+ (UIImage*)imageFromColor:(UIColor*)color withSize:(CGSize)size;
+ (UIImage*)imageFromImage:(UIImage*)image withSize:(CGSize)size;

- (UIImage*)alphaMask;

@end
