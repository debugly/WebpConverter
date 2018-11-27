//
//  NSImageCategory.m
//  WebpConverter
//
//  Created by 许乾隆 on 2018/11/27.
//  Copyright © 2018 Achievement Technologies. All rights reserved.
//

#import "NSImage+Category.h"

@implementation NSImage (Category)

- (NSImage *) imageWithInsets:(NSEdgeInsets)insets {
    NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(self.size.width + insets.left + insets.right, self.size.height + insets.top + insets.bottom)];
    [newImage lockFocus];
    [self drawAtPoint:NSMakePoint(insets.left, insets.bottom) fromRect:NSMakeRect(0, 0, self.size.width, self.size.height) operation:NSCompositeSourceOver fraction:1];
    [newImage unlockFocus];
    return newImage;
}

- (CGImageRef)CGImage {
    NSData * imageData = [self TIFFRepresentation];
    CGImageRef imageRef;
    if(!imageData) return nil;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    return imageRef;
}

@end
