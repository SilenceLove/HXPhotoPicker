//
//  Demo1ViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/17.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo1ViewController.h"
#import "HXPhotoViewController.h"
#import "HXCustomNavigationController.h"
#import "HXAlbumListViewController.h"

@interface Demo1ViewController ()<HXPhotoViewControllerDelegate,HXAlbumListViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *total;
//@property (weak, nonatomic) IBOutlet UILabel *photo;
//@property (weak, nonatomic) IBOutlet UILabel *video;
@property (weak, nonatomic) IBOutlet UILabel *original;
@property (weak, nonatomic) IBOutlet UISwitch *camera;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (weak, nonatomic) IBOutlet UITextField *photoText;
@property (weak, nonatomic) IBOutlet UITextField *videoText;
@property (weak, nonatomic) IBOutlet UITextField *columnText;
@property (weak, nonatomic) IBOutlet UISwitch *addCamera;
@property (weak, nonatomic) IBOutlet UISwitch *outerCamera;
@property (weak, nonatomic) IBOutlet UISwitch *isSystems;
@property (weak, nonatomic) IBOutlet UISwitch *showHeaderSection;
@property (weak, nonatomic) IBOutlet UISwitch *reverse;
@property (weak, nonatomic) IBOutlet UISegmentedControl *selectedTypeView;

@end

@implementation Demo1ViewController

- (HXPhotoManager *)manager
{
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhoto];
        _manager.videoMaxNum = 5;
        _manager.cacheAlbum = NO;
        _manager.style = HXPhotoAlbumStylesSystem;
        _manager.deleteTemporaryPhoto = NO;
    }
    return _manager;
}

- (void)viewDidLoad {
    [super viewDidLoad]; 
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)goAlbum:(id)sender {
    self.camera.on = NO;
    self.manager.photoMaxNum = self.photoText.text.integerValue;
    self.manager.videoMaxNum = self.videoText.text.integerValue;
    self.manager.rowCount = self.columnText.text.integerValue;
    if (self.isSystems.on) {
        self.manager.style = HXPhotoAlbumStylesSystem;
    }else {
        self.manager.style = HXPhotoAlbumStylesWeibo;
    }
    self.manager.showDateHeaderSection = self.showHeaderSection.on;
    self.manager.reverseDate = self.reverse.on;
    if (self.manager.style == HXPhotoAlbumStylesWeibo) {
        HXPhotoViewController *vc = [[HXPhotoViewController alloc] init];
        vc.delegate = self;
        vc.manager = self.manager;
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:vc] animated:YES completion:nil];
    }else {
        HXAlbumListViewController *vc = [[HXAlbumListViewController alloc] init];
        vc.delegate = self;
        vc.manager = self.manager;
        HXCustomNavigationController *nav = [[HXCustomNavigationController alloc] initWithRootViewController:vc];
        
        [self presentViewController:nav animated:YES completion:nil];
    }
}
- (IBAction)selectTypeClick:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        self.manager.type = HXPhotoManagerSelectedTypePhoto;
    }else if (sender.selectedSegmentIndex == 1) {
        self.manager.type = HXPhotoManagerSelectedTypeVideo;
    }else {
        self.manager.type = HXPhotoManagerSelectedTypePhotoAndVideo;
    }
}

- (void)albumListViewController:(HXAlbumListViewController *)albumListViewController didDoneAllList:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photoList videos:(NSArray<HXPhotoModel *> *)videoList original:(BOOL)original {
    self.total.text = [NSString stringWithFormat:@"总数量：%ld   ( 照片：%ld   视频：%ld )",allList.count, photoList.count, videoList.count];
    //    [NSString stringWithFormat:@"%ld个",allList.count];
    //    self.photo.text = [NSString stringWithFormat:@"%ld张",photos.count];
    //    self.video.text = [NSString stringWithFormat:@"%ld个",videos.count];
    self.original.text = original ? @"YES" : @"NO";
    NSSLog(@"all - %@",allList);
    NSSLog(@"photo - %@",photoList);
    NSSLog(@"video - %@",videoList);
}

- (void)photoViewControllerDidNext:(NSArray *)allList Photos:(NSArray *)photos Videos:(NSArray *)videos Original:(BOOL)original
{
    self.total.text = [NSString stringWithFormat:@"总数量：%ld   ( 照片：%ld   视频：%ld )",allList.count, photos.count, videos.count];
//    [NSString stringWithFormat:@"%ld个",allList.count];
//    self.photo.text = [NSString stringWithFormat:@"%ld张",photos.count];
//    self.video.text = [NSString stringWithFormat:@"%ld个",videos.count];
    self.original.text = original ? @"YES" : @"NO";
    NSSLog(@"all - %@",allList);
    NSSLog(@"photo - %@",photos);
    NSSLog(@"video - %@",videos);
}

- (void)photoViewControllerDidCancel
{
    NSSLog(@"取消");
}

- (IBAction)camera:(id)sender {
    UISwitch *sw = (UISwitch *)sender;
    
    self.manager.goCamera = sw.on;
}
- (IBAction)same:(id)sender {
    UISwitch *sw = (UISwitch *)sender;
    self.manager.selectTogether = sw.on;
}

- (IBAction)isLookGIFPhoto:(UISwitch *)sender {
    self.manager.lookGifPhoto = sender.on;
}

- (IBAction)isLookLivePhoto:(UISwitch *)sender {
    self.manager.lookLivePhoto = sender.on;
}

- (IBAction)outerCamera:(id)sender {
}

- (IBAction)addCamera:(id)sender {
    UISwitch *sw = (UISwitch *)sender;
    self.manager.openCamera = sw.on;
}

@end
