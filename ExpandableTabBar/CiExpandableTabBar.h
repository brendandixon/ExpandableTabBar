//
//  CiExpandableTabBar.h
//
//  Copyright 2011 Brendan Dixon
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
// 
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
// 
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE
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
