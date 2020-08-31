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
        HXPhotoEditChartletTitleModel *netModel = [HXPhotoEditChartletTitleModel modelWithImageNamed:@"hx_sticker_cover"];
        
        HXPhotoEditChartletModel *subModel1 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_chongya"];
        HXPhotoEditChartletModel *subModel2 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_jintianfenkeai"];
        HXPhotoEditChartletModel *subModel3 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_keaibiaoq"];
        HXPhotoEditChartletModel *subModel4 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_saihong"];
        HXPhotoEditChartletModel *subModel5 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_xiaochuzhujiao"];
        HXPhotoEditChartletModel *subModel6 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_yuanqimanman"];
        HXPhotoEditChartletModel *subModel7 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_yuanqishaonv"];
        HXPhotoEditChartletModel *subModel8 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_zaizaijia"];
        HXPhotoEditChartletModel *subModel9 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_haoxinqing"];
        HXPhotoEditChartletModel *subModel10 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_housailei"];
        HXPhotoEditChartletModel *subModel11 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_kehaixing"];
        HXPhotoEditChartletModel *subModel12 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_wow"];
        HXPhotoEditChartletModel *subModel13 = [HXPhotoEditChartletModel modelWithImageNamed:@"hx_sticker_woxiangfazipai"];
        netModel.models = @[subModel1, subModel2, subModel3, subModel4, subModel5, subModel6, subModel7, subModel8, subModel9, subModel10, subModel11, subModel12, subModel13];
        _chartletModels = @[netModel];
    }
    return _chartletModels;
}
@end
