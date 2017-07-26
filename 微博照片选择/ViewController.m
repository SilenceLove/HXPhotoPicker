//
//  ViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "ViewController.h"
#import "Demo1ViewController.h"
#import "Demo2ViewController.h"
#import "Demo3ViewController.h"
#import "Demo4ViewController.h"
#import "Demo5ViewController.h"
#import "Demo6ViewController.h"
@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (copy, nonatomic) NSArray *list;
@end

@implementation ViewController

- (NSArray *)list
{
    if (!_list) {
        _list = @[@"Demo1-只使用照片选择功能,不带选好后自动布局(可扩展)",@"Demo2-使用照片选择功能并且选好后自动布局",@"Demo3-附带网络照片功能",@"Demo4-单选样式支持裁剪",@"Demo5-同个界面多个选择器",@"Demo6-拍照/选择照片完之后跳界面"];
    }
    return _list;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.title = @"仿微博照片选择器";

    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = 80;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cellId"];
    [self.view addSubview:tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellId"];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text = self.list[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        Demo1ViewController *vc = [[Demo1ViewController alloc] init];
        vc.title = @"Demo1";
        [self.navigationController pushViewController:vc animated:YES];
    }else if (indexPath.row == 1) {
        Demo2ViewController *vc = [[Demo2ViewController alloc] init];
        vc.title = @"Demo2";
        [self.navigationController pushViewController:vc animated:YES];
    }else if (indexPath.row == 2) {
        Demo3ViewController *vc = [[Demo3ViewController alloc] init];
        vc.title = @"Demo3";
        [self.navigationController pushViewController:vc animated:YES];
    }else if (indexPath.row == 3) {
        Demo4ViewController *vc = [[Demo4ViewController alloc] init];
        vc.title = @"Demo4";
        [self.navigationController pushViewController:vc animated:YES];
    }else if (indexPath.row == 4) {
        Demo5ViewController *vc = [[Demo5ViewController alloc] init];
        vc.title = @"Demo5";
        [self.navigationController pushViewController:vc animated:YES];
    }else if (indexPath.row == 5) {
        Demo6ViewController *vc = [[Demo6ViewController alloc] init];
        vc.title = @"Demo6";
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
