
/**
  * APICloud Modules
  * Copyright (c) 2014-2018 by APICloud, Inc. All Rights Reserved.
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

@property (nonatomic, strong)NSMutableDictionary *eventDict;

@property (nonatomic, strong)NSMutableDictionary *maxLengthDict;

@property (nonatomic, assign) BOOL isScroll;
@property (nonatomic, assign) BOOL isEnd;
@property (nonatomic, weak) UITextField * currentTextField;
@property (nonatomic,strong) UIView * textContentView;

@end

@implementation UZUIInput

#pragma mark - lifeCycle -

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

#pragma mark - 模块接口
- (void)open:(NSDictionary *)params_ {
    _inputID++;
    
    NSInteger openCbId = [params_ integerValueForKey:@"cbId" defaultValue:-1];
    NSString *fixedOn = [params_ stringValueForKey:@"fixedOn" defaultValue:nil];
    BOOL fixed = [params_ boolValueForKey:@"fixed" defaultValue:YES];
    UIView *fatherView = [self getViewByName:fixedOn];
    self.fatherView = fatherView;
    int maxStringLenth = [params_ intValueForKey:@"maxStringLength" defaultValue:0];
    if (!self.maxLengthDict) {
        self.maxLengthDict = [NSMutableDictionary dictionary];
    }
    [self.maxLengthDict setObject:@(maxStringLenth) forKey:@(_inputID)];
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
    NSString *inputType = [params_ stringValueForKey:@"inputType" defaultValue:@"text"];
    NSString *alignment = [params_ stringValueForKey:@"alignment" defaultValue:@"left"];
    
    if (maxRows == 1) {
        UITextField *textField = [self setupTextFieldWithFrame:CGRectMake(frameX, frameY, frameW, frameH) Styles:styles placeholder:placeholder];
        if ([inputType isEqualToString:@"password"]) {
           textField.secureTextEntry = YES;
        }else
        {
           textField.secureTextEntry = NO;
        }
        textField.delegate = self;
        
        [self.inputDict setObject:textField forKey:@(_inputID)];
        [self.eventDict setObject:[NSMutableDictionary dictionary] forKey:@(_inputID)];
        
        [self addSubview:textField fixedOn:fixedOn fixed:fixed];
        
        if ([keyboardType isEqualToString:@"default"]) {
            textField.keyboardType = UIKeyboardTypeDefault;
        }else if ([keyboardType isEqualToString:@"number"]) {
            textField.keyboardType = UIKeyboardTypeNumberPad;
        }else if ([keyboardType isEqualToString:@"search"]) {
            textField.returnKeyType = UIReturnKeySearch;
        }else if ([keyboardType isEqualToString:@"next"]) {
            textField.returnKeyType = UIReturnKeyNext;
        }else if ([keyboardType isEqualToString:@"done"]) {
            textField.returnKeyType = UIReturnKeyDone;
        }else if ([keyboardType isEqualToString:@"send"]) {
            textField.returnKeyType = UIReturnKeySend;
        }
        
        if ([alignment isEqualToString:@"left"]) {
            textField.textAlignment = NSTextAlignmentLeft;
        }else if ([alignment isEqualToString:@"center"]) {
            textField.textAlignment = NSTextAlignmentCenter;
        }else  {
            textField.textAlignment = NSTextAlignmentRight;
        }
        
        if (autoFocus) {
            [textField becomeFirstResponder];
        }
        
        UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
        [textField addGestureRecognizer:pan];
        [textField addTarget:self action:@selector(textFieldChange:) forControlEvents:UIControlEventEditingChanged];
    }else {
        UZTextView *textView = [[UZTextView alloc] initWithFrame:CGRectMake(frameX, frameY, frameW, frameH) styles:styles];
        textView.placeholder = placeholder;
        
        if ([inputType isEqualToString:@"password"]) {
            textView.secureTextEntry = YES;
        } else {
            textView.secureTextEntry = NO;
        }
        
        if ([alignment isEqualToString:@"left"]) {
            textView.textAlignment = NSTextAlignmentLeft;
        }else if ([alignment isEqualToString:@"center"]) {
            textView.textAlignment = NSTextAlignmentCenter;
        }else  {
            textView.textAlignment = NSTextAlignmentRight;
        }
        textView.delegate = self;
        [self.inputDict setObject:textView forKey:@(_inputID)];
        [self.eventDict setObject:[NSMutableDictionary dictionary] forKey:@(_inputID)];
        
        [self addSubview:textView fixedOn:fixedOn fixed:fixed];
        
        if ([keyboardType isEqualToString:@"default"]) {
            textView.keyboardType = UIKeyboardTypeDefault;
        }else if ([keyboardType isEqualToString:@"number"]) {
            textView.keyboardType = UIKeyboardTypeNumberPad;
        }else if ([keyboardType isEqualToString:@"search"]) {
            textView.keyboardType = UIKeyboardTypeWebSearch;
        }else if ([keyboardType isEqualToString:@"next"]) {
            textView.returnKeyType = UIReturnKeyNext;
        }else if ([keyboardType isEqualToString:@"done"]) {
            textView.returnKeyType = UIReturnKeyDone;
        }else if ([keyboardType isEqualToString:@"send"]) {
            textView.returnKeyType = UIReturnKeySend;
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
    [sendDict setObject:@"show" forKey:@"eventType"];
    [sendDict setObject:@(true) forKey:@"status"];
    [self sendResultEventWithCallbackId:openCbId dataDict:sendDict errDict:nil doDelete:NO];
}

- (void)resetPosition:(NSDictionary *)params_ {
    NSInteger targetID = [params_ integerValueForKey:@"id" defaultValue:-1];
    //rect
    NSDictionary *rect = [params_ dictValueForKey:@"position" defaultValue:@{}];
    float frameX,frameY;
    frameX = [rect floatValueForKey:@"x" defaultValue:0];
    frameY = [rect floatValueForKey:@"y" defaultValue:0];
    id target = [self.inputDict objectForKey:@(targetID)];
    if ([target isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)target;
        CGRect rect = textField.frame;
        rect.origin.x = frameX;
        rect.origin.y = frameY;
        textField.frame = rect;
    } else {
        UZTextView *textView = (UZTextView *)target;
        CGRect rect = textView.frame;
        rect.origin.x = frameX;
        rect.origin.y = frameY;
        textView.frame = rect;
    }
    
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
        [targetView resignFirstResponder];
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
    if (textfield) {
        if (msg) {
            textfield.text = msg;
        }
        if (textfield.text) {
            [sendDict setObject:@(true) forKey:@"status"];
            [sendDict setObject:textfield.text forKey:@"msg"];
        }
    }else if (textView) {
        if (msg) {
            textView.text = msg;
        }
        if (textView.text) {
            [sendDict setObject:@(true) forKey:@"status"];
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
    NSInteger listenID = [params_ integerValueForKey:@"id" defaultValue:_inputID];
    NSInteger listenCbId = [params_ integerValueForKey:@"cbId" defaultValue:-1];
    NSString *listenedName = [params_ stringValueForKey:@"name" defaultValue:nil];
    NSMutableDictionary *tempDict = [self.eventDict objectForKey:@(listenID)];
    [tempDict setObject:@(listenCbId) forKey:listenedName];
}
- (void)getSelectedRange:(NSDictionary *)params_ {
    NSInteger getSelectedRangeCbId = [params_ integerValueForKey:@"cbId" defaultValue:-1];
    NSInteger identity = [params_ integerValueForKey:@"id" defaultValue:_inputID];
    
    if ([[_maxRowsDict objectForKey:@(identity)] integerValue] == 1) {
        UITextField *textfield = (UITextField *)[_inputDict objectForKey:@(identity)];
        [self sendResultEventWithCallbackId:getSelectedRangeCbId dataDict:@{@"location":@([self selectedRange:textfield].location)} errDict:nil doDelete:YES];
    }else {
        UZTextView *targetView = (UZTextView *)[_inputDict objectForKey:@(identity)];
        [self sendResultEventWithCallbackId:getSelectedRangeCbId dataDict:@{@"location":@(targetView.selectedRange.location)} errDict:nil doDelete:YES];
    }
    
   
}
- (NSRange) selectedRange:(UITextField *)textField
{
    UITextPosition* beginning = textField.beginningOfDocument;
    
    UITextRange* selectedRange = textField.selectedTextRange;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    
    const NSInteger location = [textField offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [textField offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    return NSMakeRange(location, length);
}
#pragma mark - 输入框文本改变事件
- (void)textDidChange:(NSNotification *)notification {
    NSInteger idNumb = 0;
    UIView *targetView = nil;
    if ([notification.object isKindOfClass:[UITextField class]]) {
        targetView = (UITextField *)notification.object;for (NSNumber *key in self.inputDict.allKeys) {
            if ([[self.inputDict objectForKey:key] isEqual:targetView]) {
                idNumb = [key integerValue];
            }
        }
        int maxStringLenth = [[self.maxLengthDict objectForKey:@(idNumb)]intValue];
        UITextField *textField = (UITextField *)notification.object;
        if (maxStringLenth && textField.text.length>maxStringLenth && textField.markedTextRange == nil) {
            textField.text = [textField.text substringWithRange: NSMakeRange(0, maxStringLenth)];
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"acceptLimitLength" object: textField];
        }
    }else {
        targetView = (UZTextView *)notification.object;
        for (NSNumber *key in self.inputDict.allKeys) {
            if ([[self.inputDict objectForKey:key] isEqual:targetView]) {
                idNumb = [key integerValue];
            }
        }
        int maxStringLenth = [[self.maxLengthDict objectForKey:@(idNumb)]intValue];
        UZTextView *textView = (UZTextView *)notification.object;
        if (maxStringLenth && textView.text.length>maxStringLenth && textView.markedTextRange == nil) {
            textView.text = [textView.text substringWithRange: NSMakeRange(0, maxStringLenth)];
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"acceptLimitLength" object: textField];
        }
        //控制占位文字
        [targetView setNeedsDisplay];
    }
   
    
    //callback
    NSInteger openCbId = [[self.openCbIdDict objectForKey:@(idNumb)] integerValue];
    if (idNumb > 0 && openCbId >=0) {
        [self sendResultEventWithCallbackId:openCbId dataDict:@{@"id" : @(idNumb), @"eventType" : @"change"} errDict:nil doDelete:NO];
    }
}

#pragma mark - 键盘弹入弹出
- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat keyboardH = keyboardFrame.size.height;
    
    NSInteger objId = -1;
    for (NSNumber * cbIdNumber in self.inputDict) {
        UIView *listenedView = [self.inputDict objectForKey:cbIdNumber];
        if ([listenedView isFirstResponder]) {
            objId = [cbIdNumber integerValue];
            break;
        }
    }
    if (objId == -1) {
        return;
    }
    NSMutableDictionary *tmpDict = [self.eventDict objectForKey:@(objId)];
    NSString * targetEventName = @"becomeFirstResponder";
    NSNumber * cbId = [tmpDict objectForKey:targetEventName];
    if (cbId) {//监听键盘弹出事件时，回调给前端获取焦点事件
        [self sendResultEventWithCallbackId:[cbId integerValue] dataDict:@{@"keyboardHeight" : @(keyboardH)}  errDict:nil doDelete:NO];
    }
    //弹出键盘后若输入框被键盘遮挡的处理
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

#pragma mark - 多行输入框的代理事件

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
//    NSString *nowText = textView.text;
//    NSInteger local = range.location;
//    NSInteger lenth = range.length;
//    NSString *newText = text;
//    NSLog(@"当前文本内容：%@",nowText);
//    NSLog(@"range的位置：%zi",local);
//    NSLog(@"range的长度：%zi",lenth);
//    NSLog(@"新文本内容：%@",newText);
//    if (maxStringLenth>0 && text.length>0) {
//        NSInteger nowTextLength = textView.text.length;
//        if (nowTextLength < maxStringLenth) {
//            NSInteger addedTextLength = nowTextLength + text.length;
//            if (addedTextLength>maxStringLenth) {
//                return NO;
//            }
//        } else {
//            return NO;
//        }
//    }
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
                } else if ([keyboardType isEqualToString:@"search"]) {
                    //callback
                    NSMutableDictionary *sendDict = [NSMutableDictionary dictionary];
                    NSInteger openCbId = [[self.openCbIdDict objectForKey:key] integerValue];
                    [sendDict setObject:@(_inputID) forKey:@"id"];
                    //[sendDict setObject:key forKey:@"id"];
                    [sendDict setObject:@"search" forKey:@"eventType"];
                    if (openCbId) {
                        [self sendResultEventWithCallbackId:openCbId dataDict:sendDict errDict:nil doDelete:NO];
                    }
                
                } else if ([keyboardType isEqualToString:@"send"]) {
                    //callback
                    NSMutableDictionary *sendDict = [NSMutableDictionary dictionary];
                    NSInteger openCbId = [[self.openCbIdDict objectForKey:key] integerValue];
                    [sendDict setObject:key forKey:@"id"];
                    [sendDict setObject:@"send" forKey:@"eventType"];
                    if (openCbId) {
                        [self sendResultEventWithCallbackId:openCbId dataDict:sendDict errDict:nil doDelete:NO];
                    }
                }else if ([keyboardType isEqualToString:@"done"]) {
                    //callback
                    NSMutableDictionary *sendDict = [NSMutableDictionary dictionary];
                    NSInteger openCbId = [[self.openCbIdDict objectForKey:key] integerValue];
                    [sendDict setObject:key forKey:@"id"];
                    [sendDict setObject:@"done" forKey:@"eventType"];
                    if (openCbId) {
                        [self sendResultEventWithCallbackId:openCbId dataDict:sendDict errDict:nil doDelete:NO];
                    }
                }
            }
        }
    }
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    NSInteger objId = -1;
    for (NSNumber * cbIdNumber in self.inputDict) {
        UITextView * tv = [self.inputDict objectForKey:cbIdNumber];
        if ([tv isEqual:textView]) {
            objId = [cbIdNumber integerValue];
            break;
        }
    }
    if (objId == -1) {
        return YES;
    }
    NSMutableDictionary *tmpDict = [self.eventDict objectForKey:@(objId)];
    NSString * targetEventName = @"resignFirstResponder";
    NSNumber * cbId = [tmpDict objectForKey:targetEventName];
    
    if (cbId) {
        [self sendResultEventWithCallbackId:[cbId integerValue] dataDict:nil errDict:nil doDelete:NO];
    }
    return YES;
}

#pragma mark - 单行输入框的代理事件

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
//    NSString *nowText = textField.text;
//    NSInteger local = range.location;
//    NSInteger lenth = range.length;
//    NSString *newText = string;
//    NSLog(@"textField 当前文本内容：%@",nowText);
//    NSLog(@"textField range的位置：%zi",local);
//    NSLog(@"textField range的长度：%zi",lenth);
//    NSLog(@"textField 新文本内容：%@",newText);
//    
//    if (maxStringLenth>0 && string.length>0) {
//        NSInteger nowTextLength = textField.text.length;
//        if (nowTextLength < maxStringLenth) {
//            NSInteger addedTextLength = nowTextLength + string.length;
//            if (addedTextLength > maxStringLenth) {
//                return NO;
//            }
//        } else {
//            return NO;
//        }
//    }
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
                        //[sendDict setObject:@(_inputID) forKey:@"id"];
                        [sendDict setObject:key forKey:@"id"];
                        [sendDict setObject:@"search" forKey:@"eventType"];
                        if (openCbId) {
                            [self sendResultEventWithCallbackId:openCbId dataDict:sendDict errDict:nil doDelete:NO];
                        }
                    }
                }else if ([keyboardType isEqualToString:@"send"]) {
                    if (key) {
                        //callback
                        NSMutableDictionary *sendDict = [NSMutableDictionary dictionary];
                        NSInteger openCbId = [[self.openCbIdDict objectForKey:key] integerValue];
                        [sendDict setObject:key forKey:@"id"];
                        [sendDict setObject:@"send" forKey:@"eventType"];
                        if (openCbId) {
                            [self sendResultEventWithCallbackId:openCbId dataDict:sendDict errDict:nil doDelete:NO];
                        }
                    }
                }else if ([keyboardType isEqualToString:@"done"]) {
                    if (key) {
                        //callback
                        NSMutableDictionary *sendDict = [NSMutableDictionary dictionary];
                        NSInteger openCbId = [[self.openCbIdDict objectForKey:key] integerValue];
                        [sendDict setObject:key forKey:@"id"];
                        [sendDict setObject:@"done" forKey:@"eventType"];
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

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    NSInteger objId = -1;
    for (NSNumber * cbIdNumber in self.inputDict) {
        UITextField * tf = [self.inputDict objectForKey:cbIdNumber];
        if ([tf isEqual:textField]) {
            objId = [cbIdNumber integerValue];
            break;
        }
    }
    if (objId == -1) {
        return YES;
    }
    NSMutableDictionary *tmpDict = [self.eventDict objectForKey:@(objId)];
    NSString * targetEventName = @"resignFirstResponder";
    NSNumber * cbId = [tmpDict objectForKey:targetEventName];
    
    if (cbId) {
        [self sendResultEventWithCallbackId:[cbId integerValue] dataDict:nil errDict:nil doDelete:NO];
    }
    
    return YES;
}

//获取定制的textField
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

#pragma mark - 属性访问器

- (NSMutableDictionary *)eventDict {
    if (!_eventDict) {
        _eventDict = [NSMutableDictionary dictionary];
    }
    return _eventDict;
}

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

#pragma mark -utility

- (void)pan:(UIPanGestureRecognizer * )pan {
    UITextField * textField = (UITextField *)pan.view;
    
    if (self.currentTextField != textField) {
        return;
    }
    if (textField.text.length == 0) {
        return;
    }
    
    if (!self.isScroll) {
        return;
    }
    
    if (self.isEnd) {
        return;
    } else {
        if (self.textContentView.bounds.origin.x < -self.textContentView.superview.bounds.origin.x) {
            CGRect bounds = CGRectMake(-self.textContentView.superview.bounds.origin.x, self.textContentView.bounds.origin.y,self.textContentView.bounds.size.width, self.textContentView.bounds.size.height);
            self.textContentView.bounds = bounds;
            
            return;
        }
        
        if (self.textContentView.bounds.origin.x > self.textContentView.bounds.size.width - self.textContentView.superview.bounds.origin.x - self.textContentView.superview.bounds.size.width) {
            CGRect bounds = CGRectMake(self.textContentView.bounds.size.width - self.textContentView.superview.bounds.origin.x - self.textContentView.superview.bounds.size.width, self.textContentView.bounds.origin.y, self.textContentView.bounds.size.width, self.textContentView.bounds.size.height);
            self.textContentView.bounds = bounds;
            
            return;
        }
    }
    
    if (pan.state == UIGestureRecognizerStateBegan || pan.state == UIGestureRecognizerStateChanged) {
        
        CGPoint point = [pan translationInView:pan.view];
        
        CGRect bounds = CGRectMake(self.textContentView.bounds.origin.x - point.x, self.textContentView.bounds.origin.y, self.textContentView.bounds.size.width, self.textContentView.bounds.size.height);
        self.textContentView.bounds = bounds;
        
        [pan setTranslation:CGPointZero inView:pan.view];
    }
}

- (void)textFieldChange:(UITextField *)textField {
    if (self.textContentView.bounds.size.width > self.textContentView.superview.bounds.size.width) {
        self.isScroll = YES;
    }else{
        self.isScroll = NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.currentTextField = nil;
    self.isEnd = YES;
    CGRect bounds = CGRectMake(0, self.textContentView.bounds.origin.y, self.textContentView.bounds.size.width, self.textContentView.bounds.size.height);
    self.textContentView.bounds = bounds;
    self.textContentView = nil;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    self.currentTextField = textField;
    if(@available(iOS 11.0, *)){
        self.textContentView = [textField valueForKey:@"textContentView"];
    } else {
        for (UIView * view in textField.subviews) {
            if ([view isKindOfClass:NSClassFromString(@"UIFieldEditor")]) {
                
                self.textContentView = [view valueForKey:@"contentView"];
                
                break;
            }
        }
    }
    self.isEnd = NO;
    CGRect bounds = CGRectMake(0, self.textContentView.bounds.origin.y, self.textContentView.bounds.size.width, self.textContentView.bounds.size.height);
    self.textContentView.bounds = bounds;
    
    if (self.textContentView.bounds.size.width > self.textContentView.superview.bounds.size.width) {
        self.isScroll = YES;
    }else{
        self.isScroll = NO;
    }
}

@end
