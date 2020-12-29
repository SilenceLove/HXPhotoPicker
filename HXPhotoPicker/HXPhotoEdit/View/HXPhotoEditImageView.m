//
//  HXPhotoEditImageView.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/23.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditImageView.h"
#import "UIView+HXExtension.h"
#import "HXPhotoEditStickerItemView.h"
#import "HXPhotoEditStickerItemContentView.h"
#import "UIImage+HXExtension.h"
#import "UIView+HXExtension.h"
#import "HXPhotoDefine.h"

NSString *const kHXImageViewData_draw = @"HXImageViewData_draw";
NSString *const kHXImageViewData_sticker = @"HXImageViewData_sticker";
NSString *const kHXImageViewData_splash = @"HXImageViewData_splash";
NSString *const kHXImageViewData_filter = @"HXImageViewData_filter";

@interface HXPhotoEditImageView ()
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) HXPhotoEditDrawView *drawView;
@property (strong, nonatomic) HXPhotoEditStickerView *stickerView;
@property (strong, nonatomic) HXPhotoEditSplashView *splashView;
@end

@implementation HXPhotoEditImageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.imageView];
        [self addSubview:self.splashView];
        [self addSubview:self.drawView];
        [self addSubview:self.stickerView];
    }
    return self;
}

- (void)changeSubviewFrame {
    self.imageView.frame = self.bounds;
    self.drawView.frame = self.imageView.frame;
    self.stickerView.frame = self.bounds;
    self.splashView.frame = self.bounds;
}
- (void)clearCoverage {
//    [self.drawView clearCoverage];
//    [self.stickerView clearCoverage];
//    [self.splashView clearCoverage];
}
- (void)setType:(HXPhotoEditImageViewType)type {
    self.drawView.userInteractionEnabled = NO;
    self.splashView.userInteractionEnabled = NO;
    if (type == HXPhotoEditImageViewTypeDraw) {
        self.drawView.userInteractionEnabled = YES;
    }else if (type == HXPhotoEditImageViewTypeSplash) {
        self.splashView.userInteractionEnabled = YES;
    }
}
- (void)setImage:(UIImage *)image {
    _image = image;
    self.imageView.image = image;
}

- (void)setMoveCenter:(BOOL (^)(CGRect))moveCenter {
    _moveCenter = moveCenter;
    if (moveCenter) {
        self.stickerView.moveCenter = moveCenter;
    } else {
        self.stickerView.moveCenter = nil;
    }
}
- (void)setGetMaxScale:(CGFloat (^)(CGSize))getMaxScale {
    _getMaxScale = getMaxScale;
    if (getMaxScale) {
        self.stickerView.getMaxScale = getMaxScale;
    }else {
        self.stickerView.getMaxScale = nil;
    }
}
- (void)setGetMinScale:(CGFloat (^)(CGSize))getMinScale {
    _getMinScale = getMinScale;
    if (getMinScale) {
        self.stickerView.getMinScale = getMinScale;
    }else {
        self.stickerView.getMinScale = nil;
    }
}
- (void)setScreenScale:(CGFloat)screenScale {
    _screenScale = screenScale;
    self.drawView.screenScale = screenScale;
    self.stickerView.screenScale = screenScale;
    self.splashView.screenScale = screenScale;
}
- (UIImage * _Nullable)editOtherImagesInRect:(CGRect)rect rotate:(CGFloat)rotate mirrorHorizontally:(BOOL)mirrorHorizontally {
    UIImage *image = nil;
    NSMutableArray *array = nil;
    for (UIView *subView in self.subviews) {
        if (subView == self.imageView) {
            continue;
        } else if ([subView isKindOfClass:[HXPhotoEditDrawView class]]) {
            if (((HXPhotoEditDrawView *)subView).count  == 0) {
                continue;
            }
        } else if ([subView isKindOfClass:[HXPhotoEditStickerView class]]) {
            if (((HXPhotoEditStickerView *)subView).count  == 0) {
                continue;
            }
        } else if ([subView isKindOfClass:[HXPhotoEditSplashView class]]) {
           if (!((HXPhotoEditSplashView *)subView).canUndo) {
               continue;
           }
       }
        if (array == nil) {
            array = [NSMutableArray arrayWithCapacity:3];
        }
        UIImage *subImage = [subView hx_captureImageAtFrame:rect];
        subView.layer.contents = (id)nil;
        if (subImage) {
            [array addObject:subImage];
        }
    }
    if (array.count) {
        image = [UIImage hx_mergeimages:array];
        if (rotate || mirrorHorizontally) {
            NSInteger angle = fabs(rotate * 180 / M_PI - 360);
            if (angle == 0 || angle == 360) {
                if (mirrorHorizontally) {
                    image = [image hx_rotationImage:UIImageOrientationUpMirrored];
                }
            }else if (angle == 90) {
                if (!mirrorHorizontally) {
                    image = [image hx_rotationImage:UIImageOrientationLeft];
                }else {
                    image = [image hx_rotationImage:UIImageOrientationRightMirrored];
                }
            }else if (angle == 180) {
                if (!mirrorHorizontally) {
                    image = [image hx_rotationImage:UIImageOrientationDown];
                }else {
                    image = [image hx_rotationImage:UIImageOrientationDownMirrored];
                }
            }else if (angle == 270) {
                if (!mirrorHorizontally) {
                    image = [image hx_rotationImage:UIImageOrientationRight];
                }else {
                    image = [image hx_rotationImage:UIImageOrientationLeftMirrored];
                }
            }
        }
    }
    return image;
}
- (void)setConfiguration:(HXPhotoEditConfiguration *)configuration {
    _configuration = configuration;
    self.stickerView.configuration = configuration;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.drawView.frame = self.imageView.frame;
    self.stickerView.frame = self.bounds;
    self.splashView.frame = self.bounds;
}
- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
    }
    return _imageView;
}
- (HXPhotoEditDrawView *)drawView {
    if (!_drawView) {
        _drawView = [[HXPhotoEditDrawView alloc] initWithFrame:self.bounds];
        _drawView.userInteractionEnabled = NO;
    }
    return _drawView;
}
- (HXPhotoEditStickerView *)stickerView {
    if (!_stickerView) {
        _stickerView = [[HXPhotoEditStickerView alloc] initWithFrame:self.bounds];
    }
    return _stickerView;
}
- (HXPhotoEditSplashView *)splashView {
    if (!_splashView) {
        _splashView = [[HXPhotoEditSplashView alloc] initWithFrame:self.bounds];
        _splashView.userInteractionEnabled = NO;
        HXWeakSelf
        _splashView.splashColor = ^UIColor *(CGPoint point) {
            return [weakSelf.imageView hx_colorOfPoint:point];
        };
    }
    return _splashView;
}
#pragma mark - 数据
- (NSDictionary *)photoEditData {
    NSDictionary *drawData = self.drawView.data;
    NSDictionary *stickerData = self.stickerView.data;
    NSDictionary *splashData = self.splashView.data;
    
    NSMutableDictionary *data = [@{} mutableCopy];
    if (drawData) [data setObject:drawData forKey:kHXImageViewData_draw];
    if (stickerData) [data setObject:stickerData forKey:kHXImageViewData_sticker];
    if (splashData) [data setObject:splashData forKey:kHXImageViewData_splash];
    
    if (data.count) {
        return data;
    }
    return nil;
}

- (void)setPhotoEditData:(NSDictionary *)photoEditData {
    self.drawView.data = photoEditData[kHXImageViewData_draw];
    self.stickerView.data = photoEditData[kHXImageViewData_sticker];
    self.splashView.data = photoEditData[kHXImageViewData_splash];
}
@end
