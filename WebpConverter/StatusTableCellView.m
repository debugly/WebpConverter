//
//  StatusTableCellView.m
//  WebpConverter
//
//  Created by 许乾隆 on 2018/11/20.
//  Copyright © 2018 Achievement Technologies. All rights reserved.
//

#import "StatusTableCellView.h"
#import "CellModel.h"

@interface StatusTableCellView ()

@property (weak,nonatomic,readwrite) CellModel *cellModel;
@property (copy,nonatomic) OnClickedInfoButtonHandler handler;

@end

@implementation StatusTableCellView

- (void)awakeFromNib
{
    [self.infoBtn setTarget:self];
    [self.infoBtn setAction:@selector(onClicked)];
    [self.infoBtn setHidden:YES];
    [self.indicator setHidden:YES];
}

- (void)onClicked
{
    if (self.handler) {
        self.handler(self.cellModel);
    }
}

- (void)registerOnClickedInfoButtonHandler:(OnClickedInfoButtonHandler)handler
{
    self.handler = handler;
}

- (void)updateModel:(CellModel *)model
{
    self.cellModel = model;
    
    [self.infoBtn setHidden:YES];
    [self.indicator setHidden:YES];
    
    switch (model.state) {
        case CellTaskStateNone:
        {
            [self.infoBtn setHidden:NO];
            [self.infoBtn setImage:[NSImage imageNamed:@"info"]];
            [self.indicator stopAnimation:nil];
        }
            break;
        case CellTaskStateRuning:
        {
            [self.infoBtn setHidden:YES];
            [self.indicator startAnimation:nil];
        }
            break;
        case CellTaskStateSucceed:
        {
            [self.indicator stopAnimation:nil];
            [self.infoBtn setHidden:NO];
            [self.infoBtn setImage:[NSImage imageNamed:@"done"]];
            
        }
            break;
        case CellTaskStateFailed:
        {
            [self.indicator stopAnimation:nil];
            [self.infoBtn setHidden:NO];
            [self.infoBtn setImage:[NSImage imageNamed:@"error"]];
        }
            break;
    }
}

@end
