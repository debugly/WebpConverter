//
//  StatusTableCellView.h
//  WebpConverter
//
//  Created by 许乾隆 on 2018/11/20.
//  Copyright © 2018 Achievement Technologies. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@class CellModel;

typedef void (^OnClickedInfoButtonHandler) (CellModel *cellModel);

@interface StatusTableCellView : NSTableCellView

@property (weak) IBOutlet NSProgressIndicator *indicator;
@property (weak) IBOutlet NSButton *infoBtn;

@property (weak,nonatomic,readonly) CellModel *cellModel;

- (void)updateModel:(CellModel *)model;
- (void)registerOnClickedInfoButtonHandler:(OnClickedInfoButtonHandler)handler;

@end

NS_ASSUME_NONNULL_END
