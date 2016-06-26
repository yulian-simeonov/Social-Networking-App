//
//  RecorderProfileViewController.m
//  NewVideoRecorder
//
//

#define IOS7  ([[[[[UIDevice currentDevice] systemVersion]componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)

//ADDED
//////#import "KZCameraView.h"
//

#import "RecorderProfileViewController.h"


@implementation RecorderProfileViewController

//ADDED
////////@synthesize photo;
//


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (IOS7)
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    
    //ADDED
    ////NSLog(@"Value of hello = %@", [self.photo objectForKey:kESPhotoUserKey]);
    //
    
    //ADDED
    ////KZCameraView *kzcameraView = [[KZCameraView alloc] init];
    ////kzcameraView.photo = photo; // the value has been sent to the SecondController
    //
    
    
    
    
    //Create CameraView
    self.cam = [[KZCameraView alloc]initWithFrame:CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) withVideoPreviewFrame:CGRectMake(0.0, 0.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
    self.cam.maxDuration = 15.0;
    self.cam.showCameraSwitch = YES; //Say YES to button to switch between front and back cameras
    
    //Create "save" button
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Post", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(saveVideo:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonAction:)];
    
    [self.view addSubview:self.cam];
}



- (void)cancelButtonAction:(id)sender {
    //Below is what is needed to dismiss the current page and refresh the video profile page. Copy this code to the save video profile section.
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SecondViewControllerDismissed" object:nil userInfo:nil];
}




-(IBAction)saveVideo:(id)sender
{
    
    [self.cam saveVideoWithCompletionBlockProfile:^(BOOL success) {
        if (success)
        {
            NSLog(@"WILL PUSH NEW CONTROLLER HERE");

            [self dismissViewControllerAnimated:YES completion:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadBegins" object:nil];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end