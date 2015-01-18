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

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *filePath = [_instance workSpacePath];
            NSArray *paths = [self.fileManager subpathsAtPath:filePath];
            NSMutableArray *allPathsM = [NSMutableArray array];
            
            for (NSString *pathName in paths) {
                
                if (!self.infoDict) {
                    if([[[pathName lastPathComponent] pathExtension] isEqualToString:staticPlist]){
                        NSString *mPath = [filePath stringByAppendingPathComponent:pathName];
                        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:mPath];
                        
                        if ([dict valueForKeyPath:UIMainStoryboardFile]) {
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
            
            for (ZLFile *file in allPathsM) {
                
                NSString *pathName = file.fileName;
                NSString *mPath = [filePath stringByAppendingPathComponent:file.filePath];
                NSString *content = [[NSString alloc] initWithContentsOfFile:mPath encoding:NSUTF8StringEncoding error:nil];
                
                NSArray *mPathLineContents = [content componentsSeparatedByString:@"\n"];
                
                if (![pathName hasSuffix:staticStoryboard]
                    ) {
                    
                    for (NSString *lineStr in mPathLineContents) {
                        
                        NSRange implementationRange = [lineStr rangeOfString:staticImplementation];
                        if (implementationRange.location != NSNotFound) {
                            break;
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
                        NSRange lineRange = [lineStr rangeOfString:[NSString stringWithFormat:@"%@=\"",staticStoryboardCustomClass]];
                        if(lineRange.location != NSNotFound){
                            NSString *str = [lineStr substringFromIndex:lineRange.location + lineRange.length];
                            NSRange lineStrRange = [str rangeOfString:@"\""];
                            str = [str substringWithRange:NSMakeRange(0, lineStrRange.location)];
                            
                            if (![[pathName stringByDeletingPathExtension] isEqualToString:[str stringByDeletingPathExtension]]) {
                                [deletePaths addObject:str];
                            }
                        }
                        
                    }
                }
            }
            
            
            for (ZLFile *file in allPathsM) {
                
                if ([self.matchsFileArray inArray:[file.fileName lastPathComponent]]) {
                    [endPathsM removeObject:file];
                }
                
                for (NSString *preStr in deletePaths) {
                    
                    if (
                        [[file.fileName stringByDeletingPathExtension] isEqualToString:[preStr stringByDeletingPathExtension]]
                        || [file.fileName rangeOfString:staticAppDelegate].location != NSNotFound
                        || [file.fileName isEqualToString:[self.infoDict[UIMainStoryboardFile] stringByAppendingPathExtension:staticStoryboard]]
                        ) {
                        
                        [endPathsM removeObject:file];
                        break;
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _files = endPathsM;
                callBack(_files);
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
