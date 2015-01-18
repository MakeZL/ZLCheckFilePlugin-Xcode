//
//  ZLCheckFile.m
//  ZLCheckFilePlugin
//
//  Created by 张磊 on 15-1-15.
//  Copyright (c) 2015年 com.zixue101.www. All rights reserved.
//

#import "ZLCheckFile.h"
#import "ZLFile.h"
#import "ZLCheckInfo.h"
#import "ZLCheckFileDataViewController.h"

@interface ZLCheckFile ()

@property (copy,nonatomic) NSString *workspacePath;
@property (strong,nonatomic) ZLCheckFileDataViewController *detaVc;
@end

@implementation ZLCheckFile

+ (void)pluginDidLoad:(NSBundle *)plugin{
    [self shared];
}

+ (instancetype)shared{
    static dispatch_once_t onceToken;
    static id instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init{
    if(self = [super init]){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];

    }
    return self;
}

#pragma mark - setup Menu
- (void)applicationDidFinishLaunching:(NSNotification *)notification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCurrentAppPath:) name:@"IDEWorkspaceBuildProductsLocationDidChangeNotification" object:nil];
    
    NSMenuItem *appItem = [[NSApp menu] itemWithTitle:@"File"];
    [[appItem submenu] addItem:[NSMenuItem separatorItem]];
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title = @"Look Check File!";
    item.action = @selector(goCheckFile);
    item.target = self;
    [[appItem submenu] addItem:item];
    
}

#pragma mark - go CheckFile vc
- (void)goCheckFile{
    self.detaVc = [[ZLCheckFileDataViewController alloc] initWithWindowNibName:@"ZLCheckFileDataViewController"];
    [self.detaVc showWindow:self.detaVc];
}

#pragma mark - set workSpacePath
- (void)getCurrentAppPath:(NSNotification *)noti{
    NSString *notiStr = [noti.object description];
    notiStr = [notiStr stringByDeletingLastPathComponent];
    NSRange preRange = [notiStr rangeOfString:@"'"];
    notiStr = [notiStr substringFromIndex:preRange.location+preRange.length];
    notiStr = [notiStr stringByReplacingOccurrencesOfString:@".xcodeproj" withString:@""];
    self.workspacePath = notiStr;
}

#pragma mark - set files
- (void)setWorkspacePath:(NSString *)workspacePath{
    _workspacePath = workspacePath;
    [[ZLCheckInfo sharedInstance] setWorkSpacePath:_workspacePath];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
