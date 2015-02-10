//
//  RecordViewController.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/30.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "RecordViewController.h"
#import "DevReocrdCell.h"
#import "CustomNaviBarView.h"
#import "DevInfoMacro.h"
#import "RecordDb.h"
#import "RecordModel.h"
#import "PlayNetViewController.h"

@interface RecordViewController ()
{
    NSMutableDictionary *deleteDic;
}
@property (nonatomic,strong) NSString *strNO;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *array;
@property (nonatomic,strong) UIButton *btnEdit;
@property (nonatomic,assign) int nStatus;
@end

@implementation RecordViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(id)init
{
    self = [super init];
    return self;
}
-(id)initWithNo:(NSString*)strNO status:(int)nStatus
{
    self = [super init];
    _strNO = strNO;
    _nStatus = nStatus;
    return self;
}
- (void)initUI
{
    
    [self setNaviBarTitle:NSLocalizedString(@"recordInfo", nil)];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                    imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
    _btnEdit = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnEdit.frame = Rect(0, 0, 40, 40);
    [_btnEdit setTitle:NSLocalizedString(@"RecordDelete", nil) forState:UIControlStateNormal];
    [_btnEdit setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_btnEdit addTarget:self action:@selector(delRecord:) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarRightBtn:_btnEdit];
}
-(void)delRecord:(id)sender
{
    UIButton *btn = sender;
    if ([btn.titleLabel.text isEqualToString:NSLocalizedString(@"RecordDelete", nil)]) {
        [btn setTitle:NSLocalizedString(@"RecordConfirm", nil) forState:UIControlStateNormal];// ＝ @"确定";
        [_tableView setEditing:YES animated:YES];
    }
    else
    {
        [btn setTitle:NSLocalizedString(@"RecordDelete", nil) forState:UIControlStateNormal];
        [_array removeObjectsInArray:[deleteDic allValues]];
        DLog(@"_array:%@--[deleteDic allValues]:%@",_array,[deleteDic allValues]);
        [RecordDb deleteRecord:[deleteDic allValues]];
        [deleteDic removeAllObjects];
        [_tableView reloadData];
        [_tableView setEditing:NO animated:YES];
    }
}
-(void)navBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initUI];
    _tableView = [[UITableView alloc] initWithFrame:Rect(0, [CustomNaviBarView barSize].height,kScreenWidth,
                                kScreenHeight-HEIGHT_MENU_VIEW(20,0)-[CustomNaviBarView barSize].height)];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _array = [[NSMutableArray alloc] initWithArray:[RecordDb queryRecord:_strNO]];
    deleteDic = [[NSMutableDictionary alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)shouldAutorotate
{
    return NO;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _array.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *staticIdentity = @"RecordDevIdentity";
    DevReocrdCell *cell = [tableView dequeueReusableCellWithIdentifier:staticIdentity];
    if (cell==nil)
    {
        cell = [[DevReocrdCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:staticIdentity];
        [cell setRecordInfo:[_array objectAtIndex:indexPath.row]];
        cell.imgView.image = _nStatus?[UIImage imageNamed:@"deviceOn"] : [UIImage imageNamed:@"deviceOff"];
    }
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 63;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_btnEdit.titleLabel.text isEqualToString:NSLocalizedString(@"RecordConfirm", nil)]) {
        [deleteDic setObject:[_array objectAtIndex:indexPath.row] forKey:indexPath];
        return;
    }
    RecordModel *record = [_array objectAtIndex:indexPath.row];
    PlayNetViewController *playControl = [[PlayNetViewController alloc] initWithContentPath:record parameters:nil];
    [self presentViewController:playControl animated:YES completion:^{}];
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_btnEdit.titleLabel.text isEqualToString:NSLocalizedString(@"RecordConfirm", nil)])
    {
        [deleteDic removeObjectForKey:indexPath];
    }
    
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}
@end
