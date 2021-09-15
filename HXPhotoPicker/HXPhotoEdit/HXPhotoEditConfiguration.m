//
//  HXPhotoEditConfiguration.m
//  photoEditDemo
//
//  Created by Silence on 2020/7/6.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditConfiguration.h"
#import "UIColor+HXExtension.h"

@implementation HXPhotoEditConfiguration
- (instancetype)init {
    self = [super init];
    if (self) {
        self.maximumLimitTextLength = 0;
        self.supportRotation = YES;
        self.clippingMinSize = CGSizeMake(80, 80);
        self.supportedInterfaceOrientations = UIInterfaceOrientationMaskPortrait;
    }
    return self;
}
- (CGFloat)brushLineMaxWidth {
    if (!_brushLineMaxWidth) {
        _brushLineMaxWidth = 12.f;
    }
    return _brushLineMaxWidth;
}
- (CGFloat)brushLineMinWidth {
    if (!_brushLineMinWidth) {
        _brushLineMinWidth = 3.f;
    }
    return _brushLineMinWidth;
}
- (UIColor *)themeColor {
    if (!_themeColor) {
        _themeColor = [UIColor hx_colorWithHexStr:@"#07C160"];
    }
    return _themeColor;
}
- (NSArray<UIColor *> *)drawColors {
    if (!_drawColors) {
        _drawColors = @[[UIColor hx_colorWithHexStr:@"#ffffff"], [UIColor hx_colorWithHexStr:@"#2B2B2B"], [UIColor hx_colorWithHexStr:@"#FA5150"], [UIColor hx_colorWithHexStr:@"#FEC200"], [UIColor hx_colorWithHexStr:@"#07C160"], [UIColor hx_colorWithHexStr:@"#10ADFF"], [UIColor hx_colorWithHexStr:@"#6467EF"]];
        self.defaultDarwColorIndex = 2;
    }
    return _drawColors;
}
- (NSArray<UIColor *> *)textColors {
    if (!_textColors) {
        _textColors = @[[UIColor hx_colorWithHexStr:@"#ffffff"], [UIColor hx_colorWithHexStr:@"#2B2B2B"], [UIColor hx_colorWithHexStr:@"#FA5150"], [UIColor hx_colorWithHexStr:@"#FEC200"], [UIColor hx_colorWithHexStr:@"#07C160"], [UIColor hx_colorWithHexStr:@"#10ADFF"], [UIColor hx_colorWithHexStr:@"#6467EF"]];
    }
    return _textColors;
}
- (UIFont *)textFont {
    if (!_textFont) {
        _textFont = [UIFont boldSystemFontOfSize:25];
    }
    return _textFont;
}
- (NSArray<HXPhotoEditChartletTitleModel *> *)chartletModels {
    if (!_chartletModels) {
        HXPhotoEditChartletTitleModel *netModel = [HXPhotoEditChartletTitleModel modelWithImageNamed:@"hx_sticker_cover"];
        
        NSArray *imageNames = @[@"chongya", @"jintianfenkeai", @"keaibiaoq", @"saihong", @"xiaochuzhujiao", @"yuanqimanman", @"yuanqishaonv", @"zaizaijia", @"haoxinqing", @"housailei", @"kehaixing", @"wow", @"woxiangfazipai" ];
        NSMutableArray *models = [NSMutableArray array];
        for (NSString *imageNamed in imageNames) {
            HXPhotoEditChartletModel *subModel = [HXPhotoEditChartletModel modelWithImageNamed:[NSString stringWithFormat:@"hx_sticker_%@", imageNamed]];
            [models addObject:subModel];
        }
        netModel.models = models.copy;
        _chartletModels = @[netModel];
    }
    return _chartletModels;
}
@end
