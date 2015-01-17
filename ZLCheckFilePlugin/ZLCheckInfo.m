//
//  ZLCheckInfo.m
//  ZLCheckFilePlugin
//
//  Created by 张磊 on 15-1-16.
//  Copyright (c) 2015年 com.zixue101.www. All rights reserved.
//

#import "ZLCheckInfo.h"
#import "ZLFile.h"

@interface ZLCheckInfo ()

@property (strong,nonatomic) NSFileManager *fileManager;
// array is files > @[ZLFile,ZLFile] ...
@property (strong,nonatomic) NSArray *files;

@end

@implementation ZLCheckInfo

- (NSFileManager *)fileManager{
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

static id _instance = nil;
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (NSArray *)files{
    if (!_files) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *filePath = [_instance workSpacePath];
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
            
//            NSString *plist = [[_instance workSpacePath] stringByAppendingPathComponent:@"files.plist"];
//            NSMutableArray *array = [NSMutableArray array];
//            for (ZLFile *file in endPathsM) {
//                [array addObject:@{@"name":file.fileName,@"path":file.filePath}];
//            }
//            [array writeToFile:plist atomically:YES];
                _files = endPathsM;
        });
        
    }
    return _files;
}

- (void)getFilesWithCallBack:(callBack)callBack{

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *filePath = [_instance workSpacePath];
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
            
            //            NSString *plist = [[_instance workSpacePath] stringByAppendingPathComponent:@"files.plist"];
            //            NSMutableArray *array = [NSMutableArray array];
            //            for (ZLFile *file in endPathsM) {
            //                [array addObject:@{@"name":file.fileName,@"path":file.filePath}];
            //            }
            //            [array writeToFile:plist atomically:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                _files = endPathsM;
                callBack(_files);
            });
        });
    

}

@end
