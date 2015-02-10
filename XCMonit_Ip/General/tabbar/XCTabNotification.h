//
//  MyNBTabNotification.h
//  NB2
//
//  Created by kohn on 13-11-16.
//  Copyright (c) 2013年 Kohn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XCTabNotification : UIView{
    UIImageView *imageView;
    UILabel *countLabel;
    NSInteger notificationCount;
}

-(NSInteger)notificationCount;
-(void)addNotifications:(NSInteger)n;
-(void)removeNotifications:(NSInteger)n;

-(void)setAllFrames:(CGRect)frame;
-(void)updateImageView;
@end
