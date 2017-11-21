//
//  HXPhotoModel.h
//  微博照片选择
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef enum : NSUInteger {
    HXPhotoModelMediaTypePhoto = 0, // 照片
    HXPhotoModelMediaTypeLivePhoto, // LivePhoto
    HXPhotoModelMediaTypePhotoGif,  // gif图
    HXPhotoModelMediaTypeVideo,     // 视频
    HXPhotoModelMediaTypeAudio,     // 预留
    HXPhotoModelMediaTypeCameraPhoto,   // 通过相机拍的照片
    HXPhotoModelMediaTypeCameraVideo,   // 通过相机录制的视频
    HXPhotoModelMediaTypeCamera         // 跳转相机
} HXPhotoModelMediaType;

typedef enum : NSUInteger {
    HXPhotoModelMediaSubTypePhoto = 0, // 照片
    HXPhotoModelMediaSubTypeVideo // 视频
} HXPhotoModelMediaSubType;

@interface HXPhotoModel : NSObject
/**
 文件在手机里的原路径(照片 或 视频)
 
 - 如果是通过相机拍摄的并且没有保存到相册(临时的) 视频有值, 照片没有值
 */
@property (strong, nonatomic) NSURL *fileURL;
/**
 创建日期
 
 - 如果是通过相机拍摄的并且没有保存到相册(临时的) 为当前时间([NSDate date])
 */
@property (strong, nonatomic) NSDate *creationDate;
/**
 修改日期
 
 - 如果是通过相机拍摄的并且没有保存到相册(临时的) 为当前时间([NSDate date])
 */
@property (strong, nonatomic) NSDate *modificationDate;
/**
 位置信息 NSData 对象
 
 - 如果是通过相机拍摄的并且没有保存到相册(临时的) 没有值
 */
@property (strong, nonatomic) NSData *locationData;
/**
 位置信息 CLLocation 对象
 
 - 如果是通过相机拍摄的并且没有保存到相册(临时的) 没有值
 */
@property (strong, nonatomic) CLLocation *location;

@property (assign, nonatomic) BOOL iCloudDownloading;
@property (assign, nonatomic) CGFloat iCloudProgress;
@property (assign, nonatomic) PHImageRequestID iCloudRequestID;

@property (copy, nonatomic) NSString *barTitle;
@property (copy, nonatomic) NSString *barSubTitle;


/**
 照片PHAsset对象
 */
@property (strong, nonatomic) PHAsset *asset;
@property (copy, nonatomic) NSString *localIdentifier;
@property (nonatomic, assign) BOOL isIcloud;
@property (nonatomic, assign) BOOL cloudIsDeletable;
@property (strong, nonatomic) NSURL *fullSizeImageURL;

/**
 视频AVAsset对象
 */
@property (strong, nonatomic) AVAsset *avAsset;
@property (strong, nonatomic) AVPlayerItem *playerItem;

/**
 照片类型
 */
@property (assign, nonatomic) HXPhotoModelMediaType type;
@property (assign, nonatomic) HXPhotoModelMediaSubType subType;

/**
 小图 -- 选中之后有值, 取消选中为空
 */
@property (strong, nonatomic) UIImage *thumbPhoto;

/**
 预览照片 -- 选中之后有值, 取消选中为空
 */
@property (strong, nonatomic) UIImage *previewPhoto;

/**  
 当前照片所在相册的名称
 */
@property (copy, nonatomic) NSString *albumName;

/**  
 请求ID
 */
@property (assign, nonatomic) PHImageRequestID requestID;
@property (assign, nonatomic) PHImageRequestID liveRequestID;


/**
 视频时长
 */
@property (copy, nonatomic) NSString *videoTime;

/**
 选择的下标
 */
@property (assign, nonatomic) NSInteger selectedIndex;
@property (assign, nonatomic) NSInteger dateSection;
@property (assign, nonatomic) NSInteger dateItem;
@property (assign, nonatomic) BOOL dateCellIsVisible;

/**
 是否选中
 */
@property (assign, nonatomic) BOOL selected;
@property (copy, nonatomic) NSString *selectIndexStr;

/**
 图片宽高
 */
@property (assign, nonatomic) CGSize imageSize;

/**
 缩小之后的图片宽高
 */
@property (assign, nonatomic) CGSize endImageSize;
@property (assign, nonatomic) CGSize previewViewSize;
@property (assign, nonatomic) CGSize endDateImageSize;
@property (assign, nonatomic) CGSize dateBottomImageSize;

/**
 判断当前照片 是否关闭了livePhoto功能
 */
@property (assign, nonatomic) BOOL isCloseLivePhoto;

/**
 拍照之后的唯一标示
 */
@property (copy, nonatomic) NSString *cameraIdentifier;

/**
 通过相机摄像的视频URL
 */
@property (strong, nonatomic) NSURL *videoURL;

/**  
 网络图片的地址
 */
@property (copy, nonatomic) NSString *networkPhotoUrl;

/**
 当前图片所在相册的下标
 */
@property (assign, nonatomic) NSInteger currentAlbumIndex;


/*** 以下属性是使用HXPhotoView时自定义转场动画时所需要的属性 ***/

/**
 选完点下一步之后在collectionView上的图片数组下标
 */
@property (assign, nonatomic) NSInteger endIndex;

@property (assign, nonatomic) NSInteger videoIndex;

/**
 选完点下一步之后在collectionView上的下标
 */
@property (assign, nonatomic) NSInteger endCollectionIndex;

@property (assign, nonatomic) NSInteger fetchOriginalIndex;
@property (assign, nonatomic) NSInteger fetchImageDataIndex;

@property (assign, nonatomic) NSInteger receivedSize;
@property (assign, nonatomic) NSInteger expectedSize;
@property (assign, nonatomic) BOOL downloadComplete;
@property (assign, nonatomic) BOOL downloadError;

@property (strong, nonatomic) UIImage *tempImage;
@property (assign, nonatomic) NSInteger rowCount;
@property (assign, nonatomic) CGSize requestSize;

+ (instancetype)photoModelWithImage:(UIImage *)image;
+ (instancetype)photoModelWithVideoURL:(NSURL *)videoURL videoTime:(NSTimeInterval)videoTime;
+ (instancetype)photoModelWithPHAsset:(PHAsset *)asset;

@property (copy, nonatomic) NSString *fullPathToFile;
@end

@class CLGeocoder;
@interface HXPhotoDateModel : NSObject
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) NSMutableArray *locationList;
@property (copy, nonatomic) NSString *dateString;
@property (copy, nonatomic) NSString *locationString;
@property (copy, nonatomic) NSArray *photoModelArray;
@property (copy, nonatomic) NSString *locationSubTitle;
@property (copy, nonatomic) NSString *locationTitle;
@property (assign, nonatomic) BOOL hasLocationTitles;
//@property (strong, nonatomic) CLGeocoder *geocoder;
@end
