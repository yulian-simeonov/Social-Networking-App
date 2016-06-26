//
//  ESPhotoDetailsFooterView.h
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//

#import "HPGrowingTextView.h"

@interface ESPhotoDetailsFooterView : UIView

/**
 *  Textfield in which the comment is typed
 */
//@property (nonatomic, strong) UITextField *commentField;
@property (nonatomic, strong) HPGrowingTextView *commentField;
/**
 *  Wether we hide the shadow or not
 */
@property (nonatomic) BOOL hideDropShadow;
/**
 *  Container view of the header
 */
@property (nonatomic, strong) UIView *mainView;
/**
 *  A navigationcontroller used to push new viewcontrollers
 */
@property (nonatomic, strong) UINavigationController *navController;

@property (nonatomic,readonly) UIButton *camButton;

/**
 *  Defining the size of the footer
 *
 *  @return size of the footer
 */
+ (CGRect)rectForView;

@end


