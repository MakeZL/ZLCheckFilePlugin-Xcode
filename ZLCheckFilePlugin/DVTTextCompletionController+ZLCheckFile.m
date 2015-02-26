//
//  DVTTextCompletionController+ZLCheckFile.m
//  ZLCheckFilePlugin
//
//  Created by 张磊 on 15-1-21.
//  Copyright (c) 2015年 com.zixue101.www. All rights reserved.
//

#import "DVTTextCompletionController+ZLCheckFile.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation DVTTextCompletionController (ZLCheckFile)

+ (void)load
{
    Method m1 = class_getInstanceMethod(self, @selector(acceptCurrentCompletion));
    Method m2 = class_getInstanceMethod(self, @selector(swizzledAcceptCurrentCompletion));

    if (m1 && m2) {
        method_exchangeImplementations(m1, m2);
    }
}

- (BOOL)swizzledAcceptCurrentCompletion {
    
    return [self swizzledAcceptCurrentCompletion];
}



@end
