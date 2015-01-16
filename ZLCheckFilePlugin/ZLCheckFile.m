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

@property (strong,nonatomic) NSFileManager *fileManager;
@property (copy,nonatomic) NSString *workspacePath;
@property (strong,nonatomic) ZLCheckFileDataViewController *detaVc;
@end

@implementation ZLCheckFile

- (NSFileManager *)fileManager{
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

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
    
    if ([_workspacePath isEqualToString:workspacePath]) {
        return ;
    }
    
    _workspacePath = workspacePath;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *filePath = workspacePath;
        NSArray *paths = [self.fileManager subpathsAtPath:filePath];
        NSMutableArray *allPathsM = [NSMutableArray array];
        
        for (NSString *pathName in paths) {
            
            if (!([[[pathName lastPathComponent] pathExtension] isEqualToString:@"h"] ||
                  [[[pathName lastPathComponent] pathExtension] isEqualToString:@"m"]
                  || [[[pathName lastPathComponent] pathExtension] isEqualToString:@"pch"])
                ) {
                continue;
            }
            ZLFile *file = [[ZLFile alloc] init];
            file.fileName = [pathName lastPathComponent];
            file.filePath = pathName;
            [allPathsM addObject:file];
        }
        
        NSMutableArray *endPathsM = [NSMutableArray arrayWithArray:allPathsM];
        NSMutableArray *deletePaths = [NSMutableArray array];
        
        for (ZLFile *file in allPathsM) {
            NSString *pathName = file.fileName;
            
            if ([pathName hasSuffix:@"h"] || [pathName hasSuffix:@"m"] || [pathName hasSuffix:@"pch"]) {
                NSString *mPath = [filePath stringByAppendingPathComponent:file.filePath];
                
                NSString *content = [[NSString alloc] initWithContentsOfFile:mPath encoding:NSUTF8StringEncoding error:nil];
                
                NSArray *mPathLineContents = [content componentsSeparatedByString:@"\n"];
                for (NSString *lineStr in mPathLineContents) {
                    NSRange preRange = [lineStr rangeOfString:@"#import \""];
                    if (preRange.location != NSNotFound) {
                        NSString *replaceStr = [lineStr substringFromIndex:preRange.location + preRange.length];
                        NSString *preStr = [replaceStr stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                        
                        if (![[pathName stringByDeletingPathExtension] isEqualToString:[preStr stringByDeletingPathExtension]]) {
                            [deletePaths addObject:preStr];
                        }
                    }
                }
            }
        }
        
        for (ZLFile *file in allPathsM) {
            for (NSString *preStr in deletePaths) {
                if ([[file.fileName stringByDeletingPathExtension] isEqualToString:[preStr stringByDeletingPathExtension]]
                    || [file.fileName isEqualToString:@"main.m"] ) {
                    [endPathsM removeObject:file];
                    break;
                }
            }
        }
        
        NSString *plist = [_workspacePath stringByAppendingPathComponent:@"files.plist"];
        NSMutableArray *array = [NSMutableArray array];
        for (ZLFile *file in endPathsM) {
            [array addObject:@{@"name":file.fileName,@"path":file.filePath}];
        }
        [array writeToFile:plist atomically:YES];
        
        if (array.count) {
            [[ZLCheckInfo sharedInstance] setWorkSpacePath:_workspacePath];
            [[ZLCheckInfo sharedInstance] setFiles:endPathsM];
        }
        
    });
    

}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
