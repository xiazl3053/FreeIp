//
//  RtspRecordViewController.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/9/16.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomViewController.h"
@interface RtspRecordViewController : CustomViewController<UITableViewDataSource,UITableViewDelegate>

-(id)initWithPath:(NSString*)strPath name:(NSString*)strDevName;


@end
