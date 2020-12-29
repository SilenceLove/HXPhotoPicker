//
//  HXPhotoEditResizeControl.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/29.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditResizeControl.h"

@interface HXPhotoEditResizeControl ()
@property (nonatomic, readwrite) CGPoint translation;
@property (nonatomic) CGPoint startPoint;
@property (nonatomic, strong) UIPanGestureRecognizer *gestureRecognizer;
@end

@implementation HXPhotoEditResizeControl
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:gestureRecognizer];
        _gestureRecognizer = gestureRecognizer;
    }
    
    return self;
}

- (BOOL)isEnabled {
    return self.gestureRecognizer.isEnabled;
}

- (void)setEnabled:(BOOL)enabled {
    self.gestureRecognizer.enabled = enabled;
}

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint translationInView = [gestureRecognizer translationInView:self.superview];
        self.startPoint = CGPointMake(roundf(translationInView.x), translationInView.y);
        
        if ([self.delegate respondsToSelector:@selector(resizeConrolDidBeginResizing:)]) {
            [self.delegate resizeConrolDidBeginResizing:self];
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gestureRecognizer translationInView:self.superview];
        self.translation = CGPointMake(roundf(self.startPoint.x + translation.x),
                                       roundf(self.startPoint.y + translation.y));
        
        if ([self.delegate respondsToSelector:@selector(resizeConrolDidResizing:)]) {
            [self.delegate resizeConrolDidResizing:self];
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        if ([self.delegate respondsToSelector:@selector(resizeConrolDidEndResizing:)]) {
            [self.delegate resizeConrolDidEndResizing:self];
        }
    }
}
@end
