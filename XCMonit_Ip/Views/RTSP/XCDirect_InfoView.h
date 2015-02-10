//
//  XCDirect_InfoView.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/1/26.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol XCDirectDelegate <NSObject>

@required
-(void)record_Direct:(NSInteger)nIndex;
-(void)update_Direct:(NSInteger)nIndex;
@optional

@end

@interface XCDirect_InfoView : UIView

@property (nonatomic,assign) NSInteger nCount;

@property (nonatomic,assign) id<XCDirectDelegate> delegate;

-(id)initWithFrame:(CGRect)frame;

@end




