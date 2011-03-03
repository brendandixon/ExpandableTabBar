//
//  CiExpandableTabBarController.h
//  concierge
//
//  Created by Brendan Dixon on 2/18/11.
//  Copyright 2011 cultured inspiration. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CiExpandableTabBar.h"

@class CiExpandableTabBarController;

const NSUInteger CiExpandableTabBarUnselected;

#pragma mark - Delegate

@protocol CiExpandableTabBarControllerDelegate <NSObject>

- (void)expandableTabBarController:(CiExpandableTabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController;
- (BOOL)expandableTabBarController:(CiExpandableTabBarController*)tabBarController shouldSelectViewController:(UIViewController*)viewController;

@end

#pragma mark - Controller

@interface CiExpandableTabBarController : UIViewController <CiExpandableTabBarDelegate> {
    
}

@property (nonatomic, assign) id<CiExpandableTabBarControllerDelegate> delegate;

@property (nonatomic, copy) NSArray* viewControllers;

@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic, assign) UIViewController* selectedViewController;

@property (nonatomic, assign) CGFloat animationDuration;

- (id)initWithViewControllers:(NSArray*)viewControllers andSelectedIndex:(NSUInteger)selectedIndex;
- (id)initWithViewControllers:(NSArray*)viewControllers;

- (void)setViewControllers:(NSArray*)viewControllers animated:(BOOL)animated;

@end
