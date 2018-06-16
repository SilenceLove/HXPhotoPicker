//
//  HXDownloadProgressView.h
//  照片选择器
//
//  Created by 洪欣 on 2017/11/20.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HXDownloadProgressView : UIView
@property (nonatomic, assign) CGFloat progress;
- (void)resetState;
- (void)startAnima;
@end
