//
//  JRStrainImageShowViewCell.m
//  JRCollectionView
//
//  Created by Mr.D on 2018/8/6.
//  Copyright © 2018年 Mr.D. All rights reserved.
//

#import "JRFilterBarCell.h"
#import "JRFilterModel.h"

CGFloat const JR_LABEL_HEIGHT = 25.f;


@interface JRFilterBarCell ()

@property (nonatomic, weak) UIImageView *showImgView;

@property (nonatomic, weak) UILabel *bottomLab;

@property (nonatomic, strong) dispatch_queue_t serialQueue;

@end

@implementation JRFilterBarCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        _serialQueue = dispatch_queue_create("JRFilterBarCellQueue", DISPATCH_QUEUE_SERIAL);
        [self _createShowImageView_jr];
    } return self;
}

+ (NSString *)identifier {
    return NSStringFromClass([JRFilterBarCell class]);
}

- (void)setCellData:(JRFilterModel *)cellData image:(UIImage *)image{
    dispatch_async(self.serialQueue, ^{
        [cellData createFilterImage:image];
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.showImgView.image = cellData.image;
        });
    });
    self.bottomLab.text = cellData.name;
}

- (void)setIsSelectedModel:(BOOL)isSelectedModel
{
    UIColor *color;
    if (isSelectedModel) {
        color = self.selectColor;
    } else {
        color = self.defaultColor;
    }
    self.showImgView.layer.borderWidth = 2.5f;
    self.showImgView.layer.borderColor = color.CGColor;
    self.bottomLab.textColor = color;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect viewR = self.contentView.bounds;
    viewR.size.height -= JR_LABEL_HEIGHT;

    self.showImgView.frame = viewR;

    CGRect labViewR = CGRectMake(2.5f, CGRectGetMaxY(viewR), CGRectGetWidth(viewR)-5.f, JR_LABEL_HEIGHT);
    self.bottomLab.frame = labViewR;
}

- (void)_createShowImageView_jr {
    if (!self.showImgView) {
        UIImageView *aImgView = [[UIImageView alloc] initWithFrame:self.contentView.frame];
        aImgView.contentMode = UIViewContentModeScaleAspectFill;
        aImgView.clipsToBounds = YES;
        [self.contentView addSubview:aImgView];
        self.showImgView = aImgView;
    }
    if (!self.bottomLab) {
        UILabel *aLab = [[UILabel alloc] initWithFrame:self.contentView.frame];
        aLab.font = [UIFont systemFontOfSize:15.f];
        aLab.textAlignment = NSTextAlignmentCenter;
        aLab.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [self.contentView addSubview:aLab];
        self.bottomLab = aLab;
    }
}

@end
