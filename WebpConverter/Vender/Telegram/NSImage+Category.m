
//
//  NSImageCategory.m
//  Messenger for Telegram
//
//  Created by Dmitry Kondratyev on 2/26/14.
//  Copyright (c) 2014 keepcoder. All rights reserved.
//

#import "NSImage+Category.h"
#import "webp/decode.h"
@implementation NSImage (Category)

- (NSImage *) imageWithInsets:(NSEdgeInsets)insets {
    NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(self.size.width + insets.left + insets.right, self.size.height + insets.top + insets.bottom)];
    [newImage lockFocus];
    [self drawAtPoint:NSMakePoint(insets.left, insets.bottom) fromRect:NSMakeRect(0, 0, self.size.width, self.size.height) operation:NSCompositeSourceOver fraction:1];
    [newImage unlockFocus];
    return newImage;
}

-(CGImageRef)CGImage {
    NSData * imageData = [self TIFFRepresentation];
    CGImageRef imageRef;
    if(!imageData) return nil;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    return imageRef;
}


+ (NSImage *)imageWithWebpData:(NSData *)imgData error:(NSError **)error {
    // `WebPGetInfo` weill return image width and height
    int width = 0, height = 0;
    if(!WebPGetInfo([imgData bytes], [imgData length], &width, &height)) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Header formatting error." forKey:NSLocalizedDescriptionKey];
        if(error != NULL)
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@.errorDomain", [[NSBundle mainBundle] bundleIdentifier]] code:-101 userInfo:errorDetail];
        return nil;
    }
    
    const struct { int width, height; } targetContextSize = { width, height};
    
    size_t targetBytesPerRow = ((4 * (int)targetContextSize.width) + 15) & (~15);
    
    void *targetMemory = malloc((int)(targetBytesPerRow * targetContextSize.height));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
    
    CGContextRef targetContext = CGBitmapContextCreate(targetMemory, (int)targetContextSize.width, (int)targetContextSize.height, 8, targetBytesPerRow, colorSpace, bitmapInfo);
    
    
    
    CGColorSpaceRelease(colorSpace);
    
    if (WebPDecodeBGRAInto(imgData.bytes, imgData.length, targetMemory, targetBytesPerRow * targetContextSize.height, targetBytesPerRow) == NULL)
    {
        NSLog(@"error decoding webp");
    }
    
    for (int y = 0; y < targetContextSize.height; y++)
    {
        for (int x = 0; x < targetContextSize.width; x++)
        {
            uint32_t *color = ((uint32_t *)&targetMemory[y * targetBytesPerRow + x * 4]);
            
            uint32_t a = (*color >> 24) & 0xff;
            uint32_t r = ((*color >> 16) & 0xff) * a;
            uint32_t g = ((*color >> 8) & 0xff) * a;
            uint32_t b = (*color & 0xff) * a;
            
            r = (r + 1 + (r >> 8)) >> 8;
            g = (g + 1 + (g >> 8)) >> 8;
            b = (b + 1 + (b >> 8)) >> 8;
            
            *color = (a << 24) | (r << 16) | (g << 8) | b;
        }
        
        for (size_t i = y * targetBytesPerRow + targetContextSize.width * 4; i < (targetBytesPerRow >> 2); i++)
        {
            *((uint32_t *)&targetMemory[i]) = 0;
        }
    }
    
    CGImageRef bitmapImage = CGBitmapContextCreateImage(targetContext);
    NSImage *image = [[NSImage alloc] initWithCGImage:bitmapImage size:NSMakeSize(width, height)];
    CGImageRelease(bitmapImage);
    
    CGContextRelease(targetContext);
    free(targetMemory);
    
    return image;
}

+ (NSImage *)imageWithWebP:(NSString *)filePath error:(NSError **)error
{
    // If passed `filepath` is invalid, return nil to caller and log error in console
    NSError *dataError = nil;;
    NSData *imgData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&dataError];
    if(dataError != nil) {
        NSLog(@"imageFromWebP: error: %@", dataError.localizedDescription);
        return nil;
    }
    
    
    return [self imageWithWebpData:imgData error:error];
    
}


+ (NSData *)convertToWebP:(NSImage *)image
                  quality:(CGFloat)quality
                   preset:(WebPPreset)preset
              configBlock:(void (^)(WebPConfig *))configBlock
                    error:(NSError **)error
{
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
    
    CGImageRef imageRef = image.CGImage;
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

- (NSImage *)imageTintedWithColor:(NSColor *)tint
{
    NSImage *image = [self copy];
    if (tint) {
        [image lockFocus];
        [tint set];
        NSRect imageRect = {NSZeroPoint, [image size]};
        NSRectFillUsingOperation(imageRect, NSCompositeSourceAtop);
        [image unlockFocus];
    }
    return image;
}

int ImgIoUtilReadFile(const char* const file_name,
                      const uint8_t** data, size_t* data_size) {
    int ok;
    uint8_t* file_data;
    size_t file_size;
    FILE* in;
    
    if (data == NULL || data_size == NULL) return 0;
    *data = NULL;
    *data_size = 0;
    
    in = fopen(file_name, "rb");
    if (in == NULL) {
        fprintf(stderr, "cannot open input file '%s'\n", file_name);
        return 0;
    }
    fseek(in, 0, SEEK_END);
    file_size = ftell(in);
    fseek(in, 0, SEEK_SET);
    // we allocate one extra byte for the \0 terminator
    file_data = (uint8_t*)malloc(file_size + 1);
    if (file_data == NULL) {
        fclose(in);
        fprintf(stderr, "memory allocation failure when reading file %s\n",
                file_name);
        return 0;
    }
    ok = (fread(file_data, file_size, 1, in) == 1);
    fclose(in);
    
    if (!ok) {
        fprintf(stderr, "Could not read %d bytes of data from file %s\n",
                (int)file_size, file_name);
        free(file_data);
        return 0;
    }
    file_data[file_size] = '\0';  // convenient 0-terminator
    *data = file_data;
    *data_size = file_size;
    return 1;
}

typedef enum {
    WEBP_PNG_FORMAT = 0,
    WEBP_JPEG_FORMAT,
    WEBP_TIFF_FORMAT,
    WEBP_WEBP_FORMAT,
    WEBP_PNM_FORMAT,
    WEBP_UNSUPPORTED_FORMAT
} WebPInputFileFormat;

typedef struct MetadataPayload {
    uint8_t* bytes;
    size_t size;
} MetadataPayload;

typedef struct Metadata {
    MetadataPayload exif;
    MetadataPayload iccp;
    MetadataPayload xmp;
} Metadata;

typedef int (*WebPImageReader)(const uint8_t* const data, size_t data_size,
                               struct WebPPicture* const pic,
                               int keep_alpha, struct Metadata* const metadata);

static WEBP_INLINE uint32_t GetBE32(const uint8_t buf[]) {
    return ((uint32_t)buf[0] << 24) | (buf[1] << 16) | (buf[2] << 8) | buf[3];
}

WebPInputFileFormat WebPGuessImageType(const uint8_t* const data,
                                       size_t data_size) {
    WebPInputFileFormat format = WEBP_UNSUPPORTED_FORMAT;
    if (data != NULL && data_size >= 12) {
        const uint32_t magic1 = GetBE32(data + 0);
        const uint32_t magic2 = GetBE32(data + 8);
        if (magic1 == 0x89504E47U) {
            format = WEBP_PNG_FORMAT;
        } else if (magic1 >= 0xFFD8FF00U && magic1 <= 0xFFD8FFFFU) {
            format = WEBP_JPEG_FORMAT;
        } else if (magic1 == 0x49492A00 || magic1 == 0x4D4D002A) {
            format = WEBP_TIFF_FORMAT;
        } else if (magic1 == 0x52494646 && magic2 == 0x57454250) {
            format = WEBP_WEBP_FORMAT;
        } else if (((magic1 >> 24) & 0xff) == 'P') {
            const int type = (magic1 >> 16) & 0xff;
            // we only support 'P5 -> P7' for now.
            if (type >= '5' && type <= '7') format = WEBP_PNM_FORMAT;
        }
    }
    return format;
}

static int FailReader(const uint8_t* const data, size_t data_size,
                      struct WebPPicture* const pic,
                      int keep_alpha, struct Metadata* const metadata) {
    (void)data;
    (void)data_size;
    (void)pic;
    (void)keep_alpha;
    (void)metadata;
    return 0;
}

int ReadPNG(const uint8_t* const data, size_t data_size,
            struct WebPPicture* const pic,
            int keep_alpha, struct Metadata* const metadata)
{
    return 0;
}

int ReadJPEG(const uint8_t* const data, size_t data_size,
            struct WebPPicture* const pic,
            int keep_alpha, struct Metadata* const metadata)
{
    return 0;
}

int ReadTIFF(const uint8_t* const data, size_t data_size,
            struct WebPPicture* const pic,
            int keep_alpha, struct Metadata* const metadata)
{
    return 0;
}

int ReadWebP(const uint8_t* const data, size_t data_size,
             WebPPicture* const pic,
             int keep_alpha, Metadata* const metadata) {
    int ok = 0;
    return ok;
}

int ReadPNM(const uint8_t* const data, size_t data_size,
            struct WebPPicture* const pic,
            int keep_alpha, struct Metadata* const metadata)
{
    return 0;
}
WebPImageReader WebPGetImageReader(WebPInputFileFormat format) {
    switch (format) {
        case WEBP_PNG_FORMAT: return ReadPNG;
        case WEBP_JPEG_FORMAT: return ReadJPEG;
        case WEBP_TIFF_FORMAT: return ReadTIFF;
        case WEBP_WEBP_FORMAT: return ReadWebP;
        case WEBP_PNM_FORMAT: return ReadPNM;
        default: return FailReader;
    }
}

void ImgIoUtilCopyPlane(const uint8_t* src, int src_stride,
                        uint8_t* dst, int dst_stride, int width, int height) {
    while (height-- > 0) {
        memcpy(dst, src, width * sizeof(*dst));
        src += src_stride;
        dst += dst_stride;
    }
}

static int ReadYUV(const uint8_t* const data, size_t data_size,
                   WebPPicture* const pic) {
    const int use_argb = pic->use_argb;
    const int uv_width = (pic->width + 1) / 2;
    const int uv_height = (pic->height + 1) / 2;
    const int y_plane_size = pic->width * pic->height;
    const int uv_plane_size = uv_width * uv_height;
    const size_t expected_data_size = y_plane_size + 2 * uv_plane_size;
    
    if (data_size != expected_data_size) {
        fprintf(stderr,
                "input data doesn't have the expected size (%d instead of %d)\n",
                (int)data_size, (int)expected_data_size);
        return 0;
    }
    
    pic->use_argb = 0;
    if (!WebPPictureAlloc(pic)) return 0;
    ImgIoUtilCopyPlane(data, pic->width, pic->y, pic->y_stride,
                       pic->width, pic->height);
    ImgIoUtilCopyPlane(data + y_plane_size, uv_width,
                       pic->u, pic->uv_stride, uv_width, uv_height);
    ImgIoUtilCopyPlane(data + y_plane_size + uv_plane_size, uv_width,
                       pic->v, pic->uv_stride, uv_width, uv_height);
    return use_argb ? WebPPictureYUVAToARGB(pic) : 1;
}

WebPImageReader WebPGuessImageReader(const uint8_t* const data,
                                     size_t data_size) {
    return WebPGetImageReader(WebPGuessImageType(data, data_size));
}

static int ReadPicture(const char* const filename, WebPPicture* const pic,
                       int keep_alpha, Metadata* const metadata) {
    const uint8_t* data = NULL;
    size_t data_size = 0;
    int ok = 0;
    
    ok = ImgIoUtilReadFile(filename, &data, &data_size);
    if (!ok) goto End;
    
    if (pic->width == 0 || pic->height == 0) {
        WebPImageReader reader = WebPGuessImageReader(data, data_size);
        ok = reader(data, data_size, pic, keep_alpha, metadata);
    } else {
        // If image size is specified, infer it as YUV format.
        ok = ReadYUV(data, data_size, pic);
    }
End:
    if (!ok) {
        fprintf(stderr, "Error! Could not process file %s\n", filename);
    }
    free((void*)data);
    return ok;
}
@end
