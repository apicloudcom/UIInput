/**
  * APICloud Modules
  * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
  * Licensed under the terms of the The MIT License (MIT).
  * Please see the license.html included with this distribution for details.
  */
#import "UZUIInput.h"
#import "NSDictionaryUtils.h"
#import "UZAppUtils.h"
#import "UZTextView.h"

#define keyBoardScale 0.5

@interface UZUIInput ()<UITextFieldDelegate,UITextViewDelegate>

{
    NSInteger _openCbId,_listenCbId;
    NSInteger _listenId;
}

@property (nonatomic, strong) NSMutableDictionary *inputDict;

@property (nonatomic, assign) NSInteger ID;

@property (nonatomic, copy) NSString *listenedName;

@property (nonatomic, copy) NSString *keyboardType;

@end

@implementation UZUIInput

- (id)initWithUZWebView:(id)webView {
    if (self = [super initWithUZWebView:webView]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChangeFrame:) name: UIKeyboardDidChangeFrameNotification object:nil];
    }
    return self;
}

- (void)dispose {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.inputDict removeAllObjects];
    
    if (_openCbId >= 0) {
        [self deleteCallback:_openCbId];
    }
    if (_listenCbId) {
        [self deleteCallback:_listenCbId];
    }
}

- (void)open:(NSDictionary *)params_ {
    _ID++;
    _openCbId = [params_ integerValueForKey:@"cbId" defaultValue:-1];
    NSString *fixedOn = [params_ stringValueForKey:@"fixedOn" defaultValue:nil];
    UIView *fatherView = [self getViewByName:fixedOn];
    //rect
    NSDictionary *rect = [params_ dictValueForKey:@"rect" defaultValue:@{}];
    float frameX,frameY,frameW,frameH;
    frameX = [rect floatValueForKey:@"x" defaultValue:0];
    frameY = [rect floatValueForKey:@"y" defaultValue:0];
    frameW = [rect floatValueForKey:@"w" defaultValue:fatherView.frame.size.width];
    frameH = [rect floatValueForKey:@"h" defaultValue:40];
    
    //styles
    NSDictionary *styles = [params_ dictValueForKey:@"styles" defaultValue:@{}];
    UZTextView *textView = [[UZTextView alloc] initWithFrame:CGRectMake(frameX, frameY, frameW, frameH) styles:styles];
    textView.placeholder = [params_ stringValueForKey:@"placeholder" defaultValue:@""];
    textView.hidden = YES;
    textView.delegate = self;
    UITextField *textField = [self setupTextFieldWithFrame:CGRectMake(frameX, frameY, frameW, frameH) styles:styles];
    textField.placeholder = [params_ stringValueForKey:@"placeholder" defaultValue:@""];
    textField.hidden = YES;
    textField.delegate = self;
    
    _keyboardType = [params_ stringValueForKey:@"keyboardType" defaultValue:@"next"];
    if ([_keyboardType isEqualToString:@"default"]) {
        textField.keyboardType = UIKeyboardTypeDefault;
        textView.keyboardType = UIKeyboardTypeDefault;
    }else if ([_keyboardType isEqualToString:@"number"]) {
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textView.keyboardType = UIKeyboardTypeNumberPad;
    }else if ([_keyboardType isEqualToString:@"search"]) {
        textField.keyboardType = UIKeyboardTypeWebSearch;
        textView.keyboardType = UIKeyboardTypeWebSearch;
    }else if ([_keyboardType isEqualToString:@"next"]) {
        textField.returnKeyType = UIReturnKeyNext;
    }
    BOOL autoFocus = [params_ boolValueForKey:@"autoFocus" defaultValue:YES];
    if (autoFocus) {
        [textField becomeFirstResponder];
        [textView becomeFirstResponder];
    }
    
    NSInteger maxRows = [params_ integerValueForKey:@"maxRows" defaultValue:1];
    if (maxRows == 1) {
        textField.hidden = NO;
        [self.inputDict setObject:textField forKey:@(_ID)];
    }else {
        textView.hidden = NO;
        [self.inputDict setObject:textView forKey:@(_ID)];
    }
    [self addSubview:textField fixedOn:fixedOn fixed:YES];
    [self addSubview:textView fixedOn:fixedOn fixed:YES];
    
    //callback
    NSMutableDictionary *sendDict = [NSMutableDictionary dictionary];
    [sendDict setObject:@(_ID) forKey:@"id"];
    [sendDict setObject:@(YES) forKey:@"status"];
    [sendDict setObject:@"show" forKey:@"eventType"];
    [self sendResultEventWithCallbackId:_openCbId dataDict:sendDict errDict:nil doDelete:NO];
}

- (void)close:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:0];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    if (targetView) {
        [targetView removeFromSuperview];
        targetView = nil;
        [_inputDict removeObjectForKey:@(identity)];
    }
}

- (void)hide:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:0];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    if (targetView) {
        targetView.hidden = YES;
    }
}

- (void)show:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:0];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    if (targetView) {
        targetView.hidden = NO;
    }
}

- (void)value:(NSDictionary *)params_ {
    NSString *msg = [params_ stringValueForKey:@"msg" defaultValue:nil];
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:0];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    NSMutableDictionary *sendDict = [NSMutableDictionary dictionary];
    [sendDict setObject:[NSNumber numberWithBool:YES] forKey:@"status"];
    if (targetView && [targetView isKindOfClass:[UITextField class]]) {
        UITextField * textField = (UITextField *)targetView;
        if (msg) {
            textField.text = msg;
        }
        if (textField.text) {
            [sendDict setObject:textField.text forKey:@"msg"];
        }
        [self sendResultEventWithCallbackId:[params_ integerValueForKey:@"cbId" defaultValue:-1]
                                   dataDict:sendDict
                                    errDict:nil
                                   doDelete:YES];
    }else {
        UZTextView * textView = (UZTextView *)targetView;
        if (msg) {
            textView.text = msg;
        }
        if (textView.text) {
            [sendDict setObject:textView.text forKey:@"msg"];
        }
        [self sendResultEventWithCallbackId:[params_ integerValueForKey:@"cbId" defaultValue:-1]
                                   dataDict:sendDict
                                    errDict:nil
                                   doDelete:YES];
    }
}

- (void)insertValue:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:0];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    NSUInteger num = 0;
    UITextField *textField = nil;
    UZTextView *textView = nil;
    if (targetView && [targetView isKindOfClass:[UITextField class]]) {
        textField = (UITextField *)targetView;
        num = textField.text.length;
    }else {
        textView = (UZTextView *)targetView;
        num = textView.text.length;
    }
    NSInteger index = [params_ floatValueForKey:@"index" defaultValue:num];
    NSString *msg = [params_ stringValueForKey:@"msg" defaultValue:@""];
    
    if (textField) {
        NSMutableString *str = [NSMutableString stringWithString:textField.text];
        if (msg) {
            [str insertString:msg atIndex:index];
        }
        textField.text = str;
    }else {
        NSMutableString *str = [NSMutableString stringWithString:textView.text];
        if (msg) {
            [str insertString:msg atIndex:index];
        }
        textView.text = str;
    }
}

- (void)popupKeyboard:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:0];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    if (targetView){
        [targetView becomeFirstResponder];
    }
}

- (void)closeKeyboard:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:0];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    if (targetView){
        [targetView resignFirstResponder];
    }
}

- (void)addEventListener:(NSDictionary *)params_ {
    _listenId = [params_ intValueForKey:@"id" defaultValue:0];
    _listenCbId = [params_ integerValueForKey:@"cbId" defaultValue:-1];
    if (_listenCbId < 0) return;
    _listenedName = [params_ stringValueForKey:@"name" defaultValue:nil];
}

#pragma mark -UIKeyboardDidChangeFrameNotification
- (void)keyboardChangeFrame:(NSNotification *)notification {
    //default upper 3 input no change with keyboard change
    if ([[self.inputDict objectForKey:@(1)] isEditing]) return;
    if ([[self.inputDict objectForKey:@(2)] isEditing]) return;
    if ([[self.inputDict objectForKey:@(3)] isEditing]) return;
    
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    for (NSNumber *key in self.inputDict.allKeys) {
        UIView *targetView = [self.inputDict objectForKey:key];
        if (targetView.superview.frame.size.height - CGRectGetMaxY(targetView.frame) < keyboardFrame.size.height) {
            [UIView animateWithDuration:0.25 animations:^{
                CGRect tempFrame = targetView.superview.frame;
                tempFrame.origin.y = (keyboardFrame.origin.y - targetView.superview.frame.size.height) * keyBoardScale;
                targetView.superview.frame = tempFrame;
            }];
            break;
        }
    }
}

#pragma mark -UITextFieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    UIView *targetView = [self.inputDict objectForKey:@(_listenId)];
    if (_listenCbId >=0 && [_listenedName isEqualToString:@"becomeFirstResponder"] && [targetView isEqual:textField]) {
        [self sendResultEventWithCallbackId:_listenCbId dataDict:nil errDict:nil doDelete:NO];
    }
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    UIView *targetView = [self.inputDict objectForKey:@(_listenId)];
    if (_listenCbId >=0 && [_listenedName isEqualToString:@"resignFirstResponder"] && [targetView isEqual:textField]) {
        [self sendResultEventWithCallbackId:_listenCbId dataDict:nil errDict:nil doDelete:NO];
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    for (NSNumber *key in self.inputDict.allKeys) {
        if ([[self.inputDict objectForKey:key] isEqual:textField]) {
            if ([_keyboardType isEqualToString:@"next"]) {
                UIView *inputView = [self.inputDict objectForKey:@([key integerValue] + 1)];
                [inputView becomeFirstResponder];
                if ([key integerValue] == self.inputDict.count) {
                    UIView *inputView = [self.inputDict objectForKey:key];
                    [inputView becomeFirstResponder];
                }
                
            }else if ([_keyboardType isEqualToString:@"search"] && _openCbId >= 0) {
                [self sendResultEventWithCallbackId:_openCbId dataDict:@{@"id" : key, @"status" : @(YES), @"showType" : @"search"} errDict:nil doDelete:NO];
            }
        }
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger ID = 0;
    for (NSNumber *key in self.inputDict.allKeys) {
        if ([[self.inputDict objectForKey:key] isEqual:textField]) {
            ID = [key integerValue];
        }
    }
    if (ID > 0 && _openCbId >=0) {
        [self sendResultEventWithCallbackId:_openCbId dataDict:@{@"id" : @(ID), @"status" : @(YES), @"showType" : @"change"} errDict:nil doDelete:NO];
    }
    return YES;
}

#pragma mark -UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    UIView *targetView = [self.inputDict objectForKey:@(_listenId)];
    if (_listenCbId >=0 && [_listenedName isEqualToString:@"becomeFirstResponder"] && [targetView isEqual:textView]) {
        [self sendResultEventWithCallbackId:_listenCbId dataDict:nil errDict:nil doDelete:NO];
    }
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    UIView *targetView = [self.inputDict objectForKey:@(_listenId)];
    if (_listenCbId >=0 && [_listenedName isEqualToString:@"becomeFirstResponder"] && [targetView isEqual:textView]) {
        [self sendResultEventWithCallbackId:_listenCbId dataDict:nil errDict:nil doDelete:NO];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    //callback
    NSInteger ID = 0;
    for (NSNumber *key in self.inputDict.allKeys) {
        if ([[self.inputDict objectForKey:key] isEqual:textView]) {
            ID = [key integerValue];
        }
    }
    if (ID > 0 && _openCbId >=0) {
        [self sendResultEventWithCallbackId:_openCbId dataDict:@{@"id" : @(ID), @"status" : @(YES), @"showType" : @"change"} errDict:nil doDelete:NO];
        
    }
    if ([text isEqualToString:@"\n"] && [_keyboardType isEqualToString:@"next"]) {
        for (NSNumber *key in self.inputDict.allKeys) {
            if ([[self.inputDict objectForKey:key] isEqual:textView]) {
                UIView *nextView = [self.inputDict objectForKey:@([key integerValue] + 1)];
                [nextView becomeFirstResponder];
                if ([key integerValue] == self.inputDict.count) {
                    nextView = [self.inputDict objectForKey:key];
                    [nextView becomeFirstResponder];
                }
            }
        }
    }
    return YES;
}

// setupTextField
- (UITextField *)setupTextFieldWithFrame:(CGRect)frame styles:(NSDictionary *)styles {
    UITextField *textField = [[UITextField alloc] initWithFrame:frame];
    //背景颜色
    NSString *bgColor = [styles stringValueForKey:@"bgColor" defaultValue:@"#fff"];
    if ([UZAppUtils isValidColor:bgColor]) {
        textField.backgroundColor = [UZAppUtils colorFromNSString:bgColor];
    }else {
        textField.backgroundColor = [UZAppUtils colorFromNSString:@"#fff"];
    }
    
    //字体
    CGFloat size = [styles floatValueForKey:@"size" defaultValue:14];
    textField.font = [UIFont systemFontOfSize:size];
    
    //字体颜色
    NSString *color = [styles stringValueForKey:@"color" defaultValue:@"#000"];
    if ([UZAppUtils isValidColor:color]) {
        textField.textColor = [UZAppUtils colorFromNSString:color];
    }else {
        textField.textColor = [UZAppUtils colorFromNSString:@"#000"];
    }
    
    // 占位文字颜色
    NSDictionary *placeholder = [styles dictValueForKey:@"placeholder" defaultValue:@{}];
    NSString *placeholderColor = [placeholder stringValueForKey:@"color" defaultValue:@"#ccc"];
    UIColor *holderColor = nil;
    if ([UZAppUtils isValidColor:placeholderColor]) {
        holderColor = [UZAppUtils colorFromNSString:placeholderColor];
    }else {
        holderColor = [UZAppUtils colorFromNSString:@"#ccc"];
    }
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"string" attributes:@{NSFontAttributeName : textField.font, NSForegroundColorAttributeName : holderColor}];
    
    return textField;
}

//lazy
- (NSMutableDictionary *)inputDict {
    if (!_inputDict) {
        _inputDict = [NSMutableDictionary dictionary];
    }
    return _inputDict;
}

@end
