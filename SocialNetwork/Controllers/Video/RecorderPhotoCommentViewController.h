//
//
//  RecorderPhotoCommentViewController.h
//  NewVideoRecorder
//
//

#import "KZCameraView.h"
#import "MBProgressHUD.h"

@interface RecorderPhotoCommentViewController : UIViewController
/**
 *  CameraViewController, implemented by the KZCameraView.
 */
@property (nonatomic, strong) KZCameraView *cam;

//ADDED
////////@property (nonatomic, strong) PFObject *photo;
//

/**
 *  User has cancelled the video, we dismiss the controller.
 */
- (void)cancelButtonAction:(id)sender;
/**
 *  User has finished and wants to save the video. We save it with the save method with completion block implemented in the KZCameraView.m file.
 */
-(IBAction)saveVideo:(id)sender;
@end