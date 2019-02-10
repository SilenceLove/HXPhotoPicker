//
//  HXPhotoModel.h
//  照片选择器
//
//  Created by 洪欣 on 17/2/8.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@class HXPhotoManager;
@class HXPhotoModel;

typedef void (^ HXModelStartRequestICloud)(PHImageRequestID iCloudRequestId, HXPhotoModel *model);
typedef void (^ HXModelProgressHandler)(double progress, HXPhotoModel *model);
typedef void (^ HXModelImageSuccessBlock)(UIImage *image, HXPhotoModel *model, NSDictionary *info);
typedef void (^ HXModelImageDataSuccessBlock)(NSData *imageData, UIImageOrientation orientation, HXPhotoModel *model, NSDictionary *info);
typedef void (^ HXModelImageURLSuccessBlock)(NSURL *imageURL, HXPhotoModel *model, NSDictionary *info);
typedef void (^ HXModelLivePhotoSuccessBlock)(PHLivePhoto *livePhoto, HXPhotoModel *model, NSDictionary *info);
typedef void (^ HXModelAVAssetSuccessBlock)(AVAsset *avAsset, AVAudioMix *audioMix, HXPhotoModel *model, NSDictionary *info);
typedef void (^ HXModelAVPlayerItemSuccessBlock)(AVPlayerItem *playerItem, HXPhotoModel *model, NSDictionary *info);
typedef void (^ HXModelAVExportSessionSuccessBlock)(AVAssetExportSession * assetExportSession, HXPhotoModel *model, NSDictionary *info);
typedef void (^ HXModelFailedBlock)(NSDictionary *info, HXPhotoModel *model);
typedef void (^ HXModelExportVideoSuccessBlock)(NSURL *videoURL, HXPhotoModel *model);
typedef void (^ HXModelExportVideoProgressHandler)(float progress, HXPhotoModel *model);

typedef NS_ENUM(NSUInteger, HXPhotoModelMediaType) {
    HXPhotoModelMediaTypePhoto          = 0,    //!< 照片
    HXPhotoModelMediaTypeLivePhoto      = 1,    //!< LivePhoto
    HXPhotoModelMediaTypePhotoGif       = 2,    //!< gif图
    HXPhotoModelMediaTypeVideo          = 3,    //!< 视频
    HXPhotoModelMediaTypeAudio          = 4,    //!< 预留
    HXPhotoModelMediaTypeCameraPhoto    = 5,    //!< 通过相机拍的临时照片、本地/网络图片
    HXPhotoModelMediaTypeCameraVideo    = 6,    //!< 通过相机录制的视频、本地视频
    HXPhotoModelMediaTypeCamera         = 7     //!< 跳转相机
};

typedef NS_ENUM(NSUInteger, HXPhotoModelMediaSubType) {
    HXPhotoModelMediaSubTypePhoto = 0,  //!< 照片
    HXPhotoModelMediaSubTypeVideo       //!< 视频
};

typedef NS_ENUM(NSUInteger, HXPhotoModelMediaTypeCameraPhotoType) {
    HXPhotoModelMediaTypeCameraPhotoTypeLocal = 1,   //!< 本地图片
    HXPhotoModelMediaTypeCameraPhotoTypeLocalGif,    //!< 本地gif图片
    HXPhotoModelMediaTypeCameraPhotoTypeNetWork,     //!< 网络图片
    HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif   //!< 网络gif图片
};

typedef NS_ENUM(NSUInteger, HXPhotoModelMediaTypeCameraVideoType) {
    HXPhotoModelMediaTypeCameraVideoTypeLocal = 1,  //!< 本地视频
    HXPhotoModelMediaTypeCameraVideoTypeNetWork     //!< 网络视频
};

typedef NS_ENUM(NSUInteger, HXPhotoModelVideoState) {
    HXPhotoModelVideoStateNormal = 0,   //!< 普通状态
    HXPhotoModelVideoStateUndersize,    //!< 视频时长小于最小选择秒数
    HXPhotoModelVideoStateOversize      //!< 视频时长超出限制
};

@interface HXPhotoModel : NSObject<NSCoding>
/**
 文件在手机里的原路径(照片 或 视频)
 只有在手机存在的图片才会有值, iCloud上的没有
 
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
 位置信息 CLLocation 对象
 
 - 通过相机拍摄的时候有定位权限的话就有值
 */
@property (strong, nonatomic) CLLocation *location;

/**  是否正在下载iCloud上的资源  */
@property (assign, nonatomic) BOOL iCloudDownloading;
/**  iCloud下载进度  */
@property (assign, nonatomic) CGFloat iCloudProgress;
/**  下载iCloud的请求id  */
@property (assign, nonatomic) PHImageRequestID iCloudRequestID;
/**  预览界面导航栏上的大标题  */
@property (copy, nonatomic) NSString *barTitle;
/**  预览界面导航栏上的小标题  */
@property (copy, nonatomic) NSString *barSubTitle;
/**  照片PHAsset对象  */
@property (strong, nonatomic) PHAsset *asset;
/**  PHAsset对象唯一标示  */
@property (copy, nonatomic) NSString *localIdentifier;
/**  是否iCloud上的资源  */
@property (nonatomic, assign) BOOL isICloud;
/**  照片类型  */
@property (assign, nonatomic) HXPhotoModelMediaType type;
/**  照片子类型  */
@property (assign, nonatomic) HXPhotoModelMediaSubType subType;

@property (assign, nonatomic) HXPhotoModelMediaTypeCameraPhotoType cameraPhotoType;
@property (assign, nonatomic) HXPhotoModelMediaTypeCameraVideoType cameraVideoType;

/**  临时的列表小图  */
@property (strong, nonatomic) UIImage *thumbPhoto;
/**  临时的预览大图  */
@property (strong, nonatomic) UIImage *previewPhoto;
/**  当前照片所在相册的名称 */
@property (copy, nonatomic) NSString *albumName;
/**  视频时长 */
@property (copy, nonatomic) NSString *videoTime;
/**  视频秒数 */
@property (nonatomic, assign) NSTimeInterval videoDuration;
/**  选择的下标 */
@property (assign, nonatomic) NSInteger selectedIndex;
/**  模型对应的Section */
@property (assign, nonatomic) NSInteger dateSection;
/**  模型对应的item */
@property (assign, nonatomic) NSInteger dateItem;
/**  cell是否显示过 */
@property (assign, nonatomic) BOOL dateCellIsVisible;
/**  是否选中 */
@property (assign, nonatomic) BOOL selected;
/**  模型所对应的选中下标 */
@property (copy, nonatomic) NSString *selectIndexStr;
/**  照片原始宽高 */
@property (assign, nonatomic) CGSize imageSize;
/**  预览界面按比例缩小之后的宽高 */
@property (assign, nonatomic) CGSize endImageSize; 
/**  3dTouch按比例缩小之后的宽高 */
@property (assign, nonatomic) CGSize previewViewSize;
/**  预览界面底部cell按比例缩小之后的宽高 */
@property (assign, nonatomic) CGSize dateBottomImageSize;
/**  拍照之后的唯一标示 */
@property (copy, nonatomic) NSString *cameraIdentifier;
/**  本地视频URL */
@property (strong, nonatomic) NSURL *videoURL;
/**  网络图片的地址 */
@property (copy, nonatomic) NSURL *networkPhotoUrl;
/**  网络图片缩略图地址  */
@property (strong, nonatomic) NSURL *networkThumbURL;
/**  当前图片所在相册的下标 */
@property (assign, nonatomic) NSInteger currentAlbumIndex;
/**  网络图片已下载的大小 */
@property (assign, nonatomic) NSInteger receivedSize;
/**  网络图片总的大小 */
@property (assign, nonatomic) NSInteger expectedSize;
/**  网络图片是否下载完成 */
@property (assign, nonatomic) BOOL downloadComplete;
/**  网络图片是否下载错误 */
@property (assign, nonatomic) BOOL downloadError;
/**  临时图片 */
@property (strong, nonatomic) UIImage *tempImage;
/**  行数 */
@property (assign, nonatomic) NSInteger rowCount;
/**  照片列表请求的资源的大小 */
@property (assign, nonatomic) CGSize requestSize;
/**
 小图照片清晰度 越大越清晰、越消耗性能。太大可能会引起界面卡顿
 默认设置：[UIScreen mainScreen].bounds.size.width
 320    ->  0.8
 375    ->  1.4
 other  ->  1.7
 */
@property (assign, nonatomic) CGFloat clarityScale;
/**  如果当前为视频资源时是禁止选择  */
@property (assign, nonatomic) BOOL videoUnableSelect;
/**  是否隐藏选择按钮  */
@property (assign, nonatomic) BOOL needHideSelectBtn;

/**  如果当前为视频资源时的视频状态  */
@property (assign, nonatomic) HXPhotoModelVideoState videoState;

@property (copy, nonatomic) NSString *cameraNormalImageNamed;
@property (copy, nonatomic) NSString *cameraPreviewImageNamed;

@property (strong, nonatomic) id tempAsset;
@property (assign, nonatomic) BOOL loadOriginalImage;

#pragma mark - < init >

/**  通过image初始化 */
+ (instancetype)photoModelWithImage:(UIImage *)image;
/**  通过视频地址和视频时长初始化 */
+ (instancetype)photoModelWithVideoURL:(NSURL *)videoURL videoTime:(NSTimeInterval)videoTime;
/**  通过本地视频地址URL对象初始化 */
+ (instancetype)photoModelWithVideoURL:(NSURL *)videoURL;
/**  通过PHAsset对象初始化 */
+ (instancetype)photoModelWithPHAsset:(PHAsset *)asset;
/**  通过网络图片URL对象初始化 */
+ (instancetype)photoModelWithImageURL:(NSURL *)imageURL;
+ (instancetype)photoModelWithImageURL:(NSURL *)imageURL thumbURL:(NSURL *)thumbURL;

#pragma mark - < Request >

+ (id)requestImageWithURL:(NSURL *)url progress:(void (^) (NSInteger receivedSize, NSInteger expectedSize))progress completion:(void (^) (UIImage * _Nullable image, NSURL * _Nonnull url, NSError * _Nullable error))completion;

+ (PHImageRequestID)requestThumbImageWithPHAsset:(PHAsset *)asset size:(CGSize)size completion:(void (^)(UIImage *image, PHAsset *asset))completion;

- (PHImageRequestID)requestImageWithOptions:(PHImageRequestOptions *)options
                                 targetSize:(CGSize)targetSize
                              resultHandler:(void (^)(UIImage *__nullable result, NSDictionary *__nullable info))resultHandler;

/**
 请求获取缩略图，主要用在列表上展示。此方法会回调多次，如果为视频的话就是视频封面
 
 @param completion 完成后的回调
 @return 请求的id，本地/网络图片返回 0
         可用于取消请求 [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)];
 */
- (PHImageRequestID)requestThumbImageCompletion:(HXModelImageSuccessBlock)completion;
- (PHImageRequestID)requestThumbImageWithSize:(CGSize)size completion:(HXModelImageSuccessBlock)completion;

/**
 请求获取预览大图，此方法只会回调一次，如果为视频的话就是视频封面

 @param size 请求大小
 @param startRequestICloud 开始请求iCloud上的资源
 @param progressHandler iCloud下载进度
 @param success 完成后的回调
 @param failed 失败后的回调，包含了详细信息
 @return 请求的id，本地/网络图片返回 0
         可用于取消请求 [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)];
 */
- (PHImageRequestID)requestPreviewImageWithSize:(CGSize)size
                             startRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                progressHandler:(HXModelProgressHandler)progressHandler
                                        success:(HXModelImageSuccessBlock)success
                                         failed:(HXModelFailedBlock)failed;

/**
 请求获取LivePhoto

 @param size 请求大小
 @param startRequestICloud 开始请求iCloud上的资源
 @param progressHandler iCloud下载进度
 @param success 完成后的回调
 @param failed 失败后的回调，包含了详细信息
 @return 请求的id，本地/网络图片返回 0
         可用于取消请求 [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)];
 */
- (PHImageRequestID)requestLivePhotoWithSize:(CGSize)size
                          startRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                             progressHandler:(HXModelProgressHandler)progressHandler
                                     success:(HXModelLivePhotoSuccessBlock)success
                                      failed:(HXModelFailedBlock)failed;
/**
 请求获取ImageData - 本地图片和相机拍照的和网络图片会获取不到
 */
- (PHImageRequestID)requestImageDataStartRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                       progressHandler:(HXModelProgressHandler)progressHandler
                                               success:(HXModelImageDataSuccessBlock)success
                                                failed:(HXModelFailedBlock)failed;

/**
 请求获取AVAsset
 @return 请求的id，本地视频/相机录制的返回 0
         可用于取消请求 [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)];
 */
- (PHImageRequestID)requestAVAssetStartRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                     progressHandler:(HXModelProgressHandler)progressHandler
                                             success:(HXModelAVAssetSuccessBlock)success
                                              failed:(HXModelFailedBlock)failed;

/**
 请求获取AVAssetExportSession - 相机录制的视频/本地视频会获取不到
 @return 请求的id，本地视频/相机录制的返回 0 
 */
- (PHImageRequestID)requestAVAssetExportSessionStartRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                                  progressHandler:(HXModelProgressHandler)progressHandler
                                                       success:(HXModelAVExportSessionSuccessBlock)success
                                                           failed:(HXModelFailedBlock)failed;
/**
 请求获取AVPlayerItem
 @return 请求的id，本地视频/相机录制的返回 0
 */
- (PHImageRequestID)requestAVPlayerItemStartRequestICloud:(HXModelStartRequestICloud)startRequestICloud
                                          progressHandler:(HXModelProgressHandler)progressHandler
                                               success:(HXModelAVPlayerItemSuccessBlock)success
                                                   failed:(HXModelFailedBlock)failed;

/**
 导出视频

 @param presetName AVAssetExportPresetHighestQuality
 @param startRequestICloud 开始下载iCloud上的视频，如果视频是iCloud的视频则会先下载
 @param iCloudProgressHandler iCloud下载进度
 @param exportProgressHandler 视频导出进度
 @param success 导出成功
 @param failed 导出失败
 */
- (void)exportVideoWithPresetName:(NSString *)presetName
               startRequestICloud:(HXModelStartRequestICloud)startRequestICloud
            iCloudProgressHandler:(HXModelProgressHandler)iCloudProgressHandler
            exportProgressHandler:(HXModelExportVideoProgressHandler)exportProgressHandler
                          success:(HXModelExportVideoSuccessBlock)success
                           failed:(HXModelFailedBlock)failed;

/**
 获取imagePath
 - 本地图片和网络图片会获取不到，只针对有PHAsset
 @return 请求的id，
         可用于取消请求 [self.asset cancelContentEditingInputRequest:(PHContentEditingInputRequestID)];
 */
- (PHContentEditingInputRequestID)requestImageURLStartRequestICloud:(void (^)(PHContentEditingInputRequestID iCloudRequestId, HXPhotoModel *model))startRequestICloud
                                                    progressHandler:(HXModelProgressHandler)progressHandler
                                                            success:(HXModelImageURLSuccessBlock)success
                                                             failed:(HXModelFailedBlock)failed;
@end

@class CLGeocoder;
@interface HXPhotoDateModel : NSObject
/**  位置信息 - 如果当前天数内包含带有位置信息的资源则有值 */
@property (strong, nonatomic) CLLocation *location;
/**  日期信息 */
@property (strong, nonatomic) NSDate *date;
/**  日期信息字符串 */
@property (copy, nonatomic) NSString *dateString;
/**  位置信息字符串 */
@property (copy, nonatomic) NSString *locationString;;
/**  同一天的资源数组 */
@property (copy, nonatomic) NSArray *photoModelArray;
/**  位置信息子标题 */
@property (copy, nonatomic) NSString *locationSubTitle;
/**  位置信息标题 */
@property (copy, nonatomic) NSString *locationTitle;

@property (strong, nonatomic) NSMutableArray *locationList;
@property (assign, nonatomic) BOOL hasLocationTitles;
@property (assign, nonatomic) BOOL locationError;
//@property (strong, nonatomic) CLGeocoder *geocoder;
@end
