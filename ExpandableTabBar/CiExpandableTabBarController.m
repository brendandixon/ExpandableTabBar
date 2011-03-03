//
//  CiExpandableTabBarController.m
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

#import "CiExpandableTabBarController.h"

const NSUInteger CiExpandableTabBarUnselected = NSUIntegerMax;
const NSInteger CiExpandableTabBarMore = NSIntegerMax;
const CGFloat CiExpandableTabBarAnimationDuration = 0.5;

static NSString* CiExpandableTabBarMoreTitle = @"More";


#pragma mark - Private Methods

@interface CiExpandableTabBarController ()

@property (nonatomic, retain) CiExpandableTabBar* expandableTabBar;
@property (nonatomic, getter=isTabBarExpanded, assign) BOOL tabBarExpanded;
@property (nonatomic, retain) UIView* viewControllersView;

- (void)ensureTabBarItems;
- (void)ensureTabBarCenter;
- (void)ensureTabBarLocationWithAnimation:(BOOL)animate completion:(void (^)(BOOL finished))completion;
- (void)ensureSelectedViewControllerIsVisible;

@end

@implementation CiExpandableTabBarController


#pragma mark - Properties

@synthesize delegate=_delegate;


@synthesize viewControllers=_viewControllers;

- (void)setViewControllers:(NSArray *)viewControllers {
  DLog();
  [self setViewControllers:viewControllers animated:NO];
}


@synthesize selectedIndex=_selectedIndex;

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
  DLog();
  _selectedIndex = selectedIndex;
  [self ensureSelectedViewControllerIsVisible];
}


- (UIViewController*)selectedViewController {
  DLog();
  return [_viewControllers count] <= _selectedIndex ? nil : [_viewControllers objectAtIndex:_selectedIndex];
}

- (void)setSelectedViewController:(UIViewController*)selectedViewController {
  DLog();
  NSUInteger selectedIndex = [_viewControllers indexOfObject:selectedViewController];
  if (selectedIndex != NSNotFound) {
    [self setSelectedIndex:selectedIndex];
  }
}

@synthesize animationDuration=_animationDuration;

@synthesize expandableTabBar=_expandableTabBar;
@synthesize tabBarExpanded=_tabBarExpanded;
@synthesize viewControllersView=_viewControllersView;


#pragma mark - Initialization

- (id)init {
  DLog();
  return [self initWithViewControllers:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  DLog();
  return [self initWithViewControllers:nil];
}

- (id)initWithViewControllers:(NSArray*)viewControllers {
  DLog();
  return [self initWithViewControllers:viewControllers andSelectedIndex:0];
}

- (id)initWithViewControllers:(NSArray*)viewControllers andSelectedIndex:(NSUInteger)selectedIndex {
  DLog();
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewControllers = (viewControllers == nil ? [[NSArray alloc] init] : [viewControllers copy]);
    _selectedIndex = selectedIndex;
    _animationDuration = CiExpandableTabBarAnimationDuration;
  }
  return self;
}

- (void)dealloc
{
  DLog();

  [_viewControllers release];
  [_expandableTabBar release];
  [_viewControllersView release];
  
  [super dealloc];
}

- (void)didReceiveMemoryWarning
{
  DLog();
  [super didReceiveMemoryWarning];
}


#pragma mark - View Lifecycle

- (void)loadView {
  DLog();
  
  UIView* view;

  // Create a plain UIView to hold the subviews
  view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  self.view = view;
  [view release];
  
  // Add a view to hold all view controller views
  view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  self.viewControllersView = view;
  [[self view] addSubview:view];
  [view release];
  
  // Then, add a view for the expandable tab bar
  self.expandableTabBar = [[CiExpandableTabBar alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
  if (_expandableTabBar) {
    [self setTabBarExpanded:NO];
    
    [self.view addSubview:_expandableTabBar];
    [_expandableTabBar setDelegate:self];
    
    [self ensureTabBarItems];
    [self ensureTabBarLocationWithAnimation:NO completion:nil];
    
    [_expandableTabBar release];
  }

  CGRect bounds = [self view].bounds;
  bounds.size.height -= [_expandableTabBar rowHeight];
  [_viewControllersView setBounds:CGRectMake(0, 0, bounds.size.width, bounds.size.height)];
  [_viewControllersView setCenter:CGPointMake(bounds.size.width / 2, bounds.size.height / 2)];
  
  // Finally, ensure the appropriate view controller is active
  [self ensureSelectedViewControllerIsVisible];
}

- (void)viewDidLoad {
  DLog();
  [super viewDidLoad];
}

- (void)viewDidUnload {
  DLog();
  [super viewDidUnload];
}

- (void)willAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  DLog();
  
  // TODO:
  // - Improve rotation animation

  [super willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  
  [_expandableTabBar setUserInteractionEnabled:NO];
  
  for (UIViewController* viewController in _viewControllers) {
    if ([viewController respondsToSelector:@selector(willRotateToInterfaceOrientation:duration:)]) {
      [viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    } else if ([viewController respondsToSelector:@selector(willAnimateFirstHalfOfRotationToInterfaceOrientation:duration:)]) {
      [viewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
  }
}

- (void)didAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  DLog();
  [super didAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation];
  
  [self ensureTabBarLocationWithAnimation:NO completion:nil];

  for (UIViewController* viewController in _viewControllers) {
    if ([viewController respondsToSelector:@selector(didAnimateFirstHalfOfRotationToInterfaceOrientation:)]) {
      [viewController didAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation];
    }
  }
}

- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation duration:(NSTimeInterval)duration {
  DLog();
  [super willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];

  [self ensureTabBarLocationWithAnimation:NO completion:nil];
  
  for (UIViewController* viewController in _viewControllers) {
    if ([viewController respondsToSelector:@selector(willAnimateSecondHalfOfRotationFromInterfaceOrientation:duration:)]) {
      [viewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
    }
  }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  DLog();
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

  [self ensureTabBarLocationWithAnimation:NO completion:nil];
  [_expandableTabBar setUserInteractionEnabled:YES];
  
  for (UIViewController* viewController in _viewControllers) {
    [viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  DLog();
  BOOL allowRotation = YES;
  for (UIViewController* viewController in _viewControllers) {
    allowRotation = allowRotation && [viewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    if (!allowRotation)
      break;
  }
  return allowRotation;
}


#pragma mark - Methods

- (void)ensureSelectedViewControllerIsVisible {
  DLog();

  _selectedIndex = [_viewControllers count] ? MIN(_selectedIndex, [_viewControllers count]-1) : CiExpandableTabBarUnselected;

  if (_selectedIndex != CiExpandableTabBarUnselected) {
    UIViewController* selectedViewController = [_viewControllers objectAtIndex:_selectedIndex];
  
    [_expandableTabBar setSelectedItem:[selectedViewController tabBarItem]];

    UIView* selectedViewControllerView = selectedViewController.view;
    if (![_viewControllersView.subviews containsObject:selectedViewControllerView]) {
      [_viewControllersView addSubview:selectedViewControllerView];
      [_viewControllersView sendSubviewToBack:selectedViewControllerView];

      CGRect bounds = [_viewControllersView bounds];
      [selectedViewControllerView setBounds:CGRectMake(0, 0, bounds.size.width, bounds.size.height)];
      [selectedViewControllerView setCenter:CGPointMake(bounds.size.width / 2, bounds.size.height / 2)];
    }
    [_viewControllersView bringSubviewToFront:selectedViewControllerView];
    
    if (_delegate) {
      [_delegate expandableTabBarController:self didSelectViewController:selectedViewController];
    }

  }
}

- (void)ensureTabBarItems {
  if (_viewControllers && _expandableTabBar) {
    UITabBarItem* tabBarItem;

    NSMutableArray* tabBarItems = [[NSMutableArray alloc] init];
    NSUInteger countControllers = [_viewControllers count];
    for (NSUInteger iController=0; iController < countControllers; iController++) {
      tabBarItem = [[_viewControllers objectAtIndex:iController] tabBarItem];
      tabBarItem.tag = iController;
      [tabBarItems addObject:tabBarItem];
    }
    [_expandableTabBar setItems:tabBarItems];
    [tabBarItems release ];

    tabBarItem = [[UITabBarItem alloc] initWithTitle:CiExpandableTabBarMoreTitle image:nil tag:CiExpandableTabBarMore];
    [_expandableTabBar setMoreTabBarItem:tabBarItem];
    [tabBarItem release];
  }
}

- (void)ensureTabBarCenter {
  CGRect bounds = [[self view] bounds];
  CGSize tabBarSize = [_expandableTabBar bounds].size;
  CGPoint tabBarCenter = _tabBarExpanded
                            ? CGPointMake(bounds.size.width / 2, bounds.size.height - (tabBarSize.height / 2))
                            : CGPointMake(bounds.size.width / 2, bounds.size.height + (tabBarSize.height / 2) - [_expandableTabBar rowHeight]);
  [_expandableTabBar setCenter:tabBarCenter];
}

- (void)ensureTabBarLocationWithAnimation:(BOOL)animate completion:(void (^)(BOOL finished))completion {
  [_expandableTabBar sizeToFit];

  if (animate) {
    if (_tabBarExpanded) {
      [UIView animateWithDuration:_animationDuration
                            delay:0.0
                          options:UIViewAnimationOptionCurveEaseOut
                       animations:^(void) { [self ensureTabBarCenter]; }
                       completion:completion];
    }
    else {
      [UIView animateWithDuration:_animationDuration
                            delay:0.0
                          options:UIViewAnimationOptionCurveEaseOut
                       animations:^(void) { [self ensureTabBarCenter]; }
                       completion:completion ];
    }
  }
  else {
    [self ensureTabBarCenter];
    if (completion) {
      completion(YES);
    }
  }
}

- (void)setViewControllers:(NSArray*)viewControllers animated:(BOOL)animated {
  // TODO:
  // - Add animation

  if (viewControllers != _viewControllers) {
    [_viewControllers release];
    _viewControllers = [viewControllers retain];

    [self ensureTabBarItems];
    [self ensureSelectedViewControllerIsVisible];
  }
}


#pragma mark - Delegate Methods

- (BOOL)expandableTabBar:(CiExpandableTabBar *)expandableTabBar shouldSelectItem:(UITabBarItem *)item {
  return (    item.tag == CiExpandableTabBarMore
          ||  (   item.tag >= 0
               && item.tag < [_viewControllers count]
               && (   !_delegate
                   || [_delegate expandableTabBarController:self shouldSelectViewController:[_viewControllers objectAtIndex:item.tag]])));
}

- (void)expandableTabBar:(CiExpandableTabBar*)expandableTabBar didSelectItem:(UITabBarItem *)item {
  if (item.tag == CiExpandableTabBarMore) {
    [_expandableTabBar highlightMoreItem:YES];
    [self setTabBarExpanded:(_tabBarExpanded ? NO : YES)];
    [self ensureTabBarLocationWithAnimation:YES completion:^(BOOL finished){ [_expandableTabBar highlightMoreItem:NO]; }];
  }
  else if (item.tag >= 0 && item.tag < [_viewControllers count]) {
    if (_tabBarExpanded) {
      [self setTabBarExpanded:NO];
      [self ensureTabBarLocationWithAnimation:YES completion:^(BOOL finished){ [self setSelectedIndex:item.tag]; }];
    }
    else {
      [self setSelectedIndex:item.tag];
    }
  }
}

@end
