//
//  HXPhotoEditViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/6/30.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoEditViewController.h"
#import "HXPhotoModel.h"
#import "HXPhotoTools.h"
#import "HXPhotoEditView.h"
@interface HXPhotoEditViewController ()<UIScrollViewDelegate>
@property (weak, nonatomic) UIScrollView *scrollView;
@property (weak, nonatomic) UIImageView *imageView;
@property (assign, nonatomic) CGPoint imageCenter;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (strong, nonatomic) UIView *bgView;
@property (strong, nonatomic) HXPhotoEditView *editView;
@property (assign, nonatomic) CGFloat minimumZoomScale;
@end

@implementation HXPhotoEditViewController
#pragma mark - < 生命周期 >
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
    [self setupUI];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
}
- (void)dealloc {
    [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
}
#pragma mark - < 设置UI >
- (void)setupUI {
    self.title = @"裁剪";
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.translucent = YES;
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightBtn setTitle:@"确定" forState:UIControlStateNormal];
    [rightBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [rightBtn setBackgroundColor:[UIColor colorWithRed:253/255.0 green:142/255.0 blue:36/255.0 alpha:1]];
    [rightBtn addTarget:self action:@selector(didRightNavBtnClick) forControlEvents:UIControlEventTouchUpInside];
    rightBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    rightBtn.layer.cornerRadius = 3;
    rightBtn.frame = CGRectMake(0, 0, 60, 25);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
    [self.view addSubview:self.bgView];
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.delegate = self;
    scrollView.bouncesZoom = YES;
    scrollView.multipleTouchEnabled = YES;
    scrollView.delegate = self;
    scrollView.scrollsToTop = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.bounces = NO;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.delaysContentTouches = NO;
    scrollView.canCancelContentTouches = YES;
    scrollView.alwaysBounceVertical = NO;
    [self.bgView addSubview:scrollView];
    
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    tap2.numberOfTapsRequired = 2;
    [scrollView addGestureRecognizer:tap2];
    self.scrollView = scrollView;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = self.coverImage;
    [scrollView addSubview:imageView];
    self.imageView = imageView;
    
    self.editView = [[HXPhotoEditView alloc] initWithFrame:self.bgView.frame];
    
    [self.view addSubview:self.editView];
    
    [self setupModel];
}
- (void)setupModel {
    CGFloat width = self.bgView.frame.size.width;
    CGFloat height = self.bgView.frame.size.height;
    CGFloat imgWidth = self.model.imageSize.width;
    CGFloat imgHeight = self.model.imageSize.height;
    CGFloat w;
    CGFloat h;
    
    imgHeight = width / imgWidth * imgHeight;
    if (imgHeight > height) {
        w = height / self.model.imageSize.height * imgWidth;
        h = height;
        self.scrollView.maximumZoomScale = width / w + 0.5;
    }else {
        w = width;
        h = imgHeight;
        self.scrollView.maximumZoomScale = 2.5;
    }
    CGFloat diameter = width - 20;
    CGFloat multiple = 1.05f;
    if (h < w) {
        if (w > diameter) {
            if (h < diameter) {
                multiple = diameter / h + 0.1;
            }
        }else {
            multiple = diameter / h + 0.1;
        }
    }else {
        if (h < diameter) {
            multiple = diameter / w + 0.1;
        }else {
            if (w < diameter) {
                multiple = diameter / w + 0.1;
            }
        }
    }
    self.scrollView.frame = self.bgView.bounds;
    self.scrollView.layer.masksToBounds = NO;
    self.scrollView.contentSize = CGSizeMake(width, h);
    self.scrollView.contentInset = UIEdgeInsetsMake(height / 2 - (diameter / 2), 10, height / 2 - (diameter / 2), 10);
    
    _imageView.frame = CGRectMake(0, 0, w, h);
    
    self.scrollView.minimumZoomScale = multiple;
    [self.scrollView setZoomScale:multiple animated:NO];
    self.minimumZoomScale = multiple;
    self.scrollView.maximumZoomScale = multiple + self.scrollView.maximumZoomScale;
    
    if (self.model.type == HXPhotoModelMediaTypeCameraPhoto) {
        self.imageView.image = self.model.previewPhoto;
    }else {
        __weak typeof(self) weakSelf = self;
        self.requestID = [HXPhotoTools getPhotoForPHAsset:self.model.asset size:PHImageManagerMaximumSize completion:^(UIImage *image, NSDictionary *info) {
            weakSelf.imageView.image = image;
        }];
    }
}
#pragma mark - < 点击事件 >
- (void)didRightNavBtnClick {
    [self clipImage];
}
- (void)doubleTap:(UITapGestureRecognizer *)tap {
    CGFloat width = self.scrollView.frame.size.width;
    CGFloat height = self.scrollView.frame.size.height;
    if (_scrollView.zoomScale > self.minimumZoomScale) {
        [_scrollView setZoomScale:self.minimumZoomScale animated:YES];
    } else {
        CGPoint touchPoint = [tap locationInView:self.imageView];
        CGFloat newZoomScale = _scrollView.maximumZoomScale;
        CGFloat xsize = width / newZoomScale;
        CGFloat ysize = height / newZoomScale;
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}
- (void)clipImage {
    NSString *cameraIdentifier = @"";
    NSDate *nowDate = [NSDate date];
    NSString *dateStr = [NSString stringWithFormat:@"%ld", (long)[nowDate timeIntervalSince1970]];
    NSString *numStr = [NSString stringWithFormat:@"%d",arc4random()%10000];
    cameraIdentifier = [cameraIdentifier stringByAppendingString:dateStr];
    cameraIdentifier = [cameraIdentifier stringByAppendingString:numStr];
    CGFloat width = self.bgView.frame.size.width;
    CGFloat height = self.bgView.frame.size.height;
    CGFloat diameter = width - 20;
    UIImage *image = [self imageFromView:self.bgView atFrame:CGRectMake(10, (height / 2 - diameter / 2), diameter, diameter)];
    HXPhotoModel *model = [[HXPhotoModel alloc] init];
    model.thumbPhoto = image;
    model.previewPhoto = image;
    model.imageSize = image.size;
    model.type = HXPhotoModelMediaTypeCameraPhoto;
    model.cameraIdentifier = cameraIdentifier;
    if ([self.delegate respondsToSelector:@selector(editViewControllerDidNextClick:)]) {
        [self.delegate editViewControllerDidNextClick:model];
    }
}
//获得某个范围内的屏幕图像
- (UIImage *)imageFromView: (UIView *) theView   atFrame:(CGRect)r {
    UIGraphicsBeginImageContext(theView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    UIRectClip(r);
    [theView.layer renderInContext:context];
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [self clipImage:theImage];
}
- (UIImage *)clipImage:(UIImage *)tempImage {
    CGFloat width = tempImage.size.width;
    CGFloat height = tempImage.size.height;
    
    CGRect rect = CGRectMake(10, height / 2 - (width - 20) / 2, width - 20, width - 20);
    CGImageRef imageRef = tempImage.CGImage;
    CGImageRef imagePartRef = CGImageCreateWithImageInRect(imageRef, rect);
    UIImage *image = [UIImage imageWithCGImage:imagePartRef];
    CGImageRelease(imagePartRef);
    return image;
}
#pragma mark - < UIScrollViewDelegate >
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
//    CGFloat offsetX = (scrollView.frame.size.width > scrollView.contentSize.width) ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
//    CGFloat offsetY = (scrollView.frame.size.height > scrollView.contentSize.height) ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
//    self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}
#pragma mark - < 懒加载 >
- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64)];
        _bgView.layer.masksToBounds = YES;
        _bgView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2];
    }
    return _bgView;
}
@end
