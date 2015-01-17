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
// project InfoPlist Dict.
@property (strong,nonatomic) NSDictionary *infoDict;

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
                
                if (!self.infoDict) {
                    if([[[pathName lastPathComponent] pathExtension] isEqualToString:@"plist"]){
                        NSString *mPath = [filePath stringByAppendingPathComponent:pathName];
                        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:mPath];
                        
                        if ([dict valueForKeyPath:@"UIMainStoryboardFile"]) {
                            self.infoDict = dict;
                        }
                    }
                }
                
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
                        
                        NSRange implementationRange = [lineStr rangeOfString:@"@implementation"];
                        if (implementationRange.location != NSNotFound) {
                            break;
                        }else{
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
                }else {
                    // storyBoard xml
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
                        || [file.fileName rangeOfString:@"AppDelegate"].location != NSNotFound
                        || [file.fileName isEqualToString:[self.infoDict[@"UIMainStoryboardFile"] stringByAppendingString:@".storyboard"]]) {
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

- (NSArray *)searchFilesWithText:(NSString *)searchText{
    if (!searchText.length) {
        return _files;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    for (ZLFile *file in _files) {
        if([[file.fileName lowercaseString] rangeOfString:[searchText lowercaseString]].location != NSNotFound){
            [array addObject:file];
        }
    }
    return array;
}

- (NSString *)exportFilesInBundlePlist{
    NSString *plist = [[[_instance workSpacePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"ZLCheckFilePlugin-Files.plist"];
    NSMutableArray *array = [NSMutableArray array];
    for (ZLFile *file in _files) {
        [array addObject:@{@"name":file.fileName,@"path":[[_instance workSpacePath] stringByAppendingPathComponent:file.filePath]}];
    }
    if([array writeToFile:plist atomically:YES]){
        return plist;
    }else{
        return nil;
    }
}

@end
