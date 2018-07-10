//
//  Demo9ViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2018/2/14.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import "Demo9ViewController.h"
#import "Demo9ViewCell.h"
#import "Demo9Model.h"
#import "HXPhotoPicker.h"
@interface Demo9ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (nonatomic, strong) NSMutableArray *uploadArray;
@property (nonatomic, strong) NSMutableArray *waitArray;
@property (nonatomic, strong) NSMutableArray *completeArray;
@property (strong, nonatomic) HXDatePhotoToolManager *toolManager;
@end

@implementation Demo9ViewController

- (HXDatePhotoToolManager *)toolManager {
    if (!_toolManager) {
        _toolManager = [[HXDatePhotoToolManager alloc] init];
    }
    return _toolManager;
}
- (void)viewDidLoad {
    [super viewDidLoad];
//    self.navigationController.navigationBar.translucent = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.dataArray = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        Demo9Model *model = [[Demo9Model alloc] init];
        [self.dataArray addObject:model];
    }
    // Do any additional setup after loading the view.
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kNavigationBarHeight, self.view.hx_w, self.view.hx_h - kNavigationBarHeight) style:UITableViewStyleGrouped];
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
#else
        if ((NO)) {
#endif
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
    self.tableView.alwaysBounceVertical = YES;
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[Demo9ViewCell class] forCellReuseIdentifier:@"CellId"];
    [self.view addSubview:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"写入" style:UIBarButtonItemStyleDone target:self action:@selector(didRightBtn)];
}
- (void)didRightBtn {
    self.completeArray = [NSMutableArray array];
    self.waitArray = [NSMutableArray arrayWithArray:self.dataArray];
    [self.view showLoadingHUDText:@"写入中"];
    [self startUpload];
}
- (void)startUpload {
    if (self.waitArray.count == 0) {
        [self.view handleLoading];
        NSSLog(@"全部写入完毕");
        return;
    }
    __block Demo9Model *model = self.waitArray.firstObject;
    [self.waitArray removeObjectAtIndex:0];
    __weak typeof(self) weakSelf = self;
    if (model.endSelectedList.count > 0) {
        [self.toolManager writeSelectModelListToTempPathWithList:model.endSelectedList requestType:0 success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
            NSSLog(@"\n第%ld个cell写入完成\n%@",[weakSelf.dataArray indexOfObject:model],allURL);
            model.photoUrls = allURL;
            [weakSelf.completeArray addObject:model];
            [weakSelf startUpload];
        } failed:^{
            [weakSelf.view handleLoading];
            [weakSelf.view showImageHUDText:[NSString stringWithFormat:@"第%ld个cell写入失败",[weakSelf.dataArray indexOfObject:model]]];
        }];
    }else {
        [self.completeArray addObject:model];
        [self startUpload];
    }
}
#pragma mark - < UITableViewDataSource >
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Demo9ViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellId"];
    cell.model = self.dataArray[indexPath.section];
    __weak typeof(self) weakSelf = self;
    [cell setPhotoViewChangeHeightBlock:^(UITableViewCell *mycell) {
        [weakSelf.tableView reloadRowsAtIndexPaths:@[[weakSelf.tableView indexPathForCell:mycell]] withRowAnimation:0];
    }];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Demo9Model *model = self.dataArray[indexPath.section];
    return model.cellHeight;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 10;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 10;
}
@end
