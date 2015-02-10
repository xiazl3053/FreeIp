//
//  RecordViewController.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/30.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import "CustomViewController.h"

@interface RecordViewController : CustomViewController<UITableViewDataSource,UITableViewDelegate>

-(id)initWithNo:(NSString*)strNO status:(int)nStatus;

@end
