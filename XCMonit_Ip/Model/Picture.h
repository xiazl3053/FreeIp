//
//  Picture.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/8/25.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PictureModel : NSObject

@property (nonatomic,assign) NSInteger nId;
@property (nonatomic,strong) NSString *strDevName;
@property (nonatomic,strong) NSString *strFile;
@property (nonatomic,strong) NSString *strTime;

-(id)initWithItems:(NSArray*)items;
@end
