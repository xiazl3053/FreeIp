//
//  ImageCellTableViewCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/11.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "ImageCell.h"
#import "UtilsMacro.h"
#import "Picture.h"
#import "RecordModel.h"
#import "RecordView.h"
#import "PictureView.h"
#import "XCPhoto.h"


@interface ImageCell()
{
    NSMutableArray *arrayView;
    NSMutableArray *arrayPic;
}
@property (nonatomic,strong) NSArray *arrayRecord;
@end

@implementation ImageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        arrayPic = [NSMutableArray array];
        _aryImage = [NSMutableArray array];
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setArrayInfo:(NSArray*)array record:(NSArray*)aryRecord
{
    _bDel = NO;
    [_aryImage removeAllObjects];
    if (_array)
    {
        [_array removeAllObjects];
        _array = nil;
    }
    if (_arrayRecord) {
        _arrayRecord = nil;
    }
    if (arrayView) {
        [arrayView removeAllObjects];
    }
    _arrayRecord = [[NSArray alloc] initWithArray:aryRecord];
    arrayView = [[NSMutableArray alloc] init];
    if(array.count>0)
    {
        _array = [[NSMutableArray alloc] initWithArray:array];
    }
    else
    {
        _array = [[NSMutableArray alloc] init];
    }
    
    [self freshCell];
}

-(void)freshCell
{
    [arrayPic removeAllObjects];
    for (UIView *view in self.contentView.subviews)
    {
        [view removeFromSuperview];
    }
    CGFloat width = kScreenWidth/3-2;//105
    CGFloat height = 144;
    NSInteger nLength = _arrayRecord.count+_array.count;
    for (int i = 0; i<nLength; i++)
    {
        // 计算位置
        int row = i/3;
        int column = i%3;
        CGFloat x = 1 + column * (width+2);
        CGFloat y = 4 + row * height;//149
        if(i<_array.count)
        {
            PictureModel *picModel = (PictureModel *)[_array objectAtIndex:i];
            PictureView *picView = [[PictureView alloc] initWithFrame:Rect(x, y, width, height)];
            [self.contentView addSubview:picView];
            
            [picView.lblDev setText:picModel.strDevName];//设备名
            NSString *time = [picModel.strFile stringByDeletingPathExtension];
            NSString *hour = [time substringWithRange:NSMakeRange(0, 2)];
            NSString *minite = [time substringWithRange:NSMakeRange(2, 2)];
            NSString *second = [time substringWithRange:NSMakeRange(4, 2)];
            NSString *strTime = [NSString stringWithFormat:@"%@:%@:%@",hour,minite,second];
            [picView.lblTime setText:strTime];
            
            picView.imgView.userInteractionEnabled=YES;//图片属性设置
            [picView.imgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)]];
            picView.imgView.tag = picModel.nId;
            
            
            __weak PictureView *__picView = picView;
            NSString *strPath = [NSString stringWithFormat:@"%@/shoto/%@/%@",kLibraryPath,picModel.strTime,picModel.strFile];
            picView.strPath = strPath;
            __block NSString *__strPath = strPath;
            dispatch_async(dispatch_get_global_queue(0, 0),
            ^{
                    UIImage *image = [[UIImage alloc] initWithContentsOfFile:__strPath];
                    dispatch_async(dispatch_get_main_queue(),^
                    {
                          [__picView.imgView setImage:image];
                    });
           });
           [arrayView addObject:picView.imgView];
           [arrayPic addObject:picView];
        }
        else
        {
            //录像记录View
            RecordView *rdView = [[RecordView alloc] initWithFrame:Rect(x, y, width, height)];
            [self.contentView addSubview:rdView];
            RecordModel *recordModel = (RecordModel *)[_arrayRecord objectAtIndex:i-_array.count];
            
            [rdView.lblDev setText:recordModel.strDevName];//设备名
            
            NSString *strTime = ([[recordModel.strStartTime stringByDeletingPathExtension] componentsSeparatedByString:@" "])[1];
            if ([strTime rangeOfString:@"-"].location != NSNotFound)
            {
                NSString *newStrTime = [strTime stringByReplacingOccurrencesOfString:@"-" withString:@":"];
                [rdView.lblTime setText:newStrTime];//时间
            }
            else
            {
                [rdView.lblTime setText:strTime];
            }
            
            rdView.imgView.userInteractionEnabled=YES;//图片属性设置
            [rdView.imgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecord:)]];
            rdView.imgView.tag = recordModel.nId;

            __weak RecordView *__rdView = rdView;
            NSString *strPath = [NSString stringWithFormat:@"%@/record/%@",kLibraryPath,recordModel.imgFile];
            __block NSString *__strPath = strPath;
            dispatch_async(dispatch_get_global_queue(0, 0),
           ^{
                 UIImage *image = [[UIImage alloc] initWithContentsOfFile:__strPath];
                 dispatch_async(dispatch_get_main_queue(),^
                 {
                      [__rdView.imgView setImage:image];
                 });
           });
        }
    }
}
-(void)tapRecord:(UITapGestureRecognizer*)tap
{
        //选择
        if(_delegate && [_delegate respondsToSelector:@selector(addRecordView:view:index:)])
        {
            [_delegate addRecordView:self view:tap.view index:tap.view.tag];
        }
}

- (void)tapImage:(UITapGestureRecognizer *)tap
{
    NSInteger count = arrayPic.count;
    [_aryImage removeAllObjects];
    // 1.封装图片数据
    for (int i = 0; i<count; i++) {
        // 替换为中等尺寸图片
//        MJPhoto *photo = [[MJPhoto alloc] init];
//        PictureView *picture = (PictureView *)[arrayPic objectAtIndex:i];
//        photo.url = picture.strPath; // 图片路径
//        photo.srcImageView = picture.imgView;
//        [_aryImage addObject:photo];
        XCPhoto *photo = [[XCPhoto alloc] init];
        PictureView *picture = (PictureView *)[arrayPic objectAtIndex:i];
        photo.strPath = picture.strPath;
        photo.nId = picture.imgView.tag;
        photo.imgName = picture.imgView.image;
        [_aryImage addObject:photo];
    }
    // 2.显示相册
    if(_delegate && [_delegate respondsToSelector:@selector(addPicView:view:index:)])
    {
        [_delegate addPicView:self view:tap.view index:tap.view.tag];
    }
}

-(void)dealloc
{
    DLog(@"删除了");
    if (_array)
    {
        [_array removeAllObjects];
        _array = nil;
    }
    for (UIView *view in self.contentView.subviews)
    {
        [view removeFromSuperview];
    }
}

@end
