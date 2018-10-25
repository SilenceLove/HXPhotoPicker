//
//  HXDatePhotoEditViewController.m
//  照片选择器
//
//  Created by 洪欣 on 2017/10/27.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXDatePhotoEditViewController.h"
#import "UIImage+HXExtension.h"
#import "UIButton+HXExtension.h"

@interface HXDatePhotoEditViewController ()<HXDatePhotoEditBottomViewDelegate>
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) HXDatePhotoEditBottomView *bottomView;
@property (assign, nonatomic) BOOL orientationDidChange;
@property (assign, nonatomic) PHImageRequestID requestId;
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
@end

@implementation HXDatePhotoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageWidth = self.model.imageSize.width;
    self.imageHeight = self.model.imageSize.height;
    [self setupUI];
    [self setupModel];
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
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopTimer];
    [[PHImageManager defaultManager] cancelImageRequest:self.requestId];
    [self.navigationController setNavigationBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
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
    if (HXShowLog) NSSLog(@"dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    
    [[PHImageManager defaultManager] cancelImageRequest:self.requestId];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}
- (void)changeSubviewFrame:(BOOL)animated {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait || UIInterfaceOrientationPortrait == UIInterfaceOrientationPortraitUpsideDown) {
        
    }else if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft){
        
    }
    CGFloat bottomMargin = hxBottomMargin;
    CGFloat width = self.view.hx_w - 40;
    CGFloat imageY = 30;
    if (HX_IS_IPhoneX_All && (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)) {
        bottomMargin = 21;
        width = self.view.hx_w - 80;
        imageY = 20;
    }
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
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.imageView.frame = CGRectMake(0, imageY, w, h);
            self.imageView.center = CGPointMake(self.view.hx_w / 2, imageY + height / 2);
            self.gridLayer.frame = self.imageView.bounds;
        }];
    }else {
        self.imageView.frame = CGRectMake(0, imageY, w, h);
        self.imageView.center = CGPointMake(self.view.hx_w / 2, imageY + height / 2);
        self.gridLayer.frame = self.imageView.bounds;
    }
    self.bottomView.frame = CGRectMake(0, self.view.hx_h - 100 - bottomMargin, self.view.hx_w, 100 + bottomMargin);
    [self clippingRatioDidChange:animated];
}
- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.bottomView];
    [self.view addSubview:self.leftTopView];
    [self.view addSubview:self.leftBottomView];
    [self.view addSubview:self.rightTopView];
    [self.view addSubview:self.rightBottomView];

    [self setupModel];
}
- (void)setupModel {
    if (self.model.asset) {
        self.bottomView.userInteractionEnabled = NO;
        __weak typeof(self) weakSelf = self;
        [self.view showLoadingHUDText:nil];
        self.requestId = [HXPhotoTools getImageData:self.model.asset startRequestIcloud:^(PHImageRequestID cloudRequestId) {
            weakSelf.requestId = cloudRequestId;
        } progressHandler:^(double progress) {
            
        } completion:^(NSData *imageData, UIImageOrientation orientation) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.bottomView.userInteractionEnabled = YES;
                UIImage *image = [UIImage imageWithData:imageData];
                if (image.imageOrientation != UIImageOrientationUp) {
                    image = [image normalizedImage];
                }
                weakSelf.originalImage = image;
                weakSelf.imageView.image = image;
                [weakSelf.view handleLoading];
                [weakSelf fixationEdit];
            });
        } failed:^(NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.view handleLoading];
                weakSelf.bottomView.userInteractionEnabled = YES;
            });
        }];
    }else {
        self.imageView.image = self.model.thumbPhoto;
        self.originalImage = self.model.thumbPhoto;
        [self fixationEdit];
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
        if (self.manager.configuration.movableCropBoxCustomRatio.x > self.manager.configuration.movableCropBoxCustomRatio.y) {
            ratio.isLandscape = YES;
        }
        [self bottomViewDidSelectRatioClick:ratio];
        [UIView animateWithDuration:0.25 animations:^{
            self.imageView.alpha = 1;
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
    self.imageView.image = image;
    CGFloat imgW = self.rightTopView.center.x - self.leftTopView.center.x;
    CGFloat imgH = self.leftBottomView.center.y - self.leftTopView.center.y;
    self.imageView.frame = CGRectMake(self.leftTopView.center.x, self.leftTopView.center.y, imgW, imgH);
    self.gridLayer.frame = self.imageView.bounds;
    self.imageWidth = image.size.width;
    self.imageHeight = image.size.height;
    [self changeSubviewFrame:YES];
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
    if (self.clippingRatio) {
        CGFloat H = rect.size.width * self.clippingRatio.ratio;
        if (H<=rect.size.height) {
            rect.size.height = H;
        } else {
            rect.size.width *= rect.size.height / H;
        }
        
        rect.origin.x = (self.imageView.bounds.size.width - rect.size.width) / 2;
        rect.origin.y = (self.imageView.bounds.size.height - rect.size.height) / 2;
    }
    [self setClippingRect:rect animated:animated];
}

- (void)setClippingRect:(CGRect)clippingRect animated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.leftTopView.center = [self.view convertPoint:CGPointMake(clippingRect.origin.x, clippingRect.origin.y) fromView:self.imageView];
            self.leftBottomView.center = [self.view convertPoint:CGPointMake(clippingRect.origin.x, clippingRect.origin.y+clippingRect.size.height) fromView:self.imageView];
            self.rightTopView.center = [self.view convertPoint:CGPointMake(clippingRect.origin.x+clippingRect.size.width, clippingRect.origin.y) fromView:self.imageView];
            self.rightBottomView.center = [self.view convertPoint:CGPointMake(clippingRect.origin.x+clippingRect.size.width, clippingRect.origin.y+clippingRect.size.height) fromView:self.imageView];
        } completion:^(BOOL finished) {
            if (self.isSelectRatio) {
                if (!self.manager.configuration.movableCropBox) {
                    [self changeClipImageView];
                }
                self.isSelectRatio = NO;
            }
        }];
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"clippingRect"];
        animation.duration = 0.2;
        animation.fromValue = [NSValue valueWithCGRect:_clippingRect];
        animation.toValue = [NSValue valueWithCGRect:clippingRect];
        [self.gridLayer addAnimation:animation forKey:nil];
        
        self.gridLayer.clippingRect = clippingRect;
        self.clippingRect = clippingRect;
        [self.gridLayer setNeedsDisplay];
    } else {
        self.clippingRect = clippingRect;
    }
}
- (void)panCircleView:(UIPanGestureRecognizer*)sender {
    CGPoint point = [sender locationInView:self.imageView];
    CGPoint dp = [sender translationInView:self.imageView];
    
    CGRect rct = self.clippingRect;
    
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
                
                if(-dp.x*ratio + dp.y > 0){ point.x = (point.y - y0) / ratio; }
                else{ point.y = point.x * ratio + y0; }
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
#pragma mark - < HXDatePhotoEditBottomViewDelegate >
- (void)bottomViewDidCancelClick {
    [self stopTimer]; 
    if (self.outside) {
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    [self.navigationController popViewControllerAnimated:NO];
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
    self.imageView.image = self.originalImage;
    self.imageWidth = self.model.imageSize.width;
    self.imageHeight = self.model.imageSize.height;
    [self changeSubviewFrame:YES];
}
- (void)bottomViewDidRotateClick {
    [self stopTimer];
    if (!self.manager.configuration.movableCropBox) {
        self.clippingRatio = nil;
    }
    self.bottomView.enabled = YES;
    self.imageView.image = [self.imageView.image rotationImage:UIImageOrientationLeft];
    self.imageWidth = self.imageView.image.size.width;
    self.imageHeight = self.imageView.image.size.height;
    [self changeSubviewFrame:YES];
}
- (void)bottomViewDidClipClick {
    [self stopTimer];
    if (self.manager.configuration.movableCropBox) {
        [self changeClipImageView];
    }
    HXPhotoModel *model = [HXPhotoModel photoModelWithImage:self.imageView.image];
    if (self.outside) {
        [self dismissViewControllerAnimated:NO completion:^{
            if ([self.delegate respondsToSelector:@selector(datePhotoEditViewControllerDidClipClick:beforeModel:afterModel:)]) {
                [self.delegate datePhotoEditViewControllerDidClipClick:self beforeModel:self.model afterModel:model];
            }
        }];
        return;
    }
    if ([self.delegate respondsToSelector:@selector(datePhotoEditViewControllerDidClipClick:beforeModel:afterModel:)]) {
        [self.delegate datePhotoEditViewControllerDidClipClick:self beforeModel:self.model afterModel:model];
    }
    [self.navigationController popViewControllerAnimated:NO];
}
- (void)bottomViewDidSelectRatioClick:(HXEditRatio *)ratio {
    [self stopTimer];
    self.isSelectRatio = YES;
    if(ratio.ratio==0){
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
        [_imageView.layer addSublayer:self.gridLayer];
        self.imagePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGridView:)];
        _imageView.userInteractionEnabled = YES;
        [_imageView addGestureRecognizer:self.imagePanGesture];
    }
    return _imageView;
}
- (HXDatePhotoEditBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[HXDatePhotoEditBottomView alloc] initWithManager:self.manager];
        _bottomView.delegate = self;
    }
    return _bottomView;
}
- (HXEditGridLayer *)gridLayer {
    if (!_gridLayer) {
        _gridLayer = [[HXEditGridLayer alloc] init];
        _gridLayer.bgColor   = [[UIColor blackColor] colorWithAlphaComponent:.5];
        _gridLayer.gridColor = [UIColor whiteColor];
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

@interface HXDatePhotoEditBottomView ()
@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIView *bottomView;
@property (strong, nonatomic) UIButton *restoreBtn;
@property (strong, nonatomic) UIButton *rotateBtn;
@property (strong, nonatomic) UIButton *cancelBtn;
@property (strong, nonatomic) UIButton *clipBtn;
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) UIButton *selectRatioBtn;
@end

@implementation HXDatePhotoEditBottomView
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
    
    [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"原始值"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setupRatioWithValue1:0 value2:0];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"正方形"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setupRatioWithValue1:1 value2:1];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"2:3" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setupRatioWithValue1:2 value2:3];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"3:4" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setupRatioWithValue1:3 value2:4];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"9:16" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setupRatioWithValue1:9 value2:16];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIAlertActionStyleCancel handler:nil]];
    
    [self.hx_viewController presentViewController:alertController animated:YES completion:nil];
}
- (void)setupRatioWithValue1:(CGFloat)value1 value2:(CGFloat)value2 {
    HXEditRatio *ratio = [[HXEditRatio alloc] initWithValue1:value1 value2:value2];
    ratio.isLandscape = NO;
    
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
    
    self.cancelBtn.frame = CGRectMake(20, 0, [HXPhotoTools getTextWidth:self.cancelBtn.currentTitle height:40 fontSize:15] + 20, 40);
    self.clipBtn.hx_size = CGSizeMake([HXPhotoTools getTextWidth:self.clipBtn.currentTitle height:40 fontSize:15] + 20, 40);
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
        [_selectRatioBtn setImage:[HXPhotoTools hx_imageNamed:@"hx_xiangce_xuanbili@2x.png"] forState:UIControlStateNormal];
        _selectRatioBtn.hx_size = CGSizeMake(50, 40);
        [_selectRatioBtn addTarget:self action:@selector(didSelectRatioBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selectRatioBtn;
}
- (UIButton *)restoreBtn {
    if (!_restoreBtn) {
        _restoreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_restoreBtn setImage:[HXPhotoTools hx_imageNamed:@"hx_paizhao_bianji_huanyuan@2x.png"] forState:UIControlStateNormal];
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
        [_rotateBtn setImage:[HXPhotoTools hx_imageNamed:@"hx_paizhao_bianji_xuanzhuan@2x.png"] forState:UIControlStateNormal];
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
        UIColor *color = self.manager.configuration.themeColor;
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
+ (BOOL)needsDisplayForKey:(NSString*)key {
    if ([key isEqualToString:@"clippingRect"]) {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

- (id)initWithLayer:(id)layer {
    self = [super initWithLayer:layer];
    if(self && [layer isKindOfClass:[HXEditGridLayer class]]){
        self.bgColor   = ((HXEditGridLayer *)layer).bgColor;
        self.gridColor = ((HXEditGridLayer *)layer).gridColor;
        self.clippingRect = ((HXEditGridLayer *)layer).clippingRect;
    }
    return self;
}

- (void)drawInContext:(CGContextRef)context {
    CGRect rct = self.bounds;
    CGContextSetFillColorWithColor(context, self.bgColor.CGColor);
    CGContextFillRect(context, rct);
    
    CGContextClearRect(context, _clippingRect);
    
    CGContextSetStrokeColorWithColor(context, self.gridColor.CGColor);
    CGContextSetShadowWithColor(context, CGSizeMake(1, 2), 0.8f, [[UIColor blackColor] colorWithAlphaComponent:0.1].CGColor);
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
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect rct = self.bounds;
    rct.origin.x = rct.size.width/2-rct.size.width/6;
    rct.origin.y = rct.size.height/2-rct.size.height/6;
    rct.size.width /= 3;
    rct.size.height /= 3;
    
    CGContextSetFillColorWithColor(context, self.bgColor.CGColor);
    CGContextFillEllipseInRect(context, rct);
}

@end

@implementation HXEditRatio {
    CGFloat _longSide;
    CGFloat _shortSide;
}
- (id)initWithValue1:(CGFloat)value1 value2:(CGFloat)value2 {
    self = [super init];
    if(self){
        _longSide  = MAX(fabs(value1), fabs(value2));
        _shortSide = MIN(fabs(value1), fabs(value2));
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
    if(_longSide==0 || _shortSide==0){
        return 0;
    }
    if(self.isLandscape){
        return _shortSide / (CGFloat)_longSide;
    }
    return _longSide / (CGFloat)_shortSide;
}

@end
