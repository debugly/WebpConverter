//
//  GragView.m
//  WebpConverter
//
//  Created by 许乾隆 on 2018/11/17.
//  Copyright © 2018 Achievement Technologies. All rights reserved.
//

#import "DragView.h"

@interface DragView ()

@property(nonatomic, copy) GragViewImageUrlsProcessBlock imageUrlsProcessor;
@property(nonatomic, copy) GragViewImageProcessBlock imageProcessor;
@property(nonatomic, assign) BOOL isReceivingDrag;

@end

@implementation DragView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if(self.isReceivingDrag){
        [[NSColor selectedControlColor]set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:dirtyRect];
        path.lineWidth = 5;
        [path stroke];
    }
}

- (void)setIsReceivingDrag:(BOOL)isReceivingDrag
{
    _isReceivingDrag = isReceivingDrag;
    [self setNeedsDisplay:YES];
}

- (void)registerImageUrlsProcess:(GragViewImageUrlsProcessBlock)block
{
    self.imageUrlsProcessor = block;
}

- (void)registerImageProcess:(GragViewImageProcessBlock)block
{
    self.imageProcessor = block;
}

- (void)setup
{
    if (@available(macOS 10.13, *)) {
        [self registerForDraggedTypes:@[NSPasteboardTypeURL,NSPasteboardTypeFileURL]];
    } else {
        [self registerForDraggedTypes:@[NSURLPboardType,NSFilenamesPboardType]];
    }
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)draggingInfo
{
    NSPasteboard *pasteBoard = [draggingInfo draggingPasteboard];
    NSDictionary *options = nil;//[NSDictionary dictionaryWithObject:[NSImage imageTypes] forKey:NSPasteboardURLReadingContentsConformToTypesKey];
    NSArray *urls = [pasteBoard readObjectsForClasses:@[[NSURL class]] options:options];
    NSArray *infoArr = [pasteBoard propertyListForType:NSFilenamesPboardType];
    
    if ([urls count] > 0) {
        if (self.imageUrlsProcessor) {
            NSMutableArray *result = [NSMutableArray arrayWithCapacity:1];
            if ([infoArr isKindOfClass:[NSArray class]]) {
                if ([infoArr count] == [urls count]) {
                    
                    for(int i = 0; i < [infoArr count]; i++){
                        
                        NSURL *url = urls[i];
                        NSString *path = infoArr[i];
                        
                        BOOL isDirectory;
                        if (![[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:&isDirectory]) {
                            ///文件（夹）不存在？
                            continue;
                        }
                        
                        if(isDirectory){
                            
                            NSArray <NSString *>*subPathArr = [[[NSFileManager defaultManager]enumeratorAtPath:path] allObjects];
                            for (NSString *p in subPathArr) {
                                
                                if ([[p lastPathComponent] hasPrefix:@"."]) {
                                    ///忽略 .DS_Store 等文件
                                    continue;
                                }
                                
                                BOOL isDirectory;
                                NSString *fullPath = [path stringByAppendingPathComponent:p];
                                if (![[NSFileManager defaultManager]fileExistsAtPath:fullPath isDirectory:&isDirectory] || isDirectory) {
                                    ///文件（夹）不存在 或者 是文件夹
                                    continue;
                                }
                                ///剩下的都是文件，通过文件名再次过滤
                                if (![@[@"jpg",@"jpeg",@"png"] containsObject:[fullPath pathExtension]]) {
                                    continue;
                                }
                                
                                //NSLog(@"%@",fullPath);
                                
                                DragFileModel *model = [DragFileModel new];
                                model.orignPath = fullPath;
                                model.readURL = [NSURL fileURLWithPath:fullPath];
                                [result addObject:model];
                            }
                            
                        }else{
                            DragFileModel *model = [DragFileModel new];
                            model.orignPath = path;
                            model.readURL = url;
                            [result addObject:model];
                        }
                    }
                    self.imageUrlsProcessor(result);
                }
            }
        }
        return YES;
    } else {
        NSImage *image = [[NSImage alloc]initWithPasteboard:pasteBoard];
        if (image) {
            if (self.imageProcessor) {
                self.imageProcessor(image);
            }
            return YES;
        }else{
            //??
        }
    }
    return NO;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender
{
    self.isReceivingDrag = NO;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)draggingInfo
{
    self.isReceivingDrag = NO;
    BOOL canAccept;
    NSPasteboard *pasteBoard = [draggingInfo draggingPasteboard];
    NSDictionary *options = nil;//[NSDictionary dictionaryWithObject:[NSImage imageTypes] forKey:NSPasteboardURLReadingContentsConformToTypesKey];
    canAccept = [pasteBoard canReadObjectForClasses:@[[NSURL class]] options:options];
    return canAccept;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)draggingInfo
{
    BOOL canAccept = [self prepareForDragOperation:draggingInfo];
    self.isReceivingDrag = canAccept;
    return canAccept ? NSDragOperationCopy : NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    self.isReceivingDrag = NO;
}

@end

