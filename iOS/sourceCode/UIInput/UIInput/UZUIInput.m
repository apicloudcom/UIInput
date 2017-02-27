
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

@interface UZUIInput ()<UITextViewDelegate,UITextFieldDelegate>

@property (nonatomic, strong) NSMutableDictionary *inputDict;

@property (nonatomic, strong) NSMutableDictionary *maxRowsDict;

@property (nonatomic, strong) NSMutableDictionary *openCbIdDict;

@property (nonatomic, strong) NSMutableDictionary *keyboardTypeDict;

@property (nonatomic, assign) NSInteger inputID;

@property (nonatomic, assign) NSInteger listenCbId;

@property (nonatomic, copy) NSString *listenedName;

@property (nonatomic, assign) NSInteger listenID;

@property (nonatomic, weak) UIView *fatherView;

@property (nonatomic, assign) CGFloat changeY;

@property (nonatomic, assign) BOOL flag;

@end

@implementation UZUIInput

- (id)initWithUZWebView:(id)webView {
    if (self = [super initWithUZWebView:webView]) {
        // 监听文字改变
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextViewTextDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
        //监听键盘改变
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dispose {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.inputDict removeAllObjects];
    [self.maxRowsDict removeAllObjects];
    for (NSNumber *openCbId in self.openCbIdDict.allValues) {
        NSInteger cbId = [openCbId integerValue];
        [self deleteCallback:cbId];
    }
    [self.openCbIdDict removeAllObjects];
    
    if (_listenCbId >= 0) {
        [self deleteCallback:_listenCbId];
    }
}

- (void)open:(NSDictionary *)params_ {
    _inputID++;
    NSInteger openCbId = [params_ integerValueForKey:@"cbId" defaultValue:-1];
    NSString *fixedOn = [params_ stringValueForKey:@"fixedOn" defaultValue:nil];
    BOOL fixed = [params_ boolValueForKey:@"fixed" defaultValue:YES];
    UIView *fatherView = [self getViewByName:fixedOn];
    self.fatherView = fatherView;
    
    //rect
    NSDictionary *rect = [params_ dictValueForKey:@"rect" defaultValue:@{}];
    float frameX,frameY,frameW,frameH;
    frameX = [rect floatValueForKey:@"x" defaultValue:0];
    frameY = [rect floatValueForKey:@"y" defaultValue:0];
    frameW = [rect floatValueForKey:@"w" defaultValue:fatherView.frame.size.width];
    frameH = [rect floatValueForKey:@"h" defaultValue:40];
    
    NSInteger maxRows = [params_ integerValueForKey:@"maxRows" defaultValue:1];
    NSDictionary *styles = [params_ dictValueForKey:@"styles" defaultValue:@{}];
    NSString *placeholder = [params_ stringValueForKey:@"placeholder" defaultValue:@""];
    NSString *keyboardType = [params_ stringValueForKey:@"keyboardType" defaultValue:@"default"];
    BOOL autoFocus = [params_ boolValueForKey:@"autoFocus" defaultValue:YES];

    if (maxRows == 1) {
        UITextField *textField = [self setupTextFieldWithFrame:CGRectMake(frameX, frameY, frameW, frameH) Styles:styles placeholder:placeholder];
        textField.delegate = self;
        [self.inputDict setObject:textField forKey:@(_inputID)];
        [self addSubview:textField fixedOn:fixedOn fixed:fixed];
        
        if ([keyboardType isEqualToString:@"default"]) {
            textField.keyboardType = UIKeyboardTypeDefault;
        }else if ([keyboardType isEqualToString:@"number"]) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }else if ([keyboardType isEqualToString:@"search"]) {
            textField.keyboardType = UIKeyboardTypeWebSearch;
        }else if ([keyboardType isEqualToString:@"next"]) {
            textField.returnKeyType = UIReturnKeyNext;
        }
        
        if (autoFocus) {
            [textField becomeFirstResponder];
        }
    }else {
        UZTextView *textView = [[UZTextView alloc] initWithFrame:CGRectMake(frameX, frameY, frameW, frameH) styles:styles];
        textView.placeholder = placeholder;
        textView.delegate = self;
        [self.inputDict setObject:textView forKey:@(_inputID)];
        [self addSubview:textView fixedOn:fixedOn fixed:fixed];
        
        if ([keyboardType isEqualToString:@"default"]) {
            textView.keyboardType = UIKeyboardTypeDefault;
        }else if ([keyboardType isEqualToString:@"number"]) {
            textView.keyboardType = UIKeyboardTypeNumberPad;
        }else if ([keyboardType isEqualToString:@"search"]) {
            textView.keyboardType = UIKeyboardTypeWebSearch;
        }else if ([keyboardType isEqualToString:@"next"]) {
            textView.returnKeyType = UIReturnKeyNext;
        }
        
        if (autoFocus) {
            [textView becomeFirstResponder];
        }
    }
    [self.keyboardTypeDict setObject:keyboardType forKey:@(_inputID)];
    [self.maxRowsDict setObject:@(maxRows) forKey:@(_inputID)];
    [self.openCbIdDict setObject:@(openCbId) forKey:@(_inputID)];
    
    //callback
    NSMutableDictionary *sendDict = [NSMutableDictionary dictionary];
    [sendDict setObject:@(_inputID) forKey:@"id"];
    [sendDict setObject:@(YES) forKey:@"status"];
    [sendDict setObject:@"show" forKey:@"eventType"];
    [self sendResultEventWithCallbackId:openCbId dataDict:sendDict errDict:nil doDelete:NO];
}

- (void)close:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:_inputID];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    if (targetView) {
        [targetView removeFromSuperview];
        targetView = nil;
        [_inputDict removeObjectForKey:@(identity)];
        [_maxRowsDict removeObjectForKey:@(identity)];
        [_keyboardTypeDict removeObjectForKey:@(identity)];
    }
}

- (void)hide:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:_inputID];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    if (targetView) {
        targetView.hidden = YES;
    }
}

- (void)show:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:_inputID];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    if (targetView) {
        targetView.hidden = NO;
    }
}

- (void)value:(NSDictionary *)params_ {
    NSString *msg = [params_ stringValueForKey:@"msg" defaultValue:nil];
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:_inputID];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    UITextField *textfield = nil;
    UZTextView *textView = nil;
    if ([[_maxRowsDict objectForKey:@(identity)] integerValue] == 1) {
        textfield = (UITextField *)targetView;
    }else {
        textView = (UZTextView *)targetView;
    }
    NSMutableDictionary *sendDict = [NSMutableDictionary dictionary];
    [sendDict setObject:[NSNumber numberWithBool:YES] forKey:@"status"];
    if (textfield) {
        if (msg) {
            textfield.text = msg;
        }
        if (textfield.text) {
            [sendDict setObject:textfield.text forKey:@"msg"];
        }
    }else if (textView) {
        if (msg) {
            textView.text = msg;
        }
        if (textView.text) {
            [sendDict setObject:textView.text forKey:@"msg"];
        }
    }
    [self sendResultEventWithCallbackId:[params_ integerValueForKey:@"cbId" defaultValue:-1]
                               dataDict:sendDict
                                errDict:nil
                               doDelete:YES];
}

- (void)insertValue:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:_inputID];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    UITextField *textfield = nil;
    UZTextView *textView = nil;
    NSUInteger num = 0;
    NSMutableString *str = [NSMutableString string];
    if ([[_maxRowsDict objectForKey:@(identity)] integerValue] == 1) {
        textfield = (UITextField *)targetView;
        num = textfield.text.length;
        str = [NSMutableString stringWithString:textfield.text];
    }else {
        textView = (UZTextView *)targetView;
        num = textView.text.length;
        str = [NSMutableString stringWithString:textView.text];
    }
    NSInteger index = [params_ floatValueForKey:@"index" defaultValue:num];
    NSString *msg = [params_ stringValueForKey:@"msg" defaultValue:@""];
    if (msg) {
        if (index > num) {
            index = num;
        }
        [str insertString:msg atIndex:index];
    }
    if (textfield) {
        textfield.text = str;
    }else if (textView) {
        textView.text = str;
    }
}

- (void)popupKeyboard:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:_inputID];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    if (targetView){
        [targetView becomeFirstResponder];
    }
}

- (void)closeKeyboard:(NSDictionary *)params_ {
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:_inputID];
    UIView *targetView = [_inputDict objectForKey:@(identity)];
    if (targetView){
        [targetView resignFirstResponder];
    }
}

- (void)addEventListener:(NSDictionary *)params_ {
    _listenID = [params_ integerValueForKey:@"id" defaultValue:_inputID];
    _listenCbId = [params_ integerValueForKey:@"cbId" defaultValue:-1];
    _listenedName = [params_ stringValueForKey:@"name" defaultValue:nil];
}

#pragma mark -UITextViewTextDidChangeNotification
- (void)textDidChange:(NSNotification *)notification {
    UIView *targetView = nil;
    if ([notification.object isKindOfClass:[UITextField class]]) {
        targetView = (UITextField *)notification.object;
    }else {
        targetView = (UZTextView *)notification.object;
        //控制占位文字
        [targetView setNeedsDisplay];
    }
    //callback
    NSInteger ID = 0;
    for (NSNumber *key in self.inputDict.allKeys) {
        if ([[self.inputDict objectForKey:key] isEqual:targetView]) {
            ID = [key integerValue];
        }
    }
    NSInteger openCbId = [[self.openCbIdDict objectForKey:@(ID)] integerValue];
    if (ID > 0 && openCbId >=0) {
        [self sendResultEventWithCallbackId:openCbId dataDict:@{@"id" : @(ID), @"status" : @(YES), @"eventType" : @"change"} errDict:nil doDelete:NO];
    }
}

#pragma mark -UIKeyboardWillShowNotification
- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat keyboardH = keyboardFrame.size.height;
    
    UIView *listenedView = [self.inputDict objectForKey:@(_listenID)];
    if (listenedView && [listenedView isFirstResponder] && _listenCbId >= 0 && [_listenedName isEqualToString:@"becomeFirstResponder"]) {
        [self sendResultEventWithCallbackId:_listenCbId dataDict:@{@"keyboardHeight" : @(keyboardH)} errDict:nil doDelete:NO];
    }
    for (NSNumber *key in self.inputDict.allKeys) {
        UIView *targetView = [self.inputDict objectForKey:key];
        if (self.fatherView.frame.size.height - CGRectGetMaxY(targetView.frame) < keyboardH && [targetView isFirstResponder] && !self.flag){
            [UIView animateWithDuration:duration animations:^{
                CGRect tempFrame = self.fatherView.frame;
                CGRect targetFrame = targetView.frame;
                CGFloat targetY = targetFrame.origin.y;
                targetFrame.origin.y = tempFrame.size.height - keyboardH - targetFrame.size.height;
                self.changeY = (targetFrame.origin.y - targetY);
                tempFrame.origin.y += self.changeY;
                self.fatherView.frame = tempFrame;
                self.flag = YES;
                return ;
            }];
        }
    }
}

#pragma mark -UIKeyboardWillHideNotification
- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    if (self.flag) {
        [UIView animateWithDuration:duration animations:^{
            CGRect tempFrame = self.fatherView.frame;
            tempFrame.origin.y -= self.changeY;
            self.fatherView.frame = tempFrame;
        }];
        self.flag = NO;
    }
}

#pragma mark -UITextViewDelegate
- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    UIView *targetView = [self.inputDict objectForKey:@(_listenID)];
    if (_listenCbId >=0 && [_listenedName isEqualToString:@"resignFirstResponder"] && [targetView isEqual:textView]) {
        [self sendResultEventWithCallbackId:_listenCbId dataDict:nil errDict:nil doDelete:NO];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        for (NSNumber *key in self.inputDict.allKeys) {
            if ([[self.inputDict objectForKey:key] isEqual:textView]) {
                NSString *keyboardType = [self.keyboardTypeDict objectForKey:key];
                if ([keyboardType isEqualToString:@"next"]) {
                    UIView *nextView = [self.inputDict objectForKey:@([key integerValue] + 1)];
                    [nextView becomeFirstResponder];
                    if ([key integerValue] == self.inputDict.count) {
                        nextView = [self.inputDict objectForKey:key];
                        [nextView becomeFirstResponder];
                    }
                }
            }
        }
    }
    return YES;
}

#pragma mark -UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    UIView *targetView = [self.inputDict objectForKey:@(_listenID)];
    if (_listenCbId >=0 && [_listenedName isEqualToString:@"resignFirstResponder"] && [targetView isEqual:textField]) {
        [self sendResultEventWithCallbackId:_listenCbId dataDict:nil errDict:nil doDelete:NO];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([string isEqualToString:@"\n"]) {
        for (NSNumber *key in self.inputDict.allKeys) {
            if ([[self.inputDict objectForKey:key] isEqual:textField]) {
                NSString *keyboardType = [self.keyboardTypeDict objectForKey:key];
                if ([keyboardType isEqualToString:@"next"]) {
                    UIView *nextView = [self.inputDict objectForKey:@([key integerValue] + 1)];
                    [nextView becomeFirstResponder];
                    if ([key integerValue] == self.inputDict.count) {
                        nextView = [self.inputDict objectForKey:key];
                        [nextView becomeFirstResponder];
                    }
                }else if ([keyboardType isEqualToString:@"search"]) {
                    if (key) {
                        //callback
                        NSMutableDictionary *sendDict = [NSMutableDictionary dictionary];
                        NSInteger openCbId = [[self.openCbIdDict objectForKey:key] integerValue];
                        [sendDict setObject:@(_inputID) forKey:@"id"];
                        [sendDict setObject:@(YES) forKey:@"status"];
                        [sendDict setObject:@"search" forKey:@"eventType"];
                        if (openCbId) {
                            [self sendResultEventWithCallbackId:openCbId dataDict:sendDict errDict:nil doDelete:NO];
                        }
                    }
                }
            }
        }
    }
    return YES;
}


//setupTextField
- (UITextField *)setupTextFieldWithFrame:(CGRect)frame Styles:(NSDictionary *)styles placeholder:(NSString *)placeholder{
    //背景颜色
    UITextField *textField = [[UITextField alloc] initWithFrame:frame];
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
    
    //占位文字颜色
    NSDictionary *placeholderDic = [styles dictValueForKey:@"placeholder" defaultValue:@{}];
    NSString *placeholderColorStr = [placeholderDic stringValueForKey:@"color" defaultValue:@"#ccc"];
    UIColor *placeholderColor = nil;
    if ([UZAppUtils isValidColor:placeholderColorStr]) {
        placeholderColor = [UZAppUtils colorFromNSString:placeholderColorStr];
    }else {
        placeholderColor = [UZAppUtils colorFromNSString:@"#ccc"];
    }
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName : placeholderColor}];
    return textField;
}

//lazy
- (NSMutableDictionary *)inputDict {
    if (!_inputDict) {
        _inputDict = [NSMutableDictionary dictionary];
    }
    return _inputDict;
}

- (NSMutableDictionary *)maxRowsDict {
    if (!_maxRowsDict) {
        _maxRowsDict = [NSMutableDictionary dictionary];
    }
    return _maxRowsDict;
}

- (NSMutableDictionary *)openCbIdDict {
    if (!_openCbIdDict) {
        _openCbIdDict = [NSMutableDictionary dictionary];
    }
    return _openCbIdDict;
}

- (NSMutableDictionary *)keyboardTypeDict {
    if (!_keyboardTypeDict) {
        _keyboardTypeDict = [NSMutableDictionary dictionary];
    }
    return _keyboardTypeDict;
}

@end
