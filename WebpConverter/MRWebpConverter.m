//
//  MRWebpConverter.m
//  WebpConverter
//
//  Created by 许乾隆 on 2018/11/27.
//  Copyright © 2018 Achievement Technologies. All rights reserved.
//

#import "MRWebpConverter.h"
#import <AppKit/NSImage.h>
#import "NSImage+Category.h"

static CGFloat kQuality = 75.0f;

@implementation MRWebpConverter

+ (NSData *)convertToWebP:(NSString *)path configBlock:(void (^)(WebPConfig * _Nonnull config))configBlock error:(NSError * _Nullable __autoreleasing *)error
{
    NSAssert(path, @"路径不能为空！");
    NSImage *img = [[NSImage alloc]initWithContentsOfFile:path];
    if (!img) {
        NSString *msg = [NSString stringWithFormat:@"不能创建图片:%@",path];
        *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain", [[NSBundle mainBundle] bundleIdentifier]] code:-100 userInfo:@{NSLocalizedDescriptionKey:msg}];
        return nil;
    }
    return [self convertImageToWebP:img configBlock:configBlock error:error];
}

+ (NSData *)convertImageToWebP:(NSImage *)image configBlock:(void (^)(WebPConfig * _Nonnull))configBlock error:(NSError * _Nullable __autoreleasing *)error
{
    CGFloat quality = kQuality;
    WebPPreset preset = WEBP_PRESET_DEFAULT;
    
    WebPConfig config;
    if (!WebPConfigPreset(&config, preset, quality)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Configuration preset failed to initialize." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain", [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        return nil;
    }
    
    if (configBlock) {
        configBlock(&config);
    }
    
    switch ((WebPPreset)preset) {
        case WEBP_PRESET_DEFAULT: {
            config.image_hint = WEBP_HINT_DEFAULT;
        } break;
        case WEBP_PRESET_PICTURE: {
            config.image_hint = WEBP_HINT_PICTURE;
        } break;
        case WEBP_PRESET_PHOTO: {
            config.image_hint = WEBP_HINT_PHOTO;
        } break;
        case WEBP_PRESET_DRAWING:
        case WEBP_PRESET_ICON:
        case WEBP_PRESET_TEXT: {
            config.image_hint = WEBP_HINT_GRAPH;
        } break;
    }
    
    if (!WebPValidateConfig(&config)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"One or more configuration parameters are beyond their valid ranges." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain", [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        return nil;
    }
    
    WebPPicture pic;
    if (!WebPPictureInit(&pic)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Failed to initialize structure. Version mismatch." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain", [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        return nil;
    }
    
    pic.colorspace = WEBP_YUV420;
    pic.writer = WebPMemoryWrite;
    
    WebPMemoryWriter writer;
    WebPMemoryWriterInit(&writer);
    
    pic.custom_ptr = &writer;
    
    CGImageRef imageRef = [image CGImage];
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    
    size_t imageWidth = CGImageGetWidth(imageRef);
    size_t imageHeight = CGImageGetHeight(imageRef);
    
    CGDataProviderRef dataProviderRef = CGImageGetDataProvider(imageRef);
    CFDataRef imageDatRef = CGDataProviderCopyData(dataProviderRef);
    
    uint8_t *imageData = (uint8_t *)CFDataGetBytePtr(imageDatRef);
    
    pic.width = (int)imageWidth;
    pic.height = (int)imageHeight;
    
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    
    switch (alphaInfo) {
            //RGBA
        case kCGImageAlphaPremultipliedLast:
        case kCGImageAlphaLast:
        {
            WebPPictureImportRGBA(&pic, imageData, (int)bytesPerRow);
        }
            break;
        case kCGImageAlphaOnly:
        {
            NSAssert(NO, @"不支持的编码类型");
        }
            break;
            //ARGB
        case kCGImageAlphaFirst:
        case kCGImageAlphaPremultipliedFirst:
        {
            WebPPictureImportBGRA(&pic, imageData, (int)bytesPerRow);
        }
            break;
            //RBGX
        case kCGImageAlphaNoneSkipLast:
        {
            NSAssert(NO, @"不支持的编码类型");
        }
            break;
            //XRBG
        case kCGImageAlphaNoneSkipFirst:
        {
            NSAssert(NO, @"不支持的编码类型");
        }
            break;
        case kCGImageAlphaNone:
        {
            WebPPictureImportRGB(&pic, imageData, (int)bytesPerRow);
        }
            break;
    }
    
    WebPPictureARGBToYUVA(&pic, pic.colorspace);
    WebPCleanupTransparentArea(&pic);
    WebPEncode(&config, &pic);
    
    NSData *webPFinalData = [NSData dataWithBytes:writer.mem length:writer.size];
    
    WebPPictureFree(&pic);
    CFRelease(imageDatRef);
    
    return webPFinalData;
}

@end
