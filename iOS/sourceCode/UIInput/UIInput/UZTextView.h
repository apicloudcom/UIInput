/**
  * APICloud Modules
  * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
  * Licensed under the terms of the The MIT License (MIT).
  * Please see the license.html included with this distribution for details.
  */

#import <UIKit/UIKit.h>

@interface UZTextView : UITextView

/** 占位文字 */
@property (nonatomic, copy) NSString *placeholder;

- (instancetype)initWithFrame:(CGRect)frame styles:(NSDictionary *)styles;
@end
