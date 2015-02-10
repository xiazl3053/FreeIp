//
//  ESGLView.h
//  kxmovie
//
//  Created by Kolyvan on 22.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import <UIKit/UIKit.h>

@class KxVideoFrame;
@class XCDecoder;
@class XCDecoderNew;
@interface KxMovieGLView : UIView

- (id) initWithFrame:(CGRect)frame
             decoder: (XCDecoder *) decoder;

- (id) initWithFrame:(CGRect)frame
             decoderNew:(XCDecoderNew *) decoder;

- (void) render: (KxVideoFrame *) frame;

- (id) initWithFrame:(CGRect)frame
               width:(CGFloat)fWidth height:(CGFloat)fHeight size:(int)nSize;

-(UIImage*)snapshot:(UIView*)eaglview;


@property (nonatomic,strong) NSString *strNO;
@end

