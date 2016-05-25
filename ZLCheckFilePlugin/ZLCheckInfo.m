//
//  ZLCheckInfo.m
//  ZLCheckFilePlugin
//
//  Created by 张磊 on 15-1-16.
//  Copyright (c) 2015年 com.zixue101.www. All rights reserved.
//

#import "ZLCheckInfo.h"
#import "NSArray+Ext.h"
#import "ZLFile.h"

@interface ZLCheckInfo ()

@property (strong,nonatomic) NSFileManager *fileManager;
// array is files > @[ZLFile,ZLFile] ...
@property (strong,nonatomic) NSArray *files;
// project InfoPlist Dict.
@property (strong,nonatomic) NSDictionary *infoDict;

@property (strong,nonatomic) NSArray *matchsFileArray;
@property (strong,nonatomic) NSArray *headerFileArray;
@end

// other static
static NSString *staticPlist = @"plist";
static NSString *staticStoryboard = @"storyboard";
static NSString *staticImplementation = @"@implementation";
static NSString *UIMainStoryboardFile = @"UIMainStoryboardFile";
static NSString *staticAppDelegate = @"AppDelegate";

// import static
static NSString *staticImport = @"#import";
static NSString *staticInclude = @"#include";

// storyboard static
static NSString *staticStoryboardCustomClass = @"customClass";


// NSPrincipalClass staic
static NSString *NSPrincipalClass = @"NSPrincipalClass";
static NSString *staticStoryboardName = @"storyboardWithName:@";

@implementation ZLCheckInfo

#pragma mark - lazy datas.
- (NSFileManager *)fileManager{
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

- (NSArray *)matchsFileArray{
    if (!_matchsFileArray) {
        _matchsFileArray = @[
                             @"main.m",
                             @"main.h",
                             @"main.c",
                             @"main.cpp",
                             @"AppDelegate",
                             @"pch",
                             ];
    }
    return _matchsFileArray;
}

- (NSArray *)headerFileArray{
    if (!_headerFileArray) {
        _headerFileArray = @[
                             @"h",
                             @"m",
                             @"c",
                             @"cpp",
                             @"storyboard",
                             @"pch",
                             ];
    }
    return _headerFileArray;
}

static id _instance = nil;
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

#pragma mark - get Files in callBack
- (void)getFilesWithCallBack:(callBack)callBack{
    self.files = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *filePath = [_instance workSpacePath];
        NSArray *paths = [self.fileManager subpathsAtPath:filePath];
        NSMutableArray *allPathsM = [NSMutableArray array];
        
        for (NSString *pathName in paths) {
            
            if (!self.infoDict) {
                if([[[pathName lastPathComponent] pathExtension] isEqualToString:staticPlist]){
                    NSString *mPath = [filePath stringByAppendingPathComponent:pathName];
                    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:mPath];
                    
                    if ([dict valueForKeyPath:UIMainStoryboardFile] || [dict valueForKeyPath:NSPrincipalClass]) {
                        self.infoDict = dict;
                    }
                }
            }
            
            if (![self.headerFileArray inArray:[[pathName lastPathComponent] pathExtension]]){
                continue;
            }
            
            ZLFile *file = [[ZLFile alloc] init];
            file.fileName = [pathName lastPathComponent];
            file.filePath = pathName;
            [allPathsM addObject:file];
        }
        
        NSMutableArray *endPathsM = [NSMutableArray arrayWithArray:allPathsM];
        NSMutableArray *deletePaths = [NSMutableArray array];
        NSMutableArray *storyboardArrayM = [NSMutableArray array];
        
        for (ZLFile *file in allPathsM) {
            // recoder look storyboard
            BOOL isImplementation = NO;
            NSString *pathName = file.fileName;
            if (![pathName length]) {
                continue;
            }
            NSString *mPath = [filePath stringByAppendingPathComponent:file.filePath];
            if (![mPath length]) {
                continue;
            }
            NSString *content = [[NSString alloc] initWithContentsOfFile:mPath encoding:NSUTF8StringEncoding error:nil];
            if (![content length]) {
                continue;
            }
            NSArray *mPathLineContents = [content componentsSeparatedByString:@"\n"];
            
            if (![pathName hasSuffix:staticStoryboard]
                ) {
                
                for (NSString *lineStr in mPathLineContents) {
                    if (![lineStr length]) {
                        continue;
                    }
                    NSRange implementationRange = [lineStr rangeOfString:staticImplementation];
                    if (implementationRange.location != NSNotFound || isImplementation) {
                        NSRange storyboardRange = [lineStr rangeOfString:staticStoryboardName];
                        if (storyboardRange.location != NSNotFound) {
                            NSString *storyboardName = [lineStr substringFromIndex:storyboardRange.location + storyboardRange.length];
                            storyboardName = [storyboardName substringFromIndex:1];
                            NSRange range = [storyboardName rangeOfString:@"\""];
                            if (range.location > [storyboardName length]) {
                                continue;
                            }
                            storyboardName = [storyboardName substringWithRange:NSMakeRange(0, range.location)];
                            [storyboardArrayM addObject:storyboardName];
                        }
                        
                        isImplementation = YES;
                    }else{
                        NSRange preRange = [lineStr rangeOfString:staticImport];
                        
                        NSRange includeRange = [lineStr rangeOfString:staticInclude];
                        if (preRange.location == NSNotFound) {
                            preRange = includeRange;
                        }
                        
                        if (preRange.location != NSNotFound) {
                            
                            NSRange charRange = [lineStr rangeOfString:@"\""];
                            NSInteger charIndex = 0;
                            if (charRange.location != NSNotFound) {
                                charIndex = (charRange.location - (preRange.location + preRange.length) + charRange.length);
                            }
                            
                            NSString *replaceStr = [lineStr substringFromIndex:preRange.location + preRange.length + charIndex];
                            NSString *preStr = [replaceStr stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                            if (![[pathName stringByDeletingPathExtension] isEqualToString:[preStr stringByDeletingPathExtension]]) {
                                [deletePaths addObject:preStr];
                            }
                        }
                        
                    }
                }
            }else {
                // storyBoard xml
                for (NSString *lineStr in mPathLineContents) {
                    if (![lineStr length]) {
                        continue;
                    }
                    NSRange lineRange = [lineStr rangeOfString:[NSString stringWithFormat:@"%@=\"",staticStoryboardCustomClass]];
                    if(lineRange.location != NSNotFound){
                        NSString *str = [lineStr substringFromIndex:lineRange.location + lineRange.length];
                        NSRange lineStrRange = [str rangeOfString:@"\""];
                        if (lineStrRange.location > [lineStr length]) {
                            continue;
                        }
                        if (lineStrRange.location > [str length]) {
                            continue;
                        }
                        str = [str substringWithRange:NSMakeRange(0, lineStrRange.location)];
                        
                        if (![[pathName stringByDeletingPathExtension] isEqualToString:[str stringByDeletingPathExtension]]) {
                            [deletePaths addObject:str];
                        }
                    }
                    
                }
            }
        }
        
        
        for (ZLFile *file in allPathsM) {
            if ([self.matchsFileArray inArray:[file.fileName lastPathComponent]]|| [self.matchsFileArray inArray:[file.fileName pathExtension]] || [storyboardArrayM inArray:[file.fileName stringByDeletingPathExtension]]){
                [endPathsM removeObject:file];
            }
            
            if ([file.fileName rangeOfString:staticAppDelegate].location != NSNotFound
                || [file.fileName isEqualToString:[self.infoDict[UIMainStoryboardFile] stringByAppendingPathExtension:staticStoryboard]]
                || [[file.fileName stringByDeletingPathExtension] isEqualToString:self.infoDict[NSPrincipalClass]]
                ) {
                [endPathsM removeObject:file];
            }
            
            for (NSString *preStr in deletePaths) {
                if (
                    [[file.fileName stringByDeletingPathExtension] isEqualToString:[preStr stringByDeletingPathExtension]]) {
                    
                    [endPathsM removeObject:file];
                    break;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _files = endPathsM;
            callBack(endPathsM);
        });
    });
    
    
}

#pragma mark - search files
- (NSArray *)searchFilesWithText:(NSString *)searchText{
    if (!searchText.length) {
        return _files;
    }
    
    return [self.files searchArrayWithSearchText:searchText];
}

#pragma mark - export Plist
- (NSString *)exportFilesInBundlePlist{
    
    NSString *plist = [[[_instance workSpacePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"ZLCheckFilePlugin-Files.plist"];
    
    if ([_files exportPlistWithPath:plist]) {
        return plist;
    }
    return nil;
}

@end
