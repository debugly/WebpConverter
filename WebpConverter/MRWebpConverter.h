//
//  MRWebpConverter.h
//  WebpConverter
//
//  Created by 许乾隆 on 2018/11/27.
//  Copyright © 2018 Achievement Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <webp/encode.h>

NS_ASSUME_NONNULL_BEGIN

@interface MRWebpConverter : NSObject

+ (NSData *)convertImageToWebP:(NSImage *)image configBlock:(void (^)(WebPConfig * _Nonnull))configBlock error:(NSError * _Nullable __autoreleasing *)error;

+ (NSData *)convertToWebP:(NSString *)path
              configBlock:(void (^)(WebPConfig *))configBlock
                    error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
