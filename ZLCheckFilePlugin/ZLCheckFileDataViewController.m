//
//  ZLCheckFileDataViewController.m
//  ZLCheckFilePlugin
//
//  Created by 张磊 on 15-1-16.
//  Copyright (c) 2015年 com.zixue101.www. All rights reserved.
//

#import "ZLCheckFileDataViewController.h"
#import "ZLCheckInfo.h"
#import "ZLFile.h"

@interface ZLCheckFileDataViewController () <NSTableViewDataSource,NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (strong,nonatomic) NSArray *datas;

@end

@implementation ZLCheckFileDataViewController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [[ZLCheckInfo sharedInstance] getFilesWithCallBack:^(NSArray *arr) {
        _datas = arr;
        NSLog(@"CallBack : %@",_datas);
        [self.tableView reloadData];
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return self.datas.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row{
    NSButton *btn = [[NSButton alloc] init];
    if (self.datas.count > row) {
        ZLFile *file = self.datas[row];
        btn.title = [[[ZLCheckInfo sharedInstance] workSpacePath] stringByAppendingPathComponent:file.filePath];
        btn.target = self;
        btn.action = @selector(clickButton:);
    }
    return btn;
}

- (void)clickButton:(NSButton *)btn{
    [self openFinderWithFilePath:btn.title];
}

#pragma mark - Open Finder
- (void)openFinderWithFilePath:(NSString *)path{
    if (!path.length) {
        return ;
    }

    NSString *open = [NSString stringWithFormat:@"open %@",path];
    NSLog(@"%@",open);
    const char *str = [open UTF8String];
    system(str);
}

@end
