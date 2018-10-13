//
//  Demo9ViewCell.h
//  照片选择器
//
//  Created by 洪欣 on 2018/2/14.
//  Copyright © 2018年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Demo9Model.h"

@class HXPhotoView;
@interface Demo9ViewCell : UITableViewCell
@property (strong, nonatomic) Demo9Model *model;
/**  照片视图  */
@property (nonatomic, strong) HXPhotoView *photoView;
@property (copy, nonatomic) void (^photoViewChangeHeightBlock)(UITableViewCell *myCell);
@end
