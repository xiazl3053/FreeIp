//
//  ImageViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/10.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "ImageViewController.h"
#import "CustomNaviBarView.h"
#import "UtilsMacro.h"
#import "ImageCell.h"
#import "XCNotification.h"
#import "Picture.h"
#import "PhoneDb.h"
#import "RecordDb.h"
#import "RecordModel.h"
#import "PlayNetViewController.h"
#import "Toast+UIView.h"
#import "NSDate+convenience.h"
#import "RecordView.h"
#import "PictureView.h"
#import "XCPhoto.h"
#import "XCPhotoViewController.h"

@interface ImageViewController ()<UITableViewDelegate,UITableViewDataSource,RecordCellDelegate>
{
    int nSelect;
    BOOL bDel;
    NSMutableDictionary *deletePic;
    NSMutableDictionary *deleteRec;
    UILabel *lblNoImage;
    UIImageView *imgNo;
}
@property (nonatomic,strong) UITableView *tableView;

@property (nonatomic,strong) NSMutableArray *arrayInfo;
@property (nonatomic,strong) NSMutableArray *arrayRecord;
@property (nonatomic,strong) VRGCalendarView *vrgCalendar;
@property (nonatomic,strong) NSMutableArray *arySet;
@property (nonatomic,strong) NSMutableDictionary *tablePic;
@property (nonatomic,strong) NSMutableDictionary *tableRec;
@property (nonatomic,strong) UIView *queryView;

@end

@implementation ImageViewController

-(void)dealloc
{
    [_tableView removeFromSuperview];
    _tableView = nil;
    [_arrayInfo removeAllObjects];
    _arrayInfo = nil;
    [_vrgCalendar removeFromSuperview];
    _vrgCalendar = nil;
    [_arySet removeAllObjects];
    _arySet = nil;
    [_tablePic removeAllObjects];
    _tablePic = nil;
    [_tableRec removeAllObjects];
    _tableRec = nil;
    [_queryView removeFromSuperview];
    _queryView = nil;
    DLog(@"image view dealloc");
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth, kScreenHeight -[CustomNaviBarView barSize].height+HEIGHT_MENU_VIEW(20, 0))];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    _arrayRecord = [NSMutableArray array];
    _arrayInfo = [[NSMutableArray alloc] init];
    _vrgCalendar = [[VRGCalendarView alloc] init];
    _vrgCalendar.delegate=self;
    _vrgCalendar.frame = CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth, 260);
    [self.view addSubview:_vrgCalendar];
    _vrgCalendar.hidden = YES;

    //查询面板
    [self addQueryView];
    
    deletePic = [NSMutableDictionary dictionary];
    deleteRec = [NSMutableDictionary dictionary];
    _arySet = [NSMutableArray array];
    _tablePic = [NSMutableDictionary dictionary];
    _tableRec = [NSMutableDictionary dictionary];
    
    imgNo = [[UIImageView alloc] initWithFrame:Rect((kScreenWidth-99)/2, (kScreenHeight-[CustomNaviBarView barSize].height-70)/2, 99, 70)];
    [imgNo setImage:[UIImage imageNamed:@"noImage"]];
    imgNo.contentMode = UIViewContentModeScaleAspectFit;
    
    imgNo.tag = 3059;
    
    lblNoImage = [[UILabel alloc] initWithFrame:Rect(0, imgNo.frame.origin.y+imgNo.frame.size.height+10, kScreenWidth, 20)];
    [lblNoImage setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    [lblNoImage setText:XCLocalized(@"noRecording")];
    [lblNoImage setTextAlignment:NSTextAlignmentCenter];
    
    lblNoImage.tag = 3060;
    [_tableView addSubview:imgNo];
    [_tableView addSubview:lblNoImage];
    imgNo.hidden = YES;
    lblNoImage.hidden = YES;
    
    [self initData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateImageList) name:NS_UPDATE_IMAGE_VC object:nil];
}

-(void)addQueryView
{
    _queryView = [[UIView alloc] initWithFrame:Rect(0,[CustomNaviBarView barSize].height, kScreenWidth, 48)];

    UILabel *label = [[UILabel alloc] initWithFrame:Rect(10,12,40,15)];
    UILabel *lblStart = [[UILabel alloc] initWithFrame:Rect(52, 12, (kScreenWidth-150)/2, 15)];
    UILabel *label2 = [[UILabel alloc] initWithFrame:Rect((kScreenWidth-150)/2+55, 12, 40, 15)];
    UILabel *lblEnd = [[UILabel alloc] initWithFrame:Rect((kScreenWidth-150)/2+95, 12, (kScreenWidth-150)/2, 15)];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = Rect(lblEnd.frame.origin.x+lblEnd.frame.size.width+10, 2 , 44, 44);
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

    [_arySet removeAllObjects];
    [_tablePic removeAllObjects];
    [_tableRec removeAllObjects];
    
    NSArray *aryShoto = [PhoneDb queryPicByTimeSE:lblStart.text end:lblEnd.text];
    
    NSMutableSet *set = [NSMutableSet set];
    for (PictureModel *pic in aryShoto)
    {
        [set addObject:pic.strTime];
        NSMutableArray *array = [_tablePic objectForKey:pic.strTime];
        if (!array)
        {
            array = [NSMutableArray array];
        }
        [array addObject:pic];
        [_tablePic setObject:array forKey:pic.strTime];
        
    }
    
    NSArray *aryRecord = [RecordDb queryRecordByTimeSE:lblStart.text end:lblEnd.text];
    for (RecordModel *record in aryRecord)
    {
        NSString *strFormat = ([record.strStartTime componentsSeparatedByString:@" "])[0];
        [set addObject:strFormat];
        NSMutableArray *array = [_tableRec objectForKey:strFormat];
        if (!array)
        {
            array = [NSMutableArray array];
        }
        [array addObject:record];
        [_tableRec setObject:array forKey:strFormat];
    }
    
    [self sortDate:(NSArray*)set];
    
    DLog(@"arySet:%@",_arySet);
    __weak ImageViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^
   {
       [weakSelf updateBackImage];
   });
}

-(void)sortDate:(NSArray*)array
{
    NSMutableArray *dataArray=[[NSMutableArray alloc]initWithCapacity:0];
    
    for (NSString *strTime in array)
    {
        NSMutableDictionary *dir=[[NSMutableDictionary alloc]init];
        [dir setObject:strTime forKey:@"time"];
        [dataArray addObject:dir];
    }
    
    NSMutableArray *myArray=[[NSMutableArray alloc]initWithCapacity:0];
    [myArray addObjectsFromArray:dataArray];
    
    NSSortDescriptor*sorter=[[NSSortDescriptor alloc] initWithKey:@"time" ascending:YES];
    NSMutableArray *sortDescriptors=[[NSMutableArray alloc]initWithObjects:&sorter count:1];
    NSArray *newArray = [myArray sortedArrayUsingDescriptors:sortDescriptors];
    
    for (NSInteger i=[newArray count]-1; i>=0; i--)
    {
        [_arySet addObject:[[newArray objectAtIndex:i] objectForKey:@"time"]];
    }
    
}

-(void)updateImageList
{
    
    [_arrayRecord removeAllObjects];
    [_arrayInfo removeAllObjects];
    [_arySet removeAllObjects];
    [_tablePic removeAllObjects];
    [_tableRec removeAllObjects];
    
    [self getAllDir];
    
}
-(void)initUI
{
    [self setNaviBarTitle:XCLocalized(@"picturesView")];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back"] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:@"NaviBtn_Back_g"] forState:UIControlStateSelected];
    [btn addTarget:self action:@selector(navBack) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarLeftBtn:btn];
    
    UIButton *btnDel = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnDel setImage:[UIImage imageNamed:@"dustbin_ico"] forState:UIControlStateNormal];
    [btnDel setImage:[UIImage imageNamed:@"ok_ico"] forState:UIControlStateSelected];
    [btnDel addTarget:self action:@selector(delRecord:) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarRightBtn:btnDel];

    
}

-(void)delRecord:(UIButton*)btn
{
    if (btn.selected)
    {
        //确认删除
        btn.selected = NO;
        NSArray *array = [deletePic allValues];
        for (PictureModel *pic in array) {
            [PhoneDb deleteRecordById:pic.nId];
        }
        NSArray *arrayRecord = [deleteRec allValues];
        [RecordDb deleteRecord:arrayRecord];
        [self initData];
        bDel = NO;
    }
    else
    {
        bDel = YES;
        btn.selected = YES;
    }
}

-(void)initData
{
    [_arySet removeAllObjects];
    [_tablePic removeAllObjects];
    [_tableRec removeAllObjects];
    [self getAllDir];
}
-(void)getAllDir
{
    NSArray *aryShoto = [PhoneDb queryAllPhone];
    NSMutableSet *set = [NSMutableSet set];
    for (PictureModel *pic in aryShoto)
    {
        [set addObject:pic.strTime];
        NSMutableArray *array = [_tablePic objectForKey:pic.strTime];
        if (!array)
        {
            array = [NSMutableArray array];
        }
        [array addObject:pic];
        [_tablePic setObject:array forKey:pic.strTime];
    }
    NSArray *aryRecord = [RecordDb queryAllRecord];
    for (RecordModel *record in aryRecord)
    {
        NSString *strFormat = ([record.strStartTime componentsSeparatedByString:@" "])[0];
        [set addObject:strFormat];
        NSMutableArray *array = [_tableRec objectForKey:strFormat];
        if (!array)
        {
            array = [NSMutableArray array];
        }
        [array addObject:record];
        [_tableRec setObject:array forKey:strFormat];
    }

    [self sortDate:(NSArray*)set];
    DLog(@"sort:%@",_arySet);
    __weak ImageViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [weakSelf updateBackImage];
    });
    
}
-(void)getDirByTime:(NSString *)strTime
{
    [_arySet removeAllObjects];
    [_tablePic removeAllObjects];
    [_tableRec removeAllObjects];
    
    NSArray *aryShoto = [PhoneDb queryRecordByTime:strTime];
    for (PictureModel *pic in aryShoto)
    {
        [_arySet addObject:pic.strTime];
        NSMutableArray *array = [_tablePic objectForKey:pic.strTime];
        if (!array)
        {
            array = [NSMutableArray array];
        }
        [array addObject:pic];
        [_tablePic setObject:array forKey:pic.strTime];
        
    }
    
    NSArray *aryRecord = [RecordDb queryRecordByTime:strTime];
    for (RecordModel *record in aryRecord)
    {
        NSString *strFormat = ([record.strStartTime componentsSeparatedByString:@" "])[0];
        [_arySet addObject:strFormat];
        NSMutableArray *array = [_tableRec objectForKey:strFormat];
        if (!array)
        {
            array = [NSMutableArray array];
        }
        [array addObject:record];
        [_tableRec setObject:array forKey:strFormat];
    }
    __weak ImageViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^
   {
       [weakSelf.tableView reloadData];
   });
}

-(BOOL)isFileExistAtPath:(NSString*)fileFullPath
{
    BOOL isExist = NO;
    isExist = [[NSFileManager defaultManager] fileExistsAtPath:fileFullPath];
    return isExist;
}

-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *strXCTableViewImagePath = @"XCTableViewImagePathIdentifier";
    ImageCell *cell = [tableView dequeueReusableCellWithIdentifier:strXCTableViewImagePath];
    if (cell==nil)
    {
        cell = [[ImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strXCTableViewImagePath];
    }
    UIView *backView = [[UIView alloc] initWithFrame:cell.frame];
    cell.selectedBackgroundView = backView;
    cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
    cell.nRow = indexPath.row;
    //先获取日期
    NSString *strTime = [_arySet objectAtIndex:indexPath.section];
    NSArray *aryInfo = [_tablePic objectForKey:strTime];
    NSArray *aryRecord = [_tableRec objectForKey:strTime];
    [cell setArrayInfo:aryInfo record:aryRecord];
    cell.delegate = self;
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _arySet.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_arySet objectAtIndex:section];
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *strTime = [_arySet objectAtIndex:indexPath.section];
    NSArray *aryInfo = [_tablePic objectForKey:strTime];
    NSArray *aryRecord = [_tableRec objectForKey:strTime];
    NSInteger nInfo,nRecord;

    nInfo = aryInfo ? aryInfo.count : 0 ;
    nRecord = aryRecord ? aryRecord.count : 0;

    
    NSInteger nLength = nInfo+nRecord;
    NSInteger nRow = (nLength%3 == 0) ? (nLength/3) : (nLength/3 + 1);
    return 4+nRow * 144;
}

-(void)calendarView:(VRGCalendarView *)calendarView switchedToMonth:(int)month targetHeight:(float)targetHeight animated:(BOOL)animated
{
    
}
-(void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date
{
    NSString *strTime = [NSString stringWithFormat:@"%d-%02d-%02d",[date year],[date month],[date day]];
    UILabel *lblSatart = (UILabel*)[_queryView viewWithTag:1003];
    UILabel *lblEnd = (UILabel*)[_queryView viewWithTag:1004];
    _vrgCalendar.currentMonth = date;
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYY-MM-dd"];
    NSDate *startDate = [dateFormat dateFromString:strTime];
    if (nSelect == 1)
    {
        NSDate *dateEnd = [dateFormat dateFromString:lblEnd.text];
        if(dateEnd.timeIntervalSince1970 >= startDate.timeIntervalSince1970)
        {
            lblSatart.text = strTime;
        }
        else
        {
            //开始日期不能大于结束日期
            [self.view makeToast:XCLocalized(@"startOEnd")];
        }
    }
    else if(nSelect == 2)
    {
        
        NSDate *dateStart = [dateFormat dateFromString:lblSatart.text];
        long lStart = dateStart.timeIntervalSince1970;
        long lTemp = startDate.timeIntervalSince1970;
        if(lStart <= lTemp)
        {
            lblEnd.text = strTime;
        }
        else
        {
            //结束日期不能大于开始日期
            [self.view makeToast:XCLocalized(@"endOStart")];
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

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectTitle) name:NS_CUSTOM_BAR_TITLE_VC object:nil];
}

-(void)selectTitle
{
    if (!_vrgCalendar.hidden)
    {
        return;
    }
    _queryView.hidden = _queryView.hidden ? NO : YES;
    if (!_queryView.hidden)
    {
        _tableView.frame = Rect(0, [CustomNaviBarView barSize].height+48, kScreenWidth, kScreenHeight-[CustomNaviBarView barSize].height-48+HEIGHT_MENU_VIEW(20, 0));
    }
    else
    {
        _tableView.frame = Rect(0, [CustomNaviBarView barSize].height, kScreenWidth, kScreenHeight-[CustomNaviBarView barSize].height+HEIGHT_MENU_VIEW(20, 0));
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)addPicView:(ImageCell*)imgCell view:(UIView*)view index:(NSInteger)nIndex
{
    PictureModel *picModel = [PhoneDb queryPicByIndex:nIndex];
    PictureView *picView = (PictureView *)[view superview];
    if (!bDel)
    {
        int nStart = 0;
        for(int i=0;i<imgCell.aryImage.count;i++)
        {
            XCPhoto *photo = [imgCell.aryImage objectAtIndex:i];
            if (photo.nId == nIndex)
            {
                nStart = i;
                break;
            }
        }
        XCPhotoViewController *viewController = [[XCPhotoViewController alloc] initWithArray:imgCell.aryImage current:nStart];
        [viewController show];
//        MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
//        browser.currentPhotoIndex = nStart; // 弹出相册时显示的第一张图片是？
//        browser.photos = imgCell.aryImage; // 设置所有的图片
//        [browser show];
    }
    else
    {
        [imgCell.aryImage removeAllObjects];
        if(!picView.imgSelect.hidden)
        {
            [deletePic removeObjectForKey:[[NSNumber alloc] initWithInteger:nIndex]];
        }
        else
        {
            [deletePic setObject:picModel forKey:[[NSNumber alloc] initWithInteger:nIndex]];
        }
        DLog(@"deleteDic:%@",deletePic);
        picView.imgSelect.hidden = picView.imgSelect.hidden ? NO : YES;
    }
}

-(void)addRecordView:(ImageCell*)imgCell view:(UIView*)view index:(NSInteger)nIndex
{
    RecordModel *recordModel = [RecordDb queryRecordById:nIndex];
    RecordView *rdView = (RecordView *)[view superview];
    if (!bDel)
    {
        RecordModel *record = [RecordDb queryRecordById:nIndex];
        PlayNetViewController *playControl = [[PlayNetViewController alloc] initWithContentPath:record parameters:nil];
        [self presentViewController:playControl animated:YES completion:^{}];
    }
    else
    {
        if(!rdView.imgSelect.hidden)
        {
            [deleteRec removeObjectForKey:[[NSNumber alloc] initWithInteger:nIndex]];
        }
        else
        {
            [deleteRec setObject:recordModel forKey:[[NSNumber alloc] initWithInteger:nIndex]];
        }
        rdView.imgSelect.hidden = rdView.imgSelect.hidden ? NO : YES;
    }
}


-(void)updateBackImage
{
    [_tableView reloadData];
    lblNoImage.hidden = YES;
    imgNo.hidden = YES;
    if (_arySet.count==0)
    {    
        lblNoImage.hidden = NO;
        imgNo.hidden = NO;
    }
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *myHeader = [[UIView alloc] initWithFrame:Rect(0, 0, kScreenWidth, 30)];
    [myHeader setBackgroundColor:RGB(236, 236, 236)];
    UILabel *myLabel = [[UILabel alloc] init];
    [myLabel setFrame:CGRectMake(10, 0, kScreenWidth, 30)];
    [myLabel setTag:101];
    [myLabel setBackgroundColor:[UIColor clearColor]];
    NSString *strInfo = [NSString stringWithFormat:@"%@",[_arySet  objectAtIndex:section]];
    [myLabel setFont:[UIFont fontWithName:@"Helvetica" size:14.0f]];
    [myLabel setTextColor:RGB(173, 173, 173)];
    [myLabel setText:strInfo];
    
    [myHeader addSubview:myLabel];
    return myHeader;
}



@end








