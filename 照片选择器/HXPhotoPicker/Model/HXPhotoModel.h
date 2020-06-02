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

typedef void (^ HXModelStartRequestICloud)(PHImageRequestID iCloudRequestId, HXPhotoModel * _Nullable model);
typedef void (^ HXModelProgressHandler)(double progress, HXPhotoModel * _Nullable model);
typedef void (^ HXModelImageSuccessBlock)(UIImage * _Nullable image, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);
typedef void (^ HXModelImageDataSuccessBlock)(NSData * _Nullable imageData, UIImageOrientation orientation, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);
typedef void (^ HXModelImageURLSuccessBlock)(NSURL * _Nullable imageURL, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);
typedef void (^ HXModelLivePhotoSuccessBlock)(PHLivePhoto * _Nullable livePhoto, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);
typedef void (^ HXModelAVAssetSuccessBlock)(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);
typedef void (^ HXModelAVPlayerItemSuccessBlock)(AVPlayerItem * _Nullable playerItem, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);
typedef void (^ HXModelAVExportSessionSuccessBlock)(AVAssetExportSession * _Nullable assetExportSession, HXPhotoModel * _Nullable model, NSDictionary * _Nullable info);
typedef void (^ HXModelFailedBlock)(NSDictionary * _Nullable info, HXPhotoModel * _Nullable model);
typedef void (^ HXModelExportVideoSuccessBlock)(NSURL * _Nullable videoURL, HXPhotoModel * _Nullable model);
typedef void (^ HXModelExportVideoProgressHandler)(float progress, HXPhotoModel * _Nullable model);

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

typedef void (^ HXModelURLHandler)(NSURL * _Nullable URL, HXPhotoModelMediaSubType mediaType,  BOOL isNetwork, HXPhotoModel * _Nullable model);

typedef NS_ENUM(NSUInteger, HXPhotoModelMediaTypeCameraPhotoType) {
    HXPhotoModelMediaTypeCameraPhotoTypeLocal = 1,          //!< 本地图片
    HXPhotoModelMediaTypeCameraPhotoTypeLocalGif,           //!< 本地gif图片
    HXPhotoModelMediaTypeCameraPhotoTypeNetWork,            //!< 网络图片
    HXPhotoModelMediaTypeCameraPhotoTypeNetWorkGif,         //!< 网络gif图片
    HXPhotoModelMediaTypeCameraPhotoTypeLocalLivePhoto      //!< 本地LivePhoto
};

typedef NS_ENUM(NSUInteger, HXPhotoModelMediaTypeCameraVideoType) {
    HXPhotoModelMediaTypeCameraVideoTypeLocal = 1,  //!< 本地视频
    HXPhotoModelMediaTypeCameraVideoTypeNetWork     //!< 网络视频
};

typedef NS_ENUM(NSUInteger, HXPhotoModelVideoState) {
    HXPhotoModelVideoStateNormal = 0,   //!< 正常状态
    HXPhotoModelVideoStateUndersize,    //!< 视频时长小于最小选择秒数
    HXPhotoModelVideoStateOversize      //!< 视频时长超出限制
};

typedef NS_ENUM(NSUInteger, HXPhotoModelFormat) {
    HXPhotoModelFormatUnknown = 0,  //!< 未知格式
    HXPhotoModelFormatPNG,          //!< PNG格式
    HXPhotoModelFormatJPG,          //!< JPG格式
    HXPhotoModelFormatGIF,          //!< GIF格式
    HXPhotoModelFormatHEIC          //!< HEIC格式
};

@interface HXPhotoModel : NSObject<NSCoding>
/**
 文件在手机里的原路径(照片 或 视频)
 只有在手机存在的图片才会有值, iCloud上的没有
 如果是通过相机拍摄的并且没有保存到相册(临时的) 视频有值, 照片没有值
 
 此属性具有不稳定性可能为空，如想获取视频地址请根据model里的导出视频方法
 | | | | | | | | | | | | | | | | | | | | | | | | |
 v v v v v v v v v v v v v v v v v v v v v v v v v
 - (void)exportVideoWithPresetName:(NSString * _Nullable)presetName
                startRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
             iCloudProgressHandler:(HXModelProgressHandler _Nullable)iCloudProgressHandler
             exportProgressHandler:(HXModelExportVideoProgressHandler _Nullable)exportProgressHandler
                           success:(HXModelExportVideoSuccessBlock _Nullable)success
                            failed:(HXModelFailedBlock _Nullable)failed
 或者将配置类里的 requestImageAfterFinishingSelection 设为YES，点击完成后会自动获取视频地址并且赋值给videoURL
 */
@property (strong, nonatomic) NSURL * _Nullable fileURL DEPRECATED_MSG_ATTRIBUTE("Use 'exportVideoWithPresetName:startRequestICloud:iCloudProgressHandler:exportProgressHandler:success:failed' instead");

/// 创建日期
/// 如果是通过相机拍摄的并且没有保存到相册(临时的) 为当前时间([NSDate date])
@property (strong, nonatomic) NSDate * _Nullable creationDate;

/// 修改日期
/// 如果是通过相机拍摄的并且没有保存到相册(临时的) 为当前时间([NSDate date])
@property (strong, nonatomic) NSDate * _Nullable modificationDate;

/// 位置信息 CLLocation 对象
/// 通过相机拍摄的时候有定位权限的话就有值
@property (strong, nonatomic) CLLocation * _Nullable location;

/// 照片类型
@property (assign, nonatomic) HXPhotoModelMediaType type;

/// 照片子类型
@property (assign, nonatomic) HXPhotoModelMediaSubType subType;
@property (assign, nonatomic) HXPhotoModelMediaTypeCameraPhotoType cameraPhotoType;
@property (assign, nonatomic) HXPhotoModelMediaTypeCameraVideoType cameraVideoType;

/// PHAsset对象
@property (strong, nonatomic) PHAsset * _Nullable asset;
/// 照片格式
@property (assign, nonatomic) HXPhotoModelFormat photoFormat;
/// 视频秒数
@property (nonatomic, assign) NSTimeInterval videoDuration;
/// 选择的下标
@property (assign, nonatomic) NSInteger selectedIndex;
/// 模型所对应的选中下标
@property (copy, nonatomic) NSString * _Nullable selectIndexStr;
/// 照片原始宽高
@property (assign, nonatomic) CGSize imageSize;
/// 本地视频URL / 网络视频地址
@property (strong, nonatomic) NSURL * _Nullable videoURL;
/// 网络图片的地址
@property (copy, nonatomic) NSURL * _Nullable networkPhotoUrl;
/// 网络图片缩略图地址
@property (strong, nonatomic) NSURL * _Nullable networkThumbURL;
/// 网络图片的大小
//@property (assign, nonatomic) NSUInteger networkImageSize;
/// 临时的列表小图 - 本地图片才用这个上传
@property (strong, nonatomic) UIImage * _Nullable thumbPhoto;
/// 临时的预览大图  - 本地图片才用这个上传
@property (strong, nonatomic) UIImage * _Nullable previewPhoto;

/// 图片本地地址
/// 正常情况下为空
/// 1.调用过 requestImageURLStartRequestICloud 这个方法会有值
/// 2.HXPhotoConfiguration.requestImageAfterFinishingSelection = YES 时，并且选择了原图或者 tpye = HXPhotoModelMediaTypePhotoGif 有值
@property (strong, nonatomic) NSURL * _Nullable imageURL;

#pragma mark - < Disabled >
/// 是否正在下载iCloud上的资源
@property (assign, nonatomic) BOOL iCloudDownloading;
/// iCloud下载进度
@property (assign, nonatomic) CGFloat iCloudProgress;
/// 下载iCloud的请求id
@property (assign, nonatomic) PHImageRequestID iCloudRequestID;
/// 预览界面导航栏上的大标题
@property (copy, nonatomic) NSString * _Nullable barTitle;
/// 预览界面导航栏上的小标题
@property (copy, nonatomic) NSString * _Nullable barSubTitle;
/// PHAsset对象唯一标示
@property (copy, nonatomic) NSString * _Nullable localIdentifier;
/// 是否iCloud上的资源
@property (nonatomic, assign) BOOL isICloud;
/**  当前照片所在相册的名称 */
@property (copy, nonatomic) NSString * _Nullable albumName;
/**  视频时长 */
@property (copy, nonatomic) NSString * _Nullable videoTime;
/**  模型对应的Section */
@property (assign, nonatomic) NSInteger dateSection;
/**  模型对应的item */
@property (assign, nonatomic) NSInteger dateItem;
/**  cell是否显示过 */
@property (assign, nonatomic) BOOL dateCellIsVisible;
/**  是否选中 */
@property (assign, nonatomic) BOOL selected;
/**  预览界面按比例缩小之后的宽高 */
@property (assign, nonatomic) CGSize endImageSize; 
/**  3dTouch按比例缩小之后的宽高 */
@property (assign, nonatomic) CGSize previewViewSize;
/**  预览界面底部cell按比例缩小之后的宽高 */
@property (assign, nonatomic) CGSize dateBottomImageSize;
/**  拍照之后的唯一标示 */
@property (copy, nonatomic) NSString * _Nullable cameraIdentifier;
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

/**  视频当前播放的时间 */
@property (assign, nonatomic) NSTimeInterval videoCurrentTime;

/// 当前资源的大小 单位：b 字节
/// 本地图片获取的大小可能不准确
@property (assign, nonatomic) NSUInteger assetByte;
@property (assign, nonatomic) BOOL requestAssetByte;


/**  临时图片 */
@property (strong, nonatomic) UIImage * _Nullable tempImage;
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
@property (copy, nonatomic) NSString * _Nullable cameraNormalImageNamed;
@property (copy, nonatomic) NSString * _Nullable cameraPreviewImageNamed;

@property (strong, nonatomic) id _Nullable tempAsset;
@property (assign, nonatomic) BOOL loadOriginalImage;

#pragma mark - < init >
/**  通过image初始化 */
+ (instancetype _Nullable)photoModelWithImage:(UIImage * _Nullable)image;
/**  通过视频地址和视频时长初始化 */
+ (instancetype _Nullable)photoModelWithVideoURL:(NSURL * _Nullable)videoURL videoTime:(NSTimeInterval)videoTime;
/**  通过本地视频地址URL对象初始化 */
+ (instancetype _Nullable)photoModelWithVideoURL:(NSURL * _Nullable)videoURL;
/**  通过PHAsset对象初始化 */
+ (instancetype _Nullable)photoModelWithPHAsset:(PHAsset * _Nullable)asset;
/**  通过视频PHAsset对象初始化视频封面 */
+ (instancetype _Nullable)videoCoverWithPHAsset:(PHAsset * _Nullable)asset;
/**  通过网络图片URL对象初始化 */
+ (instancetype _Nullable)photoModelWithImageURL:(NSURL * _Nullable)imageURL;
+ (instancetype _Nullable)photoModelWithImageURL:(NSURL * _Nullable)imageURL thumbURL:(NSURL * _Nullable)thumbURL;

/// 网络视频初始化
/// @param videoURL 网络视频地址
/// @param videoCoverURL 视频封面地址
/// @param videoDuration 视频时长
+ (instancetype _Nullable)photoModelWithNetworkVideoURL:(NSURL *_Nonnull)videoURL
                                          videoCoverURL:(NSURL *_Nonnull)videoCoverURL
                                          videoDuration:(NSTimeInterval)videoDuration;

/// 通过本地图片和视频生成本地LivePhoto
/// @param image 本地图片
/// @param videoURL 本地视频地址
+ (instancetype _Nullable)photoModelWithLivePhotoImage:(UIImage * _Nullable)image
                                              videoURL:(NSURL * _Nullable)videoURL;

/// 判断两个HXPhotoModel是否是同一个
/// @param photoModel 模型
- (BOOL)isEqualPhotoModel:(HXPhotoModel * _Nullable)photoModel;

#pragma mark - < Request >
+ (id _Nullable)requestImageWithURL:(NSURL *_Nullable)url progress:(void (^ _Nullable) (NSInteger receivedSize, NSInteger expectedSize))progress completion:(void (^ _Nullable) (UIImage * _Nullable image, NSURL * _Nullable url, NSError * _Nullable error))completion;

+ (PHImageRequestID)requestThumbImageWithPHAsset:(PHAsset * _Nullable)asset size:(CGSize)size completion:(void (^ _Nullable)(UIImage *_Nullable image, PHAsset * _Nullable asset))completion;

- (PHImageRequestID)requestImageWithOptions:(PHImageRequestOptions * _Nullable)options
                                 targetSize:(CGSize)targetSize
                              resultHandler:(void (^ _Nullable)(UIImage *__nullable result, NSDictionary *__nullable info))resultHandler;

/**
 请求获取缩略图，主要用在列表上展示。此方法会回调多次，如果为视频的话就是视频封面
 
 @param completion 完成后的回调
 @return 请求的id，本地/网络图片返回 0
         可用于取消请求 [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)];
 */
- (PHImageRequestID)requestThumbImageCompletion:(HXModelImageSuccessBlock _Nullable)completion;
- (PHImageRequestID)requestThumbImageWithSize:(CGSize)size
                                   completion:(HXModelImageSuccessBlock _Nullable)completion;
- (PHImageRequestID)highQualityRequestThumbImageWithSize:(CGSize)size completion:(HXModelImageSuccessBlock _Nullable )completion;

/**
 请求获取预览大图，此方法只会回调一次，如果为视频的话就是视频封面

 @param size 请求图片质量大小，不是尺寸的大小
 @param startRequestICloud 开始请求iCloud上的资源
 @param progressHandler iCloud下载进度
 @param success 完成后的回调
 @param failed 失败后的回调，包含了详细信息
 @return 请求的id，本地/网络图片返回 0
         可用于取消请求 [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)];
 */
- (PHImageRequestID)requestPreviewImageWithSize:(CGSize)size
                             startRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                                progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                        success:(HXModelImageSuccessBlock _Nullable)success
                                         failed:(HXModelFailedBlock _Nullable)failed;

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
                          startRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                             progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                     success:(HXModelLivePhotoSuccessBlock _Nullable)success
                                      failed:(HXModelFailedBlock _Nullable)failed;

/// 请求获取本地LivePhoto
/// @param completion 完成
- (PHLivePhotoRequestID)requestLocalLivePhotoWithCompletion:(HXModelLivePhotoSuccessBlock _Nullable)completion;

/**
 请求获取ImageData - 本地图片和相机拍照的和网络图片会获取失败
 */
- (PHImageRequestID)requestImageDataStartRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                                       progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                               success:(HXModelImageDataSuccessBlock _Nullable)success
                                                failed:(HXModelFailedBlock _Nullable)failed;

/**
 请求获取AVAsset
 @return 请求的id，本地视频/相机录制的返回 0
         可用于取消请求 [[PHImageManager defaultManager] cancelImageRequest:(PHImageRequestID)];
 */
- (PHImageRequestID)requestAVAssetStartRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                                     progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                             success:(HXModelAVAssetSuccessBlock _Nullable)success
                                              failed:(HXModelFailedBlock _Nullable)failed;

/**
 请求获取AVAssetExportSession - 相机录制的视频/本地视频会获取不到
 @return 请求的id，本地视频/相机录制的返回 0 
 */
- (PHImageRequestID)requestAVAssetExportSessionStartRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                                                  progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                                       success:(HXModelAVExportSessionSuccessBlock _Nullable)success
                                                           failed:(HXModelFailedBlock _Nullable)failed;
/**
 请求获取AVPlayerItem
 @return 请求的id，本地视频/相机录制的返回 0
 */
- (PHImageRequestID)requestAVPlayerItemStartRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                                          progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                               success:(HXModelAVPlayerItemSuccessBlock _Nullable)success
                                                   failed:(HXModelFailedBlock _Nullable)failed;

/**
 导出视频

 @param presetName AVAssetExportPresetHighestQuality // 为空时默认 AVAssetExportPresetMediumQuality
 @param startRequestICloud 开始下载iCloud上的视频，如果视频是iCloud的视频则会先下载
 @param iCloudProgressHandler iCloud下载进度
 @param exportProgressHandler 视频导出进度
 @param success 导出成功
 @param failed 导出失败
 */
- (void)exportVideoWithPresetName:(NSString * _Nullable)presetName
               startRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
            iCloudProgressHandler:(HXModelProgressHandler _Nullable)iCloudProgressHandler
            exportProgressHandler:(HXModelExportVideoProgressHandler _Nullable)exportProgressHandler
                          success:(HXModelExportVideoSuccessBlock _Nullable)success
                           failed:(HXModelFailedBlock _Nullable)failed;

/// 获取imagePath
/// 本地图片和网络图片会获取不到，只针对有PHAsset
/// @return 请求的id，可用于取消请求 [self.asset cancelContentEditingInputRequest:(PHContentEditingInputRequestID)];
/// @param startRequestICloud 开始下载iCloud上的视频，如果视频是iCloud的视频则会先下载
/// @param progressHandler iCloud下载进度
/// @param success 成功
/// @param failed 失败
- (PHContentEditingInputRequestID)requestImageURLStartRequestICloud:(void (^ _Nullable)(
                                                                                        PHContentEditingInputRequestID iCloudRequestId,
                                                                                        HXPhotoModel * _Nullable model)
                                                                     )startRequestICloud
                                                    progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                                            success:(HXModelImageURLSuccessBlock _Nullable)success
                                                             failed:(HXModelFailedBlock _Nullable)failed;

/// 获取本地图片的URL，内部会将image写入临时目录然后生成文件路径
/// 不是本地图片的会走失败回调
/// @param success 成功
/// @param failed 失败
- (void)fetchCameraImageURLWithSuccess:(HXModelImageURLSuccessBlock _Nullable)success
                                failed:(HXModelFailedBlock _Nullable)failed;

/// 获取当前资源的URL，包括本地/网络图片、视频
/// 此方法导出手机里的视频质量为中等质量
/// @param success 成功
/// @param failed 失败
- (void)fetchAssetURLWithSuccess:(HXModelURLHandler _Nullable)success
                          failed:(HXModelFailedBlock _Nullable)failed;

/// 获取当前资源的URL，包括本地/网络图片、视频
/// @param presetName 视频质量，为空的话默认 AVAssetExportPresetMediumQuality
/// @param success 成功
/// @param failed 失败
- (void)fetchAssetURLWithVideoPresetName:(NSString * _Nullable)presetName
                                 success:(HXModelURLHandler _Nullable)success
                                  failed:(HXModelFailedBlock _Nullable)failed;

@property (assign, nonatomic) CGFloat previewContentOffsetX;

@end

@class CLGeocoder;
@interface HXPhotoDateModel : NSObject
/**  位置信息 - 如果当前天数内包含带有位置信息的资源则有值 */
@property (strong, nonatomic) CLLocation * _Nullable location;
/**  日期信息 */
@property (strong, nonatomic) NSDate *_Nullable date;
/**  日期信息字符串 */
@property (copy, nonatomic) NSString *_Nullable dateString;
/**  位置信息字符串 */
@property (copy, nonatomic) NSString * _Nullable locationString;;
/**  同一天的资源数组 */
@property (copy, nonatomic) NSArray * _Nullable photoModelArray;
/**  位置信息子标题 */
@property (copy, nonatomic) NSString * _Nullable locationSubTitle;
/**  位置信息标题 */
@property (copy, nonatomic) NSString * _Nullable locationTitle;

@property (strong, nonatomic) NSMutableArray * _Nullable locationList;
@property (assign, nonatomic) BOOL hasLocationTitles;
@property (assign, nonatomic) BOOL locationError;
//@property (strong, nonatomic) CLGeocoder *geocoder;
@end
