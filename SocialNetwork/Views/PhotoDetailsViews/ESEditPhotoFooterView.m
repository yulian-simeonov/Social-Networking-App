//This section is the leave a comment for the photo or video section after the user gets here from the main timeline.
//
//  ESPhotoDetailsFooterView.m
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//

#import "ESEditPhotoFooterView.h"
#import "ESUtility.h"

@interface ESEditPhotoFooterView ()

@end

@implementation ESEditPhotoFooterView

@synthesize commentField;
@synthesize mainView;
@synthesize hideDropShadow;



#pragma mark - NSObject

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        
        mainView = [[UIView alloc] initWithFrame:CGRectMake( 0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, 51.0f)]; //10, 300
        //Below is the box color around the comment field.
        mainView.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1];
        [self addSubview:mainView];
        
        UIImageView *commentBox = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"TextFieldComment"] resizableImageWithCapInsets:UIEdgeInsetsMake(5.0f, 10.0f, 5.0f, 10.0f)]];
        //Comment field color below.
        commentBox.backgroundColor = [UIColor whiteColor];
        //Comment field below.
        //commentBox.frame = CGRectMake(55.0f, 8.0f, [UIScreen mainScreen].bounds.size.width - 70, 35.0f);
        commentBox.frame = CGRectMake(8.0f, 8.0f, [UIScreen mainScreen].bounds.size.width - 16, 35.0f);
        [mainView addSubview:commentBox];
        
        //Below is the position for the words Add a Comment in the comment box.
        //commentField = [[UITextField alloc] initWithFrame:CGRectMake( 60.0f, 10.0f, [UIScreen mainScreen].bounds.size.width - 55, 31.0f)];
        commentField = [[UITextField alloc] initWithFrame:CGRectMake( 18.0f, 10.0f, [UIScreen mainScreen].bounds.size.width - 55, 31.0f)];
        commentField.font = [UIFont systemFontOfSize:14.0f];
        commentField.placeholder = NSLocalizedString(@"Add a caption", nil);
        commentField.returnKeyType = UIReturnKeySend;
        commentField.textColor = [UIColor darkGrayColor];
        commentField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        [commentField setValue:[UIColor darkGrayColor] forKeyPath:@"_placeholderLabel.textColor"];
        [mainView addSubview:commentField];
    }
    return self;
}


#pragma mark - UIView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (!hideDropShadow) {
        [ESUtility drawSideAndBottomDropShadowForRect:mainView.frame inContext:UIGraphicsGetCurrentContext()];
    }
}


#pragma mark - ESPhotoDetailsFooterView

+ (CGRect)rectForView {
    return CGRectMake( 0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, 51.0f);
}

@end
