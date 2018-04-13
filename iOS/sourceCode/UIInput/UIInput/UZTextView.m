/**
  * APICloud Modules
  * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
  * Licensed under the terms of the The MIT License (MIT).
  * Please see the license.html included with this distribution for details.
  */

#import "UZTextView.h"
#import "UZAppUtils.h"
#import "NSDictionaryUtils.h"

@interface UZTextView ()

/** 占位文字的颜色 */
@property (nonatomic, strong) UIColor *placeholderColor;

@end

@implementation UZTextView

- (instancetype)initWithFrame:(CGRect)frame styles:(NSDictionary *)styles {
    if (self = [super initWithFrame:frame]) {
        self.alwaysBounceVertical = YES;
        
        //背景颜色
        NSString *bgColor = [styles stringValueForKey:@"bgColor" defaultValue:@"#fff"];
        if ([UZAppUtils isValidColor:bgColor]) {
            self.backgroundColor = [UZAppUtils colorFromNSString:bgColor];
        }else {
            self.backgroundColor = [UZAppUtils colorFromNSString:@"#fff"];
        }
        
        //字体
        CGFloat size = [styles floatValueForKey:@"size" defaultValue:14];
        self.font = [UIFont systemFontOfSize:size];
        
        //字体颜色
        NSString *color = [styles stringValueForKey:@"color" defaultValue:@"#000"];
        if ([UZAppUtils isValidColor:color]) {
            self.textColor = [UZAppUtils colorFromNSString:color];
        }else {
            self.textColor = [UZAppUtils colorFromNSString:@"#000"];
        }

        //占位文字颜色
        NSDictionary *placeholder = [styles dictValueForKey:@"placeholder" defaultValue:@{}];
        NSString *placeholderColor = [placeholder stringValueForKey:@"color" defaultValue:@"#ccc"];
        if ([UZAppUtils isValidColor:placeholderColor]) {
            self.placeholderColor = [UZAppUtils colorFromNSString:placeholderColor];
        }else {
            self.placeholderColor = [UZAppUtils colorFromNSString:@"#ccc"];
        }
    }
    return self;

}

/**
 * 绘制占位文字(每次drawRect:之前, 会自动清除掉之前绘制的内容)
 */
- (void)drawRect:(CGRect)rect {
    if (self.hasText) return;
    rect.origin.x = 4;
    rect.origin.y = 7;
    rect.size.width -= 2 * rect.origin.x;
    
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    attrs[NSFontAttributeName] = self.font;
    attrs[NSForegroundColorAttributeName] = self.placeholderColor;
    [self.placeholder drawInRect:rect withAttributes:attrs];
}

#pragma mark - 重写setter
- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    _placeholderColor = placeholderColor;
    
    [self setNeedsDisplay];
}

- (void)setPlaceholder:(NSString *)placeholder
{
    _placeholder = [placeholder copy];
    [self setNeedsDisplay];
}

- (void)setFont:(UIFont *)font
{
    [super setFont:font];
    [self setNeedsDisplay];
}

- (void)setText:(NSString *)text
{
    [super setText:text];
    [self setNeedsDisplay];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    [super setAttributedText:attributedText];
    [self setNeedsDisplay];
}

//- (void)setSecureTextEntry:(BOOL)secureTextEntry
//{
//    [super setSecureTextEntry:secureTextEntry];
//    [self setNeedsDisplay];
//}

@end
