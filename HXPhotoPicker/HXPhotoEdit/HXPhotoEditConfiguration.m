//
//  HXPhotoEditConfiguration.m
//  photoEditDemo
//
//  Created by 洪欣 on 2020/7/6.
//  Copyright © 2020 洪欣. All rights reserved.
//

#import "HXPhotoEditConfiguration.h"
#import "UIColor+HXExtension.h"

@implementation HXPhotoEditConfiguration
- (instancetype)init {
    self = [super init];
    if (self) {
        self.maximumLimitTextLength = 0;
        self.supportRotation = YES;
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
        HXPhotoEditChartletTitleModel *netModel = [HXPhotoEditChartletTitleModel modelWithNetworkNURL:[NSURL URLWithString:@"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/xxy_s_highlighted.png"]];
        NSString *prefix = @"http://tsnrhapp.oss-cn-hangzhou.aliyuncs.com/chartle/xxy%d.png";
        NSMutableArray *netModels = @[].mutableCopy;
        for (int i = 1; i <= 40; i++) {
            [netModels addObject:[HXPhotoEditChartletModel modelWithNetworkNURL:[NSURL URLWithString:[NSString stringWithFormat:prefix ,i]]]];
        }
        netModel.models = netModels.copy;
        _chartletModels = @[netModel];
    }
    return _chartletModels;
}
@end
