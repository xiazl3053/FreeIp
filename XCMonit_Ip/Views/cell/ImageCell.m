//
//  ImageCellTableViewCell.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/7/11.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "ImageCell.h"
#import "MJPhotoBrowser.h"
#import "MJPhoto.h"
#import "UtilsMacro.h"
#import "SDImageCache.h"
#import "UIImageView+WebCache.h"
@interface ImageCell()
{
    
}
@end

@implementation ImageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {

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
-(void)setArrayInfo:(NSArray*)array
{
    if (_array)
    {
        [_array removeAllObjects];
        _array = nil;
    }
    _array = [[NSMutableArray alloc] initWithArray:array];
    [self freshCell];
//    __weak ImageCell *weakSelf = self;
//    dispatch_async(dispatch_get_global_queue(0, 0), ^
//    {
//       [weakSelf freshCell];
//    });
}

-(void)freshCell
{
    for (UIView *view in self.contentView.subviews)
    {
        [view removeFromSuperview];
    }
    CGFloat width = 70;
    CGFloat height = 70;
    CGFloat margin = 5;
    CGFloat startX = 10;
    CGFloat startY = 8;

    for (int i = 0; i<_array.count; i++)
    {
        UIImageView *imageView = [[UIImageView alloc] init];
        [self.contentView addSubview:imageView];
        
        // 计算位置
        int row = i/4;
        int column = i%4;
        CGFloat x = startX + column * (width + margin);
        CGFloat y = startY + row * (height + margin);
        imageView.frame = CGRectMake(x, y, width, height);
        
        __weak ImageCell *weakSelf = self;
//        [imageView setImageWithURL:[NSURL URLWithString:[_array objectAtIndex:i]] placeholderImage:[UIImage imageNamed:@"realplay.png"]];
        dispatch_async(dispatch_get_global_queue(0, 0),
       ^{
               UIImage *image = [[UIImage alloc] initWithContentsOfFile:[weakSelf.array objectAtIndex:i]];
                dispatch_async(dispatch_get_main_queue(),^
               {
                   [imageView setImage:image];
               });
       });
        // 事件监听
        imageView.tag = i;
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)]];
        
        // 内容模式
        imageView.clipsToBounds = YES;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
}
- (void)tapImage:(UITapGestureRecognizer *)tap
{
    int count = _array.count;
    // 1.封装图片数据
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i<count; i++) {
        // 替换为中等尺寸图片
//        NSString *url = [_array objectAtIndex:i];
        MJPhoto *photo = [[MJPhoto alloc] init];
        photo.url = [_array objectAtIndex:i]; // 图片路径
        photo.srcImageView = self.contentView.subviews[i]; // 来源于哪个UIImageView

        [photos addObject:photo];
    }
    
    // 2.显示相册
    MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
    browser.currentPhotoIndex = tap.view.tag; // 弹出相册时显示的第一张图片是？
    browser.photos = photos; // 设置所有的图片
    [browser show];
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
