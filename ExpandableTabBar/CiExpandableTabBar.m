//
//  CiExpandableTabBar.m
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

#import "CiExpandableTabBar.h"

// Layout is broken down into phases, allowing for minimal updates
enum CiExpandableTabBarLayout {
  CiExpandableTabBarLayoutNone            = 0,

  CiExpandableTabBarLayoutItemImages      = 1 << 0,
  CiExpandableTabBarLayoutDimensions      = 1 << 1,
  CiExpandableTabBarLayoutBackgroundImage = 1 << 2,
  CiExpandableTabBarLayoutItemViews       = 1 << 3,
  CiExpandableTabBarLayoutItemViewsParent = 1 << 4,
  
  CiExpandableTabBarLayoutAll             = NSUIntegerMax
};

// The amount of padding added to all sides so that edges remain clean during rotation
const CGFloat CiExpandableTabBarPadding = 5.0;

// The default spacing around a single tab bar item
const CGFloat CiExpandableTabBarDefaultSpacing = 10.0;

// The spacing to use between the tab bar item image and its text
const CGFloat CiExpandableTabBarImageTitleSpacing = 2.0;

// The values used when creating the rounded-rect background of the selected item
const CGFloat CiExpandableTabBarHighlightAlpha = 0.15;
const CGFloat CiExpandableTabBarHighlightRadius = 5.0;
const CGFloat CiExpandableTabBarHighlightInset = 5.0;


@interface CiExpandableTabBar()

// The total number of rows
@property (nonatomic, assign) NSUInteger rows;

// The maximum size, including spacing, of a single tab bar item
@property (nonatomic, assign) CGSize maxItemSize;

// The number of items (excluding the "more" item) per row
@property (nonatomic, assign) NSUInteger itemsPerRow;

// The x offset to the first tab bar item
@property (nonatomic, assign) NSUInteger dxFirstItem;

// A collection of CiExpandableTabBarLayoutxxxx flags
@property (nonatomic, assign) NSUInteger needsLayout;

// The font used to render tab item text
@property (nonatomic, retain) UIFont* font;

// The top "rounded" image used in tab bar background
@property (nonatomic, retain) UIImage* topImage;

// These three subviews break the tab bar into its components:
// - itemBackgroundView is the back-most view and renders the "black" background
// - itemViewsParent holds the UIImageViews for all tab bar items
// - moreItemView is the UIImageView for the "more" tab bar item
@property (nonatomic, retain) UIImageView* itemBackgroundView;
@property (nonatomic, retain) UIView* itemViewsParent;
@property (nonatomic, retain) UIImageView* moreItemView;

// An array of UIImageViews created for each tab bar item (for convience)
@property (nonatomic, retain) NSMutableArray* itemViews;


- (UIImage*)imageFromTabBarItem:(UITabBarItem*)tabBarItem
                   forHighlight:(BOOL)highlighted
                       withMask:(UIImage*)alphaMask
                  withImageSize:(CGSize)sizeImageMax
                  withTitleSize:(CGSize)sizeTitleMax
                 withBackground:(UIImage*)background;

- (void)ensureItemImages;
- (void)ensureDimensions;
- (void)ensureBackgroundImage;
- (void)ensureItemViews;
- (void)ensureItemViewsParent;

- (void)highlightActiveItem;

- (void)handleTap:(UIGestureRecognizer*)gestureRecognizer;

@end


@implementation CiExpandableTabBar

#pragma mark - Properties

@synthesize delegate=_delegate;

@synthesize items=_items;
- (void)setItems:(NSArray *)items {
  [self setItems:items animated:NO];
}

@synthesize selectedItem=_selectedItem;
- (void)setSelectedItem:(UITabBarItem *)selectedItem {
  if ([_items containsObject:selectedItem]) {
    _selectedItem = selectedItem;
    [self performSelector:@selector(highlightActiveItem) withObject:nil afterDelay:0];
  }
}

@synthesize rows=_rows;

- (CGFloat)rowHeight {
  [self ensureDimensions];
  return [self maxItemSize].height;
}

@synthesize moreTabBarItem=_moreTabBarItem;
- (void)setMoreTabBarItem:(UITabBarItem *)moreTabBarItem {
  if (_moreTabBarItem != moreTabBarItem) {
    [_moreTabBarItem release];
    _moreTabBarItem = [moreTabBarItem retain];
    self.needsLayout |= CiExpandableTabBarLayoutItemImages;
  }
}

@synthesize itemSpacing=_itemSpacing;
- (void)setItemSpacing:(CGFloat)itemSpacing {
  if (_itemSpacing != itemSpacing) {
    _itemSpacing = itemSpacing;
    self.needsLayout |= CiExpandableTabBarLayoutDimensions;
  }
}

@synthesize selectedBackgroundImage=_selectedBackgroundImage;
- (UIImage*) selectedBackgroundImage {
  if (!_selectedBackgroundImage) {
    self.selectedBackgroundImage = [UIImage imageNamed:@"TabBarItemSelectedBackground.png"];
  }
  return _selectedBackgroundImage;
}
- (void) setSelectedBackgroundImage:(UIImage *)selectedBackgroundImage {
  if (_selectedBackgroundImage != selectedBackgroundImage) {
    [_selectedBackgroundImage release];
    _selectedBackgroundImage = [selectedBackgroundImage retain];
    self.needsLayout |= CiExpandableTabBarLayoutItemImages;
  }
}

- (CGFloat)padding {
  return CiExpandableTabBarPadding;
}

@synthesize maxItemSize=_maxItemSize;
@synthesize itemsPerRow=_itemsPerRow;
@synthesize dxFirstItem=_dxFirstItem;

@synthesize needsLayout=_needsLayout;
- (void)setNeedsLayout:(NSUInteger)needsLayout {
  needsLayout |= _needsLayout;
  if (_needsLayout != needsLayout) {
    _needsLayout = needsLayout;
    [self setNeedsLayout];
  }
}

@synthesize font=_font;
@synthesize topImage=_topImage;

@synthesize itemBackgroundView=_itemBackgroundView;
@synthesize itemViewsParent=_itemViewsParent;
@synthesize moreItemView=_moreItemView;

@synthesize itemViews=_itemViews;

- (void)setCenter:(CGPoint)center {
  [super setCenter:center];
  
  // If no other layout is required, immediately position the view of tab bar items
  // (If animating, this ensures that both center updates - that to the tab bar itself and
  //  those made to the view of tab bar items - happend simultaneously, creating a smooth effect)
  if (_needsLayout == CiExpandableTabBarLayoutNone) {
    _needsLayout |= CiExpandableTabBarLayoutItemViewsParent;
    [self ensureItemViewsParent];
  }
  
  // Otherwise, just note that the view tab bar items needs adjusting
  else {
    self.needsLayout |= CiExpandableTabBarLayoutItemViewsParent;
  }
}


#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame {

  self = [super initWithFrame:CGRectMake(0, 0, 0, 0)];
  if (self) {
    _itemSpacing = CiExpandableTabBarDefaultSpacing;
    _needsLayout = CiExpandableTabBarLayoutAll;

    // Clip contents so the row containing the active item may be shown without as a single row
    [self setClipsToBounds:YES];

    // Add a tap recognizer to capture touches
    UITapGestureRecognizer* tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];

    // Create the standard system font for item names
    _font = [UIFont boldSystemFontOfSize:11];
    [_font retain];

    // Create a stretchable version of the top image
    _topImage = [UIImage imageNamed:@"TabBarGradient.png"];
    CGSize size = CGSizeMake(_topImage.size.width, _topImage.size.height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    UIImage* strechableImage = [_topImage stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    [strechableImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    _topImage = UIGraphicsGetImageFromCurrentImageContext();
    [_topImage retain];
    UIGraphicsEndImageContext();

    // Create the three subviews in the proper view order
    _itemBackgroundView = [[UIImageView alloc] init];
    [self addSubview:_itemBackgroundView];
    
    _itemViewsParent = [[UIView alloc] init];
    [self addSubview:_itemViewsParent];
    [_itemViewsParent setOpaque:NO];

    _moreItemView = [[UIImageView alloc] init];
    [_moreItemView setOpaque:NO];
    [self addSubview:_moreItemView];

    // Create a mutable array to hold the tab bar item views
    _itemViews = [[NSMutableArray alloc] init];
  }

  return self;
}

- (void)dealloc {
  [_items release];
  [_moreTabBarItem release];
  [_selectedBackgroundImage release];
  
  [_font release];
  [_topImage release];
  
  [_itemBackgroundView release];
  [_itemViewsParent release];
  [_moreItemView release];

  [_itemViews release];
  
  [super dealloc];
}


#pragma mark - Instance Methods

//---------------------------------------------------------------------------------------------
// Create an image for a single tab bar item
//
- (UIImage*)imageFromTabBarItem:(UITabBarItem *)tabBarItem
                   forHighlight:(BOOL)highlighted
                       withMask:(UIImage *)alphaMask
                  withImageSize:(CGSize)sizeImageMax
                  withTitleSize:(CGSize)sizeTitleMax
                 withBackground:(UIImage*)background {
  
  // Create a state (normal or highlighted) image from the passed source image and mask
  UIImage* image = nil;
  if ([tabBarItem image]) {
    UIImage* tabBarImage = [tabBarItem image];
    UIImage* imageSrc = highlighted
                          ? [UIImage imageFromImage:self.selectedBackgroundImage withSize:tabBarImage.size]
                          : [UIImage imageFromColor:[UIColor lightGrayColor] withSize:tabBarImage.size];
    
    CGImageRef imageRef = CGImageCreateWithMask(imageSrc.CGImage, alphaMask.CGImage);
    image = [UIImage imageWithCGImage:imageRef scale:tabBarImage.scale orientation:tabBarImage.imageOrientation];
    CGImageRelease(imageRef);
  }

  // Create an image combining the state image and title
  NSString* title = tabBarItem.title;
  CGSize sizeTitle = title ? [title sizeWithFont:_font] : CGSizeMake(0, 0);

  UIGraphicsBeginImageContextWithOptions(_maxItemSize, NO, 0.0);
  
  // - Draw the background image
  if (background) {
    [background drawAtPoint:CGPointMake((_maxItemSize.width - background.size.width) / 2, (_maxItemSize.height - background.size.height) / 2)];
  }

  // - Draw the title centered along the bottom of the result image
  if (title) {
    CGRect rectTitle;
    rectTitle.origin.x = (_maxItemSize.width - sizeTitle.width) / 2;
    rectTitle.origin.y = _maxItemSize.height - sizeTitle.height - _itemSpacing;
    rectTitle.size = sizeTitle;
    
    [(highlighted ? [UIColor whiteColor] : [UIColor lightGrayColor]) set];

    [title drawInRect:rectTitle withFont:_font];
  }
  
  // - Draw the state image centered in the space above the title
  if (image) {
    NSInteger dyTitle = sizeTitleMax.height;
    dyTitle += dyTitle ? CiExpandableTabBarImageTitleSpacing : 0;

    CGPoint point;
    point.x = (_maxItemSize.width - image.size.width) / 2;
    point.y = _itemSpacing + (_maxItemSize.height - (2 * _itemSpacing) - dyTitle - image.size.height) / 2;
    [image drawAtPoint:point];
  }

  UIImage* imageResult = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return imageResult;
}

//---------------------------------------------------------------------------------------------
// Determine the maximum size required and create UIImageViews for all tab bar items
//
- (void)ensureItemImages {
  if (_needsLayout & CiExpandableTabBarLayoutItemImages) {

    // First, determine the size needed to encompass the largest image and largest title
    CGSize sizeImageMax = CGSizeMake(0, 0);
    CGSize sizeTitleMax = CGSizeMake(0, 0);
    for (UITabBarItem* tabBarItem in _items) {
      if (tabBarItem.image) {
        CGSize sizeImage = tabBarItem.image.size;
        sizeImageMax.width = MAX(sizeImageMax.width, sizeImage.width);
        sizeImageMax.height = MAX(sizeImageMax.height, sizeImage.height);
      }
      
      if (tabBarItem.title) {
        CGSize sizeTitle = [tabBarItem.title sizeWithFont:_font];
        sizeTitleMax.width = MAX(sizeTitleMax.width, sizeTitle.width);
        sizeTitleMax.height = MAX(sizeTitleMax.height, sizeTitle.height);
      }
    }
    
    if (_moreTabBarItem) {
      if (_moreTabBarItem.image) {
        CGSize sizeImage = _moreTabBarItem.image.size;
        sizeImageMax.width = MAX(sizeImageMax.width, sizeImage.width);
        sizeImageMax.height = MAX(sizeImageMax.height, sizeImage.height);
      }
      
      if (_moreTabBarItem.title) {
        CGSize sizeTitle = [_moreTabBarItem.title sizeWithFont:_font];
        sizeTitleMax.width = MAX(sizeTitleMax.width, sizeTitle.width);
        sizeTitleMax.height = MAX(sizeTitleMax.height, sizeTitle.height);
      }
    }
    
    // Set the maximum image size (including spacing)
    _maxItemSize = CGSizeMake(0, 0);
    _maxItemSize.width = MAX(sizeImageMax.width, sizeTitleMax.width);
    _maxItemSize.height = sizeImageMax.height;
    if (sizeImageMax.height && sizeTitleMax.height) {
      _maxItemSize.height += CiExpandableTabBarImageTitleSpacing;
    }
    _maxItemSize.height += sizeTitleMax.height;

    _maxItemSize.width += 2 * _itemSpacing;
    _maxItemSize.height += 2 * _itemSpacing;

    // Create a background for highlighted images
    UIGraphicsBeginImageContextWithOptions(_maxItemSize, NO, 0.0);
    
    CGRect rect = CGRectInset(CGRectMake(0, 0, _maxItemSize.width, _maxItemSize.height), CiExpandableTabBarHighlightInset, CiExpandableTabBarHighlightInset);
    
    [[UIColor colorWithWhite:1.0 alpha:CiExpandableTabBarHighlightAlpha] set];
    [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:CiExpandableTabBarHighlightRadius] fill];

    UIImage* highlightedBackground = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Finally, create all the normal and highlighted images for each item view
    [_itemViews removeAllObjects];
    rect = CGRectMake(0, 0, _maxItemSize.width, _maxItemSize.height);
    for (UITabBarItem* tabBarItem in _items) {
      UIImage* tabBarImage = [tabBarItem image];
      UIImage* alphaMask = [tabBarImage alphaMask];

      UIImage* normalImage = [self imageFromTabBarItem:tabBarItem
                                          forHighlight:NO
                                              withMask:alphaMask
                                         withImageSize:sizeImageMax
                                         withTitleSize:sizeTitleMax
                                        withBackground:nil];
      
      UIImage* highlightedImage = [self imageFromTabBarItem:tabBarItem
                                               forHighlight:YES
                                                   withMask:alphaMask
                                              withImageSize:sizeImageMax
                                              withTitleSize:sizeTitleMax
                                             withBackground:highlightedBackground];

      UIImageView* imageView = [[UIImageView alloc] initWithImage:normalImage highlightedImage:highlightedImage];
      [imageView setBounds:rect];
      [imageView setOpaque:NO];
      [_itemViews addObject:imageView];
      [imageView release];
    }
    
    if (_moreTabBarItem) {
      UIImage* tabBarImage = [_moreTabBarItem image];
      UIImage* alphaMask = [tabBarImage alphaMask];

      [_moreItemView setImage:[self imageFromTabBarItem:_moreTabBarItem
                                           forHighlight:NO
                                               withMask:alphaMask
                                          withImageSize:sizeImageMax
                                          withTitleSize:sizeTitleMax
                                         withBackground:nil]];
      
      [_moreItemView setHighlightedImage:[self imageFromTabBarItem:_moreTabBarItem
                                                      forHighlight:YES
                                                          withMask:alphaMask
                                                     withImageSize:sizeImageMax
                                                     withTitleSize:sizeTitleMax
                                                    withBackground:nil]];
    }
    
    _needsLayout ^= CiExpandableTabBarLayoutItemImages;
    _needsLayout |= CiExpandableTabBarLayoutDimensions;
    _needsLayout |= CiExpandableTabBarLayoutItemViews;
    _needsLayout |= CiExpandableTabBarLayoutItemViewsParent;
  }
}

//---------------------------------------------------------------------------------------------
// Compute the number of items per row and number of rows needed to render all tab bar items
//
- (void)ensureDimensions {
  [self ensureItemImages];
  
  if (_needsLayout & CiExpandableTabBarLayoutDimensions) {
    CGRect bounds = [self superview] ? [[self superview] bounds] : [[UIScreen mainScreen] applicationFrame];

    _itemsPerRow = (bounds.size.width - (2 * CiExpandableTabBarPadding)) / _maxItemSize.width;
    _rows = ([_items count] + _itemsPerRow - 1) / _itemsPerRow;
    if (_rows > 1) {
      _itemsPerRow -= 1;
      _rows = ([_items count] + _itemsPerRow - 1) / _itemsPerRow;
    }
    
    _needsLayout ^= CiExpandableTabBarLayoutDimensions;
    _needsLayout |= CiExpandableTabBarLayoutBackgroundImage;
    _needsLayout |= CiExpandableTabBarLayoutItemViews;
    _needsLayout |= CiExpandableTabBarLayoutItemViewsParent;
  }
}

//---------------------------------------------------------------------------------------------
// Render the "black" background image that lies behind all other views
//
- (void)ensureBackgroundImage {
  [self ensureDimensions];
  
  // Layout all items in the each orientation and create a cached image (using normal state images)
  if (_needsLayout & CiExpandableTabBarLayoutBackgroundImage) {
    
    CGSize size = [self bounds].size;
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    [_itemBackgroundView setBounds:rect];
    [_itemBackgroundView setCenter:CGPointMake(size.width / 2, size.height / 2)];
    
    UIGraphicsBeginImageContextWithOptions(size, YES, 1.0);
    
    [[UIColor blackColor] set];
    UIRectFill(rect);
    [_topImage drawInRect:CGRectMake(0, 0, rect.size.width, _topImage.size.height)];

    [_itemBackgroundView setImage:UIGraphicsGetImageFromCurrentImageContext()];
    
    UIGraphicsEndImageContext();
    
    _needsLayout ^= CiExpandableTabBarLayoutBackgroundImage;
  }
}

//---------------------------------------------------------------------------------------------
// Position the UIImageViews for all tab bar items (except the "more" item)
//
- (void)ensureItemViews {
  [self ensureBackgroundImage];

  if (_needsLayout & CiExpandableTabBarLayoutItemViews) {
    CGSize size = [self bounds].size;
    
    [_itemViewsParent removeSubviews];

    // Layout the rows evenly around the center
    NSUInteger dy = 0;
    if (_rows <= 1) {
      _dxFirstItem = (size.width / 2) - (_maxItemSize.width * ([_items count] / 2));
      if ([_items count] % 2) {
        _dxFirstItem -= _maxItemSize.width / 2;
      }
    } else {
      _dxFirstItem = (size.width - ((_itemsPerRow + 1) * _maxItemSize.width)) / 2;
    }
    
    // Layout all rows
    NSUInteger dx = _dxFirstItem;
    NSUInteger iItem = 0;
    for (UIImageView* itemView in _itemViews) {
      [_itemViewsParent addSubview:itemView];
      [itemView setCenter:CGPointMake(dx + (_maxItemSize.width / 2), dy + (_maxItemSize.height / 2))];

      iItem += 1;
      if (iItem % _itemsPerRow) {
        dx += _maxItemSize.width;
      } else {
        dx = _dxFirstItem;
        dy += _maxItemSize.height;
      }
    }

    _needsLayout ^= CiExpandableTabBarLayoutItemViews;
    _needsLayout |= CiExpandableTabBarLayoutItemViewsParent;
  }
}

//---------------------------------------------------------------------------------------------
// Position the view that holds the tab bar item UIImageViews
// - If all rows are visible, center it within the assigned bounds
// - If just one row is visible, ensure the row with the active item is visible
//
- (void)ensureItemViewsParent {
  [self ensureItemViews];

  if (_needsLayout & CiExpandableTabBarLayoutItemViewsParent) {
    CGRect bounds = [self bounds];
    
    [_itemViewsParent setBounds:bounds];
    [_itemViewsParent setCenter:CGPointMake(bounds.size.width / 2, bounds.size.height / 2)];

    CGRect parentBounds = [self superview] ? [[self superview] bounds] : [[UIScreen mainScreen] applicationFrame];
    NSUInteger indexItem = _selectedItem ? [_items indexOfObject:_selectedItem] : UINT32_MAX;
    NSInteger dy = CGRectContainsPoint(parentBounds, [self center])
                      ? 0
                      : ((indexItem / _itemsPerRow) * _maxItemSize.height);

    [_itemViewsParent setCenter:CGPointMake(bounds.size.width / 2, (bounds.size.height / 2) - dy)];

    _needsLayout ^= CiExpandableTabBarLayoutItemViewsParent;
  }
}

//---------------------------------------------------------------------------------------------
// Compute all necessary values and layout the subviews
//
- (void)layoutSubviews {
  [self ensureItemViewsParent];
  
  if (_rows > 1 && _moreTabBarItem) {
    [_moreItemView setBounds:CGRectMake(0, 0, _maxItemSize.width, _maxItemSize.height)];
    [_moreItemView setCenter:CGPointMake((_maxItemSize.width * _itemsPerRow) + _dxFirstItem + (_maxItemSize.width / 2), _maxItemSize.height / 2)];
  }
  
  _needsLayout = CiExpandableTabBarLayoutNone;
}

//---------------------------------------------------------------------------------------------
// Highlight or clear the highlight of the "more" tab bar item
//
- (void)highlightMoreItem:(BOOL)highlighted {
  if (_moreTabBarItem) {
    [_moreItemView setHighlighted:highlighted];
  }
}

//---------------------------------------------------------------------------------------------
// Highlight the "active" tab bar item
//
- (void)highlightActiveItem {
  NSUInteger indexItem = _selectedItem ? [_items indexOfObject:_selectedItem] : NSNotFound;
  if (indexItem != NSNotFound) {
    for (UIImageView* view in _itemViews) {
      [view setHighlighted:NO];
    }
    if (indexItem < [_items count]) {
      [[_itemViews objectAtIndex:indexItem] setHighlighted:YES];
    }
  }
}

//---------------------------------------------------------------------------------------------
// Replace the tab bar items; force a complete re-layout
//
- (void)setItems:(NSArray*)items animated:(BOOL)animated {
  [_items release];
  _items = [items retain];
  
  self.needsLayout = CiExpandableTabBarLayoutAll;
  
  // TODO:
  // - Add animation
}

//---------------------------------------------------------------------------------------------
// Respond to a tap
// - Notify the delegate (if any)
// - Highlight the active item
//
- (void)handleTap:(UIGestureRecognizer*)gestureRecognizer {
  if ([self isUserInteractionEnabled]) {
    CGPoint location = [gestureRecognizer locationInView:self];
    UITabBarItem* tabBarItem = nil;
    
    NSUInteger rowItem = (location.x - _dxFirstItem) / _maxItemSize.width;
    if (rowItem < _itemsPerRow) {
      NSInteger dy = ([_itemBackgroundView center].y - [_itemViewsParent center].y);
      NSUInteger row = (location.y + dy) / _maxItemSize.height;
      NSUInteger itemIndex = (row * _itemsPerRow) + rowItem;
      
      if (itemIndex < [_items count]) {
        tabBarItem = [_items objectAtIndex:itemIndex];
      }
    } else {
      if (_moreTabBarItem && rowItem == _itemsPerRow) {
        tabBarItem = _moreTabBarItem;
      }
    }
    
    
    if (tabBarItem && (!_delegate || [_delegate expandableTabBar:self shouldSelectItem:tabBarItem])) {
      self.selectedItem = tabBarItem;
      if (_delegate) {
        [_delegate expandableTabBar:self didSelectItem:tabBarItem];
        if (tabBarItem != _moreTabBarItem) {
          [self highlightActiveItem];
        }
      }
    }
  }
}

//---------------------------------------------------------------------------------------------
// Compute the size whose width matches the superview and contains enough rows to render
// all tab bar items (plus a small amount of extra padding)
//
- (CGSize)sizeThatFits:(CGSize)size {
  CGRect bounds = [self superview] ? [[self superview] bounds] : [[UIScreen mainScreen] applicationFrame];
  UIImage* image = [_itemBackgroundView image];
  
  if (!image || image.size.width != (bounds.size.width + (2 * CiExpandableTabBarPadding))) {
    [self setNeedsLayout:CiExpandableTabBarLayoutDimensions];
  }

  [self ensureDimensions];
  return CGSizeMake(bounds.size.width + (2 * CiExpandableTabBarPadding), (_maxItemSize.height * _rows) + CiExpandableTabBarPadding);
}

@end
