//
//  MyNBTabBar.m
//  NB2
//
//  Created by kohn on 13-11-16.
//  Copyright (c) 2013年 Kohn. All rights reserved.
//

#import "XCTabBar.h"
#import "DevInfoMacro.h"
#import "XCButton.h"
#import "CustomNaviBarView.h"
@interface XCTabBar()

@property (strong) NSMutableArray *buttonData;
@property (nonatomic,strong) NSMutableArray *arrayItems;

- (void)setupButtons;
@property (nonatomic,assign) NSInteger nIndex;
@end

@implementation XCTabBar

-(void)dealloc
{
    [_arrayItems removeAllObjects];
    _arrayItems = nil;
    DLog(@"xctable dealloc");
}

- (id)initWithItems:(NSArray *)items
{
    self = [super init];
    if (self) {
        DLog(@"%f",kScreenHeight);
        float originY = kScreenHeight - 49;
        self.frame = CGRectMake(0, originY+HEIGHT_MENU_VIEW(20, 0) , kScreenWidth, 49);
        [self setBackgroundColor:RGB(255, 255, 255)];
        _buttonData = [[NSMutableArray alloc]initWithArray:items];
        
        UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0.5, kScreenWidth, 0.5)];
        sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                                 green:198/255.0
                                                  blue:198/255.0
                                                 alpha:1.0];
        UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 1 , kScreenWidth, 0.5)] ;
        sLine2.backgroundColor = [UIColor whiteColor];
        
        [self addSubview:sLine1];
        [self addSubview:sLine2];
        
        [self setupButtons];
        _nIndex = 0;
    }
    return self;
}
- (void)setupButtons {
    NSInteger count = 0;
    NSInteger xExtra = 0;
    CGFloat buttonSize = kScreenWidth / [self.buttonData count];
    for (XCTabInfo *tabInfo in self.buttonData) {
        NSInteger extra = 0;
        if ([self.buttonData count] % 2 == 1) {
            if ([self.buttonData count] == 5) {
                NSInteger i = (count +1) + (floor([self.buttonData count] / 2));
                if (i == [self.buttonData count]) {
                    extra = 1;
                }else if([self.buttonData count] == 3){
                    buttonSize = floor(kScreenWidth / [self.buttonData count]);
                }
            }else{
                if (count + 1 == 2) {
                    extra = 1;
                } else if (count + 1 == 3) {
                    xExtra = 1;
                }
            }
        }
        NSInteger buttonX = count * buttonSize;
        UIView *view = [[UIView alloc] initWithFrame:Rect(buttonX, 0, buttonSize, 48)];
        view.userInteractionEnabled = YES;
        [view setTag:count+20];
        [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapIndex:)]];
        
       // DLog(@"",buttonSize);
        XCButton *tabButton = [[XCButton alloc] initWithTabInfo:tabInfo frame:CGRectMake(buttonSize/2-48/2.0, 0 ,48, 48)];
        [tabButton setTag:count+10];
        [tabButton addTarget:self action:@selector(clickIndex:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:tabButton];
        [self addSubview:view];
        
        count++;
    }
}
-(void)clickIndex:(UIButton *)sender
{
    [self setSelectIndex:sender.tag - 10];
}
-(void)tapIndex:(UITapGestureRecognizer *)sender
{
    [self setSelectIndex:sender.view.tag-20];
}
- (void)setSelectIndex:(NSInteger)nIndex
{
    UIButton *oldBtn = (UIButton*)[self viewWithTag:_nIndex+10];
    oldBtn.selected = NO;
    UIButton *btn = (UIButton*)[self viewWithTag:nIndex+10];
    btn.selected = YES;
    _nIndex = nIndex;
    XCTabInfo *tabInfo = [_buttonData objectAtIndex:nIndex];
    if (_delegate && [_delegate respondsToSelector:@selector(selectIndex:)]) {
        [_delegate selectIndex:tabInfo.viewController];
    }
}





@end


@implementation XCTabInfo

-(id)initWithTabInfo:(NSString *)title normal:(NSString *)norImg high:(NSString*)highImg
{
    self = [super init];
    _strTitle = title;
    _strNorImg = norImg;
    _strHighImg = highImg;
    return self;
}

@end


