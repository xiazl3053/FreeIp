//
//  MJPhotoToolbar.m
//  FingerNews
//
//  Created by mj on 13-9-24.
//  Copyright (c) 2013年 itcast. All rights reserved.
//

#import "MJPhotoToolbar.h"
#import "MJPhoto.h"
#import "MBProgressHUD+Add.h"
#import "XCNotification.h"
@interface MJPhotoToolbar()
{
    // 显示页码
    UILabel *_indexLabel;
    UIButton *_saveImageBtn;
}
@end

@implementation MJPhotoToolbar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setPhotos:(NSArray *)photos
{
    _photos = photos;
    
    if (_photos.count > 1) {
        _indexLabel = [[UILabel alloc] init];
        _indexLabel.font = [UIFont boldSystemFontOfSize:20];
        _indexLabel.frame = self.bounds;
        _indexLabel.backgroundColor = [UIColor clearColor];
        _indexLabel.textColor = [UIColor whiteColor];
        _indexLabel.textAlignment = NSTextAlignmentCenter;
        _indexLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:_indexLabel];
    }
    
    // 保存图片按钮
    CGFloat btnWidth = self.bounds.size.height;
    _saveImageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _saveImageBtn.frame = CGRectMake(20, 0, 80, btnWidth);
//    _saveImageBtn.autoresizingMask = [UIViewAutoresizingFlexibleHeight;
    [_saveImageBtn setTitle:@"保存相册" forState:UIControlStateNormal];
    [_saveImageBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_saveImageBtn addTarget:self action:@selector(saveImage) forControlEvents:UIControlEventTouchUpInside];
    [self setBackgroundColor:[UIColor clearColor]];
    UIView *backView = [[UIView alloc] initWithFrame:self.bounds];
    [backView setBackgroundColor:[UIColor whiteColor]];
    [backView setAlpha:0.5f];
    [self addSubview:backView];
    [self addSubview:_saveImageBtn];
    
    UIButton *_deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _deleteBtn.frame = CGRectMake(self.frame.size.width-80, 0, 60, btnWidth);
    [_deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
    [_deleteBtn addTarget:self action:@selector(deleteImage) forControlEvents:UIControlEventTouchUpInside];
    [_deleteBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self addSubview:_deleteBtn];
}
-(void)deleteImage
{
    MJPhoto *photo = _photos[_currentPhotoIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:NS_DELETE_IMAGE_VC object:photo];
}
- (void)saveImage
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        MJPhoto *photo = _photos[_currentPhotoIndex];
        UIImageWriteToSavedPhotosAlbum(photo.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    });
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        [MBProgressHUD showSuccess:@"保存失败" toView:nil];
    } else {
        MJPhoto *photo = _photos[_currentPhotoIndex];
        photo.save = NO;
        _saveImageBtn.enabled = YES;
        [MBProgressHUD showSuccess:@"成功保存到相册" toView:nil];
    }
}

- (void)setCurrentPhotoIndex:(NSUInteger)currentPhotoIndex
{
    _currentPhotoIndex = currentPhotoIndex;
    
    [_indexLabel setTextColor:[UIColor blackColor]];
    // 更新页码
    _indexLabel.text = [NSString stringWithFormat:@"%d / %d", _currentPhotoIndex + 1, _photos.count];
    
    MJPhoto *photo = _photos[_currentPhotoIndex];
    // 按钮
    _saveImageBtn.enabled = photo.image != nil && !photo.save;
}

@end
