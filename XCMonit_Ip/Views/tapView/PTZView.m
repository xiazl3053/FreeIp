//
//  PTZView.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/12/8.
//  Copyright (c) 2014年 夏钟林. All rights reserved.
//

#import "PTZView.h"
#import "P2PSDK.h"



@implementation PTZView


-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.bounds];
    [imgView setImage:[UIImage imageNamed:@"ptz_bg"]];
    [self addSubview:imgView];
    
    _btnRight = [[PTZButton alloc] initCreateButton:@"right" high:@"right_d" start:PTZCONTROLTYPE_RIGHT_START stop:PTZCONTROLTYPE_RIGHT_STOP];
    
    _btnLeft = [[PTZButton alloc] initCreateButton:@"left" high:@"left_d" start:PTZCONTROLTYPE_LEFT_START stop:PTZCONTROLTYPE_LEFT_STOP];
    
    _btnUp = [[PTZButton alloc] initCreateButton:@"up" high:@"up_d" start:PTZCONTROLTYPE_UP_START stop:PTZCONTROLTYPE_UP_STOP];
    
    _btnDown = [[PTZButton alloc] initCreateButton:@"down" high:@"down_d" start:PTZCONTROLTYPE_DOWN_START stop:PTZCONTROLTYPE_DOWN_STOP];
    
    _btnZoomIn = [[PTZButton alloc] initCreateButton:@"zoomIn" high:@"zoomIn_d" start:PTZCONTROLTYPE_ZOOMWIDE_START stop:PTZCONTROLTYPE_ZOOMWIDE_STOP];
    
    _btnZoomOut = [[PTZButton alloc] initCreateButton:@"zoomOut" high:@"zoomOut_d" start:PTZCONTROLTYPE_ZOOMTELE_START stop:PTZCONTROLTYPE_ZOOMTELE_STOP];
    
    [self addSubview:_btnRight];
    [self addSubview:_btnLeft];
    [self addSubview:_btnUp];
    [self addSubview:_btnDown];
    [self addSubview:_btnZoomIn];
    [self addSubview:_btnZoomOut];
    
    [_btnLeft addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [_btnLeft addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_btnRight addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [_btnRight addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_btnUp addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [_btnUp addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_btnDown addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [_btnDown addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_btnZoomIn addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [_btnZoomIn addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];
    [_btnZoomOut addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [_btnZoomOut addTarget:self action:@selector(touchUp:) forControlEvents:UIControlEventTouchUpInside];

    
    
    
    
    
    
    
    
    _btnZoomIn.frame = Rect(10, 10, 44, 44);
    _btnUp.frame = Rect(60, 10, 44, 44);
    _btnZoomOut.frame = Rect(110, 10, 44, 44);
    _btnLeft.frame = Rect(10, 60, 44, 44);
    _btnDown.frame = Rect(60, 60, 44, 44);
    _btnRight.frame = Rect(110, 60, 44, 44);
    
    return self;
}
-(void)touchDown:(PTZButton *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(ptzView:)])
    {
        [_delegate ptzView:sender.nStart];
    }
}
-(void)touchUp:(PTZButton *)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(ptzView:)])
    {
        [_delegate ptzView:sender.nStop];
    }
}




@end


@implementation PTZButton

-(instancetype)initCreateButton:(NSString *)strImage high:(NSString*)strHigh start:(int)nStart stop:(int)nStop
{
    
    self = [super initWithFrame:Rect(0, 0, 44, 44)];
    [self setImage:[UIImage imageNamed:strImage] forState:UIControlStateHighlighted];
    [self setImage:[UIImage imageNamed:strHigh] forState:UIControlStateNormal];
    self.nStart = nStart;
    self.nStop = nStop ;
    
    return self;
}

@end

