//
//  LFSplashView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/28.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFSplashView.h"
#import "LFMaskLayer.h"
#import "UIImage+LFMECommon.h"

NSString *const kLFSplashViewData_mosaic = @"LFSplashViewData_mosaic";
NSString *const kLFSplashViewData_blur = @"LFSplashViewData_blur";

@interface LFSplashView ()
{
    BOOL _isWork;
    BOOL _isBegan;
}

/** 马赛克 */
@property (nonatomic, strong) CALayer *imageLayer_mosaic;
@property (nonatomic, strong) LFMaskLayer *mosaicLayer;
/** 高斯模糊 */
@property (nonatomic, strong) CALayer *imageLayer_blurry;
@property (nonatomic, strong) LFMaskLayer *blurLayer;

/** 线粗 */
@property (nonatomic, assign) CGFloat lineWidth;

@end

@implementation LFSplashView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    _lineWidth = 20.f;
    _state = LFSplashStateType_Mosaic;
    
    //添加layer（imageLayer_mosaic）到self上
    self.imageLayer_mosaic = [CALayer layer];
    self.imageLayer_mosaic.frame = self.bounds;
    [self.layer addSublayer:self.imageLayer_mosaic];
    
    self.mosaicLayer = [[LFMaskLayer alloc] init];
    self.mosaicLayer.frame = self.bounds;
    [self.layer addSublayer:self.mosaicLayer];
    
    self.imageLayer_mosaic.mask = self.mosaicLayer;
    
    /** 高斯模糊 */
    self.imageLayer_blurry = [CALayer layer];
    self.imageLayer_blurry.frame = self.bounds;
    [self.layer addSublayer:self.imageLayer_blurry];
    
    self.blurLayer = [[LFMaskLayer alloc] init];
    self.blurLayer.frame = self.bounds;
    [self.layer addSublayer:self.blurLayer];
    
    self.imageLayer_blurry.mask = self.blurLayer;
    
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.imageLayer_mosaic.frame = self.bounds;
    self.mosaicLayer.frame = self.bounds;
    self.imageLayer_blurry.frame = self.bounds;
    self.blurLayer.frame = self.bounds;
}

/** 设置图片 */
- (void)setImage:(UIImage *)image mosaicLevel:(NSUInteger)level
{
    //底图
    _image = image;
    _level = level;
    self.imageLayer_mosaic.contents = (id)[_image LFME_transToMosaicLevel:level].CGImage;
    self.imageLayer_blurry.contents = (id)[_image LFME_transToBlurLevel:level].CGImage;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.allObjects.count == 1) {
        _isWork = NO;
        _isBegan = YES;
        
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        LFBlurBezierPath *path = [LFBlurBezierPath new];
        [path setLineCapStyle:kCGLineCapRound];
        [path setLineJoinStyle:kCGLineJoinRound];
        path.lineWidth = _lineWidth;
        [path moveToPoint:point];
        
        LFBlurBezierPath *mosaicPath = [path copy];
        mosaicPath.isClear = (self.state != LFSplashStateType_Mosaic);
        [self.mosaicLayer.lineArray addObject:mosaicPath];
        
        LFBlurBezierPath *blurryPath = [path copy];
        blurryPath.isClear = (self.state != LFSplashStateType_Blurry);
        [self.blurLayer.lineArray addObject:blurryPath];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.allObjects.count == 1) {

        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        
        UIBezierPath *mosaicPath = self.mosaicLayer.lineArray.lastObject;
        UIBezierPath *blurryPath = self.blurLayer.lineArray.lastObject;
        
        if (!CGPointEqualToPoint(mosaicPath.currentPoint, point)) {
            
            if (_isBegan && self.splashBegan) self.splashBegan();
            _isWork = YES;
            _isBegan = NO;
            
            [mosaicPath addLineToPoint:point];
            
            [blurryPath addLineToPoint:point];
            
            [self drawLine];
        }
        
        
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([event allTouches].count == 1){
        if (_isWork) {
            if (self.splashEnded) self.splashEnded();
        } else {
            [self undo];
        }
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([event allTouches].count == 1){
        if (_isWork) {
            if (self.splashEnded) self.splashEnded();
        } else {
            [self undo];
        }
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)drawLine
{
    [self.mosaicLayer setNeedsDisplay];
    [self.blurLayer setNeedsDisplay];
}

/** 是否可撤销 */
- (BOOL)canUndo
{
    return self.mosaicLayer.lineArray.count && self.blurLayer.lineArray.count;
}

//撤销
- (void)undo
{
    [self.mosaicLayer.lineArray removeLastObject];
    [self.blurLayer.lineArray removeLastObject];
    [self drawLine];
}

#pragma mark  - 数据
- (NSDictionary *)data
{
    if (self.mosaicLayer.lineArray.count && self.blurLayer.lineArray.count) {
        return @{kLFSplashViewData_mosaic:[self.mosaicLayer.lineArray copy]
                 , kLFSplashViewData_blur:[self.blurLayer.lineArray copy]};
    }
    return nil;
}

- (void)setData:(NSDictionary *)data
{
    NSArray *mosaicLineArray = data[kLFSplashViewData_mosaic];
    NSArray *blurLineArray = data[kLFSplashViewData_blur];
    if (mosaicLineArray) {
        [self.mosaicLayer.lineArray addObjectsFromArray:mosaicLineArray];
    }
    if (blurLineArray) {
        [self.blurLayer.lineArray addObjectsFromArray:blurLineArray];
    }
    [self drawLine];
}

@end
