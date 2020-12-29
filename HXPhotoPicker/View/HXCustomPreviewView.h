//
//  HXCustomPreviewView.h
//  HXPhotoPickerExample
//
//  Created by Silence on 2017/10/31.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol HXCustomPreviewViewDelegate <NSObject>
@optional;
- (void)tappedToFocusAtPoint:(CGPoint)point;
- (void)pinchGestureScale:(CGFloat)scale;
- (void)didLeftSwipeClick;
- (void)didRightSwipeClick;
@end

@interface HXCustomPreviewView : UIView
@property (strong, nonatomic) AVCaptureSession *session;
@property (weak, nonatomic) id<HXCustomPreviewViewDelegate> delegate;
@property (strong, nonatomic) UIColor *themeColor;
@property (nonatomic, assign) CGFloat beginGestureScale;
@property (nonatomic, assign) CGFloat effectiveScale;
@property (nonatomic, assign) CGFloat maxScale;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

- (void)setupPreviewLayer;

- (void)addSwipeGesture;

@property (nonatomic) BOOL tapToFocusEnabled;
@property (nonatomic) BOOL tapToExposeEnabled;
@property (nonatomic) BOOL pinchToZoomEnabled;

- (void)firstFocusing;
@end
