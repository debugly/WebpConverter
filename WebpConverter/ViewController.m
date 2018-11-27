//
//  ViewController.m
//  WebpConverter
//
//  Created by 许乾隆 on 2018/11/12.
//  Copyright © 2018 Achievement Technologies. All rights reserved.
//
//https://storage.googleapis.com/downloads.webmproject.org/releases/webp/index.html

#import "ViewController.h"
#import "DragView.h"
#import "MRWebpConverter.h"
#import "DragFileModel.h"
#import "CellModel.h"
#import "StatusTableCellView.h"

#define __WeakSelf__ __weak typeof(self)weakSelf = self;
#define __StrongSelf__ __strong typeof(weakSelf)self = weakSelf;

@interface ViewController ()<NSTabViewDelegate,NSTableViewDataSource,NSOpenSavePanelDelegate>

@property (weak) IBOutlet DragView *dragView;
@property (weak) IBOutlet NSView *bottomView;
@property (nonatomic,strong) NSArray *dataSource;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *tripLabel;

@property (nonatomic,strong) NSOperationQueue *queue;
@property (nonatomic,strong) NSOpenPanel *openPanel;
@property (weak) IBOutlet NSButton *beginConvertBtn;

@end

@implementation ViewController

- (NSOperationQueue *)queue
{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc]init];
        [_queue setMaxConcurrentOperationCount:4];
    }
    return _queue;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.bottomView.wantsLayer = YES;
//    self.bottomView.layer.borderWidth = 10;
    self.bottomView.layer.borderColor = [[NSColor redColor]CGColor];
//    self.bottomView.layer.masksToBounds = YES;
    
    __WeakSelf__
    [self.dragView registerImageProcess:^(NSImage * image) {
        
    }];
    
    [self.dragView registerImageUrlsProcess:^(NSArray<DragFileModel *> * modelArr) {
        __StrongSelf__
        self.dataSource = [self convertModel2CellModel:modelArr];
    }];
    
    ///等待数据源！
    [self hideTableView:YES];
}

- (void)hideTableView:(BOOL)yesno
{
   [[self.tableView superview]superview].hidden = yesno;
}

- (NSArray *)convertModel2CellModel:(NSArray<DragFileModel *> * )modelArr
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:3];
    for (DragFileModel *model in modelArr) {
        CellModel *cModel = [CellModel new];
        cModel.srcPath = model.orignPath;
        NSDictionary *attributes = [[NSFileManager defaultManager]attributesOfItemAtPath:cModel.srcPath error:nil];
        cModel.fileSize = [attributes[NSFileSize]intValue];
        [result addObject:cModel];
    }
    return [result copy];
}

- (void)setDataSource:(NSArray *)dataSource
{
    _dataSource = [dataSource copy];
    [self.tableView reloadData];
    self.tripLabel.hidden = [_dataSource count] > 0;
    [self hideTableView:!self.tripLabel.hidden];
    self.beginConvertBtn.enabled = self.tripLabel.hidden;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)openFinderPanel:(NSButton *)sender {
    // Show an 'Open' dialog box allowing save folder selection.
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setTitle:@"Open Panel Title"];
    [openPanel setPrompt:@"确定"];
    openPanel.delegate = self;
    [openPanel beginWithCompletionHandler:^(NSModalResponse result) {
        switch (result) {
            case NSModalResponseOK:
            {
                
            }
                break;
            case NSModalResponseCancel:
            {
                
            }
                break;
        }
    }];
    
    self.openPanel = openPanel;
}

- (void)panel:(id)sender didChangeToDirectoryURL:(nullable NSURL *)url NS_AVAILABLE_MAC(10_6)
{
    NSLog(@"didChangeToDirectoryURL:%@",url);
}

/* Optional - Filename customization for the NSSavePanel. Allows the delegate to customize the filename entered by the user, before the extension is appended, and before the user is potentially asked to replace a file.
 */
- (nullable NSString *)panel:(id)sender userEnteredFilename:(NSString *)filename confirmed:(BOOL)okFlag
{
    return @"none";
}

/* Optional - Sent when the user clicks the disclosure triangle to expand or collapse the file browser while in NSOpenPanel.
 */
- (void)panel:(id)sender willExpand:(BOOL)expanding
{
    
}

/* Optional - Sent when the user has changed the selection.
 */
- (void)panelSelectionDidChange:(NSOpenPanel *)sender
{
    NSLog(@"panelSelectionDidChange:%@",sender.URLs);
}

- (void)checkAllTaskFinish
{
    BOOL finished = [self.queue operationCount] == 0;
    if (finished) {
        @synchronized (self) {
            
            NSArray *urlArr = [self.dataSource copy];
            for (CellModel *model in urlArr) {
                if (model.state == CellTaskStateNone || model.state == CellTaskStateRuning) {
                    finished = NO;
                    break;
                }
            }
        }
    }
    
    if (finished) {
        if (self.beginConvertBtn.enabled && self.beginConvertBtn.state == NSControlStateValueOn) {
            BOOL hasFailed = NO;
            NSArray *urlArr = [self.dataSource copy];
            for (CellModel *model in urlArr) {
                if (model.state == CellTaskStateFailed) {
                    hasFailed = YES;
                    break;
                }
            }
            self.beginConvertBtn.state = NSControlStateValueOff;
            
            if (hasFailed) {
                self.beginConvertBtn.enabled = YES;
            } else {
                self.beginConvertBtn.enabled = NO;
            }
        }
    }
}

- (IBAction)toggleConvert:(NSButton *)sender {
    if (sender.state == NSControlStateValueOff) {
        [self stopConvert:sender];
    }else{
        [self beginConvert:sender];
    }
}

- (void)stopConvert:(NSButton *)sender
{
    [self.queue cancelAllOperations];
}

- (void)beginConvert:(NSButton *)sender
{
    NSArray *urlArr = [self.dataSource copy];
    int i = 0;
    for (CellModel *model in urlArr) {
        
        if (model.state == CellTaskStateSucceed || model.state == CellTaskStateRuning) {
            i++;
            continue;
        }
        
        NSString *path = model.srcPath;
        
        __WeakSelf__
        [self.queue addOperationWithBlock:^{
            
            model.state = CellTaskStateRuning;
            
            [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                __StrongSelf__
                
                [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:i] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,4)]];
            }];

            NSError *error = nil;
            NSData *data = [MRWebpConverter convertToWebP:path configBlock:^(WebPConfig * config) {
                config->lossless = 0;
                config->method = 4;
            } error:&error];
            
            if(!error){
                NSString *filePath = [[path stringByDeletingPathExtension]stringByAppendingPathExtension:@"webp"];
                BOOL ok = [data writeToFile:filePath options:NSDataWritingAtomic error:&error];
                if (ok) {
                    NSLog(@"%@",filePath);
                    model.destPath = filePath;
                    model.state = CellTaskStateSucceed;
                    NSDictionary *attributes = [[NSFileManager defaultManager]attributesOfItemAtPath:model.destPath error:nil];
                    model.webpFileSize = [attributes[NSFileSize]intValue];
                    model.savingSize = 100.0 * (int64_t)(model.fileSize - model.webpFileSize)/model.fileSize;
                }else{
                    NSLog(@"Write File Failed:%@,Error:%@",filePath,error);
                    model.state = CellTaskStateFailed;
                }
            }else{
                NSLog(@"Error:%@",error);
                model.state = CellTaskStateFailed;
            }
            
            [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                __StrongSelf__
                
                [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:i] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 4)]];
                
                [self checkAllTaskFinish];
            }];
        }];
        
        i++;
    }
    
    if ([self.queue operationCount] == 0) {
        sender.state = NSControlStateValueOff;
        sender.enabled = NO;
    }
}

#pragma NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.dataSource count];
}


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *identifier = tableColumn.identifier;
    NSTableCellView *cell = [tableView makeViewWithIdentifier:identifier owner:nil];
    if (row < [self.dataSource count]) {
        CellModel *model = self.dataSource[row];
        
        if ([@"status" isEqualToString:identifier]) {
            StatusTableCellView *cellView = (StatusTableCellView *)cell;
            [cellView updateModel:model];
            [cellView registerOnClickedInfoButtonHandler:^(CellModel * _Nonnull cellModel) {
                NSString *path = (model.destPath.length > 0) ? model.destPath : model.srcPath;
                [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
            }];
            
        } else if ([@"path" isEqualToString:identifier]) {
            NSString *path = (model.destPath.length > 0) ? model.destPath : model.srcPath;
            cell.textField.stringValue = path;
        } else if ([@"size" isEqualToString:identifier]) {
            cell.textField.integerValue = model.fileSize;
        } else if ([@"save" isEqualToString:identifier]) {
            if (model.state == CellTaskStateSucceed) {
                cell.textField.stringValue = [NSString stringWithFormat:@"%0.2f%%",model.savingSize];
            }else{
                cell.textField.stringValue = @"-";
            }
        }
    }
    return cell;
}

#pragma mark - 是否可以选中单元格
-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row{
    
    return NO;
//    //设置cell选中高亮颜色
//    NSTableRowView *myRowView = [self.tableView rowViewAtRow:row makeIfNecessary:NO];
//
//    [myRowView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];
//    [myRowView setEmphasized:NO];
//
//    NSLog(@"shouldSelect : %d",row);
//
//    return YES;
}

//- (void)tableViewSelectionDidChange:(NSNotification *)notification {
//
//    NSTableView *tableView = notification.object;
//    NSLog(@"---selection row %ld", tableView.selectedRow);
//    //    CustomTableCellView *contentView = [tableView makeViewWithIdentifier:@"name" owner:self];
//
//    if(tableView.selectedRow < [self.dataSource count]){
//        CellModel *model = self.dataSource[tableView.selectedRow];
//
//    }
//}

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSString *identifier = tableColumn.identifier;
    
    if ([@"status" isEqualToString:identifier]) {
        static BOOL ascending = YES;
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"state" ascending:ascending];
        self.dataSource = [self.dataSource sortedArrayUsingDescriptors:@[sort]];
        ascending = !ascending;
    } else if ([@"path" isEqualToString:identifier]) {
        static BOOL ascending = YES;
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"filePath" ascending:ascending];
        self.dataSource = [self.dataSource sortedArrayUsingDescriptors:@[sort]];
        ascending = !ascending;
    } else if ([@"size" isEqualToString:identifier]) {
        static BOOL ascending = YES;
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"fileSize" ascending:ascending];
        self.dataSource = [self.dataSource sortedArrayUsingDescriptors:@[sort]];
        ascending = !ascending;
    } else if ([@"save" isEqualToString:identifier]) {
        static BOOL ascending = YES;
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"savingSize" ascending:ascending];
        self.dataSource = [self.dataSource sortedArrayUsingDescriptors:@[sort]];
        ascending = !ascending;
    }
}

@end
