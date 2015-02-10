//
//  SubCateViewController.m
//  top100
//
//  Created by Dai Cloud on 12-7-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SubCateViewController.h"
#define COLUMN 4

@interface SubCateViewController ()

@end

@implementation SubCateViewController

@synthesize subCates=_subCates;
@synthesize cateVC=_cateVC;

- (void)dealloc
{
    [_subCates release];
    [_cateVC release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tmall_bg_furley.png"]];
    
    // init cates show
    int total = _nCount;
#define ROWHEIHT 70    
    int rows = (total / COLUMN) + ((total % COLUMN) > 0 ? 1 : 0);
    CGRect viewFrame = self.view.frame;
    viewFrame.size.height = rows*70;
    self.view.frame = viewFrame;
    UIScrollView *scrolView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 280)];
    [self.view addSubview:scrolView];
    for (int i=0; i<total; i++) {
        int row = i / COLUMN;
        int column = i % COLUMN;
        
        UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(80*column, ROWHEIHT*row, 80, ROWHEIHT)] autorelease];
        view.backgroundColor = [UIColor clearColor];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(15, 15, 50, 50);
        btn.tag = i;
        [btn addTarget:self.cateVC 
                action:@selector(subCateBtnAction:) 
      forControlEvents:UIControlEventTouchUpInside];
        NSString *strImg = [NSString stringWithFormat:@"%d",i+1];
        [btn setTitle:strImg forState:UIControlStateNormal];
        [btn setBackgroundColor:[UIColor whiteColor]];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [view addSubview:btn];
        [scrolView addSubview:view];
    }
    scrolView.contentSize = CGSizeMake(320,80*rows);
    scrolView.pagingEnabled=YES;
    [scrolView setScrollEnabled:YES];
}

@end
/*
 CGRect viewFrame = self.view.frame;
 viewFrame.size.height = 320;
 self.view.frame = viewFrame;
 UIScrollView *scrolView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
 [self.view addSubview:scrolView];
 for (int i=0; i<total; i++) {
 int row = i / COLUMN;
 int column = i % COLUMN;
 UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(50*column, ROWHEIHT*row, 50, ROWHEIHT)] autorelease];
 view.backgroundColor = [UIColor clearColor];
 UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
 btn.frame = CGRectMake(2, 2, 45, 45);
 btn.tag = i;
 [btn addTarget:self.cateVC
 action:@selector(subCateBtnAction:)
 forControlEvents:UIControlEventTouchUpInside];
 NSString *strTitle = [NSString stringWithFormat:@"%d",i];
 [btn setTitle:strTitle forState:UIControlStateNormal];
 
 [view addSubview:btn];
 
 [scrolView addSubview:view];
 }
 scrolView.contentSize = CGSizeMake(320,640);
 scrolView.pagingEnabled=YES;
 [scrolView setScrollEnabled:YES];
 
 **/











