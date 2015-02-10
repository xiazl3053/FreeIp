//
//  Picture.m
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/25.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "Picture.h"

@implementation PictureModel


-(id)initWithItems:(NSArray*)items
{
    self = [super init];
    
    if (self)
    {
        _nId = [items[0] integerValue];
        _strDevName = items[1];
        _strTime = items[2];
        _strFile = items[3];
    }
    
    return self;
}

@end
