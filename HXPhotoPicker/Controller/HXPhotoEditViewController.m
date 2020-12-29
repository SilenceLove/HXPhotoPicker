//
//  HXPhotoEditViewController.m
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/27.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "HXPhotoEditViewController.h"
#import "UIImage+HXExtension.h"
#import "UIButton+HXExtension.h"
#import "HXPhotoEditTransition.h"

@interface HXPhotoEditViewController ()<HXPhotoEditBottomViewDelegate>
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIImageView *tempImageView;
@property (strong, nonatomic) HXPhotoEditBottomView *bottomView;
@property (assign, nonatomic) BOOL orientationDidChange;
@property (assign, nonatomic) PHContentEditingInputRequestID requestId;
@property (strong, nonatomic) HXEditGridLayer *gridLayer;
@property (strong, nonatomic) HXEditCornerView *leftTopView;
@property (strong, nonatomic) HXEditCornerView *rightTopView;
@property (strong, nonatomic) HXEditCornerView *leftBottomView;
@property (strong, nonatomic) HXEditCornerView *rightBottomView;
@property (assign, nonatomic) CGRect clippingRect;
@property (strong, nonatomic) HXEditRatio *clippingRatio;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) CGFloat imageWidth;
@property (assign, nonatomic) CGFloat imageHeight;
@property (strong, nonatomic) UIImage *originalImage;
@property (strong, nonatomic) UIPanGestureRecognizer *imagePanGesture;
@property (assign, nonatomic) BOOL isSelectRatio;
@property (assign, nonatomic) UIImageOrientation currentImageOrientaion;
@property (strong, nonatomic) HXPhotoModel *afterModel;
@end

@implementation HXPhotoEditViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return [HXPhotoEditTransition transitionWithType:HXPhotoEditTransitionTypePresent model:self.model];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return [HXPhotoEditTransition transitionWithType:HXPhotoEditTransitionTypeDismiss model:self.isCancel ? self.model : self.afterModel];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageWidth = self.model.imageSize.width;
    self.imageHeight = self.model.imageSize.height;
    [self setupUI];
    if (!self.manager.configuration.movableCropBox) {
        self.bottomView.enabled = NO;
    }else {
        if (CGPointEqualToPoint(self.manager.configuration.movableCropBoxCustomRatio, CGPointZero)) {
            self.bottomView.enabled = NO;
        }
    }
    [self changeSubviewFrame:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationWillChanged:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopTimer];
    [self.model.asset cancelContentEditingInputRequest:self.requestId];
    [self.navigationController setNavigationBarHidden:NO];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.orientationDidChange) {
        self.orientationDidChange = NO;
        [self changeSubviewFrame:NO];
    }
}
- (void)deviceOrientationChanged:(NSNotification *)notify {
    self.orientationDidChange = YES;
}
- (void)deviceOrientationWillChanged:(NSNotification *)notify {
    [self stopTimer];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    
    [self.model.asset cancelContentEditingInputRequest:self.requestId];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
#pragma clang diagnostic pop
}
- (CGRect)getImageFrame {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat bottomMargin = hxBottomMargin;
    CGFloat leftRightMargin = 40;
    CGFloat imageY = HX_IS_IPhoneX_All ? 60 : 30;
    if (HX_IS_IPhoneX_All && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        bottomMargin = 21;
        leftRightMargin = 80;
        imageY = 20;
    }
    CGFloat width = self.view.hx_w - leftRightMargin;
    CGFloat height = self.view.frame.size.height - 100 - imageY - bottomMargin;
    CGFloat imgWidth = self.imageWidth;
    CGFloat imgHeight = self.imageHeight;
    CGFloat w;
    CGFloat h;
    
    if (imgWidth > width) {
        imgHeight = width / imgWidth * imgHeight;
    }
    if (imgHeight > height) {
        w = height / self.imageHeight * imgWidth;
        h = height;
    }else {
        if (imgWidth > width) {
            w = width;
        }else {
            w = imgWidth;
        }
        h = imgHeight;
    }
    
    return CGRectMake((width - w) / 2 + leftRightMargin / 2, imageY + (height - h) / 2, w, h);
}
- (void)changeSubviewFrame:(BOOL)animated {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat bottomMargin = hxBottomMargin;
    if (HX_IS_IPhoneX_All && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        bottomMargin = 21;
    }
    CGRect imageFrame = [self getImageFrame];
    if (animated) {
        self.gridLayer.frame = CGRectMake(0, 0, imageFrame.size.width, imageFrame.size.height);
        [UIView animateWithDuration:0.25 animations:^{
            self.imageView.frame = imageFrame;
        } completion:^(BOOL finished) {
            [self clippingRatioDidChange:animated];
        }];
    }else {
        self.imageView.frame = imageFrame;
//        self.imageView.center = CGPointMake(self.view.hx_w / 2, imageY + height / 2);
        self.gridLayer.frame = self.imageView.bounds;
        [self clippingRatioDidChange:animated];
    }
    self.bottomView.frame = CGRectMake(0, self.view.hx_h - 100 - bottomMargin, self.view.hx_w, 100 + bottomMargin);
}
- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.bottomView];
    [self.view addSubview:self.leftTopView];
    [self.view addSubview:self.leftBottomView];
    [self.view addSubview:self.rightTopView];
    [self.view addSubview:self.rightBottomView];
    if (self.isInside) {
        self.bottomView.alpha = 0;
        self.gridLayer.alpha = 0;
    }
    CATransition *transition = [CATransition animation];
    transition.duration = 0.2f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.imageView.layer addAnimation:transition forKey:nil];
    self.imageView.image = self.model.tempImage;
    [self setupModel];
}
- (void)completeTransition:(UIImage *)image {
    self.transitionCompletion = YES;
    self.imageView.alpha = 1;
    if (self.imageRequestComplete) {
        [self fixationEdit];
    }else {
        self.imageView.image = image;
        [self.view hx_showLoadingHUDText:nil];
    }
}
- (void)showBottomView {
    self.bottomView.alpha = 1;
}
- (void)hideImageView { 
    self.imageView.hidden = YES;
    self.leftTopView.hidden = YES;
    self.leftBottomView.hidden = YES;
    self.rightTopView.hidden = YES;
    self.rightBottomView.hidden = YES;
}
- (UIImage *)getCurrentImage {
    return self.imageView.image;
}
- (void)setupModel {
    if (self.model.asset) {
        self.bottomView.userInteractionEnabled = NO;
        if (!self.isInside) {
            [self.view hx_showLoadingHUDText:nil];
        }
        [self requestImageData];
    }else {
        self.imageView.image = self.model.thumbPhoto;
        self.originalImage = self.model.thumbPhoto;
        [self loadImageCompletion];
    }
}
- (void)requestImageData {
    HXWeakSelf
    self.requestId = [self.model requestImageDataStartRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel * _Nullable model) {
        weakSelf.requestId = iCloudRequestId;
    } progressHandler:nil success:^(NSData * _Nullable imageData, UIImageOrientation orientation, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
        weakSelf.bottomView.userInteractionEnabled = YES;
        UIImage *image = [UIImage imageWithData:imageData];
        if (image.imageOrientation != UIImageOrientationUp) {
            image = [image hx_normalizedImage];
        }
        weakSelf.originalImage = image;
        weakSelf.imageView.image = image;
        [weakSelf.view hx_handleLoading];
        [weakSelf loadImageCompletion];
    } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
        [weakSelf requestImaegURL];
    }];
}
- (void)requestImaegURL {
    HXWeakSelf
    self.requestId = [self.model requestImageURLStartRequestICloud:^(PHContentEditingInputRequestID iCloudRequestId, HXPhotoModel *model) {
        weakSelf.requestId = iCloudRequestId;
    } progressHandler:nil success:^(NSURL *imageURL, HXPhotoModel *model, NSDictionary *info) {
        weakSelf.bottomView.userInteractionEnabled = YES;
        NSData *imageData = [NSData dataWithContentsOfFile:imageURL.relativePath];
        UIImage *image = [UIImage imageWithData:imageData];
        if (image.imageOrientation != UIImageOrientationUp) {
            image = [image hx_normalizedImage];
        }
        weakSelf.originalImage = image;
        weakSelf.imageView.image = image;
        [weakSelf.view hx_handleLoading];
        [weakSelf loadImageCompletion];
    } failed:^(NSDictionary *info, HXPhotoModel *model) {
        [weakSelf requenstImage];
    }];
}
- (void)requenstImage {
    HXWeakSelf
    self.requestId = [self.model requestPreviewImageWithSize:PHImageManagerMaximumSize startRequestICloud:^(PHImageRequestID iCloudRequestId, HXPhotoModel * _Nullable model) {
        weakSelf.requestId = iCloudRequestId;
    } progressHandler:nil success:^(UIImage * _Nullable image, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info) {
        weakSelf.bottomView.userInteractionEnabled = YES;
        if (image.imageOrientation != UIImageOrientationUp) {
            image = [image hx_normalizedImage];
        }
        weakSelf.originalImage = image;
        weakSelf.imageView.image = image;
        [weakSelf.view hx_handleLoading];
        [weakSelf loadImageCompletion];
    } failed:^(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model) {
        [weakSelf.view hx_handleLoading];
        weakSelf.bottomView.userInteractionEnabled = YES;
        [weakSelf loadImageCompletion];
    }];
}
- (void)loadImageCompletion {
    self.imageRequestComplete = YES;
    if (!self.isInside) {
        [self fixationEdit];
    }else {
        if (self.transitionCompletion) {
            [self fixationEdit];
        }
    }
}
- (void)fixationEdit {
    if (self.manager.configuration.movableCropBox) {
        if (!self.manager.configuration.movableCropBoxEditSize) {
            self.leftTopView.hidden = YES;
            self.leftBottomView.hidden = YES;
            self.rightTopView.hidden = YES;
            self.rightBottomView.hidden = YES;
        }
        HXEditRatio *ratio = [[HXEditRatio alloc] initWithValue1:self.manager.configuration.movableCropBoxCustomRatio.x value2:self.manager.configuration.movableCropBoxCustomRatio.y];
        [self bottomViewDidSelectRatioClick:ratio];
        [UIView animateWithDuration:0.25 animations:^{
            self.imageView.alpha = 1;
            self.gridLayer.alpha = 1;
            if (self.manager.configuration.movableCropBoxEditSize) {
                self.leftTopView.alpha = 1;
                self.leftBottomView.alpha = 1;
                self.rightTopView.alpha = 1;
                self.rightBottomView.alpha = 1;
            }
        }];
    }else {
        [UIView animateWithDuration:0.25 animations:^{
            self.imageView.alpha = 1;
            self.gridLayer.alpha = 1;
            self.leftTopView.alpha = 1;
            self.leftBottomView.alpha = 1;
            self.rightTopView.alpha = 1;
            self.rightBottomView.alpha = 1;
        }];
    }
}
- (void)startTimer {
    if (!self.manager.configuration.movableCropBox) {
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(changeClipImageView) userInfo:nil repeats:NO];
        }
    }else {
        self.bottomView.enabled = YES;
    }
}
- (void)stopTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}
- (void)changeClipImageView {
    if (CGSizeEqualToSize(self.clippingRect.size, self.imageView.hx_size)) {
        [self stopTimer];
        return;
    }
    UIImage *image = [self clipImage];
    self.imageWidth = image.size.width;
    self.imageHeight = image.size.height;
    CGRect imageRect = [self getImageFrame];
    
    
    self.tempImageView = [[UIImageView alloc] initWithImage:image];
    CGFloat imgW = self.rightTopView.center.x - self.leftTopView.center.x;
    CGFloat imgH = self.leftBottomView.center.y - self.leftTopView.center.y;
    self.tempImageView.frame = CGRectMake(self.leftTopView.center.x, self.leftTopView.center.y, imgW, imgH);
    [self.view insertSubview:self.tempImageView aboveSubview:self.imageView];
    
    [UIView animateWithDuration:0.2f animations:^{
        self.leftTopView.alpha = 0;
        self.leftBottomView.alpha = 0;
        self.rightTopView.alpha = 0;
        self.rightBottomView.alpha = 0;
        self.imageView.alpha = 0.f;
        self.gridLayer.alpha = 0.f;
    } completion:^(BOOL finished) {
        self.gridLayer.frame = CGRectMake(0, 0, imageRect.size.width, imageRect.size.height);
        
        [UIView animateWithDuration:0.3f animations:^{
            self.tempImageView.frame = imageRect;
        } completion:^(BOOL finished) {
            self.imageView.image = image;
            self.imageView.frame = imageRect;
            [self clippingRatioDidChange:YES];
        }];
    }];
    [self stopTimer];
    self.bottomView.enabled = YES;
}
- (UIImage *)clipImage {
    CGFloat zoomScale = self.imageView.bounds.size.width / self.imageView.image.size.width;
    CGFloat widthScale = self.imageView.image.size.width / self.imageView.hx_w;
    CGFloat heightScale = self.imageView.image.size.height / self.imageView.hx_h;
    
    CGRect rct = self.clippingRect;
    rct.size.width  *= widthScale;
    rct.size.height *= heightScale;
    rct.origin.x    /= zoomScale;
    rct.origin.y    /= zoomScale;
    
    CGPoint origin = CGPointMake(-rct.origin.x, -rct.origin.y);
    UIImage *img = nil;
    
    UIGraphicsBeginImageContextWithOptions(rct.size, NO, self.imageView.image.scale);
    [self.imageView.image drawAtPoint:origin];
    img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return img;
}
- (void)panGridView:(UIPanGestureRecognizer*)sender {
    static BOOL dragging = NO;
    static CGRect initialRect;
    
    if (sender.state==UIGestureRecognizerStateBegan) {
        CGPoint point = [sender locationInView:self.imageView];
        dragging = CGRectContainsPoint(self.clippingRect, point);
        initialRect = self.clippingRect;
    } else if(dragging) {
        CGPoint point = [sender translationInView:self.imageView];
        CGFloat left  = MIN(MAX(initialRect.origin.x + point.x, 0), self.imageView.frame.size.width-initialRect.size.width);
        CGFloat top   = MIN(MAX(initialRect.origin.y + point.y, 0), self.imageView.frame.size.height-initialRect.size.height);
        
        CGRect rct = self.clippingRect;
        rct.origin.x = left;
        rct.origin.y = top;
        self.clippingRect = rct;
    }
    
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        [self startTimer];
    }else {
        [self stopTimer];
    }
}
- (void)setClippingRect:(CGRect)clippingRect {
    _clippingRect = clippingRect;
    
    self.leftTopView.center = [self.view convertPoint:CGPointMake(_clippingRect.origin.x, _clippingRect.origin.y) fromView:_imageView];
    self.leftBottomView.center = [self.view convertPoint:CGPointMake(_clippingRect.origin.x, _clippingRect.origin.y+_clippingRect.size.height) fromView:_imageView];
    self.rightTopView.center = [self.view convertPoint:CGPointMake(_clippingRect.origin.x+_clippingRect.size.width, _clippingRect.origin.y) fromView:_imageView];
    self.rightBottomView.center = [self.view convertPoint:CGPointMake(_clippingRect.origin.x+_clippingRect.size.width, _clippingRect.origin.y+_clippingRect.size.height) fromView:_imageView];
    
    self.gridLayer.clippingRect = clippingRect;
    [self.gridLayer setNeedsDisplay];
}
- (void)setClippingRatio:(HXEditRatio *)clippingRatio {
    if(clippingRatio != self.clippingRatio){
        _clippingRatio = clippingRatio;
        [self clippingRatioDidChange:YES];
    }
}
- (void)clippingRatioDidChange:(BOOL)animated {
    CGRect rect = self.imageView.bounds;
    if (self.clippingRatio && self.clippingRatio.ratio != 0) {
        if (self.clippingRatio.isLandscape) {
            CGFloat W = rect.size.height * self.clippingRatio.ratio;
            if (W <= rect.size.width) {
                rect.size.width = W;
            }else {
                CGFloat scale = rect.size.width / W;
                rect.size.height *= scale;
            }
        }else {
            CGFloat H = rect.size.width * self.clippingRatio.ratio;
            if (H <= rect.size.height) {
                rect.size.height = H;
            } else {
                CGFloat scale = rect.size.height / H;
                rect.size.width *= scale;
            }
        }
        
        rect.origin.x = (self.imageView.bounds.size.width - rect.size.width) / 2;
        rect.origin.y = (self.imageView.bounds.size.height - rect.size.height) / 2;
    }
    [self setClippingRect:rect animated:animated];
}

- (void)setClippingRect:(CGRect)clippingRect animated:(BOOL)animated {
    if (animated) {
        if (self.isSelectRatio) {
            [UIView animateWithDuration:0.1 animations:^{
                self.clippingRect = clippingRect;
            } completion:^(BOOL finished) {
                [self clippingRectComplete:clippingRect];
            }];
        }else {
            self.clippingRect = clippingRect;
            [self clippingRectComplete:clippingRect];
        }
    } else {
        self.clippingRect = clippingRect;
    }
}
- (void)clippingRectComplete:(CGRect)clippingRect {
    
    self.imageView.alpha = 1;
    
    if (self.isSelectRatio) {
        if (CGPointEqualToPoint(self.manager.configuration.movableCropBoxCustomRatio, CGPointMake(0, 0))) {
            _clippingRatio = nil;
        }
        if (!self.manager.configuration.movableCropBox) {
            [self changeClipImageView];
        }
        self.isSelectRatio = NO;
        return;
    }
    
    [self.tempImageView removeFromSuperview];
    self.tempImageView = nil;
    [UIView animateWithDuration:0.2 animations:^{
        self.leftTopView.alpha = 1;
        self.leftBottomView.alpha = 1;
        self.rightTopView.alpha = 1;
        self.rightBottomView.alpha = 1;
        self.gridLayer.alpha = 1;
    }];
}
- (void)panCircleView:(UIPanGestureRecognizer*)sender {
    CGPoint point = [sender locationInView:self.imageView];
    CGPoint dp = [sender translationInView:self.imageView];
    
    CGRect rct = self.clippingRect;
    if (self.imageView.hx_w <= 200 &&
        self.imageView.hx_h <= 200) {
        [self.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"图片尺寸过小!"]];
        return;
    }
    
    const CGFloat W = self.imageView.frame.size.width;
    const CGFloat H = self.imageView.frame.size.height;
    CGFloat minX = 0;
    CGFloat minY = 0;
    CGFloat maxX = W;
    CGFloat maxY = H;
    
    CGFloat ratio = (sender.view.tag == 1 || sender.view.tag==2) ? -self.clippingRatio.ratio : self.clippingRatio.ratio;
    
    switch (sender.view.tag) {
        case 0: // upper left
        {
            maxX = MAX((rct.origin.x + rct.size.width)  - 0.1 * W, 0.1 * W);
            maxY = MAX((rct.origin.y + rct.size.height) - 0.1 * H, 0.1 * H);
            
            if (ratio!=0) {
                CGFloat y0 = rct.origin.y - ratio * rct.origin.x;
                CGFloat x0 = -y0 / ratio;
                minX = MAX(x0, 0);
                minY = MAX(y0, 0);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x * ratio + dp.y > 0){
                    point.x = (point.y - y0) / ratio;
                } else{
                    point.y = point.x * ratio + y0;
                }
            } else {
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = rct.size.width  - (point.x - rct.origin.x);
            rct.size.height = rct.size.height - (point.y - rct.origin.y);
            rct.origin.x = point.x;
            rct.origin.y = point.y;
            break;
        }
        case 1: // lower left
        {
            maxX = MAX((rct.origin.x + rct.size.width)  - 0.1 * W, 0.1 * W);
            minY = MAX(rct.origin.y + 0.1 * H, 0.1 * H);
            
            if (ratio!=0) {
                CGFloat y0 = (rct.origin.y + rct.size.height) - ratio* rct.origin.x ;
                CGFloat xh = (H - y0) / ratio;
                minX = MAX(xh, 0);
                maxY = MIN(y0, H);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y < 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            } else {
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = rct.size.width  - (point.x - rct.origin.x);
            rct.size.height = point.y - rct.origin.y;
            rct.origin.x = point.x;
            break;
        }
        case 2: // upper right
        {
            minX = MAX(rct.origin.x + 0.1 * W, 0.1 * W);
            maxY = MAX((rct.origin.y + rct.size.height) - 0.1 * H, 0.1 * H);
            
            if (ratio!=0) {
                CGFloat y0 = rct.origin.y - ratio * (rct.origin.x + rct.size.width);
                CGFloat yw = ratio * W + y0;
                CGFloat x0 = -y0 / ratio;
                maxX = MIN(x0, W);
                minY = MAX(yw, 0);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y > 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            } else {
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = point.x - rct.origin.x;
            rct.size.height = rct.size.height - (point.y - rct.origin.y);
            rct.origin.y = point.y;
            break;
        }
        case 3: // lower right
        {
            minX = MAX(rct.origin.x + 0.1 * W, 0.1 * W);
            minY = MAX(rct.origin.y + 0.1 * H, 0.1 * H);
            
            if (ratio!=0) {
                CGFloat y0 = (rct.origin.y + rct.size.height) - ratio * (rct.origin.x + rct.size.width);
                CGFloat yw = ratio * W + y0;
                CGFloat xh = (H - y0) / ratio;
                maxX = MIN(xh, W);
                maxY = MIN(yw, H);
                
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
                
                if(-dp.x*ratio + dp.y < 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
            } else {
                point.x = MAX(minX, MIN(point.x, maxX));
                point.y = MAX(minY, MIN(point.y, maxY));
            }
            
            rct.size.width  = point.x - rct.origin.x;
            rct.size.height = point.y - rct.origin.y;
            break;
        }
        default:
            break;
    }
    self.clippingRect = rct;
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        [self startTimer];
    }else {
        [self stopTimer];
    }
}
#pragma mark - < HXPhotoEditBottomViewDelegate >
- (void)bottomViewDidCancelClick {
    [self stopTimer];
    self.isCancel = YES;
    if ([self.delegate respondsToSelector:@selector(photoEditViewControllerDidCancel:)]) {
        [self.delegate photoEditViewControllerDidCancel:self];
    }
    if (self.cancelBlock) {
        self.cancelBlock(self);
    }
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:NO];
    }else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
- (void)bottomViewDidRestoreClick {
    if (self.manager.configuration.movableCropBox) {
        if (CGPointEqualToPoint(self.manager.configuration.movableCropBoxCustomRatio, CGPointZero)) {
            self.clippingRatio = [[HXEditRatio alloc] initWithValue1:0 value2:0];
        }
    }else {
        if (CGSizeEqualToSize(self.clippingRect.size, self.originalImage.size)) {
            [self stopTimer];
            return;
        }
        if (!self.originalImage || self.imageView.image == self.originalImage) {
            [self stopTimer];
            return;
        }
    }
    [self stopTimer];
    self.clippingRatio = nil;
    self.bottomView.enabled = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.gridLayer.alpha = 0;
        self.leftTopView.alpha = 0;
        self.leftBottomView.alpha = 0;
        self.rightTopView.alpha = 0;
        self.rightBottomView.alpha = 0;
    } completion:^(BOOL finished) {
        self.imageView.image = self.originalImage;
        self.imageWidth = self.model.imageSize.width;
        self.imageHeight = self.model.imageSize.height;
        CGRect imageRect = [self getImageFrame];
        self.gridLayer.frame = CGRectMake(0, 0, imageRect.size.width, imageRect.size.height);
        
        [UIView animateWithDuration:0.3 animations:^{
            self.imageView.frame = imageRect;
        } completion:^(BOOL finished) {
            [self clippingRatioDidChange:YES];
        }];
    }];
}
- (void)bottomViewDidRotateClick {
    [self stopTimer];
    if (!self.manager.configuration.movableCropBox) {
        self.clippingRatio = nil;
    }
    self.bottomView.enabled = YES;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.gridLayer.alpha = 0;
        self.leftTopView.alpha = 0;
        self.leftBottomView.alpha = 0;
        self.rightTopView.alpha = 0;
        self.rightBottomView.alpha = 0;
    } completion:^(BOOL finished) {
        UIImage *image = [self.imageView.image hx_rotationImage:UIImageOrientationLeft];
        self.imageWidth = image.size.width;
        self.imageHeight = image.size.height;
        CGRect imageRect = [self getImageFrame];
        self.gridLayer.frame = CGRectMake(0, 0, imageRect.size.width, imageRect.size.height);
        
        [UIView animateWithDuration:0.2 animations:^{
            self.imageView.transform = CGAffineTransformMakeRotation(-M_PI_2);
            self.imageView.frame = imageRect;
        } completion:^(BOOL finished) {
            self.imageView.transform = CGAffineTransformIdentity;
            self.imageView.image = image;
            self.imageView.frame = imageRect;
            [self clippingRatioDidChange:YES];
        }];
    }];
}
- (void)bottomViewDidClipClick {
    [self stopTimer];
    UIImage *image;
    if (self.manager.configuration.movableCropBox) {
        image = [self clipImage];
//        [self changeClipImageView];
    }else {
        image = self.imageView.image;
    }
    if (self.manager.configuration.editAssetSaveSystemAblum) {
        HXWeakSelf
        [self.view hx_showLoadingHUDText:nil];
        [HXPhotoTools savePhotoToCustomAlbumWithName:self.manager.configuration.customAlbumName photo:image location:self.model.location complete:^(HXPhotoModel * _Nullable model, BOOL success) {
            [weakSelf.view hx_handleLoading:YES];
            if (model) {
                [weakSelf editPhotoCompletionWithModel:model];
            }else {
                [weakSelf.view hx_showImageHUDText:[NSBundle hx_localizedStringForKey:@"处理失败，请重试"]];
            }
        }];
    }else {
        HXPhotoModel *model = [HXPhotoModel photoModelWithImage:image];
        [self editPhotoCompletionWithModel:model];
    }
}
- (void)editPhotoCompletionWithModel:(HXPhotoModel *)model {
    if (self.outside) {
        if (self.navigationController.viewControllers.count > 1) {
            if ([self.delegate respondsToSelector:@selector(photoEditViewControllerDidClipClick:beforeModel:afterModel:)]) {
                [self.delegate photoEditViewControllerDidClipClick:self beforeModel:self.model afterModel:model];
            }
            if (self.doneBlock) {
                self.doneBlock(self.model, model, self);
            }
            [self.navigationController popViewControllerAnimated:NO];
        }else {
            [self dismissViewControllerAnimated:NO completion:^{
                if ([self.delegate respondsToSelector:@selector(photoEditViewControllerDidClipClick:beforeModel:afterModel:)]) {
                    [self.delegate photoEditViewControllerDidClipClick:self beforeModel:self.model afterModel:model];
                }
                if (self.doneBlock) {
                    self.doneBlock(self.model, model, self);
                }
            }];
        }
        return;
    }
    self.isCancel = NO;
    self.afterModel = model;
    if (self.manager.configuration.singleSelected &&
        self.manager.configuration.singleJumpEdit) {
        if (self.navigationController.viewControllers.count > 1) {
            if ([self.delegate respondsToSelector:@selector(photoEditViewControllerDidClipClick:beforeModel:afterModel:)]) {
                [self.delegate photoEditViewControllerDidClipClick:self beforeModel:self.model afterModel:model];
            }
            if (self.doneBlock) {
                self.doneBlock(self.model, model, self);
            }
            [self.navigationController popViewControllerAnimated:NO];
        }else {
            [self dismissViewControllerAnimated:NO completion:^{
                if ([self.delegate respondsToSelector:@selector(photoEditViewControllerDidClipClick:beforeModel:afterModel:)]) {
                    [self.delegate photoEditViewControllerDidClipClick:self beforeModel:self.model afterModel:model];
                }
                if (self.doneBlock) {
                    self.doneBlock(self.model, model, self);
                }
            }];
        }
    }else {
        if ([self.delegate respondsToSelector:@selector(photoEditViewControllerDidClipClick:beforeModel:afterModel:)]) {
            [self.delegate photoEditViewControllerDidClipClick:self beforeModel:self.model afterModel:model];
        }
        if (self.doneBlock) {
            self.doneBlock(self.model, model, self);
        }
        if (self.navigationController.viewControllers.count > 1) {
            [self.navigationController popViewControllerAnimated:NO];
        }else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}
- (void)bottomViewDidSelectRatioClick:(HXEditRatio *)ratio {
    [self stopTimer];
    self.isSelectRatio = YES;
    if(ratio.ratio == 0){
        [self bottomViewDidRestoreClick];
    } else {
        self.clippingRatio = ratio;
        if (self.manager.configuration.movableCropBox) {
            if (CGPointEqualToPoint(self.manager.configuration.movableCropBoxCustomRatio, CGPointZero)) {
                self.bottomView.enabled = YES;
            }
        }
    }
}
#pragma mark - < 懒加载 >
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.alpha = 0;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [_imageView addSubview:self.gridLayer];
        self.imagePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGridView:)];
        _imageView.userInteractionEnabled = YES;
        [_imageView addGestureRecognizer:self.imagePanGesture];
    }
    return _imageView;
}
- (HXPhotoEditBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[HXPhotoEditBottomView alloc] initWithManager:self.manager];
        _bottomView.delegate = self;
    }
    return _bottomView;
}
- (HXEditGridLayer *)gridLayer {
    if (!_gridLayer) {
        _gridLayer = [[HXEditGridLayer alloc] init];
        _gridLayer.bgColor   = [[UIColor blackColor] colorWithAlphaComponent:.5];
        _gridLayer.gridColor = [UIColor whiteColor];
        _gridLayer.alpha = 0.f;
    }
    return _gridLayer;
}
- (HXEditCornerView *)leftTopView {
    if (!_leftTopView) {
        _leftTopView = [self editCornerViewWithTag:0];
    }
    return _leftTopView;
}
- (HXEditCornerView *)leftBottomView {
    if (!_leftBottomView) {
        _leftBottomView = [self editCornerViewWithTag:1];
    }
    return _leftBottomView;
}
- (HXEditCornerView *)rightTopView {
    if (!_rightTopView) {
        _rightTopView = [self editCornerViewWithTag:2];
    }
    return _rightTopView;
}
- (HXEditCornerView *)rightBottomView {
    if (!_rightBottomView) {
        _rightBottomView = [self editCornerViewWithTag:3]; 
    }
    return _rightBottomView;
}
- (HXEditCornerView *)editCornerViewWithTag:(NSInteger)tag {
    HXEditCornerView *view = [[HXEditCornerView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    view.backgroundColor = [UIColor clearColor];
    view.bgColor = [UIColor whiteColor];
    view.tag = tag;
    view.alpha = 0;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panCircleView:)];
    [view addGestureRecognizer:panGesture];
    [panGesture requireGestureRecognizerToFail:self.imagePanGesture];
    return view;
}
@end

@interface HXPhotoEditBottomView ()
@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIView *bottomView;
@property (strong, nonatomic) UIButton *restoreBtn;
@property (strong, nonatomic) UIButton *rotateBtn;
@property (strong, nonatomic) UIButton *cancelBtn;
@property (strong, nonatomic) UIButton *clipBtn;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) UIButton *selectRatioBtn;
@end

@implementation HXPhotoEditBottomView
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            
            UIColor *color = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : self.manager.configuration.themeColor;
            if ([color isEqual:[UIColor blackColor]]) {
                color = [UIColor whiteColor];
            }
            [self.clipBtn setTitleColor:color forState:UIControlStateNormal];
            [self.clipBtn setTitleColor:[color colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
        }
    }
#endif
}
- (instancetype)initWithManager:(HXPhotoManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    if (!self.manager.configuration.movableCropBox) {
        [self addSubview:self.topView];
    }else {
        if (CGPointEqualToPoint(self.manager.configuration.movableCropBoxCustomRatio, CGPointZero)) {
            [self addSubview:self.topView];
        }
    }
    [self addSubview:self.bottomView];
}
- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    self.restoreBtn.enabled = enabled;
    if (!self.manager.configuration.singleSelected) {
        self.clipBtn.enabled = enabled;
    }
}
- (void)didRestoreBtnClick {
    if ([self.delegate respondsToSelector:@selector(bottomViewDidRestoreClick)]) {
        [self.delegate bottomViewDidRestoreClick];
    }
}
- (void)didCancelBtnClick {
    if ([self.delegate respondsToSelector:@selector(bottomViewDidCancelClick)]) {
        [self.delegate bottomViewDidCancelClick];
    }
}
- (void)didRotateBtnClick {
    if ([self.delegate respondsToSelector:@selector(bottomViewDidRotateClick)]) {
        [self.delegate bottomViewDidRotateClick];
    }
}
- (void)didClipBtnClick {
    if ([self.delegate respondsToSelector:@selector(bottomViewDidClipClick)]) {
        [self.delegate bottomViewDidClipClick];
    }
}
- (void)didSelectRatioBtnClick {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIPopoverPresentationController *pop = [alertController popoverPresentationController];
        pop.permittedArrowDirections = UIPopoverArrowDirectionAny;
        pop.sourceView = self;
        pop.sourceRect = self.bounds;
    }
    NSArray *ratios = self.manager.configuration.photoEditCustomRatios;
    for (NSDictionary *ratioDict in ratios) {
        NSString *key = ratioDict.allKeys.firstObject;
        CGPoint ratio = CGPointFromString([ratioDict objectForKey:key]);
        [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:key] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self setupRatioWithValue1:ratio.x value2:ratio.y];
        }]];
    }
    [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIAlertActionStyleCancel handler:nil]];
    
    [self.hx_viewController presentViewController:alertController animated:YES completion:nil];
}
- (void)setupRatioWithValue1:(CGFloat)value1 value2:(CGFloat)value2 {
    HXEditRatio *ratio = [[HXEditRatio alloc] initWithValue1:value1 value2:value2];
    
    if ([self.delegate respondsToSelector:@selector(bottomViewDidSelectRatioClick:)]) {
        [self.delegate bottomViewDidSelectRatioClick:ratio];
    }
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.topView.frame = CGRectMake(0, 0, self.hx_w, 60);
    self.bottomView.frame = CGRectMake(0, 60, self.hx_w, 40);
    self.restoreBtn.hx_x = self.hx_w / 2 - 20 - self.restoreBtn.hx_w;
    self.restoreBtn.center = CGPointMake(self.restoreBtn.center.x, 30);
    
    self.rotateBtn.hx_x = self.hx_w / 2 + 20;
    self.rotateBtn.center = CGPointMake(self.rotateBtn.center.x, 30);
    
    self.cancelBtn.frame = CGRectMake(20, 0, 0 + 20, 40);
    self.cancelBtn.hx_w = self.cancelBtn.titleLabel.hx_getTextWidth + 20;
    
    self.clipBtn.hx_h = 40;
    self.clipBtn.hx_w = self.clipBtn.titleLabel.hx_getTextWidth;
    self.clipBtn.hx_x = self.hx_w - 20 - self.clipBtn.hx_w;
    
    self.selectRatioBtn.center = CGPointMake(self.hx_w / 2, 20);
}
- (UIView *)topView {
    if (!_topView) {
        _topView = [[UIView alloc] init];
        [_topView addSubview:self.restoreBtn];
        [_topView addSubview:self.rotateBtn];
    }
    return _topView;
}
- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        [_bottomView addSubview:self.cancelBtn];
        [_bottomView addSubview:self.clipBtn];
        if (!self.manager.configuration.movableCropBox) {
            [_bottomView addSubview:self.selectRatioBtn];
        }else {
            if (CGPointEqualToPoint(self.manager.configuration.movableCropBoxCustomRatio, CGPointZero)) {
                [_bottomView addSubview:self.selectRatioBtn];
            }
        }
    }
    return _bottomView;
}
- (UIButton *)selectRatioBtn {
    if (!_selectRatioBtn) {
        _selectRatioBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectRatioBtn setImage:[UIImage hx_imageNamed:@"hx_xiangce_xuanbili"] forState:UIControlStateNormal];
        _selectRatioBtn.hx_size = CGSizeMake(50, 40);
        [_selectRatioBtn addTarget:self action:@selector(didSelectRatioBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selectRatioBtn;
}
- (UIButton *)restoreBtn {
    if (!_restoreBtn) {
        _restoreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_restoreBtn setImage:[UIImage hx_imageNamed:@"hx_paizhao_bianji_huanyuan"] forState:UIControlStateNormal];
        [_restoreBtn setTitle:[NSBundle hx_localizedStringForKey:@"还原"] forState:UIControlStateNormal];
        [_restoreBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_restoreBtn setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
        _restoreBtn.enabled = NO;
        _restoreBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _restoreBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 0);
        [_restoreBtn addTarget:self action:@selector(didRestoreBtnClick) forControlEvents:UIControlEventTouchUpInside];
        _restoreBtn.hx_size = CGSizeMake(100, 60);
    }
    return _restoreBtn;
}
- (UIButton *)rotateBtn {
    if (!_rotateBtn) {
        _rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rotateBtn setImage:[UIImage hx_imageNamed:@"hx_paizhao_bianji_xuanzhuan"] forState:UIControlStateNormal];
        [_rotateBtn setTitle:[NSBundle hx_localizedStringForKey:@"旋转"] forState:UIControlStateNormal];
        [_rotateBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _rotateBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        _rotateBtn.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 0);
        [_rotateBtn addTarget:self action:@selector(didRotateBtnClick) forControlEvents:UIControlEventTouchUpInside];
        _rotateBtn.hx_size = CGSizeMake(100, 60);
    }
    return _rotateBtn;
}
- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelBtn setTitle:[NSBundle hx_localizedStringForKey:@"取消"] forState:UIControlStateNormal];
        [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        _cancelBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_cancelBtn addTarget:self action:@selector(didCancelBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}
- (UIButton *)clipBtn {
    if (!_clipBtn) {
        _clipBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        if (self.manager.configuration.singleSelected) {
            [_clipBtn setTitle:[NSBundle hx_localizedStringForKey:@"选择"] forState:UIControlStateNormal];
        }else {
            [_clipBtn setTitle:[NSBundle hx_localizedStringForKey:@"裁剪"] forState:UIControlStateNormal];
            if (!self.manager.configuration.movableCropBox) {
                _clipBtn.enabled = NO;
            }else {
                if (CGPointEqualToPoint(self.manager.configuration.movableCropBoxCustomRatio, CGPointZero)) {
                    _clipBtn.enabled = NO;
                }
            }
        }
        UIColor *color = [HXPhotoCommon photoCommon].isDark ? [UIColor whiteColor] : self.manager.configuration.themeColor;
        if ([color isEqual:[UIColor blackColor]]) {
            color = [UIColor whiteColor];
        }
        [_clipBtn setTitleColor:color forState:UIControlStateNormal];
        [_clipBtn setTitleColor:[color colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
        _clipBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        _clipBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_clipBtn addTarget:self action:@selector(didClipBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _clipBtn;
}
@end

@implementation HXEditGridLayer
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rct = self.bounds;
    CGContextSetFillColorWithColor(context, self.bgColor.CGColor);
    CGContextFillRect(context, rct);
    
    CGContextClearRect(context, _clippingRect);
    
    CGContextSetStrokeColorWithColor(context, self.gridColor.CGColor);
    //    CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 0, [UIColor clearColor].CGColor);
    CGContextSetLineWidth(context, 1);
    
    rct = self.clippingRect;
    
    CGContextBeginPath(context);
    CGFloat dW = 0;
    for(int i = 0; i < 4; ++i){
        CGContextMoveToPoint(context, rct.origin.x+dW, rct.origin.y);
        CGContextAddLineToPoint(context, rct.origin.x+dW, rct.origin.y+rct.size.height);
        dW += _clippingRect.size.width/3;
    }
    
    dW = 0;
    for(int i = 0; i < 4; ++i){
        CGContextMoveToPoint(context, rct.origin.x, rct.origin.y+dW);
        CGContextAddLineToPoint(context, rct.origin.x+rct.size.width, rct.origin.y+dW);
        dW += rct.size.height/3;
    }
    CGContextStrokePath(context);
}
@end


@implementation HXEditCornerView
- (void)drawRect:(CGRect)rect {
    UIBezierPath *bezier = [UIBezierPath bezierPath];
    bezier.lineWidth = 2.5f;
    bezier.lineCapStyle = kCGLineCapButt;
    CGFloat margin = bezier.lineWidth / 2.f;
    if (self.tag == 0) {
        [bezier moveToPoint:CGPointMake(self.hx_w / 2 - margin, self.hx_h)];
        [bezier addLineToPoint:CGPointMake(self.hx_w / 2 - margin, self.hx_h / 2 - margin)];
        [bezier addLineToPoint:CGPointMake(self.hx_w, self.hx_h / 2 - margin)];
    }else if (self.tag == 1) {
        [bezier moveToPoint:CGPointMake(self.hx_w / 2 - margin, 0)];
        [bezier addLineToPoint:CGPointMake(self.hx_w / 2 - margin, self.hx_h / 2 + margin)];
        [bezier addLineToPoint:CGPointMake(self.hx_w, self.hx_h / 2 + margin)];
    }else if (self.tag == 2) {
        [bezier moveToPoint:CGPointMake(0, self.hx_h / 2 - margin)];
        [bezier addLineToPoint:CGPointMake(self.hx_w / 2 + margin, self.hx_h / 2 - margin)];
        [bezier addLineToPoint:CGPointMake(self.hx_w / 2 + margin, self.hx_h)];
    }else {
        [bezier moveToPoint:CGPointMake(0, self.hx_h / 2 + margin)];
        [bezier addLineToPoint:CGPointMake(self.hx_w / 2 + margin, self.hx_h / 2 + margin)];
        [bezier addLineToPoint:CGPointMake(self.hx_w / 2 + margin, 0)];
    }
    
    [[UIColor whiteColor] set];
    [bezier stroke];
}

@end

@implementation HXEditRatio {
    CGFloat _longSide;
    CGFloat _shortSide;
}
- (id)initWithValue1:(CGFloat)value1 value2:(CGFloat)value2 {
    self = [super init];
    if(self){
//        _longSide  = MAX(fabs(value1), fabs(value2));
//        _shortSide = MIN(fabs(value1), fabs(value2));
        _longSide  = value2;
        _shortSide = value1;
        if (value1 > value2) {
            self.isLandscape = YES;
        }
    }
    return self;
}
- (NSString*)description {
    NSString *format = (self.titleFormat) ? self.titleFormat : @"%g : %g";
    
    if(self.isLandscape){
        return [NSString stringWithFormat:format, _longSide, _shortSide];
    }
    return [NSString stringWithFormat:format, _shortSide, _longSide];
}
- (CGFloat)ratio {
    if(_longSide == 0 || _shortSide == 0){
        return 0;
    }
    if(self.isLandscape){
        return _shortSide / (CGFloat)_longSide;
    }
    return _longSide / (CGFloat)_shortSide;
}

@end
