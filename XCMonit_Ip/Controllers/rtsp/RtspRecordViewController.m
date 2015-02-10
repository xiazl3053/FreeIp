//
//  RtspRecordViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/9/16.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RtspRecordViewController.h"
#import "CustomNaviBarView.h"
#import "RecordModel.h"
#import "RecordNOCell.h"
#import "RecordView.h"
#import "VRGCalendarView.h"
#import "NSDate+convenience.h"
#import "RecordDb.h"
#import "PlayNetViewController.h"
#import "Toast+UIView.h"
#import "XCNotification.h"

@interface RtspRecordViewController ()<RecordNOCellDelegate,VRGCalendarViewDelegate>
{
    BOOL bDelRecord;
    NSMutableDictionary *deleteDic;
    int nSelect;
}
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSString *strPath;
@property (nonatomic,strong) NSString *strDevName;
@property (nonatomic,strong) UIButton *btnEdit;
@property (nonatomic,strong) VRGCalendarView *vrgCalendar;
@property (nonatomic,strong) UIView *queryView;




@property (nonatomic,strong) NSString *strNO;

@property (nonatomic,strong) NSMutableArray *array;

@property (nonatomic,assign) int nStatus;
@property (nonatomic,strong) NSMutableSet *arySet;
@property (nonatomic,strong) NSMutableDictionary *tableDic;


@end

@implementation RtspRecordViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)initUI
{
    
    [self setNaviBarTitle:XCLocalized(@"recordInfo")];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    _btnEdit = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnEdit.frame = Rect(0, 0, 40, 40);
    [_btnEdit setImage:[UIImage imageNamed:@"dustbin"] forState:UIControlStateNormal];
    [_btnEdit setImage:[UIImage imageNamed:@"ok_ico"] forState:UIControlStateHighlighted];
    [_btnEdit setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_btnEdit addTarget:self action:@selector(delRecord:) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarRightBtn:_btnEdit];
}
-(void)delRecord:(UIButton*)btn
{
    if (!btn.selected)
    {
        bDelRecord = YES;
        btn.selected = YES;
    }
    else
    {
        bDelRecord = NO;
        btn.selected = NO;
        [RecordDb deleteRecord:[deleteDic allValues]];
        __weak RtspRecordViewController *_weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_weakSelf initData];
            [_weakSelf.tableView reloadData];
        });
    }
}

-(void)initData
{
    [_arySet removeAllObjects];
    [_tableDic removeAllObjects];
    NSArray *array = [RecordDb queryRtsp:_strPath name:_strDevName];//+(NSArray*)queryRtsp:(NSString*)strPath name:(NSString*)strDevName
    for (RecordModel *record in array) {
        NSString *strFormat = ([record.strStartTime componentsSeparatedByString:@" "])[0];
        [_arySet addObject:strFormat];
        NSMutableArray *array = [_tableDic objectForKey:strFormat];
        if (!array)
        {
            array = [NSMutableArray array];
        }
        [array addObject:record];
        [_tableDic setObject:array forKey:strFormat];
    }
}


-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    _tableView = [[UITableView alloc] initWithFrame:Rect(0, [CustomNaviBarView barSize].height,kScreenWidth,
                                                                           kScreenHeight-[CustomNaviBarView barSize].height+HEIGHT_MENU_VIEW(20, 0))];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    _vrgCalendar = [[VRGCalendarView alloc] init];
    _vrgCalendar.delegate=self;
    _vrgCalendar.frame = CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth, 260);
    [self.view addSubview:_vrgCalendar];
    _vrgCalendar.hidden = YES;
    
    _queryView = [[UIView alloc] initWithFrame:Rect(0,[CustomNaviBarView barSize].height, kScreenWidth, 48)];
    UILabel *label = [[UILabel alloc] initWithFrame:Rect(10,12,40,15)];
    UILabel *lblStart = [[UILabel alloc] initWithFrame:Rect(52, 12, 80, 15)];
    UILabel *label2 = [[UILabel alloc] initWithFrame:Rect(135, 12, 40, 15)];
    UILabel *lblEnd = [[UILabel alloc] initWithFrame:Rect(177, 12, 80, 15)];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = Rect(270, 2 , 44, 44);
    [label setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [lblStart setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [label2 setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [lblEnd setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    
    label.text = XCLocalized(@"startTime");
    label2.text = XCLocalized(@"endTime");
    lblStart.textColor = RGB(15,173,225);
    lblEnd.textColor = RGB(15, 173, 225);
    
    NSDate *date = [NSDate date];
    NSString *strEnd = [NSString stringWithFormat:@"%d-%02d-%02d",date.year,date.month,date.day];
    NSDate *agoDate = [NSDate dateWithTimeIntervalSinceNow:-7*24*60*60];
    NSString *strStart = [NSString stringWithFormat:@"%d-%02d-%02d",agoDate.year,agoDate.month,agoDate.day];
    lblStart.text = strStart;
    lblEnd.text = strEnd;
    [lblStart addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(startDate)]];
    [lblEnd addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endDate)]];
    [lblEnd setUserInteractionEnabled:YES];
    [lblStart setUserInteractionEnabled:YES];
    
    label.textColor = [UIColor blackColor];
    label2.textColor = [UIColor blackColor];
    [btn setImage:[UIImage imageNamed:@"query"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@""] forState:UIControlStateHighlighted];
    
    [btn addTarget:self action:@selector(queryRecordInfo) forControlEvents:UIControlEventTouchUpInside];
    
    [_queryView addSubview:lblStart];
    [_queryView addSubview:label];
    [_queryView addSubview:label2];
    [_queryView addSubview:lblEnd];
    [_queryView addSubview:btn];
    
    label.tag = 1001;
    label2.tag = 1002;
    lblStart.tag = 1003;
    lblEnd.tag = 1004;
    btn.tag = 1005;
    
    [self.view insertSubview:_queryView aboveSubview:_tableView];
    _queryView.hidden = YES;
    
    deleteDic = [[NSMutableDictionary alloc] init];
    _arySet = [NSMutableSet set];
    _tableDic = [NSMutableDictionary dictionary];
    [self initData];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectTitle) name:NS_CUSTOM_BAR_TITLE_VC object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)selectTitle
{
    if (!_vrgCalendar.hidden) {
        return;
    }
    _queryView.hidden = _queryView.hidden ? NO : YES;
    if (!_queryView.hidden)
    {
        _tableView.frame = Rect(0, [CustomNaviBarView barSize].height+48, kScreenWidth, kScreenHeight-[CustomNaviBarView barSize].height-48);
    }
    else
    {
        _tableView.frame = Rect(0, [CustomNaviBarView barSize].height, kScreenWidth, kScreenHeight-[CustomNaviBarView barSize].height);
    }
}

-(void)startDate
{
    nSelect = 1;
    _vrgCalendar.hidden = NO;
}
-(void)endDate
{
    nSelect = 2;
    _vrgCalendar.hidden = NO;
}

-(void)queryRecordInfo
{
    UILabel *lblStart = (UILabel*)[_queryView viewWithTag:1003];
    UILabel *lblEnd = (UILabel*)[_queryView viewWithTag:1004];
    //queryRtspByTimeSE
    NSArray *array = [RecordDb queryRtspByTimeSE:_strPath name:_strDevName start:lblStart.text endTime:lblEnd.text];
    [_arySet removeAllObjects];
    [_tableDic removeAllObjects];
    for (RecordModel *record in array)
    {
        NSString *strFormat = ([record.strStartTime componentsSeparatedByString:@" "])[0];
        [_arySet addObject:strFormat];
        NSMutableArray *array = [_tableDic objectForKey:strFormat];
        if (!array)
        {
            array = [NSMutableArray array];
        }
        [array addObject:record];
        [_tableDic setObject:array forKey:strFormat];
    }
    __weak RtspRecordViewController *__weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [__weakSelf.tableView reloadData];
    });
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(id)initWithPath:(NSString*)strPath name:(NSString*)strDevName
{
    self = [super init];
    _strPath = strPath;
    _strDevName = strDevName;
    return self;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *staticIdentity = @"RecordDevIdentity";
    RecordNOCell *cell = [tableView dequeueReusableCellWithIdentifier:staticIdentity];
    if (cell==nil)
    {
        cell = [[RecordNOCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:staticIdentity];
    }
    UIView *backView = [[UIView alloc] initWithFrame:cell.frame];
    cell.selectedBackgroundView = backView;
    cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
    
    cell.delegate = self;
    NSString *strTime = [_arySet.allObjects objectAtIndex:indexPath.section];
    NSArray *aryInfo = [_tableDic objectForKey:strTime];
    [cell setArrayRecord:aryInfo];
    return cell;
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *strTime = [_arySet.allObjects objectAtIndex:indexPath.section];
    NSArray *aryInfo = [_tableDic objectForKey:strTime];
    NSInteger nInfo;
    nInfo = aryInfo ? aryInfo.count : 0 ;
    NSInteger nLength = nInfo;
    NSInteger nRow = (nLength%3 == 0) ? (nLength/3) : (nLength/3 + 1);
    return 2+nRow * 150;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_btnEdit.titleLabel.text isEqualToString:XCLocalized(@"RecordConfirm")])
    {
        
    }
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _arySet.allObjects.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[_arySet allObjects] objectAtIndex:section];
}

-(void)recordNOCell:(UIView*)view index:(NSInteger)nId
{
    RecordModel *recordModel = [RecordDb queryRecordById:nId];
    if(!bDelRecord)
    {
        PlayNetViewController *playControl = [[PlayNetViewController alloc] initWithContentPath:recordModel parameters:nil];
        [self presentViewController:playControl animated:YES completion:^{}];
    }
    else
    {
        RecordView *rdView = (RecordView *)[view superview];
        if(!rdView.imgSelect.hidden)
        {
            [deleteDic removeObjectForKey:[[NSNumber alloc] initWithInteger:nId]];
        }
        else
        {
            [deleteDic setObject:recordModel forKey:[[NSNumber alloc] initWithInteger:nId]];
        }
        DLog(@"deleteDic:%@",deleteDic);
        
        rdView.imgSelect.hidden = rdView.imgSelect.hidden ? NO : YES;
    }
}

-(void)calendarView:(VRGCalendarView *)calendarView switchedToMonth:(int)month targetHeight:(float)targetHeight animated:(BOOL)animated
{
    
}
-(void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date
{
    DLog(@"Selected date = %@",date);
    NSString *strTime = [NSString stringWithFormat:@"%d-%02d-%02d",[date year],[date month],[date day]];
    UILabel *lblSatart = (UILabel*)[_queryView viewWithTag:1003];
    UILabel *lblEnd = (UILabel*)[_queryView viewWithTag:1004];
    _vrgCalendar.currentMonth = date;
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYY-MM-dd"];
    
    if (nSelect == 1) {
        NSDate *dateEnd = [dateFormat dateFromString:lblEnd.text];
        
        if(dateEnd.timeIntervalSinceNow >= date.timeIntervalSinceNow)
        {
            lblSatart.text = strTime;
        }
        else
        {
            //开始日期不能大于结束日期
            [self.view makeToast:@"开始日期不能在结束日期之后"];
        }
    }
    else if(nSelect == 2)
    {
        
        NSDate *dateStart = [dateFormat dateFromString:lblSatart.text];
        if(dateStart.timeIntervalSinceNow <= date.timeIntervalSinceNow)
        {
            lblEnd.text = strTime;
        }
        else
        {
            //结束日期不能大于开始日期
            [self.view makeToast:@"结束日期不能在开始日期之前"];
        }
    }
    
    _vrgCalendar.hidden = YES;
}

#pragma mark 重力处理
- (BOOL)shouldAutorotate
{
    return NO;
}
-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
