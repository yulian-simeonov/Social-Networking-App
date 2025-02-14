//
//  ESAccountViewController.m
//  D'Netzwierk
//
//  Created by Eric Schanet on 6/05/2014.
//  Copyright (c) 2014 Eric Schanet. All rights reserved.
//

//Original header height below
//#define HeaderHeight 265.0f
#define HeaderHeight 320.0f

#define IS_IPHONE5 (([[UIScreen mainScreen] bounds].size.height-568)?NO:YES)

#import "ESAccountViewController.h"
#import "ESPhotoCell.h"
#import "TTTTimeIntervalFormatter.h"
#import "ESLoadMoreCell.h"
#import "UIImage+ImageEffects.h"
#import "UIImage+ResizeAdditions.h"
#import "ESEditPhotoViewController.h"
#import "SCLAlertView.h"
#import "ESEditProfileViewController.h"

#import "MMDrawerBarButtonItem.h"
#import "MFSideMenu.h"
#import "AppDelegate.h"
#import "KILabel.h"
#import "TOWebViewController.h"
#import "ESFollowersViewController.h"






#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)




//ADDED
#import "RecorderProfileViewController.h"


CGFloat const offset_HeaderStop = 40.0;
CGFloat const offset_B_LabelHeader = 0.0;
CGFloat const distance_W_LabelHeader = 35.0;

@implementation ESAccountViewController
@synthesize headerView, user, profilePictureImageView, backgroundImageView, reportUser, userDisplayNameLabel, infoLabel, userMentionLabel, profilePictureBackgroundView, siteLabel, whiteBackground, grayLine, texturedBackgroundView, photoCountLabel, followerCountLabel, followingCountLabel, editProfileBtn, cityLabel, segmentedControl, followerBtn, followingBtn, photosBtn;


//ADDED for video profile
@synthesize moviePlayer;
//@synthesize mediaItemButton;
//



#pragma mark - UIViewController
-(void)tapBtn {
    
    [self.menuContainerViewController setMenuState:MFSideMenuStateLeftMenuOpen completion:^{}];
    
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ESTabBarControllerDidFinishEditingPhotoNotification object:nil];
    
}
-(void)viewWillAppear:(BOOL)animated {
    self.tableView.tag = 2;
    self.navigationController.navigationBarHidden = NO;
    [self updateBarButtonItems:1];
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.container.panMode = MFSideMenuPanModeDefault;
    if ([self.user objectForKey:@"profileColor"]) {
        NSArray *components = [[self.user objectForKey:@"profileColor"] componentsSeparatedByString:@","];
        CGFloat r = [[components objectAtIndex:0] floatValue];
        CGFloat g = [[components objectAtIndex:1] floatValue];
        CGFloat b = [[components objectAtIndex:2] floatValue];
        CGFloat a = [[components objectAtIndex:3] floatValue];
        UIColor *color = [UIColor colorWithRed:r green:g blue:b alpha:a];
        self.navigationController.navigationBar.barTintColor = color;
    }
    else {
        //self.navigationController.navigationBar.barTintColor = [UIColor colorWithHue:204.0f/360.0f saturation:76.0f/100.0f brightness:86.0f/100.0f alpha:1];
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithHue:196.0f/360.0f saturation:100.0f/100.0f brightness:94.0f/100.0f alpha:1];
    }
    
    //Calculate Luminance
    CGFloat luminance;
    CGFloat red, green, blue;
    
    //Check for clear or uncalculatable color and assume white
    if (![self.navigationController.navigationBar.barTintColor getRed:&red green:&green blue:&blue alpha:nil]) {
        self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar"]];
    }
    
    //Relative luminance in colorimetric spaces - http://en.wikipedia.org/wiki/Luminance_(relative)
    red *= 0.2126f; green *= 0.7152f; blue *= 0.0722f;
    luminance = red + green + blue;
    
    if (luminance > 0.5f) {
   //     self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBarDark"]];
    }
    else     self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar"]];


}
- (void)viewDidAppear:(BOOL)animated {
    PFFile *imageFile = [self.user objectForKey:kESUserProfilePicMediumKey];
    if (imageFile) {
        [profilePictureImageView setFile:imageFile];
        [profilePictureImageView loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) { }
        }];
    }
    
    //[self restartVideo];
    [moviePlayer play];
}

-(void)viewWillDisappear:(BOOL)animated {
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = nil;
    //self.navigationController.navigationBar.barTintColor = [UIColor colorWithHue:204.0f/360.0f saturation:76.0f/100.0f brightness:86.0f/100.0f alpha:1];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithHue:196.0f/360.0f saturation:100.0f/100.0f brightness:94.0f/100.0f alpha:1];

    //NSLog(@"New view controller was pushed");
    ////////[moviePlayer stop];
    [moviePlayer stop];
}
- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.navigationBar.translucent = YES;
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.scrollsToTop = YES;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    
    if (!self.user) {
        [NSException raise:NSInvalidArgumentException format:@"user cannot be nil"];
    }
    MMDrawerBarButtonItem * leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(tapBtn)];
    if (self.tabBarController.selectedIndex == 1 && [[PFUser currentUser].objectId isEqualToString:self.user.objectId]) {
        [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
    }
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar"]];
    
    int i = 400;
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake( 0.0f, 0.0f, self.tableView.bounds.size.width, i)];
    [self.headerView setBackgroundColor:[UIColor clearColor]]; // should be clear, this will be the container for our avatar, photo count, follower count, following count, and so on
    
    [self setupHeader];
    
    
    
    //[self ReloadVideo:0];
    //[self restartVideo];
    ////[self restartVideo];
    
    
    //ADDED
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_data) name:@"reload_data" object:nil];
    //
}
- (void)updateBarButtonItems:(CGFloat)alpha
{
    [self.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    self.navigationItem.titleView.alpha = alpha;
    self.navigationController.navigationBar.tintColor = [self.navigationController.navigationBar.tintColor colorWithAlphaComponent:alpha];
}
- (void) disableScrollsToTopPropertyOnAllSubviewsOf:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            ((UIScrollView *)subview).scrollsToTop = NO;
        }
        [self disableScrollsToTopPropertyOnAllSubviewsOf:subview];
    }
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    //The section below controls if the users scrolls down then the background image stretches to fill the screen.
    CGFloat yPos = -scrollView.contentOffset.y;
    if (yPos > 0) {
        CGRect imgRect = self.imageView.frame;
        imgRect.origin.y = scrollView.contentOffset.y;
        
        imgRect.size.height = HeaderHeight+yPos;
        self.imageView.frame = imgRect;
    }
}

- (void)attemptOpenURL:(NSURL *)url
{
    TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:url];
    webViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:webViewController animated:YES];

}

# pragma mark - Header setup

- (void) setupHeader {
  
    //Below is where the video profile will display
    
/*    
    self.imageView = [[PFImageView alloc] initWithImage:[UIImage imageNamed:@""]];
    [self.imageView setFile:[self.user objectForKey:kESUserHeaderPicMediumKey]];
    [self.imageView loadInBackground:^(UIImage *image, NSError *error) {
    }];
    self.imageView.frame = CGRectMake(0, 0, self.view.frame.size.width, HeaderHeight);
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.headerView addSubview:self.imageView];
*/
    

    
    int w = 0;
    
    if (IS_IPHONE_4_OR_LESS) {
        w = 230.0f;
    }
    else if (IS_IPHONE_5) {
        w = 300.0f;
    }
    else if (IS_IPHONE_6) {
        w = 400.0f;
    }
    else if (IS_IPHONE_6P) {
        w = 470.0f;
    }
    else if (IS_IPAD) {
        w = 750.0f;
    }
    else {
        w = 400.0f;
    }
    

    
//Video Profile
    PFImageView *videoView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, w)];
    
    PFFile *_video =[self.user objectForKey:kESUserVideoFileKey];
    if (_video) {
        [_video getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"MyFile.m4v"];
                [data writeToFile:appFile atomically:YES];
                NSURL *movieUrl = [NSURL fileURLWithPath:appFile];
                [self.moviePlayer setContentURL:movieUrl];
                //NSLog(@"video url...%@", movieUrl);
                
                moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:movieUrl];
                
                moviePlayer.controlStyle = MPMovieControlStyleNone;
                //[moviePlayer setScalingMode:MPMovieScalingModeAspectFill];
                [moviePlayer setScalingMode:MPMovieScalingModeFill];
                [moviePlayer setFullscreen:FALSE];
                [moviePlayer.view setFrame:videoView.bounds];
                
                //Center the movieplayer
                //moviePlayer.view.center = self.view.center;
                
                //Loops Video Profile
                //moviePlayer.repeatMode = MPMovieRepeatModeOne;
                
                [videoView addSubview:moviePlayer.view];
                
                [moviePlayer prepareToPlay];
                moviePlayer.shouldAutoplay = YES;
                               
            }
        }];
    }
    

    
    [self.headerView addSubview: videoView];
    
    
    
    // Create a standard UIButton programmatically using convenience method
    UIButton *camButton2 = [UIButton buttonWithType:UIButtonTypeCustom];
    
    // Set the location (x,y) and size (width,height) of the button
    camButton2.frame = CGRectMake(0.0f, 0.0f, 375.0f, 400.0f);
    
    // Create UIImages from image resources in your application bundle
    // using convenience methods (no need to release)
    ////UIImage *normal = [UIImage imageNamed:@"ZingCamComm"];
    ////UIImage *highlighted = [UIImage imageNamed:@"ZingCamCommClick"];
    
    // Set the button's background to an image
    ////[camButton2 setBackgroundImage:normal forState:UIControlStateNormal];
    ////[camButton2 setBackgroundImage:highlighted forState:UIControlStateHighlighted];
    
    // Add the target-action for the touch event
    #pragma GCC diagnostic ignored "-Wundeclared-selector"
    
    [camButton2 addTarget:self action:@selector(ReloadVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.headerView addSubview:camButton2];
    
    
    
    
    
//
    
    
    

    
    
    
    //The below section is what will display the video almost full screen
     int i = 0;
    if (![self.user objectForKey:@"UserInfo"] || [[self.user objectForKey:@"UserInfo"] isEqualToString:@""]) {
        i = 190;
    }
    else i = 240;
    int i3 = 0;
    if (![self.user objectForKey:@"UserInfo"] || [[self.user objectForKey:@"UserInfo"] isEqualToString:@""]) {
        i3 = 350;
    }
    else i3 = 400;
    [UIView animateWithDuration:100
                          delay:0
                        options:UIViewAnimationOptionAllowAnimatedContent
                     animations:^{
                         //self.headerView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, i3);
                         
                         
                         
                         //Below is the top to bottom position of the 3 buttons
                         if (IS_IPHONE_4_OR_LESS) {
                             self.headerView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 385);
                         }
                         else if (IS_IPHONE_5) {
                             self.headerView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 460);
                         }
                         else if (IS_IPHONE_6) {
                             self.headerView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 565);
                         }
                         else if (IS_IPHONE_6P) {
                             self.headerView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 635);
                         }
                         else if (IS_IPAD) {
                             self.headerView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 920);
                         }
                         else {
                             self.headerView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 565);
                         }
                         
                         
                         
                         //Below is the height of where the following buttons go down
                         //////////////////////////////////self.headerView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 450);
                         //whiteBackground.frame = CGRectMake(0, 160, [UIScreen mainScreen].bounds.size.width, i);
                         ////////////////////whiteBackground.frame = CGRectMake(0, 300, [UIScreen mainScreen].bounds.size.width, i);
                         
                         if (IS_IPHONE_4_OR_LESS) {
                             whiteBackground.frame = CGRectMake(0, 230, [UIScreen mainScreen].bounds.size.width, i);
                         }
                         else if (IS_IPHONE_5) {
                             whiteBackground.frame = CGRectMake(0, 300, [UIScreen mainScreen].bounds.size.width, i);
                         }
                         else if (IS_IPHONE_6) {
                             whiteBackground.frame = CGRectMake(0, 400, [UIScreen mainScreen].bounds.size.width, i);
                         }
                         else if (IS_IPHONE_6P) {
                             whiteBackground.frame = CGRectMake(0, 470, [UIScreen mainScreen].bounds.size.width, i);
                         }
                         else if (IS_IPAD) {
                             whiteBackground.frame = CGRectMake(0, 1050, [UIScreen mainScreen].bounds.size.width, i);
                         }
                         else {
                             whiteBackground.frame = CGRectMake(0, 400, [UIScreen mainScreen].bounds.size.width, i);
                         }
                         
                     } completion:^(BOOL finished){NSLog(@"animation finished");}
     ];

    //The below line displays the background image larger in height
    //whiteBackground = [[UIView alloc]initWithFrame:CGRectMake(0, 160, [UIScreen mainScreen].bounds.size.width, i)];
    /////////////////////whiteBackground = [[UIView alloc]initWithFrame:CGRectMake(0, 300, [UIScreen mainScreen].bounds.size.width, i)];
    
    if (IS_IPHONE_4_OR_LESS) {
        whiteBackground = [[UIView alloc]initWithFrame:CGRectMake(0, 230, [UIScreen mainScreen].bounds.size.width, i)];
    }
    else if (IS_IPHONE_5) {
        whiteBackground = [[UIView alloc]initWithFrame:CGRectMake(0, 300, [UIScreen mainScreen].bounds.size.width, i)];
    }
    else if (IS_IPHONE_6) {
        whiteBackground = [[UIView alloc]initWithFrame:CGRectMake(0, 400, [UIScreen mainScreen].bounds.size.width, i)];
    }
    else if (IS_IPHONE_6P) {
        whiteBackground = [[UIView alloc]initWithFrame:CGRectMake(0, 470, [UIScreen mainScreen].bounds.size.width, i)];
    }
    else if (IS_IPAD) {
        whiteBackground = [[UIView alloc]initWithFrame:CGRectMake(0, 750, [UIScreen mainScreen].bounds.size.width, i)];
    }

    else {
        whiteBackground = [[UIView alloc]initWithFrame:CGRectMake(0, 400, [UIScreen mainScreen].bounds.size.width, i)];
    }
    
    [whiteBackground setBackgroundColor:[UIColor whiteColor]];
    [self.headerView addSubview:whiteBackground];
    
  
    
    //Below is the line that ends the profile and then shows recent posts
    grayLine = [[UILabel alloc]initWithFrame:CGRectMake(0, self.headerView.frame.size.height -10, [UIScreen mainScreen].bounds.size.width, 0.5)];
    [grayLine setBackgroundColor:[UIColor lightGrayColor]];
    [self.headerView addSubview:grayLine];
    
    
    
    
    
    //Below is what shows the round profile photo
    //profilePictureBackgroundView = [[UIButton alloc] initWithFrame:CGRectMake(16, 106, 108, 108)];
    /////////////profilePictureBackgroundView = [[UIButton alloc] initWithFrame:CGRectMake(16, 246, 108, 108)];
    
    if (IS_IPHONE_4_OR_LESS) {
        profilePictureBackgroundView = [[UIButton alloc] initWithFrame:CGRectMake(16, 176, 108, 108)];
    }
    else if (IS_IPHONE_5) {
        profilePictureBackgroundView = [[UIButton alloc] initWithFrame:CGRectMake(16, 246, 108, 108)];
    }
    else if (IS_IPHONE_6) {
        profilePictureBackgroundView = [[UIButton alloc] initWithFrame:CGRectMake(16, 346, 108, 108)];
    }
    else if (IS_IPHONE_6P) {
        profilePictureBackgroundView = [[UIButton alloc] initWithFrame:CGRectMake(16, 416, 108, 108)];
    }
    else if (IS_IPAD) {
        profilePictureBackgroundView = [[UIButton alloc] initWithFrame:CGRectMake(16, 696, 108, 108)];
    }
    else {
        profilePictureBackgroundView = [[UIButton alloc] initWithFrame:CGRectMake(16, 346, 108, 108)];
    }
    
    [profilePictureBackgroundView setBackgroundColor:[UIColor whiteColor]];
    profilePictureBackgroundView.alpha = 1.0f;
    CALayer *layer = [profilePictureBackgroundView layer];
    layer.cornerRadius = 54;
    layer.masksToBounds = YES;
    [self.headerView addSubview:profilePictureBackgroundView];

    //profilePictureImageView = [[PFImageView alloc] initWithFrame:CGRectMake(20, 110.0f, 100.0f, 100.0f)];
    ///////////////////////profilePictureImageView = [[PFImageView alloc] initWithFrame:CGRectMake(20, 250.0f, 100.0f, 100.0f)];
    
    if (IS_IPHONE_4_OR_LESS) {
        profilePictureImageView = [[PFImageView alloc] initWithFrame:CGRectMake(20, 180.0f, 100.0f, 100.0f)];
    }
    else if (IS_IPHONE_5) {
        profilePictureImageView = [[PFImageView alloc] initWithFrame:CGRectMake(20, 250.0f, 100.0f, 100.0f)];
    }
    else if (IS_IPHONE_6) {
        profilePictureImageView = [[PFImageView alloc] initWithFrame:CGRectMake(20, 350.0f, 100.0f, 100.0f)];
    }
    else if (IS_IPHONE_6P) {
        profilePictureImageView = [[PFImageView alloc] initWithFrame:CGRectMake(20, 420.0f, 100.0f, 100.0f)];
    }
    else if (IS_IPAD) {
        profilePictureImageView = [[PFImageView alloc] initWithFrame:CGRectMake(20, 700.0f, 100.0f, 100.0f)];
    }
    else {
        profilePictureImageView = [[PFImageView alloc] initWithFrame:CGRectMake(20, 350.0f, 100.0f, 100.0f)];
    }
    
    [self.headerView addSubview:profilePictureImageView];
    [profilePictureImageView setContentMode:UIViewContentModeScaleAspectFill];
    layer = [profilePictureImageView layer];
    layer.cornerRadius = 50.0f;
    layer.masksToBounds = YES;
    profilePictureImageView.alpha = 1.0f;
    
    
    
    
    

    
    
    UIImageView *profilePictureStrokeImageView = [[UIImageView alloc] initWithFrame:CGRectMake( 88.0f, 24.0f, 143.0f, 143.0f)];
    profilePictureStrokeImageView.alpha = 1.0f;
    [self.headerView addSubview:profilePictureStrokeImageView];
    
    
    
    
    if ([[self.user objectForKey:@"Gender"] isEqualToString:@"female"] || [[self.user objectForKey:@"Gender"] isEqualToString:@"weiblech"]) {
        [profilePictureImageView setImage:[UIImage imageNamed:@"AvatarPlaceholderProfileFemale"]];

    }
    else [profilePictureImageView setImage:[UIImage imageNamed:@"AvatarPlaceholderProfile"]];
    
    PFFile *imageFile = [self.user objectForKey:kESUserProfilePicMediumKey];
    if (imageFile) {
        [profilePictureImageView setFile:imageFile];
        [profilePictureImageView loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                [UIView animateWithDuration:0.2f animations:^{
                    profilePictureBackgroundView.alpha = 1.0f;
                    profilePictureStrokeImageView.alpha = 1.0f;
                    profilePictureImageView.alpha = 1.0f;
                }];
                
                backgroundImageView = [[UIImageView alloc] initWithImage:[image applyLightEffect]];
                backgroundImageView.frame = self.tableView.backgroundView.bounds;
                backgroundImageView.alpha = 0.0f;
                [self.tableView.backgroundView addSubview:backgroundImageView];
                
                [UIView animateWithDuration:0.2f animations:^{
                    backgroundImageView.alpha = 1.0f;
                }];
            }
        }];
    }
    
    
    
    
    
    
    
    
    
    
    //Displays the username in the profile
    //userDisplayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 220, self.headerView.bounds.size.width, 22.0f)];
    ///////////////////////userDisplayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 355, self.headerView.bounds.size.width, 22.0f)];
    
    if (IS_IPHONE_4_OR_LESS) {
        userDisplayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 285, self.headerView.bounds.size.width, 22.0f)];
    }
    else if (IS_IPHONE_5) {
        userDisplayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 355, self.headerView.bounds.size.width, 22.0f)];
    }
    else if (IS_IPHONE_6) {
        userDisplayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 455, self.headerView.bounds.size.width, 22.0f)];
    }
    else if (IS_IPHONE_6P) {
        userDisplayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 525, self.headerView.bounds.size.width, 22.0f)];
    }
    else if (IS_IPAD) {
        userDisplayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 805, self.headerView.bounds.size.width, 22.0f)];
    }
    else {
        userDisplayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 455, self.headerView.bounds.size.width, 22.0f)];
    }
    
    
    [userDisplayNameLabel setTextAlignment:NSTextAlignmentLeft];
    [userDisplayNameLabel setBackgroundColor:[UIColor clearColor]];
    [userDisplayNameLabel setTextColor:[UIColor blackColor]];
    if ([self.user objectForKey:kESUserDisplayNameKey]) {
        [userDisplayNameLabel setText:[self.user objectForKey:kESUserDisplayNameKey]];
    }
    else {
        [userDisplayNameLabel setText:[self.user objectForKey:@"username"]];
    }
    [userDisplayNameLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [self.headerView addSubview:userDisplayNameLabel];

    
    
    //Displays the users mention name in the profile
    //userMentionLabel = [[UILabel alloc] initWithFrame:CGRectMake( 15, 230, [UIScreen mainScreen].bounds.size.width - 15, 40)];
    //////////////userMentionLabel = [[UILabel alloc] initWithFrame:CGRectMake( 15, 365, [UIScreen mainScreen].bounds.size.width - 15, 40)];
    
    if (IS_IPHONE_4_OR_LESS) {
        userMentionLabel = [[UILabel alloc] initWithFrame:CGRectMake( 15, 295, [UIScreen mainScreen].bounds.size.width - 15, 40)];
    }
    else if (IS_IPHONE_5) {
        userMentionLabel = [[UILabel alloc] initWithFrame:CGRectMake( 15, 365, [UIScreen mainScreen].bounds.size.width - 15, 40)];
    }
    else if (IS_IPHONE_6) {
        userMentionLabel = [[UILabel alloc] initWithFrame:CGRectMake( 15, 465, [UIScreen mainScreen].bounds.size.width - 15, 40)];
    }
    else if (IS_IPHONE_6P) {
        userMentionLabel = [[UILabel alloc] initWithFrame:CGRectMake( 15, 535, [UIScreen mainScreen].bounds.size.width - 15, 40)];
    }
    else if (IS_IPAD) {
        userMentionLabel = [[UILabel alloc] initWithFrame:CGRectMake( 15, 815, [UIScreen mainScreen].bounds.size.width - 15, 40)];
    }
    else {
        userMentionLabel = [[UILabel alloc] initWithFrame:CGRectMake( 15, 465, [UIScreen mainScreen].bounds.size.width - 15, 40)];
    }
    
    [userMentionLabel setTextAlignment:NSTextAlignmentLeft];
    [userMentionLabel setBackgroundColor:[UIColor clearColor]];
    [userMentionLabel setTextColor:[UIColor grayColor]];
    [userMentionLabel setText:[NSString stringWithFormat:@"@%@",[self.user objectForKey:@"usernameFix"]]];
    [userMentionLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [self.headerView addSubview:userMentionLabel];
    
    
    
    
    
    
    //Below is the text info of the bio
    infoLabel = [[UILabel alloc] initWithFrame:CGRectMake( 15, 268, [UIScreen mainScreen].bounds.size.width - 25, 80)];
    if (IS_IPHONE5) {
        infoLabel.frame = CGRectMake(15, 268, [UIScreen mainScreen].bounds.size.width - 25, 100);
    }
    [infoLabel setTextAlignment:NSTextAlignmentLeft];
    infoLabel.alpha = 1.0f;
    [infoLabel setBackgroundColor:[UIColor clearColor]];
    [infoLabel setTextColor:[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1]];
    [infoLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0f]];
    infoLabel.numberOfLines = 4;
    infoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    PFUser *_user = [PFUser currentUser];
    if (![self.user objectForKey:@"UserInfo"] && self.user == _user) {
        infoLabel.text = NSLocalizedString(@"Tell everyone how awesome you are.", nil);
    }
    else if (![self.user objectForKey:@"UserInfo"] && self.user != _user) {
        infoLabel.text = NSLocalizedString(@"", nil);
    }
    else {
        infoLabel.text = [NSString stringWithFormat:@"%@",[self.user objectForKey:@"UserInfo"]];
    }
    CGSize maximumLabelSize = CGSizeMake(296, FLT_MAX);
    CGSize expectedLabelSize = [infoLabel.text sizeWithFont:infoLabel.font constrainedToSize:maximumLabelSize lineBreakMode:infoLabel.lineBreakMode];
    //adjust the label the the new height.
    CGRect newFrame = infoLabel.frame;
    newFrame.size.height = expectedLabelSize.height;
    infoLabel.frame = newFrame;
    //[self.headerView addSubview:infoLabel];
    
    
    
    
    
    
    
    int i2 = 0;
    if (![self.user objectForKey:@"UserInfo"] || [[self.user objectForKey:@"UserInfo"] isEqualToString:@""]) {
        i2 =  infoLabel.frame.origin.y + 5;
    }
    else i2 =  infoLabel.frame.origin.y + infoLabel.frame.size.height + 5;
    cityLabel = [[UILabel alloc] initWithFrame:CGRectMake( 15,i2, [UIScreen mainScreen].bounds.size.width - 300, 20)];
    [cityLabel setTextAlignment:NSTextAlignmentLeft];
    [cityLabel setBackgroundColor:[UIColor clearColor]];
    [cityLabel setTextColor:[UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1]];
    [cityLabel setText:[self.user objectForKey:@"Location"]];
    [cityLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0f]];
    CGSize _maximumLabelSize = CGSizeMake(296, FLT_MAX);
    CGSize _expectedLabelSize = [cityLabel.text sizeWithFont:cityLabel.font constrainedToSize:_maximumLabelSize lineBreakMode:cityLabel.lineBreakMode];
    CGRect _newFrame = cityLabel.frame;
    _newFrame.size.width = _expectedLabelSize.width;
    cityLabel.frame = _newFrame;
    //[self.headerView addSubview:cityLabel];
    
    
    siteLabel = [[KILabel alloc]initWithFrame:CGRectMake(cityLabel.frame.size.width + cityLabel.frame.origin.x + 15, i2, [UIScreen mainScreen].bounds.size.width - (cityLabel.frame.size.width + cityLabel.frame.origin.x + 15), 20)];
    if ([self.user objectForKey:@"Website"]) {
        siteLabel.text = [self.user objectForKey:@"Website"];
    }
    [siteLabel setTextAlignment:NSTextAlignmentLeft];
    siteLabel.alpha = 1.0f;
    [siteLabel setBackgroundColor:[UIColor clearColor]];
    //[self.headerView addSubview:siteLabel];

    
    
    
    //Now we're preparing for the segmented control, to display photos, followers and following ...
    __block int photos;
    __block int follower;
    __block int following;
    
    PFQuery *queryPhotoCount = [PFQuery queryWithClassName:kESPhotoClassKey];
    [queryPhotoCount whereKey:kESPhotoUserKey equalTo:self.user];
    [queryPhotoCount setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [queryPhotoCount countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            [photoCountLabel setText:[NSString stringWithFormat:NSLocalizedString(@"%d post%@", nil), number, number==1?@"":NSLocalizedString(@"s", nil)]];
            [[ESCache sharedCache] setPhotoCount:[NSNumber numberWithInt:number] user:self.user];
            [photosBtn setTitle:[NSString stringWithFormat:NSLocalizedString(@"%d post%@", nil), number, number==1?@"":NSLocalizedString(@"s", nil)] forState:UIControlStateNormal];
            photos = number;
        }
    }];
    
    PFQuery *queryFollowerCount = [PFQuery queryWithClassName:kESActivityClassKey];
    [queryFollowerCount whereKey:kESActivityTypeKey equalTo:kESActivityTypeFollow];
    [queryFollowerCount whereKey:kESActivityToUserKey equalTo:self.user];
    [queryFollowerCount setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [queryFollowerCount countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            [followerBtn setTitle:[NSString stringWithFormat:@"%d follower%@", number, number==1?@"":NSLocalizedString(@"s", nil)] forState:UIControlStateNormal];
             follower = number;
        }
    }];
    
    PFQuery *queryFollowingCount = [PFQuery queryWithClassName:kESActivityClassKey];
    [queryFollowingCount whereKey:kESActivityTypeKey equalTo:kESActivityTypeFollow];
    [queryFollowingCount whereKey:kESActivityFromUserKey equalTo:self.user];
    [queryFollowingCount setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [queryFollowingCount countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            [followingBtn setTitle:[NSString stringWithFormat:NSLocalizedString(@"%d following", nil), number] forState:UIControlStateNormal];
            following = number;
        }
    }];
    //editProfileBtn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 170, 100, 30)];
    //////////////////editProfileBtn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 310, 100, 35)];
    
    if (IS_IPHONE_4_OR_LESS) {
        editProfileBtn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 240, 100, 35)];
    }
    else if (IS_IPHONE_5) {
        editProfileBtn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 310, 100, 35)];
    }
    else if (IS_IPHONE_6) {
        editProfileBtn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 410, 100, 35)];
    }
    else if (IS_IPHONE_6P) {
        editProfileBtn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 480, 100, 35)];
    }
    else if (IS_IPAD) {
        editProfileBtn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 760, 100, 35)];
    }
    else {
        editProfileBtn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 410, 100, 35)];
    }
    
    
    
    //ADDED Section Below
    // Create a standard UIButton programmatically using convenience method
    UIButton *camButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    // Set the location (x,y) and size (width,height) of the button
    ///////////////camButton.frame = CGRectMake(165.0f, 310.0f, 35.0f, 35.0f);
    
    if (IS_IPHONE_4_OR_LESS) {
        camButton.frame = CGRectMake(165.0f, 240.0f, 35.0f, 35.0f);
    }
    else if (IS_IPHONE_5) {
        camButton.frame = CGRectMake(165.0f, 310.0f, 35.0f, 35.0f);
    }
    else if (IS_IPHONE_6) {
        camButton.frame = CGRectMake(220.0f, 410.0f, 35.0f, 35.0f);
    }
    else if (IS_IPHONE_6P) {
        camButton.frame = CGRectMake(260.0f, 480.0f, 35.0f, 35.0f);
    }
    else if (IS_IPAD) {
        camButton.frame = CGRectMake(610.0f, 760.0f, 35.0f, 35.0f);
    }
    else {
        camButton.frame = CGRectMake(165.0f, 410.0f, 35.0f, 35.0f);
    }
    
    
    
        
if ([[self.user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
    // Create UIImages from image resources in your application bundle
    // using convenience methods (no need to release)
    UIImage *normal = [UIImage imageNamed:@"ZingCamComm"];
    UIImage *highlighted = [UIImage imageNamed:@"ZingCamCommClick"];
    
    // Set the button's background to an image
    [camButton setBackgroundImage:normal forState:UIControlStateNormal];
    [camButton setBackgroundImage:highlighted forState:UIControlStateHighlighted];
    
    // Add the target-action for the touch event
    #pragma GCC diagnostic ignored "-Wundeclared-selector"
    
    [camButton addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.headerView addSubview:camButton];
}
    

    //Below is what displays the Edit Profile, Follers, Following & Photo buttons in the users profile
    [self.headerView addSubview:editProfileBtn];

    followerBtn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 47.5, self.headerView.frame.size.height   - 50, 95, 25)];
    followingBtn = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 105, self.headerView.frame.size.height   - 50, 95, 25)];
    photosBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, self.headerView.frame.size.height   - 50, 95, 25)];

    [followerBtn setTitle:NSLocalizedString(@"0 following", nil) forState:UIControlStateNormal];
    [photosBtn setTitle:NSLocalizedString(@"0 photos", nil) forState:UIControlStateNormal];
    [followingBtn setTitle:NSLocalizedString(@"0 followers", nil) forState:UIControlStateNormal];
    
    [followerBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [photosBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [followingBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    
    followingBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    followerBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    photosBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    
    [followingBtn addTarget:self action:@selector(showFollowings) forControlEvents:UIControlEventTouchDown];
    [followerBtn addTarget:self action:@selector(showFollowers) forControlEvents:UIControlEventTouchDown];
    
    photosBtn.layer.cornerRadius = 3;
    followerBtn.layer.cornerRadius = 3;
    followingBtn.layer.cornerRadius = 3;
    
    photosBtn.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
    followerBtn.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
    followingBtn.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
    
    
    
    // Below is where the display of 3 buttons horizontal in the user profile
    [self.headerView addSubview:followingBtn];
    [self.headerView addSubview:followerBtn];
    [self.headerView addSubview:photosBtn];
    
    if (![[self.user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [loadingActivityIndicatorView startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingActivityIndicatorView];
        
        // check if the currentUser is following this user
        PFQuery *queryIsFollowing = [PFQuery queryWithClassName:kESActivityClassKey];
        [queryIsFollowing whereKey:kESActivityTypeKey equalTo:kESActivityTypeFollow];
        [queryIsFollowing whereKey:kESActivityToUserKey equalTo:self.user];
        [queryIsFollowing whereKey:kESActivityFromUserKey equalTo:[PFUser currentUser]];
        [queryIsFollowing setCachePolicy:kPFCachePolicyCacheThenNetwork];
        [queryIsFollowing countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
            if (error && [error code] != kPFErrorCacheMiss) {
                self.navigationItem.rightBarButtonItem = nil;
            } else {
                if (number == 0) {
                    [self configureFollowButton];
                } else {
                    [self configureUnfollowButton];
                }
            }
        }];
    }
    else {
        [self configureSettingsButton];
    }
    self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;

    if (![[self.user objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        //reportUser = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 140 , 175, 20, 20)];
        if (IS_IPHONE_4_OR_LESS) {
            reportUser = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 240, 100, 35)];
        }
        else if (IS_IPHONE_5) {
            reportUser = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 310, -50, 35)];
        }
        else if (IS_IPHONE_6) {
            reportUser = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 410, -50, 35)];
        }
        else if (IS_IPHONE_6P) {
            reportUser = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 480, 100, 35)];
        }
        else if (IS_IPAD) {
            reportUser = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 760, 100, 35)];
        }
        else {
            reportUser = [[UIButton alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 410, 100, 35)];
        }

        
        
        [reportUser setImage:[UIImage imageNamed:@"ButtonImageSettings"] forState:UIControlStateNormal];
        [reportUser setImage:[UIImage imageNamed:@"ButtonImageSettingsSelected"] forState:UIControlStateHighlighted];
        [reportUser addTarget:self action:@selector(ReportTap) forControlEvents:UIControlEventTouchUpInside];
        [self.headerView addSubview:reportUser];
    }

    __unsafe_unretained typeof(self) weakSelf = self;
    self.siteLabel.linkTapHandler = ^(KILinkType linkType, NSString *string, NSRange range) {
        if (linkType == KILinkTypeURL)
        {
            // Open URLs
            [weakSelf attemptOpenURL:[NSURL URLWithString:string]];
            NSLog(@"URL:%@",string);
        }
        else if (linkType == KILinkTypeHashtag) {
            //What do you want to happen?
            
        }
        else
        {
            //Same here...
            
        }
    };

}

# pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 22) {
        if (buttonIndex == 0) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"What do you want the user to be reported for?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Sexual content", nil), NSLocalizedString(@"Offensive content", nil), NSLocalizedString(@"Spam", nil), NSLocalizedString(@"Other", nil), nil];
            //actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
            actionSheet.tag = 23;
            [actionSheet showInView:self.headerView];
        }
    }
    else if (actionSheet.tag == 23) {
        if (buttonIndex == 0) {
            [self reportUser:0];
        }
        else if (buttonIndex == 1) {
            [self reportUser:1];
        }
        else if (buttonIndex == 2) {
            [self reportUser:2];
        }
        else if (buttonIndex == 3) {
            [self reportUser:3];
        }
    }
       
}

#pragma mark - PFQueryTableViewController

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    self.tableView.tableHeaderView = headerView;
}

- (PFQuery *)queryForTable {
    if (!self.user) {
        PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
        [query setLimit:0];
        return query;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    if (self.objects.count == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    [query whereKey:kESPhotoUserKey equalTo:self.user];
    [query orderByDescending:@"createdAt"];
    [query includeKey:kESPhotoUserKey];
    
    return query;
}

# pragma mark - UITableView

- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *LoadMoreCellIdentifier = @"LoadMoreCell";
    
    ESLoadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:LoadMoreCellIdentifier];
    if (!cell) {
        cell = [[ESLoadMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LoadMoreCellIdentifier];
        cell.selectionStyle =UITableViewCellSelectionStyleGray;
        //cell.separatorImageTop.image = [UIImage imageNamed:@"SeparatorTimelineDark"];
        cell.hideSeparatorBottom = YES;
        cell.mainView.backgroundColor = [UIColor clearColor];
    }
    return cell;
}


#pragma mark - ()

//Below are the buttons to follow and unfollow plus the edit profile button.

- (void)followButtonAction:(id)sender {
    UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [loadingActivityIndicatorView startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingActivityIndicatorView];
    
    [self configureUnfollowButton];
    
    [ESUtility followUserEventually:self.user block:^(BOOL succeeded, NSError *error) {
        if (error) {
            [self configureFollowButton];
        }
    }];
}

- (void)unfollowButtonAction:(id)sender {
    UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [loadingActivityIndicatorView startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingActivityIndicatorView];
    
    [self configureFollowButton];
    
    [ESUtility unfollowUserEventually:self.user];
}
- (void)configureSettingsButton {
    NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if ([language isEqualToString:@"lb"]) {
        
        //Not sure what the below line does.
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 150, 170, 135, 30);
    }
    [editProfileBtn addTarget:self action:@selector(editProfileBtnTapped) forControlEvents:UIControlEventTouchUpInside];
    [editProfileBtn setTitle:NSLocalizedString(@"Edit Profile",nil) forState:UIControlStateNormal];
    [editProfileBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [editProfileBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    editProfileBtn.titleLabel.textColor = [UIColor grayColor];
    editProfileBtn.tintColor = [UIColor grayColor];
    editProfileBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    editProfileBtn.layer.borderWidth = 1;
    editProfileBtn.layer.borderColor = [UIColor grayColor].CGColor;
    editProfileBtn.layer.cornerRadius = 4;
    editProfileBtn.layer.masksToBounds = YES;
    
}

- (void)configureFollowButton {
    //editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 170, 100, 30);
    if (IS_IPHONE_4_OR_LESS) {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 240, 100, 35);
    }
    else if (IS_IPHONE_5) {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 310, 100, 35);
    }
    else if (IS_IPHONE_6) {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 410, 100, 35);
    }
    else if (IS_IPHONE_6P) {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 480, 100, 35);
    }
    else if (IS_IPAD) {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 760, 100, 35);
    }
    else {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 410, 100, 35);
    }
    
    
    
    
    
    
    
    [editProfileBtn addTarget:self action:@selector(followButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [editProfileBtn setTitle:NSLocalizedString(@"Follow",nil) forState:UIControlStateNormal];
    //[editProfileBtn setTitleColor:[UIColor colorWithRed:32/255.0f green:131/255.0f blue:251/255.0f alpha:1] forState:UIControlStateNormal];
    [editProfileBtn setTitleColor:[UIColor colorWithHue:196.0f/360.0f saturation:100.0f/100.0f brightness:94.0f/100.0f alpha:1] forState:UIControlStateNormal];
    //[editProfileBtn setTitleColor:[UIColor colorWithRed:32/255.0f green:131/255.0f blue:251/255.0f alpha:1] forState:UIControlStateHighlighted];
    [editProfileBtn setTitleColor:[UIColor colorWithHue:196.0f/360.0f saturation:100.0f/100.0f brightness:94.0f/100.0f alpha:1] forState:UIControlStateHighlighted];
    editProfileBtn.backgroundColor = [UIColor clearColor];
    editProfileBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    editProfileBtn.layer.borderWidth = 1;
    //editProfileBtn.layer.borderColor = [UIColor colorWithRed:32.0f/255.0f green:131.0f/255.0f blue:251.0f/255.0f alpha:1].CGColor;
    editProfileBtn.layer.borderColor = [UIColor colorWithHue:196.0f/360.0f saturation:100.0f/100.0f brightness:94.0f/100.0f alpha:1].CGColor;
    editProfileBtn.layer.cornerRadius = 4;
    editProfileBtn.layer.masksToBounds = YES;
    [[ESCache sharedCache] setFollowStatus:NO user:self.user];
    
    UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingActivityIndicatorView];
    [loadingActivityIndicatorView stopAnimating];
}

- (void)configureUnfollowButton {
    //editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 170, 100, 30);
    if (IS_IPHONE_4_OR_LESS) {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 240, 100, 35);
    }
    else if (IS_IPHONE_5) {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 310, 100, 35);
    }
    else if (IS_IPHONE_6) {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 410, 100, 35);
    }
    else if (IS_IPHONE_6P) {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 480, 100, 35);
    }
    else if (IS_IPAD) {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 760, 100, 35);
    }
    else {
        editProfileBtn.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 110, 410, 100, 35);
    }

    
    
    [editProfileBtn addTarget:self action:@selector(unfollowButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [editProfileBtn setTitle:NSLocalizedString(@"Following",nil) forState:UIControlStateNormal];
    [editProfileBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [editProfileBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    editProfileBtn.titleLabel.textColor = [UIColor whiteColor];
    editProfileBtn.tintColor = [UIColor whiteColor];
    //editProfileBtn.backgroundColor = [UIColor colorWithRed:32.0f/255.0f green:131.0f/255.0f blue:251.0f/255.0f alpha:1];
    editProfileBtn.backgroundColor = [UIColor colorWithHue:196.0f/360.0f saturation:100.0f/100.0f brightness:94.0f/100.0f alpha:1];
    editProfileBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    editProfileBtn.layer.borderWidth = 1;
    //editProfileBtn.layer.borderColor = [UIColor colorWithRed:32.0f/255.0f green:131.0f/255.0f blue:251.0f/255.0f alpha:1].CGColor;
    editProfileBtn.layer.borderColor = [UIColor colorWithHue:196.0f/360.0f saturation:100.0f/100.0f brightness:94.0f/100.0f alpha:1].CGColor;
    editProfileBtn.layer.cornerRadius = 4;
    editProfileBtn.layer.masksToBounds = YES;
    [[ESCache sharedCache] setFollowStatus:YES user:self.user];
    
    UIActivityIndicatorView *loadingActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingActivityIndicatorView];
    [loadingActivityIndicatorView stopAnimating];
}

-(void)reportUser:(int)i {
    PFObject *object = [PFObject objectWithClassName:@"Report"];
    [object setObject:user forKey:@"ReportedUser"];
    
    if (i == 0) {
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"Sexual", nil)];
        [object setObject:reason forKey:@"Reason"];
    }
    else if (i == 1) {
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"Offensive", nil)];
        [object setObject:reason forKey:@"Reason"];
    }
    else if (i == 2) {
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"Spam", nil)];
        [object setObject:reason forKey:@"Reason"];
    }
    else if (i == 3) {
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"Other", nil)];
        [object setObject:reason forKey:@"Reason"];
    }
    
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            
            [alert showNotice:self.tabBarController title:NSLocalizedString(@"Notice", nil)
                    subTitle:NSLocalizedString(@"User has been successfully reported.", nil)
            closeButtonTitle:@"OK" duration:0.0f];
        }
        else {
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            
            [alert showError:self.tabBarController title:NSLocalizedString(@"Hold On...", nil)
                     subTitle:NSLocalizedString(@"Check your internet connection.", nil)
             closeButtonTitle:@"OK" duration:0.0f];
            
            NSLog(@"error %@",error);
        }
        
    }];
    
    
}

- (void) editProfileBtnTapped {
    
    
    //NSLog(@"editProfile Button has been tapped!");
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ESEditProfileViewController *profileViewController = [[ESEditProfileViewController alloc] initWithNibName:nil bundle:nil andOptionForTutorial:@"NO"];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:profileViewController];
        [self presentViewController:navController animated:YES completion:nil];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didDismissSecondViewController)
                                                 name:@"SecondViewControllerDismissed"
                                               object:nil];
    
}





//ADDED Section Below
- (void)btnClicked:(UIButton *)sender {
   
    self.navController = [[UINavigationController alloc] init];
    
    [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    RecorderProfileViewController *viewController = [[RecorderProfileViewController alloc] init];
    
    [viewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [self.navController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [self.navController pushViewController:viewController animated:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
    #define ROOTVIEW [[[UIApplication sharedApplication] keyWindow] rootViewController]
        [ROOTVIEW presentViewController:self.navController animated:YES completion:^{}];
    });

}
    
    
    


- (void) didDismissSecondViewController {
    //This method happens when the done button is pressed on the edit profile screen.
    //NSLog(@"didDismissSecondViewController was called upon!");
    [self setupHeader];
}
- (void) ReportTap {
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:NSLocalizedString(@"Do you want to report the user for infringing our terms of use?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Yes, Report", nil) otherButtonTitles: nil];
    actionSheet.tag = 22;
    [actionSheet showInView:self.headerView];
}
-(void)showFollowers {
    ESFollowersViewController *followerView = [[ESFollowersViewController alloc] initWithStyle:UITableViewStyleGrouped andOption:@"Followers" andUser:self.user];
    [self.navigationController pushViewController:followerView animated:YES];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

}
-(void)showFollowings {
    ESFollowersViewController *followerView = [[ESFollowersViewController alloc] initWithStyle:UITableViewStyleGrouped andOption:@"Following" andUser:self.user];
    [self.navigationController pushViewController:followerView animated:YES];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

}
//Hot fix for the bug in the Parse SDK
- (NSIndexPath *)_indexPathForPaginationCell {
    return [NSIndexPath indexPathForRow:0 inSection:[self.objects count]];
    
}



-(void)ReloadVideo:(id)sender{
    [moviePlayer stop];
    [moviePlayer play];
}






//ADDED
-(void)handle_data {
    [self viewDidLoad];
}
//






-(void)restartVideo
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:nil];
    [moviePlayer stop];
    [moviePlayer play];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:nil];
}


@end