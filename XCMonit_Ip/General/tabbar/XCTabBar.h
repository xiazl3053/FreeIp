//
//  MyNBTabBar.h
//  NB2
//
//  Created by kohn on 13-11-16.
//  Copyright (c) 2013年 Kohn. All rights reserved.
//

#import <UIKit/UIKit.h>
@class XCTabController;
@protocol XCTabBarDelegate <NSObject>

- (void)selectIndex:(UIViewController *)viewController;

@end


@interface XCTabBar : UIView

@property (nonatomic,assign)id<XCTabBarDelegate> delegate;


- (id)initWithItems:(NSArray *)items;
- (void)setSelectIndex:(NSInteger)nIndex;



@end

