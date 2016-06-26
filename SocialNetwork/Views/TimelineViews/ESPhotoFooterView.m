//
//  ESPhotoFooterView.m
//  d'Netzwierk
//
//  Created by Eric Schanet on 17.06.14.
//
//

#import "ESPhotoFooterView.h"
#import "ESProfileImageView.h"
#import "TTTTimeIntervalFormatter.h"
#import "ESUtility.h"
#import "ESConstants.h"

#import <QuartzCore/QuartzCore.h>


@interface ESPhotoFooterView ()
/**
 *  Containerview of the footer
 */
@property (nonatomic, strong) UIView *containerView2;
/**
 *  ImageView of the user's profile picture
 */
@property (nonatomic, strong) ESProfileImageView *avatarImageView;
/**
 *  Button with the username as title
 */
@property (nonatomic, strong) UIButton *userButton;
/**
 *  A timestamp indicating when the photo has been uploaded
 */
@property (nonatomic, strong) UILabel *timestampLabel;
/**
 *  Formatter used to create standardized time stamps
 */
@property (nonatomic, strong) TTTTimeIntervalFormatter *timeIntervalFormatter;
@end


@implementation ESPhotoFooterView
@synthesize containerView2;
@synthesize avatarImageView;
@synthesize userButton;
@synthesize timestampLabel;
@synthesize timeIntervalFormatter;
@synthesize photo;
@synthesize buttons;
@synthesize likeButton;
@synthesize commentButton;
@synthesize delegate;
@synthesize labelButton;
@synthesize labelComment;
@synthesize likeImage;
@synthesize commentImage;
@synthesize shareButton;
@synthesize commentLikeButton;


#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame buttons:(ESPhotoFooterButtons)otherButtons {
    self = [super initWithFrame:frame];
    if (self) {
        [ESPhotoFooterView validateButtons:otherButtons];
        buttons = otherButtons;
        
        self.clipsToBounds = NO;
        self.containerView2.clipsToBounds = NO;
        self.superview.clipsToBounds = NO;
        [self setBackgroundColor:[UIColor clearColor]];
        
        // translucent portion
        self.containerView2 = [[UIView alloc] initWithFrame:CGRectMake( 0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, self.bounds.size.height)];
        [self addSubview:self.containerView2];

        [self.containerView2 setOpaque:NO];
        self.opaque = NO;
        [self.containerView2 setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0]];
        [self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0]];
        self.superview.opaque = NO;
        
        UIImageView *containerImage = [[UIImageView alloc]initWithImage:nil];
        containerImage.backgroundColor = [UIColor whiteColor];
        [containerImage setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 84)];
        [self.containerView2 addSubview:containerImage];
        
        UIImageView *straightLine = [[UIImageView alloc]initWithImage:nil];
        //straightLine.backgroundColor = [UIColor colorWithRed:211.0f/255.0f green:211.0f/255.0f blue:211.0f/255 alpha:1.0f];
        straightLine.backgroundColor = [UIColor colorWithRed:239.0f/255.0f green:239.0f/255.0f blue:239.0f/255 alpha:1.0f];
        //straightLine.backgroundColor = [UIColor grayColor];
        //[straightLine setFrame:CGRectMake(5, 70, 365, 15)];
        [straightLine setFrame:CGRectMake(-2, 55, 385, 10)];
        straightLine.layer.cornerRadius = 3;
        
        
        straightLine.clipsToBounds = YES;
        //straightLine.layer.cornerRadius = 8.0;
        straightLine.layer.borderWidth = 1.0;
        straightLine.layer.borderColor = [UIColor colorWithRed:219.0f/255.0f green:219.0f/255.0f blue:219.0f/255 alpha:1.0f].CGColor;
        
        
        
        //straightLine.alpha = 0.0;
        [self.containerView2 addSubview:straightLine];
        
        //UIButton *backgroundHeart = [[UIButton alloc]initWithFrame:CGRectMake(20.0f, 30.0f, 90.0f, 29.0f)];
        UIButton *backgroundHeart = [[UIButton alloc]initWithFrame:CGRectMake(10.0f, 10.0f, 29.0f, 29.0f)];
        if (IS_IPHONE6) {
            //backgroundHeart.frame = CGRectMake(30.0f, 30.0f, 90.0f, 29.0f);
            backgroundHeart.frame = CGRectMake(10.0f, 10.0f, 29.0f, 29.0f);
        }
        [backgroundHeart setImage:[UIImage imageNamed:@"ButtonLike"] forState:UIControlStateNormal];
        //backgroundHeart.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:240.0f/255.0f blue:240.0f/255.0f alpha:1.0f];
        backgroundHeart.layer.cornerRadius = 2;
        [containerView2 addSubview:backgroundHeart];
        backgroundHeart.userInteractionEnabled = NO;
        
    
        //Share Button on timeline.
        shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [containerView2 addSubview:self.shareButton];
        
        
        
        if (IS_IPHONE_4_OR_LESS) {
            [self.shareButton setFrame:CGRectMake( 283.0f, 10.0f, 29.0f, 29.0f)];
        }
        else if (IS_IPHONE_5) {
            [self.shareButton setFrame:CGRectMake( 283.0f, 10.0f, 29.0f, 29.0f)];
        }
        else if (IS_IPHONE_6) {
            [self.shareButton setFrame:CGRectMake( 337.0f, 10.0f, 29.0f, 29.0f)];
        }
        else if (IS_IPHONE_6P) {
            [self.shareButton setFrame:CGRectMake( 375.0f, 10.0f, 29.0f, 29.0f)];
        }
        else if (IS_IPAD) {
            [self.shareButton setFrame:CGRectMake( 731.0f, 10.0f, 29.0f, 29.0f)];
        }
        else {
            [self.shareButton setFrame:CGRectMake( 337.0f, 10.0f, 29.0f, 29.0f)];
        }
        
        
        
        
        
        
        
        
        
        
        /*
        if (IS_IPHONE6) {
            //[self.shareButton setFrame:CGRectMake( 143.0f, 30.0f, 90.0f, 29.0f)];
            [self.shareButton setFrame:CGRectMake( 337.0f, 10.0f, 29.0f, 29.0f)];
        }
        else {
            //[self.shareButton setFrame:CGRectMake( 115.0f, 30.0f, 90.0f, 29.0f)];
            [self.shareButton setFrame:CGRectMake( 140.0f, 10.0f, 29.0f, 29.0f)];
        }
        */
        
        
        
        //[self.shareButton setBackgroundColor:[UIColor colorWithRed:240.0f/255.0f green:240.0f/255.0f blue:240.0f/255.0f alpha:1.0f]];
        [self.shareButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f,0.0f, 0.0f, 0.0f)];
        [self.shareButton setImage:[UIImage imageNamed:@"ShareButton"] forState:UIControlStateNormal];
        [self.shareButton setSelected:NO];
        [self.shareButton addTarget:nil action:@selector(shareButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        self.shareButton.layer.cornerRadius = 3;
        
        
        if (self.buttons & ESPhotoFooterButtonsComment) {
            // comments button
            
            
            //Below is the comment count
            commentImage = [UIButton buttonWithType:UIButtonTypeCustom];
            [containerView2 addSubview:self.commentImage];
            [self.commentImage setFrame:CGRectMake( 140.0f, 10.0f, 40.0f, 29.0f)];
            [self.commentImage setBackgroundColor:[UIColor clearColor]];
            //[self.commentImage setTitle:@"0" forState:UIControlStateNormal];
            [self.commentImage setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [self.commentImage setTitleEdgeInsets:UIEdgeInsetsMake( 0.0f, 0.0f, 0.0f, 0.0f)];
            [[self.commentImage titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]]; // The size of the Number of comments
            [[self.commentImage titleLabel] setMinimumScaleFactor:0.8f];
            [[self.commentImage titleLabel] setAdjustsFontSizeToFitWidth:YES];
            //self.commentImage.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
            self.commentImage.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            
            commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [containerView2 addSubview:self.commentButton];
            
            
            /*
            if (IS_IPHONE_4_OR_LESS) {
                [self.commentButton setFrame:CGRectMake( 105.0f, 10.0f, 29.0f, 29.0f)];
            }
            else if (IS_IPHONE_5) {
                [self.commentButton setFrame:CGRectMake( 105.0f, 10.0f, 29.0f, 29.0f)];
            }
            else if (IS_IPHONE_6) {
                [self.commentButton setFrame:CGRectMake( 105.0f, 10.0f, 29.0f, 29.0f)];
            }
            else if (IS_IPHONE_6P) {
                [self.commentButton setFrame:CGRectMake( 105.0f, 10.0f, 29.0f, 29.0f)];
            }
            else if (IS_IPAD) {
                [self.commentButton setFrame:CGRectMake( 105.0f, 10.0f, 29.0f, 29.0f)];
            }
            else {
                [self.commentButton setFrame:CGRectMake( 105.0f, 10.0f, 29.0f, 29.0f)];
            }
            */
            
            
            
            //if (IS_IPHONE6) {
                [self.commentButton setFrame:CGRectMake( 105.0f, 10.0f, 29.0f, 29.0f)];
            //[self.commentButton setFrame:CGRectMake( 90.0f, -10.0f, 50.0f, 50.0f)];
            //}
            //else {
                //[self.commentButton setFrame:CGRectMake( 170.0f, 10.0f, 29.0f, 29.0f)];
                //[self.commentButton setFrame:CGRectMake( 210.0f, 30.0f, 50.0f, 50.0f)];
            //}
            
            
            
            
            
            
            
            //Button color
            //[self.commentButton setBackgroundColor:[UIColor colorWithRed:240.0f/255.0f green:240.0f/255.0f blue:240.0f/255.0f alpha:1.0f]];
            self.commentButton.layer.cornerRadius = 3;
            [self.commentButton setTitle:@"" forState:UIControlStateNormal];
            [self.commentButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [self.commentButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
            [self.commentButton setTitleEdgeInsets:UIEdgeInsetsMake( 0.0f, 0.0f, 0.0f, 0.0f)];
            [self.commentButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f,0.0f, 0.0f, 0.0f)];
            [[self.commentButton titleLabel] setShadowOffset:CGSizeMake( 0.0f, 1.0f)];
            [[self.commentButton titleLabel] setFont:[UIFont systemFontOfSize:12.0f]];
            [[self.commentButton titleLabel] setMinimumScaleFactor:0.8f];
            [[self.commentButton titleLabel] setAdjustsFontSizeToFitWidth:YES];
            [self.commentButton setImage:[UIImage imageNamed:@"IconComment"] forState:UIControlStateNormal];
            [self.commentButton setSelected:NO];
            
            //Below displays the wording for comments
            labelComment = [UIButton buttonWithType:UIButtonTypeCustom];
            //[containerView2 addSubview:self.labelComment];
            [self.labelComment setFrame:CGRectMake( 148.0f, 10.0f, 80.0f, 29.0f)];
            [self.labelComment setBackgroundColor:[UIColor clearColor]];
            [self.labelComment setTitle:NSLocalizedString(@"comments", nil) forState:UIControlStateNormal];
            [self.labelComment setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [self.labelComment setTitleEdgeInsets:UIEdgeInsetsMake( 0.0f, 0.0f, 0.0f, 0.0f)];
            [[self.labelComment titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]]; // The wording Comments
            [[self.labelComment titleLabel] setMinimumScaleFactor:0.8f];
            [[self.labelComment titleLabel] setAdjustsFontSizeToFitWidth:NO];
            self.labelComment.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            }
        

        
        if (self.buttons & ESPhotoFooterButtonsLike) {
            // like button
            UIImage *image = [UIImage imageNamed:@"ButtonLike"];
            UIImage *image2 = [UIImage imageNamed:@"ButtonLikeSelected"];
            
            likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
            labelButton = [UIButton buttonWithType:UIButtonTypeCustom];
            likeImage = [UIButton buttonWithType:UIButtonTypeCustom];
            [containerView2 addSubview:self.labelButton];
            [containerView2 addSubview:self.likeImage];
            [containerView2 addSubview:self.likeButton];
            if (IS_IPHONE6) {
                //[self.likeButton setFrame:CGRectMake(30.0f, 30.0f, 90.0f, 29.0f)];
                [self.likeButton setFrame:CGRectMake(10.0f, 10.0f, 29.0f, 29.0f)];
            }
            else {
                //[self.likeButton setFrame:CGRectMake(20.0f, 30.0f, 90.0f, 29.0f)];
                [self.likeButton setFrame:CGRectMake(10.0f, 10.0f, 29.0f, 29.0f)];
            }
            //Below displays the like counts and the wording
            //[self.labelButton setFrame:CGRectMake(28.0f, 0.0f, 60.0f, 29.0f)];
 //           [self.labelButton setFrame:CGRectMake(52.0f, 10.0f, 60.0f, 29.0f)];
            //[self.likeImage setFrame:CGRectMake(-15.0f, 0.0f, 40.0f, 29.0f)];
            [self.likeImage setFrame:CGRectMake(45.0f, 10.0f, 40.0f, 29.0f)];
            
            //[self.likeButton setBackgroundColor:[UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:200.0f/255.0f alpha:1.0f]];
            [self.labelButton setBackgroundColor:[UIColor clearColor]];
            [self.likeImage setBackgroundColor:[UIColor clearColor]];
            [self.likeButton setTitle:@"" forState:UIControlStateNormal];
            [self.labelButton setTitle:NSLocalizedString(@"likes", nil) forState:UIControlStateNormal];
            [self.likeImage setTitle:@"0" forState:UIControlStateNormal];
            [self.likeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [self.labelButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [self.likeImage setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [self.likeButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
            [self.labelButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
            [self.likeImage setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
            [self.likeButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateSelected];
            [self.labelButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateSelected];
            [self.likeImage setTitleShadowColor:[UIColor clearColor] forState:UIControlStateSelected];
            [self.likeButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
            [self.likeButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f,0.0f, 0.0f, 0.0f)];
            [self.likeImage setImageEdgeInsets:UIEdgeInsetsMake(0.0f,0.0f, 0.0f, 0.0f)];
            self.labelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            //self.likeImage.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
            self.likeImage.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            [self.labelButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f,0.0f, 0.0f, 0.0f)];
            [self.likeImage setTitleEdgeInsets:UIEdgeInsetsMake(0.0f,0.0f, 0.0f, 0.0f)];
            [[self.likeButton titleLabel] setShadowOffset:CGSizeMake(0.0f, 0.0f)];
            [[self.labelButton titleLabel] setShadowOffset:CGSizeMake(0.0f, 0.0f)];
            [[self.likeImage titleLabel] setShadowOffset:CGSizeMake(0.0f, 0.0f)];
            [[self.likeButton titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]];
            [[self.labelButton titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]]; // The wording Like
            [[self.likeImage titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]];  // The Number
            [[self.likeButton titleLabel] setMinimumScaleFactor:0.8f];
            [[self.labelButton titleLabel] setMinimumScaleFactor:0.8f];
            [[self.likeImage titleLabel] setMinimumScaleFactor:0.8f];
            [[self.likeButton titleLabel] setAdjustsFontSizeToFitWidth:YES];
            [[self.labelButton titleLabel] setAdjustsFontSizeToFitWidth:YES];
            [[self.likeImage titleLabel] setAdjustsFontSizeToFitWidth:YES];
            [self.likeButton setAdjustsImageWhenHighlighted:NO];
            [self.labelButton setAdjustsImageWhenHighlighted:NO];
            [self.likeImage setAdjustsImageWhenHighlighted:NO];
            [self.likeButton setAdjustsImageWhenDisabled:NO];
            [self.labelButton setAdjustsImageWhenDisabled:NO];
            [self.likeImage setAdjustsImageWhenDisabled:NO];
            [self.likeButton setImage:image forState:UIControlStateNormal];
            [self.likeButton setImage:image2 forState:UIControlStateSelected];
            [self.likeButton setSelected:NO];
            [self.labelButton setSelected:NO];
        }
        //Below is what shows the details controller when the likes or comments text is tappped
        
        //commentLikeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        //[containerView2 addSubview:self.commentLikeButton];
        //[self.commentLikeButton setFrame:CGRectMake(170, 10, 29, 29)];
        //[self.commentLikeButton setBackgroundColor:[UIColor clearColor]];
        //[self.commentLikeButton addTarget:self action:@selector(didTapCommentOnPhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
    return self;
}


#pragma mark - ESPhotoFooterView

- (void)setPhoto:(PFObject *)aPhoto {
    
    photo = aPhoto;
    
    [self.shareButton addTarget:self action:@selector(didTapSharePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    CGFloat constrainWidth = containerView2.bounds.size.width;
    
    if (self.buttons & ESPhotoFooterButtonsComment) {
        constrainWidth = self.commentButton.frame.origin.x;
        [self.commentButton addTarget:self action:@selector(didTapCommentOnPhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (self.buttons & ESPhotoFooterButtonsLike) {
        constrainWidth = self.likeButton.frame.origin.x;
        [self.likeButton addTarget:self action:@selector(didTapLikePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self setNeedsDisplay];
}

- (void)setLikeStatus:(BOOL)liked {
    [self.likeButton setSelected:liked];
    
    if (liked) {
        //        [self.likeButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
        [[self.likeButton titleLabel] setShadowOffset:CGSizeMake(0.0f, -1.0f)];
    } else {
        //        [self.likeButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
        [[self.likeButton titleLabel] setShadowOffset:CGSizeMake(0.0f, 1.0f)];
    }
}

- (void)shouldEnableLikeButton:(BOOL)enable {
    
    if (enable) {
        [self.likeButton removeTarget:self action:@selector(didTapLikePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [self.likeButton addTarget:self action:@selector(didTapLikePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
}
- (void)shouldReEnableLikeButton:(NSNumber*)enable {
    
    if (enable == [NSNumber numberWithInt:1]) {
        self.likeButton.userInteractionEnabled = YES;
    } else {
        self.likeButton.userInteractionEnabled = NO;
    }
}
- (void)shareButtonTapped {

}

#pragma mark - ()

+ (void)validateButtons:(ESPhotoFooterButtons)buttons {
    if (buttons == ESPhotoFooterButtonsNone) {
        [NSException raise:NSInvalidArgumentException format:@"Buttons must be set before initializing ESPhotoFooterView."];
    }
}

- (void)didTapLikePhotoButtonAction:(UIButton *)button {
    if (delegate && [delegate respondsToSelector:@selector(photoFooterView:didTapLikePhotoButton:photo:)]) {
        [delegate photoFooterView:self didTapLikePhotoButton:button photo:self.photo];
    }
}

- (void)didTapCommentOnPhotoButtonAction:(UIButton *)sender {
    if (delegate && [delegate respondsToSelector:@selector(photoFooterView:didTapCommentOnPhotoButton:photo:)]) {
        [delegate photoFooterView:self didTapCommentOnPhotoButton:sender photo:self.photo];
    }
}
- (void)didTapSharePhotoButtonAction:(UIButton *)sender {
    if (delegate && [delegate respondsToSelector:@selector(photoFooterView:didTapSharePhotoButton:photo:)]) {
        [delegate photoFooterView:self didTapSharePhotoButton:sender photo:self.photo];
    }
}

@end

