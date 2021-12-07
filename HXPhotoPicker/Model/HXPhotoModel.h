//
//  HXPhotoModel.h
//  HXPhotoPickerExample
//
//  Created by Silence on 17/2/8.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HXPhotoTypes.h"

@class HXPhotoManager;
@class HXPhotoEdit;
@class HXAssetURLResult;

@interface HXPhotoModel : NSObject<NSCoding>
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
/// 系统相册的资源(PHAsset不为nil的)需要通过exportVideoWithPresetName...方法获取
@property (strong, nonatomic) NSURL * _Nullable videoURL;

/// livephoto - 网络视频地址
@property (strong, nonatomic) NSURL * _Nullable livePhotoVideoURL;

/// 网络图片的地址
@property (copy, nonatomic) NSURL * _Nullable networkPhotoUrl;

/// 网络图片缩略图地址
@property (strong, nonatomic) NSURL * _Nullable networkThumbURL;

/// 网络图片的大小
//@property (assign, nonatomic) NSUInteger networkImageSize;

/// 临时的列表小图 - 本地图片才用这个上传
/// 获取图片请使用 request相关方法
@property (strong, nonatomic) UIImage * _Nullable thumbPhoto;

/// 临时的预览大图  - 本地图片才用这个上传
/// 获取图片请使用 request相关方法
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

/// 当前照片所在相册的名称
@property (copy, nonatomic) NSString * _Nullable albumName;

/// 视频时长
@property (copy, nonatomic) NSString * _Nullable videoTime;

/// cell是否显示过
@property (assign, nonatomic) BOOL dateCellIsVisible;

/// 是否选中
@property (assign, nonatomic) BOOL selected;

/// 预览界面按比例缩小之后的宽高
@property (assign, nonatomic) CGSize endImageSize;

/// 3dTouch按比例缩小之后的宽高
@property (assign, nonatomic) CGSize previewViewSize;

/// 预览界面底部cell按比例缩小之后的宽高
@property (assign, nonatomic) CGSize dateBottomImageSize;

/// 拍照之后的唯一标示
@property (copy, nonatomic) NSString * _Nullable cameraIdentifier;

/// 当前图片所在相册的下标
@property (assign, nonatomic) NSInteger currentAlbumIndex;

/// 网络图片已下载的大小
@property (assign, nonatomic) NSInteger receivedSize;

/// 网络图片总的大小
@property (assign, nonatomic) NSInteger expectedSize;

/// 网络图片是否下载完成
@property (assign, nonatomic) BOOL downloadComplete;

/// 网络图片是否下载错误
@property (assign, nonatomic) BOOL downloadError;

/// 视频当前播放的时间
@property (assign, nonatomic) NSTimeInterval videoCurrentTime;

/// 当前资源的大小 单位：b 字节
/// 网络图片/视频为0
@property (assign, nonatomic) NSUInteger assetByte;
@property (assign, nonatomic) BOOL requestAssetByte;

/// 编辑的数据
/// 传入之前的编辑数据可以在原有基础上继续编辑
@property (strong, nonatomic) HXPhotoEdit * _Nullable photoEdit;
/// 是否隐藏选择按钮
@property (assign, nonatomic) BOOL needHideSelectBtn;
/// 如果当前为视频资源时的视频状态
@property (assign, nonatomic) HXPhotoModelVideoState videoState;
@property (copy, nonatomic) NSString * _Nullable cameraNormalImageNamed;
@property (copy, nonatomic) NSString * _Nullable cameraPreviewImageNamed;

@property (assign, nonatomic) BOOL loadOriginalImage;
/// 临时图片
@property (strong, nonatomic) UIImage * _Nullable tempImage;

#pragma mark - < init >
/// 通过image初始化
/// @param image UIImage
+ (instancetype _Nullable)photoModelWithImage:(UIImage * _Nullable)image;
/// 通过视频地址和视频时长初始化
/// @param videoURL 视频地址
/// @param videoTime 视频时长
+ (instancetype _Nullable)photoModelWithVideoURL:(NSURL * _Nullable)videoURL videoTime:(NSTimeInterval)videoTime;
/// 通过本地视频地址URL对象初始化
/// @param videoURL 本地视频地址URL
+ (instancetype _Nullable)photoModelWithVideoURL:(NSURL * _Nullable)videoURL;
/// 通过PHAsset对象初始化
/// @param asset PHAsset
+ (instancetype _Nullable)photoModelWithPHAsset:(PHAsset * _Nullable)asset;
/// 通过视频PHAsset对象初始化视频封面
/// @param asset PHAsset
+ (instancetype _Nullable)videoCoverWithPHAsset:(PHAsset * _Nullable)asset;
/// 通过网络图片URL对象初始化
/// @param imageURL 网络图片URL
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

/// 通过网络图片和视频生成本地LivePhoto
/// @param imageURL 网络图片地址
/// @param videoURL 网络视频地址
+ (instancetype _Nullable)photoModelWithLivePhotoNetWorkImage:(NSURL * _Nullable)imageURL
                                              netWorkVideoURL:(NSURL * _Nullable)videoURL;
/// 判断两个HXPhotoModel是否是同一个
/// @param photoModel 模型
- (BOOL)isEqualToPhotoModel:(HXPhotoModel * _Nullable)photoModel;

/// 获取当前asset是不是iCloud上的资源
- (void)isICloudAssetWithCompletion:(void (^_Nullable)(BOOL isICloud, HXPhotoModel * _Nullable model))completion;

#pragma mark - < Request >
+ (id _Nullable)requestImageWithURL:(NSURL *_Nullable)url progress:(void (^ _Nullable) (NSInteger receivedSize, NSInteger expectedSize))progress completion:(void (^ _Nullable) (UIImage * _Nullable image, NSURL * _Nullable url, NSError * _Nullable error))completion;

/// 请求获取缩略图，主要用在列表上展示。此方法会回调多次，如果为视频的话就是视频封面
- (PHImageRequestID)requestThumbImageCompletion:(HXModelImageSuccessBlock _Nullable)completion;
- (PHImageRequestID)requestThumbImageWithWidth:(CGFloat)width
                                    completion:(HXModelImageSuccessBlock _Nullable)completion;

/// 请求获取缩略图，主要用在列表上展示。此方法只会回调一次
- (PHImageRequestID)highQualityRequestThumbImageWithWidth:(CGFloat)width
                                               completion:(HXModelImageSuccessBlock _Nullable )completion;

/// 请求获取预览大图，此方法只会回调一次，如果为视频的话就是视频封面
/// @param size 请求图片质量大小，不是尺寸的大小
- (PHImageRequestID)requestPreviewImageWithSize:(CGSize)size
                             startRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                                progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                        success:(HXModelImageSuccessBlock _Nullable)success
                                         failed:(HXModelFailedBlock _Nullable)failed;

/// 请求获取LivePhoto
/// @param size 请求图片质量大小，不是尺寸的大小
- (PHImageRequestID)requestLivePhotoWithSize:(CGSize)size
                          startRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                             progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                     success:(HXModelLivePhotoSuccessBlock _Nullable)success
                                      failed:(HXModelFailedBlock _Nullable)failed;

/// 请求获取本地LivePhoto
- (void)requestLocalLivePhotoWithReqeustID:(void (^ _Nullable)(PHLivePhotoRequestID requestID))requestID
                                    header:(void (^ _Nullable)(AVAssetWriter * _Nullable writer, AVAssetReader * _Nullable videoReader, AVAssetReader * _Nullable audioReader))header
                                completion:(HXModelLivePhotoSuccessBlock _Nullable)completion;

/// 请求获取ImageData
- (PHImageRequestID)requestImageDataStartRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                                       progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                               success:(HXModelImageDataSuccessBlock _Nullable)success
                                                failed:(HXModelFailedBlock _Nullable)failed;

- (PHImageRequestID)requestImageDataWithLoadOriginalImage:(BOOL)originalImage
                                       startRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                                          progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                                  success:(HXModelImageDataSuccessBlock _Nullable)success
                                                   failed:(HXModelFailedBlock _Nullable)failed;

/// 请求获取AVAsset
- (PHImageRequestID)requestAVAssetStartRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                                     progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                             success:(HXModelAVAssetSuccessBlock _Nullable)success
                                              failed:(HXModelFailedBlock _Nullable)failed;

/// 请求获取AVAssetExportSession
- (PHImageRequestID)requestAVAssetExportSessionStartRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                                                  progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                                       success:(HXModelAVExportSessionSuccessBlock _Nullable)success
                                                           failed:(HXModelFailedBlock _Nullable)failed;

/// 请求获取AVPlayerItem
- (PHImageRequestID)requestAVPlayerItemStartRequestICloud:(HXModelStartRequestICloud _Nullable)startRequestICloud
                                          progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                               success:(HXModelAVPlayerItemSuccessBlock _Nullable)success
                                                   failed:(HXModelFailedBlock _Nullable)failed;

/// 导出视频
/// @param presetName 视频质量，为空时默认 AVAssetExportPresetMediumQuality
/// @param startRequestICloud 准备开始下载iCloud上的视频，如果视频是iCloud的视频则会先下载
/// @param iCloudProgressHandler iCloud下载进度
/// @param exportProgressHandler 视频导出进度
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
- (PHContentEditingInputRequestID)requestImageURLStartRequestICloud:(void (^ _Nullable)(
                                                                                        PHContentEditingInputRequestID iCloudRequestId,
                                                                                        HXPhotoModel * _Nullable model)
                                                                     )startRequestICloud
                                                    progressHandler:(HXModelProgressHandler _Nullable)progressHandler
                                                            success:(HXModelImageURLSuccessBlock _Nullable)success
                                                             failed:(HXModelFailedBlock _Nullable)failed;

/// 获取Livephoto里的图片和视频地址
- (void)requestLivePhotoAssetsWithSuccess:(HXModelLivePhotoAssetsSuccessBlock _Nullable)success
                                   failed:(HXModelFailedBlock _Nullable)failed;

/// 获取本地图片的URL，内部会将image写入临时目录然后生成文件路径
/// 不是本地图片的会走失败回调
- (void)getCameraImageURLWithSuccess:(HXModelImageURLSuccessBlock _Nullable)success
                              failed:(HXModelFailedBlock _Nullable)failed;

/// 获取当前资源的image，包括本地/网络图片、视频
/// 如果为视频则为视频封面
- (void)getImageWithSuccess:(HXModelImageSuccessBlock _Nullable)success
                     failed:(HXModelFailedBlock _Nullable)failed;

/// 获取当前资源的URL，包括本地/网络图片、视频
/// 此方法导出手机里的视频质量为中等质量
- (void)getAssetURLWithSuccess:(HXModelURLHandler _Nullable)success
                        failed:(HXModelFailedBlock _Nullable)failed;

/// 获取当前资源的URL，包括本地/网络图片、视频
/// @param presetName 视频质量，为空的话默认 AVAssetExportPresetMediumQuality
- (void)getAssetURLWithVideoPresetName:(NSString * _Nullable)presetName
                               success:(HXModelURLHandler _Nullable)success
                                failed:(HXModelFailedBlock _Nullable)failed;

/// 获取原视频地址
- (void)getVideoURLWithSuccess:(HXModelURLHandler _Nullable)success
                        failed:(HXModelFailedBlock _Nullable)failed;

/// 获取图片地址
/// @param resultHandler 获取结果
- (void)getImageURLWithResultHandler:(void (^ _Nullable)(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel))resultHandler;

/// 获取视频地址
/// @param exportPreset 导出的视频分辨率, HXVideoExportPresetRatio_Original 为获取原始视频
/// @param videoQuality 导出的视频质量 [1-10]
/// @param resultHandler 导出结果
- (void)getVideoURLWithExportPreset:(HXVideoExportPreset)exportPreset
                       videoQuality:(NSInteger)videoQuality
                      resultHandler:(void (^ _Nullable)(HXAssetURLResult * _Nullable result, HXPhotoModel * _Nonnull photoModel))resultHandler;

@property (assign, nonatomic) CGFloat previewContentOffsetX;

@end
