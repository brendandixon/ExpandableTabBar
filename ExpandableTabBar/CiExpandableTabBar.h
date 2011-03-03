//
//  CiExpandableTabBar.h
//  concierge
//
//  Created by Brendan Dixon on 2/19/11.
//  Copyright 2011 cultured inspiration. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class CiExpandableTabBar;

@protocol CiExpandableTabBarDelegate <NSObject>

- (BOOL)expandableTabBar:(CiExpandableTabBar*)expandableTabBar shouldSelectItem:(UITabBarItem*)item;
- (void)expandableTabBar:(CiExpandableTabBar*)expandableTabBar didSelectItem:(UITabBarItem*)item;

@end


@interface CiExpandableTabBar : UIView {
}

@property (nonatomic, assign) id<CiExpandableTabBarDelegate> delegate;

@property (nonatomic, copy) NSArray* items;
@property (nonatomic, assign) UITabBarItem* selectedItem;

@property (nonatomic, readonly) NSUInteger rows;
@property (nonatomic, readonly) NSUInteger rowHeight;

@property (nonatomic, retain) UITabBarItem* moreTabBarItem;

@property (nonatomic, assign) NSUInteger spacing;
@property (nonatomic, retain) UIImage* selectedBackgroundImage;

- (void)highlightMoreItem:(BOOL)highlighted;
- (void)setItems:(NSArray*)items animated:(BOOL)animated;

@end
