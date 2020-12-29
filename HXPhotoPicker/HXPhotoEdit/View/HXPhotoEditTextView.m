//
//  HXPhotoEditTextView.m
//  photoEditDemo
//
//  Created by Silence on 2020/6/22.
//  Copyright © 2020 Silence. All rights reserved.
//

#import "HXPhotoEditTextView.h"
#import "UIView+HXExtension.h"
#import "HXPhotoEditGraffitiColorViewCell.h"
#import "HXPhotoDefine.h"
#import "UIImage+HXExtension.h"
#import "UIColor+HXExtension.h"
#import "HXPhotoEditConfiguration.h"
#import "NSBundle+HXPhotoPicker.h"
#import "UIFont+HXExtension.h"
#import "HXPhotoTools.h"

#define HXEditTextBlankWidth 22
#define HXEditTextRadius 8.f
#define HXEditTextBottomViewMargin ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortrait || [[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationPortraitUpsideDown) ? hxBottomMargin : 10

@interface HXPhotoEditTextView ()<UITextViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSLayoutManagerDelegate>
@property (nonatomic, strong) NSMutableArray *rectArray;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *doneBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewRightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topRightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomRightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomLeftConstraint;

@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIButton *textBtn;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;
@property (strong, nonatomic) NSMutableArray *colorModels;
@property (strong, nonatomic) HXPhotoEditGraffitiColorModel *currentSelectModel;
@property (assign, nonatomic) NSRange currentTextRange;
@property (assign, nonatomic) BOOL currentIsBlank;
@property (assign, nonatomic) BOOL isDelete;
@property (copy, nonatomic) void (^ completion)(HXPhotoEditTextModel *textModel);
@property (strong, nonatomic) HXPhotoEditTextModel *textModel;
/// 将字体属性记录成公用的, 然后在每次UITextview的内容将要发生变化的时候，重置一下它的该属性。
@property (copy, nonatomic) NSDictionary *typingAttributes;

@property (strong, nonatomic) HXPhotoEditTextLayer *textLayer;
@property (strong, nonatomic) UIColor *useBgColor;
@property (assign, nonatomic) BOOL showBackgroudColor;
@property (assign, nonatomic) NSInteger maxIndex;
@property (assign, nonatomic) BOOL textIsDelete;
@end

@implementation HXPhotoEditTextView

+ (instancetype)showEitdTextViewWithConfiguration:(HXPhotoEditConfiguration *)configuration
                                       completion:(void (^ _Nullable)(HXPhotoEditTextModel *textModel))completion {
    return [self showEitdTextViewWithConfiguration:configuration textModel:nil completion:completion];
}

+ (instancetype)showEitdTextViewWithConfiguration:(HXPhotoEditConfiguration *)configuration
                                        textModel:(HXPhotoEditTextModel *)textModel
                                       completion:(void (^)(HXPhotoEditTextModel * _Nonnull))completion {
    HXPhotoEditTextView *view = [HXPhotoEditTextView initView];
    view.configuration = configuration;
    view.textModel = textModel;
    view.textColors = configuration.textColors;
    view.completion = completion;
    view.frame = [UIScreen mainScreen].bounds;
    view.hx_y = view.hx_h;
    [[UIApplication sharedApplication].keyWindow addSubview:view];
    [view show];
    return view;
}
+ (instancetype)initView {
    return [[[NSBundle hx_photoPickerBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] lastObject];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
- (void)awakeFromNib {
    [super awakeFromNib];
    [self.cancelBtn setTitle:[NSBundle hx_localizedStringForKey:@"取消"] forState:UIControlStateNormal];
    self.cancelBtn.titleLabel.font = [UIFont hx_mediumPingFangOfSize:16];
    [self.doneBtn setTitle:[NSBundle hx_localizedStringForKey:@"完成"] forState:UIControlStateNormal];
    self.doneBtn.titleLabel.font = [UIFont hx_mediumPingFangOfSize:16];
    self.textBtn.layer.cornerRadius = 1.f;
    [self.textBtn setImage:[UIImage hx_imageContentsOfFile:@"hx_photo_edit_text_ normal"] forState:UIControlStateNormal];
    [self.textBtn setImage:[UIImage hx_imageContentsOfFile:@"hx_photo_edit_text_selected"] forState:UIControlStateSelected];
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
        self.topViewHeightConstraint.constant = 50;
        self.topLeftConstraint.constant = hxTopMargin;
        self.topRightConstraint.constant = hxTopMargin;
        self.bottomLeftConstraint.constant = hxTopMargin;
        self.bottomRightConstraint.constant = hxTopMargin;
        self.bottomViewHeightConstraint.constant = 50.f;
        self.textViewLeftConstraint.constant = hxTopMargin;
        self.textViewRightConstraint.constant = hxTopMargin;
    }else {
        self.bottomViewHeightConstraint.constant = 60.f;
        self.textViewLeftConstraint.constant = 10.f;
        self.textViewRightConstraint.constant = 10.f;
        self.topViewHeightConstraint.constant = hxNavigationBarHeight;
    }

    self.bottomViewBottomConstraint.constant = HXEditTextBottomViewMargin;
    [self.doneBtn hx_radiusWithRadius:3 corner:UIRectCornerAllCorners];
    
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.delegate = self;
    self.textView.layoutManager.delegate = self;
    CGFloat xMargin = 15, yMargin = 15;
    // 使用textContainerInset设置top、leaft、right
    self.textView.textContainerInset = UIEdgeInsetsMake(yMargin, xMargin, yMargin, xMargin);
    self.textView.contentInset = UIEdgeInsetsZero;
    
    [self.textView becomeFirstResponder];
    
    self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 20);
    self.flowLayout.minimumInteritemSpacing = 5;
    self.flowLayout.itemSize = CGSizeMake(30.f, 30.f);
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([HXPhotoEditGraffitiColorViewCell class]) bundle:[NSBundle hx_photoPickerBundle]] forCellWithReuseIdentifier:NSStringFromClass([HXPhotoEditGraffitiColorViewCell class])];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillAppearance:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationWillChanged) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
}
- (void)deviceOrientationWillChanged {
    [self.textView endEditing:YES];
    [self removeFromSuperview];
}
- (void)setConfiguration:(HXPhotoEditConfiguration *)configuration {
    _configuration = configuration;
    self.textView.tintColor = configuration.themeColor;
    [self.doneBtn setBackgroundColor:configuration.themeColor];
}
- (void)setTextAttributes {
    self.textView.font = self.configuration.textFont;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 8.f;
    NSDictionary *attributes = @{
                                 NSFontAttributeName: self.configuration.textFont,
                                 NSParagraphStyleAttributeName : paragraphStyle
                                 };
    self.typingAttributes = attributes;
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.textModel.text? : @"" attributes:attributes];
}
- (HXPhotoEditTextLayer *)createTextBackgroudColorWithPath:(CGPathRef)path {
    HXPhotoEditTextLayer *shapeLayer = [HXPhotoEditTextLayer layer];
    shapeLayer.path = path;
    shapeLayer.lineWidth = 0.f;
    CGColorRef color = self.showBackgroudColor ? self.useBgColor.CGColor : [UIColor clearColor].CGColor;
    shapeLayer.strokeColor = color;
    shapeLayer.fillColor = color;
    return shapeLayer;
}
- (void)setTextModel:(HXPhotoEditTextModel *)textModel {
    _textModel = textModel;
    self.textView.text = textModel.text;
    self.showBackgroudColor = textModel.showBackgroud;
    self.textBtn.selected = textModel.showBackgroud;
    [self setTextAttributes];
}
- (void)setTextColors:(NSArray<UIColor *> *)textColors {
    _textColors = textColors;
    self.colorModels = @[].mutableCopy;
    for (UIColor *color in textColors) {
        HXPhotoEditGraffitiColorModel *model = [[HXPhotoEditGraffitiColorModel alloc] init];
        model.color = color;
        [self.colorModels addObject:model];
        if (self.textModel) {
            if (color == self.textModel.textColor) {
                if (self.textModel.showBackgroud) {
                    if ([model.color hx_colorIsWhite]) {
                        [self changeTextViewTextColor:[UIColor blackColor]];
                    }else {
                        [self changeTextViewTextColor:[UIColor whiteColor]];
                    }
                    self.useBgColor = model.color;
                }else {
                    [self changeTextViewTextColor:color];
                }
                model.selected = YES;
                self.currentSelectModel = model;
            }
        }else {
            if (self.colorModels.count == 1) {
                [self changeTextViewTextColor:color];
                model.selected = YES;
                self.currentSelectModel = model;
            }
        }
    }
    [self.collectionView reloadData];
    if (self.textBtn.selected) {
        [self drawTextBackgroudColor];
    }
}
- (void)changeTextViewTextColor:(UIColor *)color {
    self.textView.textColor = color;
    NSMutableDictionary *dicy = self.typingAttributes.mutableCopy;
    [dicy setObject:color forKey:NSForegroundColorAttributeName];
    self.typingAttributes = dicy.copy;
    self.textView.typingAttributes = self.typingAttributes;
}
- (void)keyboardWillAppearance:(NSNotification *)notification {
    NSInteger duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] integerValue];
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat height = keyboardFrame.size.height;
    [UIView animateWithDuration:duration animations:^{
        self.bottomViewBottomConstraint.constant = height;
        [self layoutIfNeeded];
    }];
}

- (void)keyboardWillDismiss:(NSNotification *)notification {
    NSInteger duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] integerValue];
    [UIView animateWithDuration:duration animations:^{
        self.bottomViewBottomConstraint.constant = HXEditTextBottomViewMargin;
        [self layoutIfNeeded];
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.colorModels.count;
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoEditGraffitiColorViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([HXPhotoEditGraffitiColorViewCell class]) forIndexPath:indexPath];
    cell.model = self.colorModels[indexPath.item];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoEditGraffitiColorModel *model = self.colorModels[indexPath.item];
    if (self.currentSelectModel == model) {
        return;
    }
    if (self.currentSelectModel.selected) {
        self.currentSelectModel.selected = NO;
        HXPhotoEditGraffitiColorViewCell *beforeCell = (HXPhotoEditGraffitiColorViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:[self.colorModels indexOfObject:self.currentSelectModel] inSection:0]];
        [beforeCell setSelected:NO];
    }
    model.selected = YES;
    self.currentSelectModel = model;
    if (self.showBackgroudColor) {
        self.useBgColor = model.color;
        if ([model.color hx_colorIsWhite]) {
            [self changeTextViewTextColor:[UIColor blackColor]];
        }else {
            [self changeTextViewTextColor:[UIColor whiteColor]];
        }
    }else {
        [self changeTextViewTextColor:model.color];
    }
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}
- (void)textViewDidChange:(UITextView *)textView {
    textView.typingAttributes = self.typingAttributes;
    if (self.textIsDelete) {
        [self drawTextBackgroudColor];
        self.textIsDelete = NO;
    }
//    [self contentSizeToFit];
    if (!self.textView.text.length) {
        self.textLayer.frame = CGRectZero;
        return;
    }else {
        if (textView.text.length > self.configuration.maximumLimitTextLength &&
            self.configuration.maximumLimitTextLength > 0) {
            textView.text = [textView.text substringToIndex:self.configuration.maximumLimitTextLength];
        }
    }
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (!text.length) {
        self.textIsDelete = YES;
    }
    return YES;
}
//- (void)contentSizeToFit {
//    //先判断一下有没有文字（没文字就没必要设置居中了）
//    if([self.textView.text length] > 0) {
//        //textView的contentSize属性
//        CGSize contentSize = self.textView.contentSize;
//        //textView的内边距属性
//        UIEdgeInsets offset;
//        CGSize newSize = contentSize;
//        //如果文字内容高度没有超过textView的高度
//        if(contentSize.height <= self.textView.frame.size.height) {
//            //textView的高度减去文字高度除以2就是Y方向的偏移量，也就是textView的上内边距
//            CGFloat offsetY = (self.textView.frame.size.height - contentSize.height) / 2;
//            offset = UIEdgeInsetsMake(offsetY, 0, 0, 0);
//        }else { //如果文字高度超出textView的高度
//            newSize = self.textView.frame.size;
//            offset = UIEdgeInsetsZero;
//            newSize = contentSize;
//        }
//
//        //根据前面计算设置textView的ContentSize和Y方向偏移量
//        [self.textView setContentSize:newSize];
//        [self.textView setContentInset:offset];
//    }
//}
- (IBAction)didCancelClick:(id)sender {
    [self hide];
}
- (IBAction)didDoneClick:(id)sender {
    [self.textView resignFirstResponder];
    if (!self.textView.text.length) {
        [self hide];
        return;
    }
    if (self.completion) {
        HXPhotoEditTextModel *textModel = [[HXPhotoEditTextModel alloc] init];
        for (UIView *view in self.textView.subviews) {
            if ([view isKindOfClass:NSClassFromString(@"_UITextContainerView")]) {
                textModel.image = [self snapshotCALayer:view];
                view.layer.contents = (id)nil;
                break;
            }
        }
        textModel.text = self.textView.text;
        textModel.textColor = self.currentSelectModel.color;
        textModel.showBackgroud = self.showBackgroudColor;
        self.completion(textModel);
    }
    [self hide];
}
- (CGFloat)getTextMaximumWidthWithView:(UIView *)view {
    CGSize newSize = [self.textView sizeThatFits:CGSizeMake(view.hx_w, view.hx_h)];
    return newSize.width;
}
- (UIImage *)snapshotCALayer:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake([self getTextMaximumWidthWithView:view], view.hx_h), NO, [UIScreen mainScreen].scale);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
- (IBAction)didTextBtnClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.showBackgroudColor = sender.selected;
    self.useBgColor = self.currentSelectModel.color;
    if (sender.selected) {
        if ([self.currentSelectModel.color hx_colorIsWhite]) {
            [self changeTextViewTextColor:[UIColor blackColor]];
        }else {
            [self changeTextViewTextColor:[UIColor whiteColor]];
        }
    }else {
        [self changeTextViewTextColor:self.currentSelectModel.color];
    }
}
- (void)show {
    [UIView animateWithDuration:0.3 animations:^{
        self.hx_y = 0;
    }];
}
- (void)hide {
    [self.textView endEditing:YES];
    [UIView animateWithDuration:0.3 animations:^{
        self.hx_y = self.hx_h;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
- (void)layoutManager:(NSLayoutManager *)layoutManager didCompleteLayoutForTextContainer:(NSTextContainer *)textContainer atEnd:(BOOL)layoutFinishedFlag {
    if (layoutFinishedFlag) {
        [self drawTextBackgroudColor];
    }
}

- (void)drawTextBackgroudColor {
    if (!self.textView.text.length) {
        self.textLayer.path = nil;
        return;
    }
    NSRange range = [self.textView.layoutManager characterRangeForGlyphRange:NSMakeRange(0, self.textView.text.length)
                                     actualGlyphRange:NULL];
    NSRange glyphRange = [self.textView.layoutManager glyphRangeForCharacterRange:range
                                      actualCharacterRange:NULL];
    NSMutableArray *rectArray = @[].mutableCopy;
    HXWeakSelf
    [self.textView.layoutManager enumerateLineFragmentsForGlyphRange:glyphRange usingBlock:^(CGRect rect, CGRect usedRect, NSTextContainer * _Nonnull textContainer, NSRange glyphRange, BOOL * _Nonnull stop) {
        CGRect newRect = usedRect;
        NSString *glyphStr = (weakSelf.textView.text.length >= (glyphRange.location + glyphRange.length) && weakSelf.textView.text.length) ? [weakSelf.textView.text substringWithRange:glyphRange] : nil;
        if (glyphStr.length > 0 && [[glyphStr substringWithRange:NSMakeRange(glyphStr.length - 1, 1)] isEqualToString:@"\n"]) {
            newRect = CGRectMake(newRect.origin.x - 6, newRect.origin.y - 8, newRect.size.width + 12, newRect.size.height + 8);
        }else {
            newRect = CGRectMake(newRect.origin.x - 6, newRect.origin.y - 8, newRect.size.width + 12, newRect.size.height + 16);
        }
        NSValue *value = [NSValue valueWithCGRect:newRect];
        [rectArray addObject:value];
    }];
    UIBezierPath *path = [self drawBackgroundWithRectArray:rectArray];
    CGColorRef color = self.showBackgroudColor ? self.useBgColor.CGColor : [UIColor clearColor].CGColor;
    if (self.textLayer) {
        self.textLayer.path = path.CGPath;
        self.textLayer.strokeColor = color;
        self.textLayer.fillColor = color;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.textLayer.frame = CGRectMake(15, 15, path.bounds.size.width, self.textView.contentSize.height);
        [CATransaction commit];
    }else {
        for (UIView *view in self.textView.subviews) {
            if ([view isKindOfClass:NSClassFromString(@"_UITextContainerView")]) {
                self.textLayer = [self createTextBackgroudColorWithPath:path.CGPath];
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                self.textLayer.frame = CGRectMake(15, 15, path.bounds.size.width, self.textView.contentSize.height);
                [CATransaction commit];
                [view.layer insertSublayer:self.textLayer atIndex:0];
                break;
            }
        }
    }
}

- (UIBezierPath *)drawBackgroundWithRectArray:(NSMutableArray *)rectArray {
    self.rectArray = rectArray;
    [self preProccess];
    UIBezierPath *path = [UIBezierPath bezierPath];
//    if (self.showBackgroudColor) {
        UIBezierPath *bezierPath;
        CGPoint startPoint = CGPointZero;
        for (int i = 0; i < self.rectArray.count; i++) {
            NSValue *curValue = [self.rectArray objectAtIndex:i];
            CGRect cur = curValue.CGRectValue;
            if (cur.size.width <= HXEditTextBlankWidth) {
                continue;
            }
            CGFloat loctionX = cur.origin.x;
            CGFloat loctionY = cur.origin.y;
            BOOL half = NO;
            if (!bezierPath) {
                // 设置起点
                bezierPath = [UIBezierPath bezierPath];
                startPoint = CGPointMake(loctionX , loctionY + HXEditTextRadius);
                [bezierPath moveToPoint:startPoint];
                [bezierPath addArcWithCenter:CGPointMake(loctionX + HXEditTextRadius, loctionY + HXEditTextRadius) radius:HXEditTextRadius startAngle:M_PI endAngle:1.5 * M_PI clockwise:YES];
                [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(cur) - HXEditTextRadius, loctionY)];
                [bezierPath addArcWithCenter:CGPointMake(CGRectGetMaxX(cur) - HXEditTextRadius, loctionY + HXEditTextRadius) radius:HXEditTextRadius startAngle:M_PI * 1.5 endAngle:0 clockwise:YES];
            }else {
                NSValue *lastCurValue = [self.rectArray objectAtIndex:i - 1];
                CGRect lastCur = lastCurValue.CGRectValue;
                CGRect nextCur;
                if (CGRectGetMaxX(lastCur) > CGRectGetMaxX(cur)) {
                    if (i + 1 < self.rectArray.count) {
                        NSValue *nextCurValue = [self.rectArray objectAtIndex:i + 1];
                        nextCur = nextCurValue.CGRectValue;
                        if (nextCur.size.width > HXEditTextBlankWidth) {
                            if (CGRectGetMaxX(nextCur) > CGRectGetMaxX(cur)) {
                                half = YES;
                            }
                        }
                    }
                    if (half) {
                        CGFloat radius = (nextCur.origin.y - CGRectGetMaxY(lastCur)) / 2;
                        CGFloat centerY = nextCur.origin.y - radius;
                        [bezierPath addArcWithCenter:CGPointMake(CGRectGetMaxX(cur) + radius, centerY) radius:radius startAngle:-0.5 * M_PI endAngle:-1.5 * M_PI clockwise:NO];
                    }else {
                        [bezierPath addArcWithCenter:CGPointMake(CGRectGetMaxX(cur) + HXEditTextRadius, CGRectGetMaxY(lastCur) + HXEditTextRadius) radius:HXEditTextRadius startAngle:-0.5 * M_PI endAngle:-M_PI clockwise:NO];
                    }
                }else if (CGRectGetMaxX(lastCur) == CGRectGetMaxX(cur)) {
                    [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(cur), CGRectGetMaxY(cur) - HXEditTextRadius)];
                }else {
                    [bezierPath addArcWithCenter:CGPointMake(CGRectGetMaxX(cur) - HXEditTextRadius, cur.origin.y + HXEditTextRadius) radius:HXEditTextRadius startAngle:1.5 * M_PI endAngle:0.f clockwise:YES];
                }
            }
            BOOL hasNext = NO;
            if (i + 1 < self.rectArray.count) {
                NSValue *nextCurValue = [self.rectArray objectAtIndex:i + 1];
                CGRect nextCur = nextCurValue.CGRectValue;
                if (nextCur.size.width > HXEditTextBlankWidth) {
                    if (CGRectGetMaxX(cur) > CGRectGetMaxX(nextCur)) {
                        CGPoint point = CGPointMake(CGRectGetMaxX(cur), CGRectGetMaxY(cur) - HXEditTextRadius);
                        if (!CGPointEqualToPoint(point, bezierPath.currentPoint)) {
                            [bezierPath addLineToPoint:point];
                            [bezierPath addArcWithCenter:CGPointMake(CGRectGetMaxX(cur) - HXEditTextRadius, CGRectGetMaxY(cur) - HXEditTextRadius) radius:HXEditTextRadius startAngle:0 endAngle:0.5 * M_PI clockwise:YES];
                        }else {
                            [bezierPath addArcWithCenter:CGPointMake(CGRectGetMaxX(cur) - HXEditTextRadius, CGRectGetMaxY(cur) - HXEditTextRadius) radius:HXEditTextRadius startAngle:0 endAngle:0.5 * M_PI clockwise:YES];
                        }
                        
                        [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(nextCur) + HXEditTextRadius, CGRectGetMaxY(cur))];
                    }else if (CGRectGetMaxX(cur) == CGRectGetMaxX(nextCur)) {
                        [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(cur), CGRectGetMaxY(cur))];
                    }else {
                        if (!half) {
                            CGPoint point = CGPointMake(CGRectGetMaxX(cur), nextCur.origin.y - HXEditTextRadius);
                            if (!CGPointEqualToPoint(point, bezierPath.currentPoint)) {
                                [bezierPath addLineToPoint:point];
                                [bezierPath addArcWithCenter:CGPointMake(CGRectGetMaxX(cur) + HXEditTextRadius, nextCur.origin.y - HXEditTextRadius) radius:HXEditTextRadius startAngle:-M_PI endAngle:-1.5f * M_PI clockwise:NO];
                            }else {
                                [bezierPath addArcWithCenter:CGPointMake(bezierPath.currentPoint.x + HXEditTextRadius, bezierPath.currentPoint.y) radius:HXEditTextRadius startAngle:-M_PI endAngle:-1.5f * M_PI clockwise:NO];
                            }
                        }
                        [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(nextCur) - HXEditTextRadius, nextCur.origin.y)];
                    }
                    hasNext = YES;
                }
            }
            if (!hasNext) {
                [bezierPath addLineToPoint:CGPointMake(CGRectGetMaxX(cur), CGRectGetMaxY(cur) - HXEditTextRadius)];

                [bezierPath addArcWithCenter:CGPointMake(CGRectGetMaxX(cur) - HXEditTextRadius, CGRectGetMaxY(cur) - HXEditTextRadius) radius:HXEditTextRadius startAngle:0 endAngle:0.5 * M_PI clockwise:YES];
                                                       
                [bezierPath addLineToPoint:CGPointMake(cur.origin.x + HXEditTextRadius, CGRectGetMaxY(cur))];
                
                [bezierPath addArcWithCenter:CGPointMake(cur.origin.x + HXEditTextRadius, CGRectGetMaxY(cur) - HXEditTextRadius) radius:HXEditTextRadius startAngle:0.5 * M_PI endAngle:M_PI clockwise:YES];
                
                [bezierPath addLineToPoint:CGPointMake(cur.origin.x, startPoint.y)];
            
                [path appendPath:bezierPath];
                bezierPath = nil;
            }
        }
//    }
    return path;
}
- (NSMutableArray *)rectArray {
    if (!_rectArray) {
        _rectArray = @[].mutableCopy;
    }
    return _rectArray;
}

- (void)preProccess {
    self.maxIndex = 0;
    if (self.rectArray.count < 2) {
        return;
    }
    for (int i = 1; i < self.rectArray.count; i++) {
        self.maxIndex = i;
        [self processRectIndex:i];
    }
}

- (void)processRectIndex:(int) index {
    if (self.rectArray.count < 2 || index < 1 || index > self.maxIndex) {
        return;
    }
    NSValue *value1 = [self.rectArray objectAtIndex:index - 1];
    NSValue *value2 = [self.rectArray objectAtIndex:index];
    CGRect last = value1.CGRectValue;
    CGRect cur = value2.CGRectValue;
    if (cur.size.width <= HXEditTextBlankWidth || last.size.width <= HXEditTextBlankWidth) {
        return;
    }
    BOOL t1 = NO;
    BOOL t2 = NO;
    //if t1 == true 改变cur的rect
    if (cur.origin.x > last.origin.x) {
        if (cur.origin.x - last.origin.x < 2 * HXEditTextRadius) {
            cur = CGRectMake(last.origin.x, cur.origin.y, cur.size.width, cur.size.height);
            t1 = YES;
        }
    }else if (cur.origin.x < last.origin.x) {
        if (last.origin.x - cur.origin.x < 2 * HXEditTextRadius) {
            cur = CGRectMake(last.origin.x, cur.origin.y, cur.size.width, cur.size.height);
            t1 = YES;
        }
    }
    if (CGRectGetMaxX(cur) > CGRectGetMaxX(last)) {
        CGFloat poor = CGRectGetMaxX(cur) - CGRectGetMaxX(last);
        if (poor < 2 * HXEditTextRadius) {
            last = CGRectMake(last.origin.x, last.origin.y, cur.size.width, last.size.height);
            t2 = YES;
        }
    }
    if (CGRectGetMaxX(cur) < CGRectGetMaxX(last)) {
        CGFloat poor = CGRectGetMaxX(last) - CGRectGetMaxX(cur);
        if (poor < 2 * HXEditTextRadius) {
            cur = CGRectMake(cur.origin.x, cur.origin.y, last.size.width, cur.size.height);
            t1 = YES;
        }
    }
    if (t1) {
        NSValue *newValue = [NSValue valueWithCGRect:cur];
        [self.rectArray replaceObjectAtIndex:index withObject:newValue];
        [self processRectIndex:index + 1];
    }
    if (t2) {
        NSValue *newValue = [NSValue valueWithCGRect:last];
        [self.rectArray replaceObjectAtIndex:index - 1 withObject:newValue];
        [self processRectIndex:index - 1];
    }
     
    return;
}
@end


@implementation HXPhotoEditTextModel
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.image = [aDecoder decodeObjectForKey:@"image"];
        self.text = [aDecoder decodeObjectForKey:@"text"];
        self.textColor = [aDecoder decodeObjectForKey:@"textColor"];
        self.showBackgroud = [aDecoder decodeBoolForKey:@"showBackgroud"];
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.image forKey:@"image"];
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeObject:self.textColor forKey:@"textColor"];
    [aCoder encodeBool:self.showBackgroud forKey:@"showBackgroud"];
}
@end

@implementation HXPhotoEditTextLayer

@end
