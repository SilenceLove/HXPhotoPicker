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
#import "HXPhotoManager.h"
#import "UIImage+HXExtension.h"
#import "HXPhotoCustomNavigationBar.h"
@interface HXPhotoEditViewController ()<UIScrollViewDelegate>
@property (weak, nonatomic) UIScrollView *scrollView;
@property (weak, nonatomic) UIImageView *imageView;
@property (assign, nonatomic) CGPoint imageCenter;
@property (assign, nonatomic) PHImageRequestID requestID;
@property (strong, nonatomic) UIView *bgView;
@property (strong, nonatomic) HXPhotoEditView *editView;
@property (assign, nonatomic) CGFloat minimumZoomScale;
@property (strong, nonatomic) HXPhotoCustomNavigationBar *navBar;
@property (strong, nonatomic) UINavigationItem *navItem;
@end

@implementation HXPhotoEditViewController
#pragma mark - < 生命周期 >
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
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
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightBtn setTitle:[NSBundle hx_localizedStringForKey:@"确定"] forState:UIControlStateNormal];
    [rightBtn setTitleColor:self.photoManager.UIManager.navRightBtnNormalTitleColor forState:UIControlStateNormal];
    [rightBtn setBackgroundColor:self.photoManager.UIManager.navRightBtnNormalBgColor];
    [rightBtn addTarget:self action:@selector(didRightNavBtnClick) forControlEvents:UIControlEventTouchUpInside];
    rightBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    rightBtn.layer.cornerRadius = 3;
    rightBtn.frame = CGRectMake(0, 0, 60, 25);
    self.navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
    [self.view addSubview:self.bgView];
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.delegate = self;
    scrollView.bouncesZoom = YES;
    scrollView.multipleTouchEnabled = YES;
    scrollView.delegate = self;
    scrollView.scrollsToTop = NO;
    if (self.photoManager.singleSelecteClip) {
        scrollView.bounces = NO;
    }else {
        scrollView.bounces = YES;
    }
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
    
    if (self.photoManager.singleSelecteClip) {
        self.navItem.title = [NSBundle hx_localizedStringForKey:@"裁剪"];
        
        self.editView = [[HXPhotoEditView alloc] initWithFrame:self.bgView.frame];
        [self.view addSubview:self.editView];
    }else {
        self.navItem.title = [NSBundle hx_localizedStringForKey:@"预览"];
    }
    [self setupModel];
    [self.view addSubview:self.navBar];
    if (self.photoManager.UIManager.navBar) {
        self.photoManager.UIManager.navBar(self.navBar);
    }
    if (self.photoManager.UIManager.navItem) {
        self.photoManager.UIManager.navItem(self.navItem);
    }
    if (self.photoManager.UIManager.navRightBtn) {
        self.photoManager.UIManager.navRightBtn(rightBtn);
    }
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
    if (self.photoManager.singleSelecteClip) {
        
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
        
        self.imageView.frame = CGRectMake(0, 0, w, h);
        
        self.scrollView.minimumZoomScale = multiple;
        self.minimumZoomScale = multiple;
        self.scrollView.maximumZoomScale = multiple + self.scrollView.maximumZoomScale;
        
        if (self.model.type == HXPhotoModelMediaTypeCameraPhoto) {
            self.imageView.image = self.model.previewPhoto;
        }else {
            __weak typeof(self) weakSelf = self; 
            self.requestID = [HXPhotoTools fetchPhotoWithAsset:self.model.asset photoSize:CGSizeMake(width * 1.5, height * 1.5) completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                weakSelf.imageView.image = photo;
            }];
        }
        [self.scrollView setZoomScale:multiple animated:NO];
    }else {
        self.scrollView.frame = self.bgView.bounds;
        self.scrollView.contentSize = CGSizeMake(width, h);
        self.imageView.frame = CGRectMake(0, 0, w, h);
        self.imageView.center = CGPointMake(width / 2, height / 2);
        self.scrollView.minimumZoomScale = 1;
        self.minimumZoomScale = 1;
        [self.scrollView setZoomScale:1.0 animated:NO];
        if (self.model.type == HXPhotoModelMediaTypePhotoGif) {
            __weak typeof(self) weakSelf = self;
            [HXPhotoTools FetchPhotoDataForPHAsset:self.model.asset completion:^(NSData *imageData, NSDictionary *info) {
                UIImage *gifImage = [UIImage animatedGIFWithData:imageData];
                weakSelf.imageView.image = gifImage;
            }];
        }else {
            if (self.model.type == HXPhotoModelMediaTypeCameraPhoto) {
                self.imageView.image = self.model.thumbPhoto;
            }else {
                if (self.model.previewPhoto) {
                    self.imageView.image = self.model.previewPhoto;
                }else {
                    __weak typeof(self) weakSelf = self;
                    PHImageRequestID requestID;
                    if (imgHeight > imgWidth / 9 * 17) {
                        requestID = [HXPhotoTools fetchPhotoWithAsset:self.model.asset photoSize:CGSizeMake(width, height) completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                            weakSelf.imageView.image = photo;
                        }];
                    }else {
                        requestID = [HXPhotoTools fetchPhotoWithAsset:self.model.asset photoSize:CGSizeMake(self.model.endImageSize.width, self.model.endImageSize.height) completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                            weakSelf.imageView.image = photo;
                        }];
                    }
                    if (self.requestID != requestID) {
                        [[PHImageManager defaultManager] cancelImageRequest:self.requestID];
                    }
                    self.requestID = requestID;
                }
            }
        }
    }
}
#pragma mark - < 点击事件 >
- (void)dismissClick {
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)didRightNavBtnClick {
    if (self.photoManager.singleSelecteClip) {
        [self clipImage];
    }else {
        self.model.thumbPhoto = self.imageView.image;
        self.model.previewPhoto = self.imageView.image;
        if ([self.delegate respondsToSelector:@selector(editViewControllerDidNextClick:)]) {
            [self.delegate editViewControllerDidNextClick:self.model];
        }
    }
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
    if (!self.photoManager.singleSelecteClip) {
        CGFloat offsetX = (scrollView.frame.size.width > scrollView.contentSize.width) ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
        CGFloat offsetY = (scrollView.frame.size.height > scrollView.contentSize.height) ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
        self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
    }
//    CGFloat offsetX = (scrollView.frame.size.width > scrollView.contentSize.width) ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
//    CGFloat offsetY = (scrollView.frame.size.height > scrollView.contentSize.height) ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
//    self.imageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}
#pragma mark - < 懒加载 >
- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, kNavigationBarHeight, self.view.frame.size.width, self.view.frame.size.height - kNavigationBarHeight)];
        _bgView.layer.masksToBounds = YES;
        _bgView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2];
    }
    return _bgView;
}

- (HXPhotoCustomNavigationBar *)navBar {
    if (!_navBar) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _navBar = [[HXPhotoCustomNavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, kNavigationBarHeight)];
        [self.view addSubview:_navBar];
        [_navBar pushNavigationItem:self.navItem animated:NO];
        _navBar.tintColor = self.photoManager.UIManager.navLeftBtnTitleColor;
        _navBar.titleTextAttributes = @{NSForegroundColorAttributeName : self.photoManager.UIManager.navTitleColor};
        if (self.photoManager.UIManager.navBackgroundImageName) {
            [_navBar setBackgroundImage:[HXPhotoTools hx_imageNamed:self.photoManager.UIManager.navBackgroundImageName] forBarMetrics:UIBarMetricsDefault];
        }else if (self.photoManager.UIManager.navBackgroundColor) {
            [_navBar setBackgroundColor:self.photoManager.UIManager.navBackgroundColor];
        } 
    }
    return _navBar;
}
- (UINavigationItem *)navItem {
    if (!_navItem) {
        _navItem = [[UINavigationItem alloc] init];
        
        _navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissClick)]; 
    }
    return _navItem;
}
@end
