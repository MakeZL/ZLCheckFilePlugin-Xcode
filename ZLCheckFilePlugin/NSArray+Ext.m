//
//  NSArray+Ext.m
//  ZLCheckFilePlugin
//
//  Created by 张磊 on 15-1-18.
//  Copyright (c) 2015年 com.zixue101.www. All rights reserved.
//

#import "NSArray+Ext.h"
#import "ZLFile.h"
#import "ZLCheckInfo.h"

@implementation NSArray (Ext)
- (BOOL)inArray:(NSString *)pathExtension{
    return [self containsObject:pathExtension];
}

- (BOOL)exportPlistWithPath:(NSString *)path{
    NSMutableArray *array = [NSMutableArray array];
    for (ZLFile *file in self) {
        [array addObject:@{@"name":file.fileName,@"path":[[[ZLCheckInfo sharedInstance] workSpacePath] stringByAppendingPathComponent:file.filePath]}];
    }
    return [array writeToFile:path atomically:YES];
}

- (instancetype)searchArrayWithSearchText:(NSString *)searchText{
    NSMutableArray *array = [NSMutableArray array];
    for (ZLFile *file in self) {
        if([[file.fileName lowercaseString] rangeOfString:[searchText lowercaseString]].location != NSNotFound){
            [array addObject:file];
        }
    }
    return array;
}
@end
