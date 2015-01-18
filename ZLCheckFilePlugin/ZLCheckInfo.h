//
//  ZLCheckInfo.h
//  ZLCheckFilePlugin
//
//  Created by 张磊 on 15-1-16.
//  Copyright (c) 2015年 com.zixue101.www. All rights reserved.
//  Save Data Class.

#import <Foundation/Foundation.h>

typedef void(^callBack)(NSArray *arr);

@interface ZLCheckInfo : NSObject

// instance a object
+ (instancetype)sharedInstance;
// work path
@property (copy,nonatomic) NSString *workSpacePath;
- (void)getFilesWithCallBack:(callBack)callBack;
// return .plist file Path.
- (NSString *)exportFilesInBundlePlist;
// search files
- (NSArray *)searchFilesWithText:(NSString *)searchText;
@end
