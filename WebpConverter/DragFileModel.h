//
//  DragFileModel.h
//  WebpConverter
//
//  Created by 许乾隆 on 2018/11/17.
//  Copyright © 2018 Achievement Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DragFileModel : NSObject

@property(nonatomic,strong) NSURL *readURL;
@property(nonatomic,copy) NSString *orignPath;

@end

NS_ASSUME_NONNULL_END
