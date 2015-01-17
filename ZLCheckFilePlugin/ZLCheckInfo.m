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

- (void)getFilesWithCallBack:(callBack)callBack{

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *filePath = [_instance workSpacePath];
            NSArray *paths = [self.fileManager subpathsAtPath:filePath];
            NSMutableArray *allPathsM = [NSMutableArray array];
            
            for (NSString *pathName in paths) {
                
                if (!([[[pathName lastPathComponent] pathExtension] isEqualToString:@"h"] ||
                      [[[pathName lastPathComponent] pathExtension] isEqualToString:@"m"]
                      || [[[pathName lastPathComponent] pathExtension] isEqualToString:@"pch"]
                      || [[[pathName lastPathComponent] pathExtension] isEqualToString:@"storyboard"])
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
                
                NSString *mPath = [filePath stringByAppendingPathComponent:file.filePath];
                
                NSString *content = [[NSString alloc] initWithContentsOfFile:mPath encoding:NSUTF8StringEncoding error:nil];
                
                NSArray *mPathLineContents = [content componentsSeparatedByString:@"\n"];
                
                if ([pathName hasSuffix:@"h"] || [pathName hasSuffix:@"m"] || [pathName hasSuffix:@"pch"]) {
                    
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
                }else if ([pathName hasSuffix:@"storyboard"]){
                    for (NSString *lineStr in mPathLineContents) {
                        NSRange lineRange = [lineStr rangeOfString:@"customClass=\""];
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
                for (NSString *preStr in deletePaths) {
                    if ([[file.fileName stringByDeletingPathExtension] isEqualToString:[preStr stringByDeletingPathExtension]]
                        || [file.fileName isEqualToString:@"main.m"]
                        || [file.fileName isEqualToString:@"Main.storyboard"]) {
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

- (NSString *)exportFilesInBundlePlist{
    NSString *plist = [[[_instance workSpacePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"ZLCheckFilePlugin-Files.plist"];
    NSMutableArray *array = [NSMutableArray array];
    for (ZLFile *file in _files) {
        [array addObject:@{@"name":file.fileName,@"path":file.filePath}];
    }
    if([array writeToFile:plist atomically:YES]){
        return plist;
    }else{
        return nil;
    }
}

@end
