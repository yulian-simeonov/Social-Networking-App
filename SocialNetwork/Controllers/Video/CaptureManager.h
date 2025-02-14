/*
     File: CaptureManager.h
 
 Based on AVCamCaptureManager by Apple
 
 Abstract: Uses the AVCapture classes to capture video and still images.
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>






@class AVCamRecorder;
@protocol CaptureManagerDelegate;





@interface CaptureManager : NSObject {
}


@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,assign) AVCaptureVideoOrientation orientation;
@property (nonatomic,strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic,strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic,strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic,strong) AVCamRecorder *recorder;
@property (nonatomic,assign) id deviceConnectedObserver;
@property (nonatomic,assign) id deviceDisconnectedObserver;
@property (nonatomic,assign) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic,assign) id <CaptureManagerDelegate> delegate;
@property (nonatomic,strong) NSMutableArray *assets;
@property (nonatomic,assign) NSTimer *exportProgressBarTimer;
@property (nonatomic,strong) AVAssetExportSession *exportSession;


//ADDED
/**
 *  PFObject containing all the private data of the user.
 */
///@property (nonatomic, strong) PFObject *sensitiveData;




//ADDED for photo
/// The photo displayed in the view
///////////@property (nonatomic, strong) PFObject *photo;

/**
 *  Init method of the header
 *
 *  @param frame  size of the header
 *  @param aPhoto the photo we display in the viewcontroller
 *
 *  @return self
 */
/////////- (id)initWithFrame:(CGRect)frame photo:(PFObject*)aPhoto;



// define delegate property
//@property (nonatomic, assign) id  delegate;

// define public functions
//-(void)helloDelegate;
////////-(NSString *)helloDelegate;









- (BOOL) setupSession;
- (void) startRecording;
- (void) stopRecording;
- (void) saveVideoWithCompletionBlock:(void(^)(BOOL success))completion;
//Video Comments
- (void) saveVideoWithCompletionBlockComment:(void(^)(BOOL success))completion;

//Video Profile
- (void) saveVideoWithCompletionBlockProfile:(void(^)(BOOL success))completion;

- (NSUInteger) cameraCount;
- (NSUInteger) micCount;
- (void) autoFocusAtPoint:(CGPoint)point;
- (void) continuousFocusAtPoint:(CGPoint)point;
- (void) switchCamera;
- (void) deleteLastAsset;

@end

// These delegate methods can be called on any arbitrary thread. If the delegate does something with the UI when called, make sure to send it to the main thread.
@protocol CaptureManagerDelegate <NSObject>
@optional


// define protocol functions that can be used in any class using this delegate
///////////-(void)sayHello:(CaptureManager *)customClass;
///////////-(NSString *)sayHello:(CaptureManager *)customClass;





- (void) removeTimeFromDuration:(float)removeTime;

- (void) updateProgress;
- (void) removeProgress;

- (void) captureManager:(CaptureManager *)captureManager didFailWithError:(NSError *)error;
- (void) captureManagerRecordingBegan:(CaptureManager *)captureManager;
- (void) captureManagerRecordingFinished:(CaptureManager *)captureManager;
- (void) captureManagerStillImageCaptured:(CaptureManager *)captureManager;
- (void) captureManagerDeviceConfigurationChanged:(CaptureManager *)captureManager;
@end
