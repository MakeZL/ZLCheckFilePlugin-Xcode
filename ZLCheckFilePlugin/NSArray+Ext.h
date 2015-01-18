//
//  NSArray+Ext.h
//  ZLCheckFilePlugin
//
//  Created by 张磊 on 15-1-18.
//  Copyright (c) 2015年 com.zixue101.www. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Ext)
// match array in pathExtension
- (BOOL)inArray:(NSString *)pathExtension;
// export path
- (BOOL)exportPlistWithPath:(NSString *)path;
// return search files in searchText
- (instancetype)searchArrayWithSearchText:(NSString *)searchText;
@end
