//
//  MyNBTabNotification.m
//  NB2
//
//  Created by kohn on 13-11-16.
//  Copyright (c) 2013年 Kohn. All rights reserved.
//

#import "XCTabNotification.h"
#define FONT_SIZE 12

@implementation XCTabNotification

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        notificationCount = 0;
        imageView = [[UIImageView alloc] init];
        imageView.frame = self.frame;
        [self addSubview:imageView];
        
        countLabel = [[UILabel alloc] init];
        countLabel.backgroundColor = [UIColor clearColor];
        countLabel.textColor = [UIColor whiteColor];
        countLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
        countLabel.textAlignment = NSTextAlignmentCenter;
        countLabel.frame = self.frame;
        [self addSubview:countLabel];
        self.userInteractionEnabled = NO;
    }
    return self;
}
- (void)setAllFrames:(CGRect)frame{
    self.frame = frame;
    imageView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    countLabel.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}
- (NSInteger)notificationCount {
    return notificationCount;
}
- (void)addNotifications:(NSInteger)n{
    if (n > 0) {
        notificationCount += n;
    }
    [self updateImageView];
}
- (void)removeNotifications:(NSInteger)n{
    if (n > 0) {
        notificationCount -= n;
    }
    if (notificationCount < 0) notificationCount = 0;
    [self updateImageView];
}
- (void)updateImageView{
    NSString *notificationLightIconFile;
    if ([self notificationCount] <= 0) {
        notificationLightIconFile = @"";
    }else{
        notificationLightIconFile = @"tabBarNotificationLightOn";
    }
    UIImage *notificationLight = [UIImage imageNamed:notificationLightIconFile];
    imageView.image = notificationLight;
    if ([self notificationCount] > 0 && [self notificationCount] < 100) {
        countLabel.text = [NSString stringWithFormat:@"%d",[self notificationCount]];
    }else if ([self notificationCount] >= 100){
        countLabel.text = @"99+";
    }else{
        countLabel.text = @"";
    }
    
}

@end
