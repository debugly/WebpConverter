//
//  CellModel.h
//  WebpConverter
//
//  Created by 许乾隆 on 2018/11/18.
//  Copyright © 2018 Achievement Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CellTaskState) {
    CellTaskStateNone,
    CellTaskStateRuning,
    CellTaskStateSucceed,
    CellTaskStateFailed
};

@interface CellModel : NSObject

@property (nonatomic,copy) NSString *srcPath;
@property (nonatomic,copy) NSString *destPath;
@property (nonatomic,assign) uint64 fileSize;
@property (nonatomic,assign) uint64 webpFileSize;
@property (nonatomic,assign) CGFloat savingSize;
@property (nonatomic,assign) CellTaskState state;

@end

NS_ASSUME_NONNULL_END
