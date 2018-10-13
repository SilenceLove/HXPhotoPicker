//
//  LFAudioTrackBar.m
//  LFMediaEditingController
//
//  Created by LamTsanFeng on 2017/8/10.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAudioTrackBar.h"
#import "LFMediaEditingHeader.h"
#import "UIView+LFMEFrame.h"

#import <MediaPlayer/MediaPlayer.h>

@implementation LFAudioItem

+ (instancetype)defaultAudioItem
{
    LFAudioItem *item = [self new];
    if (item) {
        item.title = [NSBundle LFME_localizedStringForKey:@"_LFME_defaultAudioItem_name"];
        item.isOriginal = YES;
        item.isEnable = YES;
    }
    return item;
}

@end


@interface LFAudioTrackCell : UITableViewCell



@end

@implementation LFAudioTrackCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
//        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor clearColor];
        self.textLabel.textColor = [UIColor whiteColor];
        self.multipleSelectionBackgroundView = [[UIView alloc] init];
    }
    return self;
}

@end

@interface LFAudioTrackBar () <UITableViewDelegate, UITableViewDataSource, MPMediaPickerControllerDelegate>

@property (nonatomic, strong) NSMutableArray <LFAudioItem *> *m_audioUrls;

@property (nonatomic, weak) UITableView *tableView;

@end

@implementation LFAudioTrackBar

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
    return [self initWithFrame:frame layout:nil];
}

- (instancetype)initWithFrame:(CGRect)frame layout:(void (^)(LFAudioTrackBar *audioTrackBar))layoutBlock
{
    self = [super initWithFrame:frame];
    if (self) {
        _customToolbarHeight = 44.f;
        _customTopbarHeight = 64.f;
        _naviHeight = 44.f;
        if (layoutBlock) {
            layoutBlock(self);
        }
        layoutBlock = nil;
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.f];
    _m_audioUrls = [@[] mutableCopy];
    
    [self configCustomNaviBar];
    [self configTableView];
    [self configToolbar];
}

- (void)configCustomNaviBar
{
    /** 顶部栏 */
    CGFloat margin = 8;
    CGFloat size = _naviHeight;
    UIView *topbar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, _customTopbarHeight)];
    topbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    topbar.backgroundColor = [UIColor clearColor];
    
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat editCancelWidth = [self.cancelButtonTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, size) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width + 30;
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(margin, topbar.height-size, editCancelWidth, size)];
    cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [cancelButton setTitle:self.cancelButtonTitle forState:UIControlStateNormal];
    cancelButton.titleLabel.font = font;
    [cancelButton setTitleColor:self.cancelButtonTitleColorNormal forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat editOkWidth = [self.oKButtonTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, size) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width + 30;
    UIButton *finishButton = [[UIButton alloc] initWithFrame:CGRectMake(self.width - editOkWidth - margin, topbar.height-size, editOkWidth, size)];
    finishButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [finishButton setTitle:self.oKButtonTitle forState:UIControlStateNormal];
    finishButton.titleLabel.font = font;
    [finishButton setTitleColor:self.oKButtonTitleColorNormal forState:UIControlStateNormal];
    [finishButton addTarget:self action:@selector(finishButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    [topbar addSubview:cancelButton];
    [topbar addSubview:finishButton];
    
    [self addSubview:topbar];
}

- (void)configTableView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, _customTopbarHeight, self.width, self.height-_customTopbarHeight-_customToolbarHeight) style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundColor = [UIColor clearColor];
    /** 这个设置iOS9以后才有，主要针对iPad，不设置的话，分割线左侧空出很多 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
    if ([tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }
#pragma clang diagnostic pop
    /** 解决ios7中tableview每一行下面的线向右偏移的问题 */
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    if (@available(iOS 11.0, *)){
        [tableView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }
    tableView.tableFooterView = [[UIView alloc] init];
    tableView.allowsSelection = NO;
    tableView.allowsMultipleSelectionDuringEditing = YES;
    tableView.estimatedRowHeight = 0;
    tableView.estimatedSectionHeaderHeight = 0;
    tableView.estimatedSectionFooterHeight = 0;
    
    tableView.editing = YES;
    [self addSubview:tableView];
    self.tableView = tableView;
}

- (void)configToolbar
{
    UIView *toolbar = [[UIView alloc] initWithFrame:CGRectMake(0, self.height-_customToolbarHeight, self.width, _customToolbarHeight)];
    
    CGFloat rgb = 34 / 255.0;
    toolbar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    
    CGSize size = CGSizeMake(44, 44);
    CGFloat margin = 10.f;
    
    /** 左 */
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame = (CGRect){{margin,0}, size};
    [leftButton setImage:bundleEditImageNamed(@"EditImageTrashBtn.png") forState:UIControlStateNormal];
    [leftButton setImage:bundleEditImageNamed(@"EditImageTrashBtn_HL.png") forState:UIControlStateHighlighted];
    [leftButton setImage:bundleEditImageNamed(@"EditImageTrashBtn_HL.png") forState:UIControlStateSelected];
    [leftButton addTarget:self action:@selector(audioTrackTrash) forControlEvents:UIControlEventTouchUpInside];
    [toolbar addSubview:leftButton];
    
    /** 右 */
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = (CGRect){{CGRectGetWidth(self.frame)-size.width-margin,0}, size};
    [rightButton setImage:bundleEditImageNamed(@"EditImageAddBtn.png") forState:UIControlStateNormal];
    [rightButton setImage:bundleEditImageNamed(@"EditImageAddBtn_HL.png") forState:UIControlStateHighlighted];
    [rightButton setImage:bundleEditImageNamed(@"EditImageAddBtn_HL.png") forState:UIControlStateSelected];
    [rightButton addTarget:self action:@selector(audioTrackAdd) forControlEvents:UIControlEventTouchUpInside];
    [toolbar addSubview:rightButton];
    
    [self addSubview:toolbar];
}


#pragma mark - 顶部栏(action)
- (void)cancelButtonClick
{
    if ([self.delegate respondsToSelector:@selector(lf_audioTrackBarDidCancel:)]) {
        [self.delegate lf_audioTrackBarDidCancel:self];
    }
}

- (void)finishButtonClick
{
    NSMutableArray <LFAudioItem *> *results = [@[] mutableCopy];
    for (NSInteger i=0; i<self.m_audioUrls.count; i++) {
        LFAudioItem *item = self.m_audioUrls[i];
        [results addObject:item];
    }
    
    if ([self.delegate respondsToSelector:@selector(lf_audioTrackBar:didFinishAudioUrls:)]) {
        [self.delegate lf_audioTrackBar:self didFinishAudioUrls:results];
    }
}

- (void)audioTrackTrash
{
    NSMutableArray <LFAudioItem *>*deleteItems = [@[] mutableCopy];
    for (LFAudioItem *item in self.m_audioUrls) {
        if (item.isOriginal) {
            continue;
        }
        if (item.isEnable) {
            [deleteItems addObject:item];
        }
    }
    if (deleteItems.count) {
        [self.m_audioUrls removeObjectsInArray:deleteItems];;
        [self.tableView reloadData];
    }
}

- (void)audioTrackAdd
{
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    picker.prompt = [NSBundle LFME_localizedStringForKey:@"_LFME_MediaPicker_prompt"];   //弹出选择播放歌曲的提示
    picker.showsCloudItems = YES;     //显示为下载的歌曲
    picker.allowsPickingMultipleItems = YES;  //是否允许多选
    picker.delegate = self;
    [self.delegate presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView beginUpdates];
    LFAudioItem *item = self.m_audioUrls[indexPath.row];
    item.isEnable = YES;
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [tableView endUpdates];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView beginUpdates];
    LFAudioItem *item = self.m_audioUrls[indexPath.row];
    item.isEnable = NO;
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [tableView endUpdates];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.m_audioUrls.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *audioTrackCellIdentifier = @"audioTrackCellIdentifier";
    
    LFAudioTrackCell *cell = [tableView dequeueReusableCellWithIdentifier:audioTrackCellIdentifier];
    if (cell == nil) {
        cell = [[LFAudioTrackCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:audioTrackCellIdentifier];
    }
    LFAudioItem *item = self.m_audioUrls[indexPath.row];
    cell.textLabel.text = item.title;
    
    if (item.isEnable) {
        [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - MPMediaPickerControllerDelegate
- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection{
    NSMutableArray *mediaUrls = [@[] mutableCopy];
    for (MPMediaItem* mediaItem in [mediaItemCollection items]) {
        NSURL *url = mediaItem.assetURL;
        if (url && [mediaUrls containsObject:url] == NO) {
            [mediaUrls addObject:url];
            LFAudioItem *item = [LFAudioItem new];
            item.title = mediaItem.title;
            item.url = url;
            item.isEnable = YES;
            [self.m_audioUrls addObject:item];
        }
    }
    
    if (mediaUrls.count) {
        [self.tableView reloadData];
    }
    
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - getter/setter
- (NSArray<NSURL *> *)audioUrls
{
    return [self.m_audioUrls copy];
}

- (void)setAudioUrls:(NSArray<LFAudioItem *> *)audioUrls
{
    self.m_audioUrls = [@[] mutableCopy];
    if (audioUrls.count) {
        for (LFAudioItem *item in audioUrls) {
            [self.m_audioUrls addObject:item];
        }
    }
}

@end
