//
//  LFSplashView_new.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/6/7.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFSplashView_new.h"
#import "LFSplashLayer.h"
#import "LFMediaEditingHeader.h"

NSString *const kLFSplashViewData = @"LFSplashViewData";
NSString *const kLFSplashViewData_layerArray = @"LFSplashViewData_layerArray";
NSString *const kLFSplashViewData_frameArray = @"LFSplashViewData_frameArray";

@interface LFSplashView_new ()
{
    BOOL _isWork;
    BOOL _isBegan;
}
/** 图层 */
@property (nonatomic, strong) NSMutableArray <LFSplashLayer *>*layerArray;
/** 已显示坐标 */
@property (nonatomic, strong) NSMutableArray <NSValue *>*frameArray;

@property (nonatomic, assign) BOOL isErase;
/** 方形大小 */
@property (nonatomic, assign) CGFloat squareWidth;
/** 画笔大小 */
@property (nonatomic, assign) CGSize paintSize;
@end

@implementation LFSplashView_new

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
    _squareWidth = 15.f;
    _paintSize = CGSizeMake(50, 50);
    _state = LFSplashStateType_Mosaic;
    _layerArray = [@[] mutableCopy];
    _frameArray = [@[] mutableCopy];
}

- (CGPoint)divideMosaicPoint:(CGPoint)point
{
    CGFloat scope = self.squareWidth;
    int x = point.x/scope;
    int y = point.y/scope;
    return CGPointMake(x*scope, y*scope);
}

- (NSArray <NSValue *>*)divideMosaicRect:(CGRect)rect
{
    CGFloat scope = self.squareWidth;
    
    NSMutableArray *array = @[].mutableCopy;
    
    if (CGRectEqualToRect(CGRectZero, rect)) {
        return array;
    }
    
    CGFloat minX = CGRectGetMinX(rect);
    CGFloat maxX = CGRectGetMaxX(rect);
    CGFloat minY = CGRectGetMinY(rect);
    CGFloat maxY = CGRectGetMaxY(rect);
    
    /** 左上角 */
    CGPoint leftTop = [self divideMosaicPoint:CGPointMake(minX, minY)];
    /** 右下角 */
    CGPoint rightBoom = [self divideMosaicPoint:CGPointMake(maxX, maxY)];
    
    NSInteger countX = (rightBoom.x - leftTop.x)/scope;
    NSInteger countY = (rightBoom.y - leftTop.y)/scope;
    
    for (NSInteger i = 0; i < countX; i++) {
        for (NSInteger j = 0; j < countY;  j++) {
            CGPoint point = CGPointMake(leftTop.x + i * scope, leftTop.y + j * scope);
            NSValue *value = [NSValue valueWithCGPoint:point];
            [array addObject:value];
        }
    }
    
    return array;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.allObjects.count == 1) {
        _isWork = NO;
        _isBegan = YES;
        
        //1、触摸坐标
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        //2、创建LFSplashBlur
        if (self.state == LFSplashStateType_Mosaic) {
            CGPoint mosaicPoint = [self divideMosaicPoint:point];
            NSValue *value = [NSValue valueWithCGPoint:mosaicPoint];
            if (![self.frameArray containsObject:value]) {
                [self.frameArray addObject:value];
                
                LFSplashBlur *blur = [LFSplashBlur new];
                blur.rect = CGRectMake(mosaicPoint.x, mosaicPoint.y, self.squareWidth, self.squareWidth);
                blur.color = self.splashColor ? self.splashColor(blur.rect.origin) : nil;
                
                LFSplashLayer *layer = [LFSplashLayer layer];
                layer.frame = self.bounds;
                [layer.lineArray addObject:blur];
                
                [self.layer addSublayer:layer];
                [self.layerArray addObject:layer];
            } else {
                LFSplashLayer *layer = [LFSplashLayer layer];
                layer.frame = self.bounds;
                
                [self.layer addSublayer:layer];
                [self.layerArray addObject:layer];
            }
        } else if (self.state == LFSplashStateType_Paintbrush) {
            LFSplashImageBlur *blur = [LFSplashImageBlur new];
            blur.rect = CGRectMake(point.x-self.paintSize.width/2, point.y-self.paintSize.height/2, self.paintSize.width, self.paintSize.height);
            blur.color = self.splashColor ? self.splashColor(blur.rect.origin) : nil;
            LFSplashLayer *layer = [LFSplashLayer layer];
            layer.frame = self.bounds;
            [layer.lineArray addObject:blur];
            
            [self.layer addSublayer:layer];
            [self.layerArray addObject:layer];
        }
        

    
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.allObjects.count == 1) {
        
        
        //1、触摸坐标
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        if (_isBegan && self.splashBegan) self.splashBegan();
        _isWork = YES;
        _isBegan = NO;
        /** 获取上一个对象坐标判断是否重叠 */
        LFSplashLayer *layer = self.layerArray.lastObject;
        LFSplashBlur *prevBlur = layer.lineArray.lastObject;
        
        if (self.state == LFSplashStateType_Mosaic) {
            CGPoint mosaicPoint = [self divideMosaicPoint:point];
            NSValue *value = [NSValue valueWithCGPoint:mosaicPoint];
            if (![self.frameArray containsObject:value]) {
                [self.frameArray addObject:value];
                //2、创建LFSplashBlur
                LFSplashBlur *blur = [LFSplashBlur new];
                blur.rect = CGRectMake(mosaicPoint.x, mosaicPoint.y, self.squareWidth, self.squareWidth);
                blur.color = self.splashColor ? self.splashColor(blur.rect.origin) : nil;
                
                [layer.lineArray addObject:blur];
                [layer setNeedsDisplay];
            }
        } else if (self.state == LFSplashStateType_Paintbrush) {
            /** 限制绘画的间隙 */
            if (CGRectContainsPoint(prevBlur.rect, point) == NO) {
                //2、创建LFSplashBlur
                LFSplashImageBlur *blur = [LFSplashImageBlur new];
                blur.imageName = @"EditImageMosaicBrush.png";
                blur.color = self.splashColor ? self.splashColor(point) : nil;
                /** 新增随机位置 */
                int x = self.paintSize.width + 20;
                float randomX = floorf(arc4random()%x) - x/2;
                blur.rect = CGRectMake(point.x-self.paintSize.width/2 + randomX, point.y-self.paintSize.height/2, self.paintSize.width, self.paintSize.height);
                
                [layer.lineArray addObject:blur];
                
                /** 新增额外对象 密集图片 */
                [layer setNeedsDisplay];
                
                /** 扩大范围 */
                CGRect paintRect = CGRectInset(blur.rect, -self.squareWidth, -self.squareWidth);
                [self.frameArray removeObjectsInArray:[self divideMosaicRect:paintRect]];
            }
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
            LFSplashLayer *layer = self.layerArray.lastObject;
            if (layer.lineArray.count == 0) {
                [self undo];
            }
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
            LFSplashLayer *layer = self.layerArray.lastObject;
            if (layer.lineArray.count == 0) {
                [self undo];
            }
        } else {
            [self undo];
        }
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

/** 是否可撤销 */
- (BOOL)canUndo
{
    return self.layerArray.count;
}

//撤销
- (void)undo
{
    LFSplashLayer *layer = self.layerArray.lastObject;
    if ([layer.lineArray.firstObject isMemberOfClass:[LFSplashBlur class]]) {
        for (LFSplashBlur *blur in layer.lineArray) {
            [self.frameArray removeObject:[NSValue valueWithCGPoint:blur.rect.origin]];
        }
    }
    [layer removeFromSuperlayer];
    [self.layerArray removeLastObject];
}

#pragma mark  - 数据
- (NSDictionary *)data
{
    if (self.layerArray.count) {
        NSMutableArray *lineArray = [@[] mutableCopy];
        for (LFSplashLayer *layer in self.layerArray) {
            [lineArray addObject:layer.lineArray];
        }
        
        return @{kLFSplashViewData:@{
                         kLFSplashViewData_layerArray:[lineArray copy],
                         kLFSplashViewData_frameArray:[self.frameArray copy]
                         }};
    }
    return nil;
}

- (void)setData:(NSDictionary *)data
{
    NSDictionary *dataDict = data[kLFSplashViewData];
    NSArray *lineArray = dataDict[kLFSplashViewData_layerArray];
    for (NSArray *subLineArray in lineArray) {
        LFSplashLayer *layer = [LFSplashLayer layer];
        layer.frame = self.bounds;
        [layer.lineArray addObjectsFromArray:subLineArray];
        
        [self.layer addSublayer:layer];
        [self.layerArray addObject:layer];
        [layer setNeedsDisplay];
    }
    NSArray *frameArray = dataDict[kLFSplashViewData_frameArray];
    [self.frameArray addObjectsFromArray:frameArray];
}

@end
