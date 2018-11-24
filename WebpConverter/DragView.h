//
//  GragView.h
//  WebpConverter
//
//  Created by 许乾隆 on 2018/11/17.
//  Copyright © 2018 Achievement Technologies. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DragFileModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^GragViewImageUrlsProcessBlock) (NSArray <DragFileModel *>*);
typedef void(^GragViewImageProcessBlock) (NSImage *);

@interface DragView : NSView

- (void)registerImageUrlsProcess:(GragViewImageUrlsProcessBlock)block;
- (void)registerImageProcess:(GragViewImageProcessBlock)block;

@end

NS_ASSUME_NONNULL_END
