//This section is the leave a comment for the photo or video section after the user gets here from the main timeline.
//
//  ESPhotoDetailsFooterView.m
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//

#import "ESPhotoDetailsFooterView.h"
#import "ESUtility.h"
#import "RecorderPhotoCommentViewController.h"

@interface ESPhotoDetailsFooterView () <HPGrowingTextViewDelegate>

@end

@implementation ESPhotoDetailsFooterView

@synthesize commentField;
@synthesize mainView;
@synthesize hideDropShadow;
@synthesize navController;


#pragma mark - NSObject

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.navController = [[UINavigationController alloc] init];

        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        
        [self createView];
    }
    return self;
}


- (void)btnClicked:(UIButton *)sender {
    
    [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    RecorderPhotoCommentViewController *viewController = [[RecorderPhotoCommentViewController alloc] init];
    [viewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [self.navController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [self.navController pushViewController:viewController animated:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        #define ROOTVIEW [[[UIApplication sharedApplication] keyWindow] rootViewController]
        [ROOTVIEW presentViewController:self.navController animated:YES completion:^{}];
    });
    
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


- (void)createView {
    
    mainView = [[UIView alloc] initWithFrame:CGRectMake( [UIScreen mainScreen].bounds.origin.x,  [UIScreen mainScreen].bounds.origin.y, [UIScreen mainScreen].bounds.size.width,  51.0f)];
    mainView.backgroundColor = [UIColor colorWithRed:233.0/255.0 green:233.0/255.0 blue:233.0/255.0 alpha:1.0];
    [self addSubview:mainView];
    
    // Create a standard UIButton programmatically using convenience method
    UIButton *camButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    // Set the location (x,y) and size (width,height) of the button
    camButton.frame = CGRectMake(9.0f, 8.0f, 35.0f, 35.0f);
    
    // Create UIImages from image resources in your application bundle
    // using convenience methods (no need to release)
    UIImage *normal = [UIImage imageNamed:@"Comm"];
    UIImage *highlighted = [UIImage imageNamed:@"CommClick"];
    
    // Set the button's background to an image
    [camButton setBackgroundImage:normal forState:UIControlStateNormal];
    [camButton setBackgroundImage:highlighted forState:UIControlStateHighlighted];
    
    // Add the target-action for the touch event
#pragma GCC diagnostic ignored "-Wundeclared-selector"
    
    
    [camButton addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.mainView addSubview:camButton];
    
    self.commentField = [[HPGrowingTextView alloc] initWithFrame:CGRectMake(51.0f, 8.0f, [UIScreen mainScreen].bounds.size.width - 59, 35.0f)];
    self.commentField.isScrollable = NO;
    self.commentField.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    self.commentField.minNumberOfLines = 1;
    self.commentField.maxNumberOfLines = 5;
    self.commentField.returnKeyType = UIReturnKeyDefault; //just as an example
    self.commentField.font = [UIFont systemFontOfSize:16.0f];
    self.commentField.delegate = self;
    self.commentField.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    self.commentField.backgroundColor = [UIColor whiteColor];
    self.commentField.keyboardType=UIKeyboardTypeDefault;
    self.commentField.textColor = [UIColor darkGrayColor];
    [self.commentField setPlaceholder:@"Add a comment..."];
    self.commentField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.commentField.returnKeyType = UIReturnKeyDone;
    
    
    commentField.layer.cornerRadius=6;
    commentField.layer.borderColor=[UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:1.0].CGColor;
    commentField.layer.borderWidth=1.0;
    commentField.clipsToBounds=YES;
    
    [mainView addSubview:commentField];
    
    //[self.commentField becomeFirstResponder];
    
}

@end
