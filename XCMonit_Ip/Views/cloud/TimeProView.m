//
//  TimeProView.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 15/5/20.
//  Copyright (c) 2015年 夏钟林. All rights reserved.
//

#import "TimeProView.h"

@interface TimeProView()
{
    UILabel *lblTime;
     
}
@property (nonatomic,strong) UIView *timeFirstView;

@property (nonatomic,strong) UIView *timeSecondView;



@end

@implementation TimeProView


-(NSString *)getTime
{
    return  lblTime.text;
}

-(void)createTimeView
{
    
    for (int i = 0; i<24; i++)
    {
        
    }
}


@end
