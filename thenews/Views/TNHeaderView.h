//
//  TNHeaderView.h
//  The News
//
//  Created by Tosin Afolabi on 06/04/2014.
//  Copyright (c) 2014 Tosin Afolabi. All rights reserved.
//

#import "DNStory.h"
#import <UIKit/UIKit.h>

typedef void (^ButtonActionBlock)(void);

@interface TNHeaderView : UIView

@property (strong, nonatomic) DNStory *story;

- (id)initWithFrame:(CGRect)frame type:(TNType)type;
- (void)configureForStory:(DNStory *)story;

- (void)setButtonTitle:(NSString *)title;
- (void)setButtonAction:(ButtonActionBlock)block;

@end
