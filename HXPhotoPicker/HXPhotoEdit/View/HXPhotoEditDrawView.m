//
//  HXPhotoEditDrawView.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/23.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditDrawView.h"

NSString *const kHXDrawViewData = @"HXDrawViewData";

@interface HXDrawBezierPath : UIBezierPath
@property (strong, nonatomic) UIColor *color;
@end

@implementation HXDrawBezierPath
@end

@interface HXPhotoEditDrawView ()
/// 笔画
@property (strong, nonatomic) NSMutableArray <HXDrawBezierPath *>*lineArray;
/// 图层
@property (strong, nonatomic) NSMutableArray <CAShapeLayer *>*slayerArray;
@property (assign, nonatomic) BOOL isWork;
@property (assign, nonatomic) BOOL isBegan;
@end

@implementation HXPhotoEditDrawView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.lineWidth = 5.f;
        self.lineColor = [UIColor whiteColor];
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        self.exclusiveTouch = YES;
        self.lineArray = @[].mutableCopy;
        self.slayerArray = @[].mutableCopy;
        self.enabled = YES;
        self.screenScale = 1;
    }
    return self;
}
- (CAShapeLayer *)createShapeLayer:(HXDrawBezierPath *)path {
    CAShapeLayer *slayer = [CAShapeLayer layer];
    slayer.path = path.CGPath;
    slayer.backgroundColor = [UIColor clearColor].CGColor;
    slayer.fillColor = [UIColor clearColor].CGColor;
    slayer.lineCap = kCALineCapRound;
    slayer.lineJoin = kCALineJoinRound;
    slayer.strokeColor = path.color.CGColor;
    slayer.lineWidth = path.lineWidth;
    return slayer;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([event allTouches].count == 1 && self.enabled) {
        self.isWork = NO;
        self.isBegan = YES;
        HXDrawBezierPath *path = [[HXDrawBezierPath alloc] init];
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        path.lineWidth = self.lineWidth;
        path.lineCapStyle = kCGLineCapRound;
        path.lineJoinStyle = kCGLineJoinRound;
        [path moveToPoint:point];
        path.color = self.lineColor;
        [self.lineArray addObject:path];
        
        CAShapeLayer *slayer = [self createShapeLayer:path];
        [self.layer addSublayer:slayer];
        [self.slayerArray addObject:slayer];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([event allTouches].count == 1 && self.enabled){
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        HXDrawBezierPath *path = self.lineArray.lastObject;
        if (!CGPointEqualToPoint(path.currentPoint, point)) {
            if (self.beganDraw) {
                self.beganDraw();
            }
            self.isBegan = NO;
            self.isWork = YES;
            [path addLineToPoint:point];
            CAShapeLayer *slayer = self.slayerArray.lastObject;
            slayer.path = path.CGPath;
        }
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    if ([event allTouches].count == 1 && self.enabled){
        if (self.isWork) {
            if (self.endDraw) {
                self.endDraw();
            }
        } else {
            [self undo];
        }
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([event allTouches].count == 1 && self.enabled){
        if (self.isWork) {
            if (self.endDraw) {
                self.endDraw();
            }
        } else {
            [self undo];
        }
    } else {
        [super touchesCancelled:touches withEvent:event];
    }
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
}

- (BOOL)canUndo {
    return self.lineArray.count;
}

- (void)undo {
    [self.slayerArray.lastObject removeFromSuperlayer];
    [self.slayerArray removeLastObject];
    [self.lineArray removeLastObject];
}
- (BOOL)isDrawing {
    if (!self.userInteractionEnabled || !self.enabled) {
        return NO;
    }
    return _isWork;
}
/** 图层数量 */
- (NSUInteger)count {
    return self.lineArray.count;
}

- (void)clearCoverage {
    [self.lineArray removeAllObjects];
    [self.slayerArray performSelector:@selector(removeFromSuperlayer)];
    [self.slayerArray removeAllObjects];
}
#pragma mark  - 数据
- (NSDictionary *)data {
    if (self.lineArray.count) {
        return @{kHXDrawViewData:[self.lineArray copy]};
    }
    return nil;
}

- (void)setData:(NSDictionary *)data {
    NSArray *lineArray = data[kHXDrawViewData];
    if (lineArray.count) {
        for (HXDrawBezierPath *path in lineArray) {
            CAShapeLayer *slayer = [self createShapeLayer:path];
            [self.layer addSublayer:slayer];
            [self.slayerArray addObject:slayer];
        }
        [self.lineArray addObjectsFromArray:lineArray];
    }
}
@end
