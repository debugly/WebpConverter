//
//  NSImageCategory.h
//  WebpConverter
//
//  Created by 许乾隆 on 2018/11/27.
//  Copyright © 2018 Achievement Technologies. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Category)

- (NSImage *) imageWithInsets:(NSEdgeInsets)insets;

- (CGImageRef)CGImage;

@end
