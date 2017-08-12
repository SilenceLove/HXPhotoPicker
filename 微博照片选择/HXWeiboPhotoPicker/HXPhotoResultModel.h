//
//  HXPhotoResultModel.h
//  微博照片选择
//
//  Created by 洪欣 on 2017/8/12.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
typedef enum : NSUInteger {
    HXPhotoResultModelMediaTypePhoto = 0, // 照片
    HXPhotoResultModelMediaTypeVideo // 视频
} HXPhotoResultModelMediaType;
@interface HXPhotoResultModel : NSObject

/**  标记  */
@property (assign, nonatomic) NSInteger index;
@property (assign, nonatomic) NSInteger photoIndex;
@property (assign, nonatomic) NSInteger videoIndex;

/**  资源类型  */
@property (assign, nonatomic) HXPhotoResultModelMediaType type;

/**  原图URL  */
@property (strong, nonatomic) NSURL *fullSizeImageURL;

/**  原尺寸image 如果资源为视频时此字段为视频封面图片  */
@property (strong, nonatomic) UIImage *displaySizeImage;

/**  原图方向  */
@property (assign, nonatomic) int fullSizeImageOrientation;

/**  视频Asset  */
@property (strong, nonatomic) AVAsset *avAsset;

/**  视频URL  */
@property (strong, nonatomic) NSURL *videoURL;

/**  创建日期  */
@property (strong, nonatomic) NSDate *creationDate;

/**  位置信息  */
@property (strong, nonatomic) CLLocation *location;

@end
