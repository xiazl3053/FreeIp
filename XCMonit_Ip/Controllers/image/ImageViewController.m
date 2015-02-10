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

@interface ImageViewController ()<UITableViewDelegate,UITableViewDataSource>
{

}
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *arrayHeader;
@property (nonatomic,strong) NSMutableArray *arrayFile;
@property (nonatomic,strong) NSMutableDictionary *arrayDict;
@end

@implementation ImageViewController

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
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [CustomNaviBarView barSize].height, kScreenWidth, kScreenHeight -[CustomNaviBarView barSize].height)];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _arrayHeader = [NSMutableArray array];
    _arrayFile = [NSMutableArray array];
    _arrayDict = [[NSMutableDictionary alloc] init];
    [self initData];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateImageList) name:NS_UPDATE_IMAGE_VC object:nil];
}
-(void)updateImageList
{
    [_arrayHeader removeAllObjects];
    [_arrayFile removeAllObjects];
    [_arrayDict removeAllObjects];
    [self getAllDir];
    __weak ImageViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^
   {
       [weakSelf.tableView reloadData];
   });
    
}
-(void)initUI
{
    [self setNaviBarTitle:NSLocalizedString(@"picturesView", nil)];
    UIButton *btn = [CustomNaviBarView createImgNaviBarBtnByImgNormal:@"NaviBtn_Back"
                                                         imgHighlight:@"NaviBtn_Back_g" imgSelected:nil target:self action:@selector(navBack)];
    [self setNaviBarLeftBtn:btn];
}
-(void)initData
{
    [self getAllDir];
    
}
-(void)getAllDir
{
    NSArray *contentOfFolder = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:kLibaryShoto error:NULL];
    for (NSString *aPath in contentOfFolder) {
        NSString * fullPath = [kLibaryShoto stringByAppendingPathComponent:aPath];
        BOOL isDir;
        //获取shoto下面所有的目录
        if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] && isDir)
        {
            [_arrayHeader addObject:aPath];//如果是目录，则加入到_arrayHeader中
            
            //查找shoto/日期 下面的文件   如果文件后缀名为PNG,则加入到_arrayFile中
            NSArray *_arrayPng = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullPath error:NULL];
            NSMutableArray *arrayList = [[NSMutableArray alloc] init];
            for (NSString *filename in _arrayPng)
            {
                NSString *filepath = [fullPath stringByAppendingPathComponent:filename];
                if ([self isFileExistAtPath:filepath])
                {
                    if ([[filename pathExtension] isEqualToString:@"png"] || [[filename pathExtension] isEqualToString:@"jpg"])
                    {
                        [arrayList addObject:[fullPath stringByAppendingPathComponent:filename]];
                    }
                }
            }
            if(arrayList.count>0)
            {
                [_arrayFile addObject:arrayList];
                [_arrayDict setObject:[_arrayFile objectAtIndex:_arrayFile.count-1] forKey:aPath];
            }
            else
            {
                [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
                [_arrayHeader removeObject:aPath];
            }
            
        }
    }
}
-(BOOL)isFileExistAtPath:(NSString*)fileFullPath {
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
 //   static NSString *strXCTableViewImagePath = @"XCTableViewImagePathIdentifier";
    
    NSString *strInfo = [_arrayHeader objectAtIndex:indexPath.section];
    NSArray *array = [_arrayDict objectForKey:strInfo];
    
    ImageCell *cell = [tableView dequeueReusableCellWithIdentifier:strInfo];

    if (cell==nil)
    {
        cell = [[ImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strInfo];
    }
    if(_arrayHeader.count > indexPath.section)
    {
        NSString *strInfo = [_arrayHeader objectAtIndex:indexPath.section];
        array = [_arrayDict objectForKey:strInfo];
        //获取到所有图片的路径,
        cell.strFile = strInfo;
    }
    if (cell.array.count != array.count)
    {
        [cell setArrayInfo:array];
    }
    UIView *backView = [[UIView alloc] initWithFrame:cell.frame];
    cell.selectedBackgroundView = backView;
    cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
    return cell;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _arrayHeader.count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_arrayHeader objectAtIndex:section];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *strInfo = [_arrayHeader objectAtIndex:indexPath.section];
    NSArray *array = [_arrayDict objectForKey:strInfo];
    int nRow = (array.count%4 == 0) ? (array.count/4) : (array.count/4 + 1);
    return 8+nRow * 75 +5;
}
/*
  lipo -create /Users/xiazhonglin/Desktop/iosp2p/avmv7/libenet.a
    /Users/xiazhonglin/Desktop/iosp2p/armv7s/libenet.a -output
    /Users/xiazhonglin/Desktop/iosp2p/new/libenet.a
 
    lipo -create /Users/xiazhonglin/Desktop/iosp2p/armv7/libenet.a /Users/xiazhonglin/Desktop/iosp2p/armv7s/libenet.a -output /Users/xiazhonglin/Desktop/iosp2p/libenet.a
 
     lipo -create /Users/xiazhonglin/Desktop/iosp2p/armv7/libnattrav.a /Users/xiazhonglin/Desktop/iosp2p/armv7s/libnattrav.a -output /Users/xiazhonglin/Desktop/iosp2p/libnattrav.a
 
 lipo -create /Users/xiazhonglin/Desktop/iosp2p/armv7/librutil.a /Users/xiazhonglin/Desktop/iosp2p/armv7s/librutil.a -output /Users/xiazhonglin/Desktop/iosp2p/librutil.a
 
  lipo -create /Users/xiazhonglin/Desktop/iosp2p/armv7/libsdkclient.a /Users/xiazhonglin/Desktop/iosp2p/armv7s/libsdkclient.a -output /Users/xiazhonglin/Desktop/iosp2p/libsdkclient.a
 
 libnattrav.a  librutil.a libsdkclient.a
 
*/
@end
