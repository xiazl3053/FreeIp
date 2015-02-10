//
//  XCPlayNetViewController.h
//  XCMonit_Ip
//
//  Created by 夏钟林 on 14/6/30.
//  Copyright (c) 2014年 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RecordModel;
@interface PlayNetViewController : UIViewController

- (id) initWithContentPath: (RecordModel *) record
                parameters: (NSDictionary *) parameters;



@end
