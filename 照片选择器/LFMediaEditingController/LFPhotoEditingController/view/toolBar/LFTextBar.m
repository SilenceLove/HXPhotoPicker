//
//  LFTextBar.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/22.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFTextBar.h"
#import "UIView+LFMEFrame.h"
#import "LFMediaEditingHeader.h"
#import "LFText.h"
#import "JRPickColorView.h"

/** 来限制最大输入只能100个字符 */
#define MAX_LIMIT_NUMS 100

@interface LFTextBar () <UITextViewDelegate, JRPickColorViewDelegate>

@property (nonatomic, weak) UIView *topbar;
@property (nonatomic, weak) UITextView *lf_textView;

@property (nonatomic, weak) JRPickColorView *lf_colorSlider;
@property (nonatomic, weak) UIView *lf_keyboardBar;

@end

@implementation LFTextBar

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

- (instancetype)initWithFrame:(CGRect)frame layout:(void (^)(LFTextBar *textBar))layoutBlock
{
    self = [super initWithFrame:frame];
    if (self) {
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
    if (iOS8Later) {
        // 定义毛玻璃效果
        self.backgroundColor = [UIColor clearColor];
        UIBlurEffect * blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView * effe = [[UIVisualEffectView alloc]initWithEffect:blur];
        effe.frame = self.bounds;
        effe.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:effe];
    } else {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    }
    
    [self addKeyBoardNotify];
    
    [self configCustomNaviBar];
    [self configTextView];
    [self configKeyBoardBar];

    [self setTextColor:kSliderColors[0]]; /** 白色 */
}

- (BOOL)becomeFirstResponder
{
    return [self.lf_textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    return [self.lf_textView resignFirstResponder];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addKeyBoardNotify
{
    // 添加键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)setShowText:(LFText *)showText
{
    _showText = showText;
    [self.lf_textView setText:showText.text];
    if (showText.textColor) {
        [self setTextColor:showText.textColor];
    }
}

- (void)configCustomNaviBar
{
    /** 顶部栏 */
    CGFloat margin = 8;
    CGFloat size = _naviHeight;
    
    CGFloat topbarHeight = _customTopbarHeight;
    CGFloat topSubViewY = topbarHeight - size;
    
    UIView *topbar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.width, topbarHeight)];
    topbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    topbar.backgroundColor = [UIColor clearColor];
    
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat editCancelWidth = [self.cancelButtonTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, _customTopbarHeight) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width + 30;
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(margin, topSubViewY, editCancelWidth, size)];
    cancelButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [cancelButton setTitle:self.cancelButtonTitle forState:UIControlStateNormal];
    cancelButton.titleLabel.font = font;
    [cancelButton setTitleColor:self.cancelButtonTitleColorNormal forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat editOkWidth = [self.oKButtonTitle boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, _customTopbarHeight) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.width + 30;
    UIButton *finishButton = [[UIButton alloc] initWithFrame:CGRectMake(self.width - editOkWidth - margin, topSubViewY, editOkWidth, size)];
    finishButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [finishButton setTitle:self.oKButtonTitle forState:UIControlStateNormal];
    finishButton.titleLabel.font = font;
    [finishButton setTitleColor:self.oKButtonTitleColorNormal forState:UIControlStateNormal];
    [finishButton addTarget:self action:@selector(finishButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    [topbar addSubview:cancelButton];
    [topbar addSubview:finishButton];
    
    [self addSubview:topbar];
    _topbar = topbar;
}

- (void)configTextView
{
    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(_topbar.frame), self.width, self.height-CGRectGetHeight(_topbar.frame))];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    textView.delegate = self;
    textView.backgroundColor = [UIColor clearColor];
//    [textView setTextColor:[UIColor whiteColor]];
    [textView setFont:[UIFont systemFontOfSize:25.f]];
    textView.returnKeyType = UIReturnKeyDone;
    [self addSubview:textView];
    self.lf_textView = textView;
}

- (void)configKeyBoardBar
{
    UIView *keyboardBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.height-44, self.width, 44)];
    keyboardBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    keyboardBar.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.8];
    
    /** 拾色器 */
    CGFloat sliderHeight = 34.f, margin = 30.f;
    CGFloat sliderWidth = MIN(400, CGRectGetWidth(keyboardBar.frame)-2*margin);
    JRPickColorView *_colorSlider = [[JRPickColorView alloc] initWithFrame:CGRectMake((CGRectGetWidth(keyboardBar.frame)-sliderWidth)/2, (CGRectGetHeight(keyboardBar.frame)-sliderHeight)/2, sliderWidth, sliderHeight) colors:kSliderColors];
//    _colorSlider.showColor = kSliderColors[0]; /** 白色 */
    _colorSlider.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _colorSlider.delegate = self;
    [_colorSlider setMagnifierMaskImage:bundleEditImageNamed(@"EditImageWaterDrop.png")];
    [keyboardBar addSubview:_colorSlider];
    self.lf_colorSlider = _colorSlider;
    
    [self addSubview:keyboardBar];
    self.lf_keyboardBar = keyboardBar;
}

/** 设置文字拾起器默认颜色 */
- (void)setTextColor:(UIColor *)textColor
{
    self.lf_colorSlider.color = textColor;
    self.lf_textView.textColor = textColor;
}

#pragma mark - 顶部栏(action)
- (void)cancelButtonClick
{
    if ([self.delegate respondsToSelector:@selector(lf_textBarControllerDidCancel:)]) {
        [self.delegate lf_textBarControllerDidCancel:self];
    }
}

- (void)finishButtonClick
{
    if ([self.delegate respondsToSelector:@selector(lf_textBarController:didFinishText:)]) {
        LFText *text = nil;
        if (self.lf_textView.text.length) {            
            text = [LFText new];
            text.text = self.lf_textView.text;
            text.textColor = self.lf_textView.textColor;
            CGFloat fontSize = 30.f;
            UIFont *font = [UIFont systemFontOfSize:fontSize];
            text.font = font;
        }
        [self.delegate lf_textBarController:self didFinishText:text];
    }
}

#pragma mark - 键盘通知出来方法
- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.lf_keyboardBar.y = self.height-CGRectGetHeight(keyboardRect)-CGRectGetHeight(self.lf_keyboardBar.frame);
        self.lf_textView.height = self.height-self.lf_keyboardBar.y;
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.lf_keyboardBar.y = self.height-CGRectGetHeight(keyboardRect)-CGRectGetHeight(self.lf_keyboardBar.frame);
        self.lf_textView.height = self.height-self.lf_keyboardBar.y;
    }];
}


#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)text
{
    
    if ([text isEqualToString:@"\n"])
    {
        [self finishButtonClick];
        return NO;
    }
    
    UITextRange *selectedRange = [textView markedTextRange];
    //获取高亮部分
    UITextPosition *pos = [textView positionFromPosition:selectedRange.start offset:0];
    //获取高亮部分内容
    //NSString * selectedtext = [textView textInRange:selectedRange];
    
    //如果有高亮且当前字数开始位置小于最大限制时允许输入
    if (selectedRange && pos) {
        NSInteger startOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selectedRange.start];
        NSInteger endOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selectedRange.end];
        NSRange offsetRange = NSMakeRange(startOffset, endOffset - startOffset);
        
        if (offsetRange.location < MAX_LIMIT_NUMS) {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    
    
    NSString *comcatstr = [textView.text stringByReplacingCharactersInRange:range withString:text];
    
    NSInteger caninputlen = MAX_LIMIT_NUMS - comcatstr.length;
    
    if (caninputlen >= 0)
    {
        return YES;
    }
    else
    {
        NSInteger len = text.length + caninputlen;
        //防止当text.length + caninputlen < 0时，使得rg.length为一个非法最大正数出错
        NSRange rg = {0,MAX(len,0)};
        
        if (rg.length > 0)
        {
            NSString *s = @"";
            //判断是否只普通的字符或asc码(对于中文和表情返回NO)
            BOOL asc = [text canBeConvertedToEncoding:NSASCIIStringEncoding];
            if (asc) {
                s = [text substringWithRange:rg];//因为是ascii码直接取就可以了不会错
            }
            else
            {
                __block NSInteger idx = 0;
                __block NSString  *trimString = @"";//截取出的字串
                //使用字符串遍历，这个方法能准确知道每个emoji是占一个unicode还是两个
                [text enumerateSubstringsInRange:NSMakeRange(0, [text length])
                                         options:NSStringEnumerationByComposedCharacterSequences
                                      usingBlock: ^(NSString* substring, NSRange substringRange, NSRange enclosingRange, BOOL* stop) {
                                          
                                          if (idx >= rg.length) {
                                              *stop = YES; //取出所需要就break，提高效率
                                              return ;
                                          }
                                          
                                          trimString = [trimString stringByAppendingString:substring];
                                          
                                          idx++;
                                      }];
                
                s = trimString;
            }
            //rang是指从当前光标处进行替换处理(注意如果执行此句后面返回的是YES会触发didchange事件)
            [textView setText:[textView.text stringByReplacingCharactersInRange:range withString:s]];
            //既然是超出部分截取了，哪一定是最大限制了。
//            self.lbNums.text = [NSString stringWithFormat:@"%d/%ld",0,(long)MAX_LIMIT_NUMS];
        }
        return NO;
    }
    
}

- (void)textViewDidChange:(UITextView *)textView
{
    UITextRange *selectedRange = [textView markedTextRange];
    //获取高亮部分
    UITextPosition *pos = [textView positionFromPosition:selectedRange.start offset:0];
    
    //如果在变化中是高亮部分在变，就不要计算字符了
    if (selectedRange && pos) {
        return;
    }
    
    NSString  *nsTextContent = textView.text;
    NSInteger existTextNum = nsTextContent.length;
    
    if (existTextNum > MAX_LIMIT_NUMS)
    {
        //截取到最大位置的字符(由于超出截部分在should时被处理了所在这里这了提高效率不再判断)
        NSString *s = [nsTextContent substringToIndex:MAX_LIMIT_NUMS];
        
        [textView setText:s];
    }
    
    //不让显示负数 口口日
//    self.lbNums.text = [NSString stringWithFormat:@"%ld/%d",MAX(0,MAX_LIMIT_NUMS - existTextNum),MAX_LIMIT_NUMS];
}

#pragma mark - JRPickColorViewDelegate
- (void)JRPickColorView:(JRPickColorView *)pickColorView didSelectColor:(UIColor *)color
{
    self.lf_textView.textColor = color;
}
@end
