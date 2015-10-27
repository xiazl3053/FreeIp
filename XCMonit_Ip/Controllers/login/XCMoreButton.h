//
//  XCMoreButton.h
//  XCMonit_Ip
//
//  Created by xiongchi on 15/10/10.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import <UIKit/UIKit.h>


@class XCMoreInfo;
@interface XCMoreButton : UIButton

- (id)initWithFrame:(CGRect)frame info:(XCMoreInfo *)more;

@end


@interface XCMoreInfo : NSObject

@property (nonatomic,copy) NSString *strNormal;
@property (nonatomic,copy) NSString *strHigh;
@property (nonatomic,copy) NSString *strTitle;

- (id)initWithInfo:(NSString *)strTitle normal:(NSString *)strNormal high:(NSString *)strHigh;

@end