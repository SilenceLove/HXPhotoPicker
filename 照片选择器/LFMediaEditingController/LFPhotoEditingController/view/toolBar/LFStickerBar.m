//
//  LFStickerBar.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/21.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFStickerBar.h"
#import "LFMediaEditingHeader.h"
#import "UIView+LFMEFrame.h"
#import "LFEditCollectionView.h"

CGFloat const lf_stickerSize = 80;
CGFloat const lf_stickerMargin = 10;

#define kImageExtensions @[@"png", @"jpg", @"jpeg", @"gif"]

#pragma mark - LFStickerCollectionViewCell
@interface LFStickerCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) UIImageView *lf_imageView;

+ (NSString *)identifier;
@end

@implementation LFStickerCollectionViewCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat width = self.contentView.frame.size.width;
    CGFloat height = self.contentView.frame.size.height;
    self.lf_imageView.frame = CGRectMake(0, 0, width, height);
}

- (void)customInit
{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:imageView];
    self.lf_imageView = imageView;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.lf_imageView.image = nil;
}

+ (NSString *)identifier
{
    return NSStringFromClass([LFStickerCollectionViewCell class]);
}

@end

@interface LFStickerBar () <UIScrollViewDelegate>

@property (nonatomic, strong) NSString *resourcePath;
@property (nonatomic, strong) NSArray<NSString *> *files;

@property (nonatomic, weak) LFEditCollectionView *lf_collectionViewSticker;

/* 外置资源 */
@property (nonatomic, assign) BOOL external;

/* 记录自身高度 */
@property (nonatomic, assign) CGFloat myHeight;

@end

@implementation LFStickerBar

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _myHeight = frame.size.height;
        [self customInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame resourcePath:(NSString *)resourcePath
{
    self = [super initWithFrame:frame];
    if (self) {
        _myHeight = frame.size.height;
        _resourcePath = resourcePath;
        [self customInit];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (@available(iOS 11.0, *)) {
        self.lf_collectionViewSticker.height = self.height - self.safeAreaInsets.bottom;
    }
}

- (void)customInit
{
    if (iOS8Later) {
        // 定义毛玻璃效果
        self.backgroundColor = [UIColor clearColor];
        UIBlurEffect * blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView * effe = [[UIVisualEffectView alloc]initWithEffect:blur];
        effe.frame = self.bounds;
        [self addSubview:effe];
    } else {
        self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.8];
    }
    self.userInteractionEnabled = YES;
    /** 添加按钮获取点击 */
    UIButton *bgButton = [UIButton buttonWithType:UIButtonTypeCustom];
    bgButton.frame = self.bounds;
    [self addSubview:bgButton];
    
    NSFileManager *fileManager = [NSFileManager new];
    if (self.resourcePath && [fileManager fileExistsAtPath:self.resourcePath]) {
        NSArray *files = [fileManager contentsOfDirectoryAtPath:self.resourcePath error:nil];
        NSMutableArray *newFiles = [@[] mutableCopy];
        for (NSString *fileName in files) {
            if ([kImageExtensions containsObject:[fileName.pathExtension lowercaseString]]) {
                [newFiles addObject:fileName];
            }
        }
        self.files = [newFiles copy];
        self.external = YES;
    } else {
        NSString *path = [NSBundle LFME_stickersPath];
        self.files = [fileManager contentsOfDirectoryAtPath:path error:nil];
    }
    
    [self setupCollectionView];
}

- (void)setupCollectionView
{
    LFEditCollectionView *lf_collectionViewSticker = [[LFEditCollectionView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
    [lf_collectionViewSticker setBackgroundColor:[UIColor clearColor]];
    
    lf_collectionViewSticker.itemSize = CGSizeMake(lf_stickerSize, lf_stickerSize);
    lf_collectionViewSticker.sectionInset = UIEdgeInsetsMake(lf_stickerMargin, lf_stickerMargin, lf_stickerMargin, lf_stickerMargin);
    lf_collectionViewSticker.minimumInteritemSpacing = lf_stickerMargin;
    lf_collectionViewSticker.minimumLineSpacing = lf_stickerMargin;
    
    [lf_collectionViewSticker registerClass:[LFStickerCollectionViewCell class] forCellWithReuseIdentifier:[LFStickerCollectionViewCell identifier]];
    
    if (self.files.count) {
        lf_collectionViewSticker.dataSources = @[self.files];
    }
    
    __weak typeof(self) weakSelf = self;
    [lf_collectionViewSticker callbackCellIdentifier:^NSString * _Nonnull(NSIndexPath * _Nonnull indexPath) {
        return [LFStickerCollectionViewCell identifier];
    } configureCell:^(NSIndexPath * _Nonnull indexPath, id  _Nonnull item, UICollectionViewCell * _Nonnull cell) {
        UIImage * backImage = nil;
        if (weakSelf.external) {
            backImage = [UIImage imageWithContentsOfFile:[weakSelf.resourcePath stringByAppendingPathComponent:item]];
        } else {
            backImage = bundleStickerImageNamed(item);
        }
        ((LFStickerCollectionViewCell *)cell).lf_imageView.image = backImage;
    } didSelectItemAtIndexPath:^(NSIndexPath * _Nonnull indexPath, id  _Nonnull item) {
        if ([weakSelf.delegate respondsToSelector:@selector(lf_stickerBar:didSelectImage:)]) {
            UIImage * backImage = nil;
            if (weakSelf.external) {
                backImage = [UIImage imageWithContentsOfFile:[weakSelf.resourcePath stringByAppendingPathComponent:item]];
            } else {
                backImage = bundleStickerImageNamed(item);
            }
            [weakSelf.delegate lf_stickerBar:weakSelf didSelectImage:backImage];
        }
    }];
    
    [self addSubview:lf_collectionViewSticker];
    self.lf_collectionViewSticker = lf_collectionViewSticker;
}


@end
