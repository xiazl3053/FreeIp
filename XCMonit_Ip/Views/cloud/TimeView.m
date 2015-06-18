//
//  TimeView.m
//  TestInfo
//
//  Created by 夏钟林 on 15/5/25.
//  Copyright (c) 2015年 xiazl. All rights reserved.
//

#import "TimeView.h"
#import <time.h>
@interface TimeView()
{
    UIPanGestureRecognizer *panGesture;
    long lStartWidth;
    CGSize labelsize;
}

@end

@implementation TimeView

-(id)initWithFrame:(CGRect)frame time:(NSString *)strTime
{
    self = [super initWithFrame:frame];
    [self settingTime:strTime];
    return self;
}

-(void)settingTime:(NSString *)strTime
{
    [self setBackgroundColor:[UIColor clearColor]];
    [self setUserInteractionEnabled:YES];
    panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panEvent:)];
    [self addGestureRecognizer:panGesture];
    _fValue = 2;
    _nWidth = 100;
  
    NSDateFormatter* fmt = [[NSDateFormatter alloc] init];
    
    fmt.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    
    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    NSDate *testTime = [fmt dateFromString:strTime];
    
    DLog(@"testTime:%@",testTime);
    
    NSTimeInterval time = [testTime timeIntervalSince1970];
    
    NSLog(@"2015-05-10--time:%li",(long)time);
    lStartWidth = time;
    
    UIFont *font = [UIFont fontWithName:@"Helvetica" size:15];
    
    labelsize = [@"1970-01-01 00:00:00" sizeWithFont:font constrainedToSize:CGSizeMake(200.0f, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping];
    
}

-(NSString *)strTime
{
    struct tm *p=NULL;
    char month;
    char day;
    char hour;
    char minute;
    char Second;
    
    p = localtime(&(lStartWidth));
    
    month = p->tm_mon + 1;
    day = p->tm_mday;
    hour = p->tm_hour;
    minute = p->tm_min;
    Second = p->tm_sec;
    NSString *strTime = [NSString stringWithFormat:@"%d-%02d-%02d %02d:%02d:%02d",1900+p->tm_year,month,day,hour,minute,Second];
    return strTime;
}

-(NSString*)strDate
{
    struct tm *p=NULL;
    char month;
    char day;
    char hour;
    char minute;
    char Second;
    
    p = localtime(&(lStartWidth));
    
    month = p->tm_mon + 1;
    day = p->tm_mday;
    hour = p->tm_hour;
    minute = p->tm_min;
    Second = p->tm_sec;
    NSString *strTime = [NSString stringWithFormat:@"%d-%02d-%02d 00:00:00",1900+p->tm_year,month,day];
    return strTime;
}

-(void)panEvent:(UIPanGestureRecognizer*)pan
{
    CGPoint pt = [pan translationInView:self];
//    NSLog(@"pt:%f--%f",pt.x,pt.y);
    CGFloat fWid = pt.x;
    //  1 * 36 秒
    lStartWidth -= ((int)fWid*36);
    [pan setTranslation:CGPointZero inView:self];
    [self setNeedsDisplay];
    if ([pan state]==UIGestureRecognizerStateEnded) {
        DLog(@"发送当前时间");
    }
}

-(void)initBodyView
{
  
}

-(void)drawRect:(CGRect)rect
{
    //横线的位置
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context,[UIColor whiteColor].CGColor);
    CGContextSetRGBStrokeColor(context, 15.0f/255, 173.0f/255, 225.0f/225, 1.0);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, 0.0, 39);
    CGContextAddLineToPoint(context,rect.size.width, 39);
    CGContextStrokePath(context);
    
    struct tm *p=NULL;
    char month;
    char day;
    char hour;
    char minute;
    char Second;
    
    p = localtime(&(lStartWidth));
    month = p->tm_mon + 1;
    day = p->tm_mday;
    hour = p->tm_hour;
    minute = p->tm_min;
    Second = p->tm_sec;
    
    //计算中间点位置
    CGFloat fWidth = (CGFloat)(p->tm_min *60 + p->tm_sec)*100.0/3600;
    
    int nTime =((int)rect.size.width/_nWidth)/2+1;
    for (int i=0; i<nTime; i++)
    {
        [self drawHour:context pointX:rect.size.width/2-fWidth-_nWidth*i];
        CGContextSetRGBFillColor (context, 1, 255.0f/255, 255.0f/225, 1.0); //使用黑色填充
        int nHour = (p->tm_hour-i) < 0 ? (24-abs(p->tm_hour-i)) : (p->tm_hour-i);//设置时间范围不会小于0
        //写左边时间
        NSString *strStartTime = [NSString stringWithFormat:@"%02d:00",nHour];
        UIFont *font = [UIFont fontWithName:@"Helvetica" size:10];
        [strStartTime drawInRect:CGRectMake(rect.size.width/2-fWidth-_nWidth*i-10, 20 ,labelsize.width, 12) withFont:font];
        [self drawHour:context pointX:rect.size.width/2+(_nWidth-fWidth)+_nWidth*i];
        //写右边的时间
        nHour = (p->tm_hour+i+1) > 23 ? (abs(p->tm_hour+i+1)%24) : (p->tm_hour+i+1);//设置时间范围不会超过24小时
        NSString *strEndTime = [NSString stringWithFormat:@"%02d:00",nHour];
        [strEndTime drawInRect:CGRectMake(rect.size.width/2+(_nWidth-fWidth)+_nWidth*i-10, 20 ,labelsize.width, 12) withFont:font];
    }
    //写总体时间
    NSString *strTime = [NSString stringWithFormat:@"%d-%02d-%02d %02d:%02d:%02d",1900+p->tm_year,month,day,hour,minute,Second];
    CGContextSetRGBFillColor (context,  1, 1, 1, 1.0);//设置笔的颜色
    CGContextSetLineWidth(context, 1);
    UIFont *font = [UIFont fontWithName:@"Helvetica" size:15];
    [strTime drawInRect:CGRectMake(rect.size.width/2-labelsize.width/2, 1 ,labelsize.width, 20) withFont:font];
    
    CGContextSetRGBStrokeColor(context,234/255.0,87/255.0,52/255.0, 1.0);
    CGContextSetLineWidth(context, 2);
    CGContextMoveToPoint(context, rect.size.width/2-1, 20);
    CGContextAddLineToPoint(context,rect.size.width/2, 60);
    CGContextStrokePath(context);
}

-(void)drawHour:(CGContextRef)context pointX:(CGFloat)pinX
{
    CGContextSetRGBStrokeColor(context, 15.0f/255, 173.0f/255, 225.0f/225, 1.0);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, pinX, 30);
    CGContextAddLineToPoint(context,pinX, 40);
    CGContextStrokePath(context);
}





@end
