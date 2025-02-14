/*
     File: CaptureManager.m
 
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

#import "CaptureManager.h"
#import "AVCamRecorder.h"
#import "AVCamUtilities.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageProperties.h>
#import "UIImage+ResizeAdditions.h"
#import "MBProgressHUD.h"
#import "SCLAlertView.h"
#import "AppDelegate.h"


#define MAX_DURATION 0.25



@interface CaptureManager (RecorderDelegate) <AVCamRecorderDelegate>

@end


#pragma mark -
@interface CaptureManager (InternalUtilityMethods)
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition)position;
- (AVCaptureDevice *) frontFacingCamera;
- (AVCaptureDevice *) backFacingCamera;
- (AVCaptureDevice *) audioDevice;
- (NSURL *) tempFileURL;
- (void) removeFile:(NSURL *)outputFileURL;
- (void) copyFileToDocuments:(NSURL *)fileURL;
@end


//ADDED
///BOOL tutorial;


#pragma mark -
@implementation CaptureManager



//ADDED for photo
//@synthesize photo;

///////////@synthesize delegate;








///@synthesize sensitiveData;






- (id) init
{
    self = [super init];
    if (self != nil) {
		__block id weakSelf = self;
        void (^deviceConnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
			AVCaptureDevice *device = [notification object];
        
			BOOL sessionHasDeviceWithMatchingMediaType = NO;
			NSString *deviceMediaType = nil;
			if ([device hasMediaType:AVMediaTypeAudio])
                deviceMediaType = AVMediaTypeAudio;
			else if ([device hasMediaType:AVMediaTypeVideo])
                deviceMediaType = AVMediaTypeVideo;
			
			if (deviceMediaType != nil) {
				for (AVCaptureDeviceInput *input in [self.session inputs])
				{
					if ([[input device] hasMediaType:deviceMediaType]) {
						sessionHasDeviceWithMatchingMediaType = YES;
						break;
					}
				}
				
				if (!sessionHasDeviceWithMatchingMediaType) {
					NSError	*error;
					AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
					if ([self.session canAddInput:input])
						[self.session addInput:input];
				}				
			}
            
			if ([self.delegate respondsToSelector:@selector(captureManagerDeviceConfigurationChanged:)]) {
				[self.delegate captureManagerDeviceConfigurationChanged:self];
			}			
        };
        void (^deviceDisconnectedBlock)(NSNotification *) = ^(NSNotification *notification) {
			AVCaptureDevice *device = [notification object];
			
			if ([device hasMediaType:AVMediaTypeAudio]) {
				[self.session removeInput:[weakSelf audioInput]];
				[weakSelf setAudioInput:nil];
			}
			else if ([device hasMediaType:AVMediaTypeVideo]) {
				[self.session removeInput:[weakSelf videoInput]];
				[weakSelf setVideoInput:nil];
			}
			
			if ([self.delegate respondsToSelector:@selector(captureManagerDeviceConfigurationChanged:)]) {
				[self.delegate captureManagerDeviceConfigurationChanged:self];
			}			
        };
        
        self.assets = [[NSMutableArray alloc] init];
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [self setDeviceConnectedObserver:[notificationCenter addObserverForName:AVCaptureDeviceWasConnectedNotification object:nil queue:nil usingBlock:deviceConnectedBlock]];
        [self setDeviceDisconnectedObserver:[notificationCenter addObserverForName:AVCaptureDeviceWasDisconnectedNotification object:nil queue:nil usingBlock:deviceDisconnectedBlock]];
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
		
		self.orientation = AVCaptureVideoOrientationPortrait;
        
        
        //ADDED
//        PFQuery *query = [PFQuery queryWithClassName:@"SensitiveData"];
//        [query whereKey:@"user" equalTo:[PFUser currentUser]];
//        [query getFirstObjectInBackgroundWithBlock:^(PFObject *result, NSError *error) {
//            if (!error) {
//                sensitiveData = result;
//            } else {
//                if (tutorial == NO) {
//                    [ProgressHUD showError:NSLocalizedString(@"Connection error...", nil)];
//                }
//            }
//        }];
        
        
        
        
    }
    
    return self;
}

- (void) dealloc
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:[self deviceConnectedObserver]];
    [notificationCenter removeObserver:[self deviceDisconnectedObserver]];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[self session] stopRunning];
}

- (BOOL) setupSession
{
    BOOL success = NO;
    
    //Torch or flash can be set here. I personaly don't like it 
	// Set torch and flash mode to auto
/*	if ([[self backFacingCamera] hasFlash]) {
		if ([[self backFacingCamera] lockForConfiguration:nil]) {
			if ([[self backFacingCamera] isFlashModeSupported:AVCaptureFlashModeAuto]) {
				[[self backFacingCamera] setFlashMode:AVCaptureFlashModeAuto];
			}
			[[self backFacingCamera] unlockForConfiguration];
		}
	}
	if ([[self backFacingCamera] hasTorch]) {
		if ([[self backFacingCamera] lockForConfiguration:nil]) {
			if ([[self backFacingCamera] isTorchModeSupported:AVCaptureTorchModeAuto]) {
				[[self backFacingCamera] setTorchMode:AVCaptureTorchModeAuto];
			}
			[[self backFacingCamera] unlockForConfiguration];
		}
	}*/
	
    //ADDED
    //AppDelegate *delegate = [AppDelegate getAppDelegate];
    //PFObject *photo = delegate.photo;
    //PFObject *photo = delegate.object;
    
    
    
    
    
    
    
    //NSLog(@"Value of helloooo = %@", [photo objectForKey:kESPhotoUserKey]);
    /////////NSLog(@"Value of helloooo = %@", photo);
    
   //NSLog(@"Value of helloooo = %@", [photo objectForKey:kESPhotoUserKey]);
    //NSLog(@"Value of helloooo = %@", [photo objectForKey:kESVideoFileKey]);
    //NSLog(@"Value of helloooo = %@", [object objectForKey:kESActivityPhotoKey]);
    /////////////////NSLog(@"Value of helloooo = %@", photo);
    //
    
    
    // Init the device inputs
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:nil];
    AVCaptureDeviceInput *newAudioInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    
    // Create session (use default AVCaptureSessionPresetHigh)
    AVCaptureSession *newCaptureSession = [[AVCaptureSession alloc] init];
    
    
    // Add inputs and output to the capture session
    if ([newCaptureSession canAddInput:newVideoInput]) {
        [newCaptureSession addInput:newVideoInput];
    }
    if ([newCaptureSession canAddInput:newAudioInput]) {
        [newCaptureSession addInput:newAudioInput];
    }

    [self setVideoInput:newVideoInput];
    [self setAudioInput:newAudioInput];
    [self setSession:newCaptureSession];
    
	// Set up the movie file output
    NSURL *outputFileURL = [self tempFileURL];
    AVCamRecorder *newRecorder = [[AVCamRecorder alloc] initWithSession:[self session] outputFileURL:outputFileURL];
    [newRecorder setDelegate:self];
	
	// Send an error to the delegate if video recording is unavailable
	if (![newRecorder recordsVideo] && [newRecorder recordsAudio]) {
		NSString *localizedDescription = NSLocalizedString(@"Video recording unavailable", @"Video recording unavailable description");
		NSString *localizedFailureReason = NSLocalizedString(@"Movies recorded on this device will only contain audio. They will be accessible through iTunes file sharing.", @"Video recording unavailable failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
								   localizedDescription, NSLocalizedDescriptionKey, 
								   localizedFailureReason, NSLocalizedFailureReasonErrorKey, 
								   nil];
		NSError *noVideoError = [NSError errorWithDomain:@"AVCam" code:0 userInfo:errorDict];
		if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
			[[self delegate] captureManager:self didFailWithError:noVideoError];
		}
	}
	
	[self setRecorder:newRecorder];
	
    success = YES;
    
    return success;
}

- (void)switchCamera
{
    NSArray* inputs = self.session.inputs;
    for (AVCaptureDeviceInput* input in inputs) {
        AVCaptureDevice* device = input.device;
        if ([device hasMediaType: AVMediaTypeVideo]) {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice* newCamera = nil;
            AVCaptureDeviceInput* newInput = nil;
            
            if (position == AVCaptureDevicePositionFront)
                newCamera = [self cameraWithPosition: AVCaptureDevicePositionBack];
            else
                newCamera = [self cameraWithPosition: AVCaptureDevicePositionFront];
            
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error: nil] ;
            
            // beginConfiguration ensures that pending changes are not applied immediately
            [self.session beginConfiguration] ;
            
            [self.session removeInput :input] ;
            [self.session addInput : newInput] ;
            
            //Changes take effect once the outermost commitConfiguration is invoked.
            [self.session commitConfiguration] ;
            break ;
        }
    }
}

- (void) startRecording
{
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns
		// to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library
		// when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error:
		// after the recorded file has been saved.
        [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}]];
    }
    
    [self removeFile:[[self recorder] outputFileURL]];
    [[self recorder] startRecordingWithOrientation:self.orientation];
}

- (void) stopRecording
{
    [[self recorder] stopRecording];
}

- (void) saveVideoWithCompletionBlock:(void (^)(BOOL))completion
{
    if ([self.assets count] != 0) {

        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        // 2 - Video track
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];        
        __block CMTime time = kCMTimeZero;
        __block CGAffineTransform translate;
        __block CGSize size;
        
        [self.assets enumerateObjectsUsingBlock:^(AVAsset *asset, NSUInteger idx, BOOL *stop) {

           // AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:string]];//obj]];
            AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                           ofTrack:videoAssetTrack atTime:time error:nil];
            
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:time error:nil];
            if(idx == 0)
            {
                // Set your desired output aspect ratio here. 1.0 for square, 16/9.0 for widescreen, etc.
                CGFloat desiredAspectRatio = 1.0;
                CGSize naturalSize = CGSizeMake(videoAssetTrack.naturalSize.width, videoAssetTrack.naturalSize.height);
                CGSize adjustedSize = CGSizeApplyAffineTransform(naturalSize, videoAssetTrack.preferredTransform);
                adjustedSize.width = ABS(adjustedSize.width);
                adjustedSize.height = ABS(adjustedSize.height);
                if (adjustedSize.width > adjustedSize.height) {
                    size = CGSizeMake(adjustedSize.height * desiredAspectRatio, adjustedSize.height);
                    translate = CGAffineTransformMakeTranslation(-(adjustedSize.width - size.width) / 2.0, 0);
                } else {
                    size = CGSizeMake(adjustedSize.width, adjustedSize.width / desiredAspectRatio);
                    translate = CGAffineTransformMakeTranslation(0, -(adjustedSize.height - size.height) / 2.0);
                }
                CGAffineTransform newTransform = CGAffineTransformConcat(videoAssetTrack.preferredTransform, translate);
                [videoTrack setPreferredTransform:newTransform];
                
                // Check the output size - for best results use sizes that are multiples of 16
                // More info: http://stackoverflow.com/questions/22883525/avassetexportsession-giving-me-a-green-border-on-right-and-bottom-of-output-vide
                if (fmod(size.width, 4.0) != 0)
                    NSLog(@"NOTE: The video output width %0.1f is not a multiple of 4, which may cause a green line to appear at the edge of the video", size.width);
                if (fmod(size.height, 4.0) != 0)
                    NSLog(@"NOTE: The video output height %0.1f is not a multiple of 4, which may cause a green line to appear at the edge of the video", size.height);
            }
            
            time = CMTimeAdd(time, asset.duration);
        }];
        
        AVMutableVideoCompositionInstruction *vtemp = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        vtemp.timeRange = CMTimeRangeMake(kCMTimeZero, time);
        NSLog(@"\nInstruction vtemp's time range is %f %f", CMTimeGetSeconds( vtemp.timeRange.start),
              CMTimeGetSeconds(vtemp.timeRange.duration));
        
        // Also tried videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack
        AVMutableVideoCompositionLayerInstruction *vLayerInstruction = [AVMutableVideoCompositionLayerInstruction
                                                                        videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        

        [vLayerInstruction setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
        vtemp.layerInstructions = @[vLayerInstruction];
        
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.renderSize = size;
        videoComposition.frameDuration = CMTimeMake(1,30);
        videoComposition.instructions = @[vtemp];
        
        // 4 - Get path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path =  [documentsDirectory stringByAppendingPathComponent:
                                 [NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
        NSURL *url = [NSURL fileURLWithPath:path];

        // 5 - Create exporter
        self.exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                          presetName:AVAssetExportPresetMediumQuality];
        self.exportSession.outputURL = url;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        self.exportSession.shouldOptimizeForNetworkUse = YES;
        self.exportSession.videoComposition = videoComposition;
        self.exportProgressBarTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self.delegate selector:@selector(updateProgress) userInfo:nil repeats:YES];
        
        __block id weakSelf = self;
      
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            NSLog (@"i is in your block, exportin. status is %ld",(long)self.exportSession.status);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
                AVAssetImageGenerator *generateImg = [[AVAssetImageGenerator alloc] initWithAsset:asset];
                NSError *error = NULL;
                CMTime time = CMTimeMake(1, 65);
                CGImageRef refImg = [generateImg copyCGImageAtTime:time actualTime:NULL error:&error];
                NSLog(@"error==%@, Refimage==%@", error, refImg);
                
                UIImage *FrameImage= [[UIImage alloc] initWithCGImage:refImg];
                UIImage *_FrameImage= [[UIImage alloc] initWithCGImage:refImg];
                UIImage *thumbnailImage = [_FrameImage thumbnailImage:86.0f transparentBorder:0.0f cornerRadius:42.0f interpolationQuality:kCGInterpolationDefault];
                
                //Video thumbnail quality
                NSData *imageData = UIImageJPEGRepresentation(FrameImage, 1.0f);
                //NSData *imageData = UIImageJPEGRepresentation(FrameImage, 0.8f);
                PFFile *thumbnail = [PFFile fileWithData:imageData];
                NSData *_imageData = UIImageJPEGRepresentation(thumbnailImage, 0.8f);
                PFFile *_thumbnail = [PFFile fileWithData:_imageData];
                
                NSData *videoData = [[NSData alloc] initWithContentsOfURL:url];
                PFFile *videoFile = [PFFile fileWithData:videoData];
                NSLog(@"%@",[NSByteCountFormatter stringFromByteCount:videoData.length countStyle:NSByteCountFormatterCountStyleFile]);

                //Below section is what disallows current user to delete other users comments
                //PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
                //[ACL setPublicReadAccess:YES];
                //[ACL setPublicWriteAccess:YES];
                
                PFObject *videoObject = [PFObject objectWithClassName:kESPhotoClassKey];
                [videoObject setObject:videoFile forKey:kESVideoFileKey];
                [videoObject setObject:thumbnail forKey:kESVideoFileThumbnailKey];
                [videoObject setObject:_thumbnail forKey:kESVideoFileThumbnailRoundedKey];
                [videoObject setObject:kESVideoTypeKey forKey:kESVideoOrPhotoTypeKey];
                //[videoObject setACL:ACL];
                [videoObject setObject:[PFUser currentUser] forKey:@"user"];
                
                [videoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadEnds" object:nil];
                    if (succeeded) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadSucceeds" object:nil];
                    }
                    else if (error) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadFails" object:nil];
                    }
                }];
                
                [weakSelf exportDidFinish:self.exportSession withCompletionBlock:completion];
            });
        }];
    }
}


//Video Comments
- (void) saveVideoWithCompletionBlockComment:(void (^)(BOOL))completion
{
    if ([self.assets count] != 0) {
        
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        // 2 - Video track
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        __block CMTime time = kCMTimeZero;
        __block CGAffineTransform translate;
        __block CGSize size;
        
        [self.assets enumerateObjectsUsingBlock:^(AVAsset *asset, NSUInteger idx, BOOL *stop) {
            
            // AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:string]];//obj]];
            AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:videoAssetTrack atTime:time error:nil];
            
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:time error:nil];
            if(idx == 0)
            {
                // Set your desired output aspect ratio here. 1.0 for square, 16/9.0 for widescreen, etc.
                CGFloat desiredAspectRatio = 1.0;
                CGSize naturalSize = CGSizeMake(videoAssetTrack.naturalSize.width, videoAssetTrack.naturalSize.height);
                CGSize adjustedSize = CGSizeApplyAffineTransform(naturalSize, videoAssetTrack.preferredTransform);
                adjustedSize.width = ABS(adjustedSize.width);
                adjustedSize.height = ABS(adjustedSize.height);
                if (adjustedSize.width > adjustedSize.height) {
                    size = CGSizeMake(adjustedSize.height * desiredAspectRatio, adjustedSize.height);
                    translate = CGAffineTransformMakeTranslation(-(adjustedSize.width - size.width) / 2.0, 0);
                } else {
                    size = CGSizeMake(adjustedSize.width, adjustedSize.width / desiredAspectRatio);
                    translate = CGAffineTransformMakeTranslation(0, -(adjustedSize.height - size.height) / 2.0);
                }
                CGAffineTransform newTransform = CGAffineTransformConcat(videoAssetTrack.preferredTransform, translate);
                [videoTrack setPreferredTransform:newTransform];
                
                // Check the output size - for best results use sizes that are multiples of 16
                // More info: http://stackoverflow.com/questions/22883525/avassetexportsession-giving-me-a-green-border-on-right-and-bottom-of-output-vide
                if (fmod(size.width, 4.0) != 0)
                    NSLog(@"NOTE: The video output width %0.1f is not a multiple of 4, which may cause a green line to appear at the edge of the video", size.width);
                if (fmod(size.height, 4.0) != 0)
                    NSLog(@"NOTE: The video output height %0.1f is not a multiple of 4, which may cause a green line to appear at the edge of the video", size.height);
            }
            
            time = CMTimeAdd(time, asset.duration);
        }];
        
        AVMutableVideoCompositionInstruction *vtemp = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        vtemp.timeRange = CMTimeRangeMake(kCMTimeZero, time);
        NSLog(@"\nInstruction vtemp's time range is %f %f", CMTimeGetSeconds( vtemp.timeRange.start),
              CMTimeGetSeconds(vtemp.timeRange.duration));
        
        // Also tried videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack
        AVMutableVideoCompositionLayerInstruction *vLayerInstruction = [AVMutableVideoCompositionLayerInstruction
                                                                        videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        
        [vLayerInstruction setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
        vtemp.layerInstructions = @[vLayerInstruction];
        
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.renderSize = size;
        videoComposition.frameDuration = CMTimeMake(1,30);
        videoComposition.instructions = @[vtemp];
        
        // 4 - Get path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path =  [documentsDirectory stringByAppendingPathComponent:
                           [NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
        NSURL *url = [NSURL fileURLWithPath:path];
        
        // 5 - Create exporter
        self.exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                              presetName:AVAssetExportPresetMediumQuality];
        self.exportSession.outputURL = url;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        self.exportSession.shouldOptimizeForNetworkUse = YES;
        self.exportSession.videoComposition = videoComposition;
        self.exportProgressBarTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self.delegate selector:@selector(updateProgress) userInfo:nil repeats:YES];
        
        __block id weakSelf = self;
        
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            NSLog (@"i is in your block, exportin. status is %ld",(long)self.exportSession.status);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
                AVAssetImageGenerator *generateImg = [[AVAssetImageGenerator alloc] initWithAsset:asset];
                NSError *error = NULL;
                CMTime time = CMTimeMake(1, 65);
                CGImageRef refImg = [generateImg copyCGImageAtTime:time actualTime:NULL error:&error];
                NSLog(@"error==%@, Refimage==%@", error, refImg);
                
                UIImage *FrameImage= [[UIImage alloc] initWithCGImage:refImg];
                UIImage *_FrameImage= [[UIImage alloc] initWithCGImage:refImg];
                UIImage *thumbnailImage = [_FrameImage thumbnailImage:86.0f transparentBorder:0.0f cornerRadius:42.0f interpolationQuality:kCGInterpolationDefault];
                NSData *imageData = UIImageJPEGRepresentation(FrameImage, 0.8f);
                PFFile *thumbnail = [PFFile fileWithData:imageData];
                NSData *_imageData = UIImageJPEGRepresentation(thumbnailImage, 0.8f);
                PFFile *_thumbnail = [PFFile fileWithData:_imageData];
                
                NSData *videoData = [[NSData alloc] initWithContentsOfURL:url];
                PFFile *videoFile = [PFFile fileWithData:videoData];
                NSLog(@"%@",[NSByteCountFormatter stringFromByteCount:videoData.length countStyle:NSByteCountFormatterCountStyleFile]);
                
                //Below section is what disallows current user to delete other users comments
                //PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
                //[ACL setPublicReadAccess:YES];
                //[ACL setPublicWriteAccess:YES];
                
                
                
                
                

                
                //Below is where the saving takes place for the video to the Activity Class in Parse
                PFObject *comment = [PFObject objectWithClassName:kESActivityClassKey];
                
                AppDelegate *delegate = [AppDelegate getAppDelegate];
                PFObject *object = delegate.object;
                
                [comment setObject:[object objectForKey:kESPhotoUserKey] forKey:kESActivityToUserKey]; // Set toUser
                [comment setObject:object forKey:kESActivityPhotoKey]; // Set Photo currently being viewed in detail
                
                if ([object objectForKey:kESVideoFileKey]) {
                    [comment setObject:kESActivityTypeCommentVideo forKey:kESActivityTypeKey];
                }else if ([[object objectForKey:@"type"] isEqualToString:@"text"]) {
                    [comment setObject:kESActivityTypeCommentPost forKey:kESActivityTypeKey];
                }else [comment setObject:kESActivityTypeCommentPhoto forKey:kESActivityTypeKey];
                
                [comment setObject:object.objectId forKey:kESActivityPhotoIDKey];
                
                
                
                // Also the PhotoID needs to be saved with the current photo being viewed in the detail
                
                
                //ADDED for video comments
                [comment setObject:kESActivityTypeCommentVideo forKey:kESActivityTypeKey];
                //
                
                [[ESCache sharedCache] incrementCommentCountForPhoto:object];
                
                //ADDED for video comment FIX
                [comment setObject:@"" forKey:kESActivityContentKey];
                //
                
                
                
                [comment setObject:[PFUser currentUser] forKey:kESActivityFromUserKey]; // Set fromUser
                [comment setObject:videoFile forKey:kESActivityVideoFileKey];
                [comment setObject:thumbnail forKey:kESActivityVideoFileThumbnailKey];
                [comment setObject:_thumbnail forKey:kESActivityVideoFileThumbnailRoundedKey];
                //[comment setACL:ACL];
                [comment setObject:[PFUser currentUser] forKey:@"user"];
                
                [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadEnds" object:nil];
                    if (succeeded) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadSucceeds" object:nil];
                    }
                    else if (error) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadFails" object:nil];
                    }
                }];
                
                [weakSelf exportDidFinish:self.exportSession withCompletionBlockComment:completion];
            });
        }];
    }
    
}





//Video Profile
- (void) saveVideoWithCompletionBlockProfile:(void (^)(BOOL))completion
{
    if ([self.assets count] != 0) {
        
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        // 2 - Video track
        AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        __block CMTime time = kCMTimeZero;
        __block CGAffineTransform translate;
        __block CGSize size;
        
        [self.assets enumerateObjectsUsingBlock:^(AVAsset *asset, NSUInteger idx, BOOL *stop) {
            
            // AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:string]];//obj]];
            AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:videoAssetTrack atTime:time error:nil];
            
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:time error:nil];
            if(idx == 0)
            {
                // Set your desired output aspect ratio here. 1.0 for square, 16/9.0 for widescreen, etc.
                CGFloat desiredAspectRatio = 1.0;
                CGSize naturalSize = CGSizeMake(videoAssetTrack.naturalSize.width, videoAssetTrack.naturalSize.height);
                CGSize adjustedSize = CGSizeApplyAffineTransform(naturalSize, videoAssetTrack.preferredTransform);
                adjustedSize.width = ABS(adjustedSize.width);
                adjustedSize.height = ABS(adjustedSize.height);
                if (adjustedSize.width > adjustedSize.height) {
                    size = CGSizeMake(adjustedSize.height * desiredAspectRatio, adjustedSize.height);
                    translate = CGAffineTransformMakeTranslation(-(adjustedSize.width - size.width) / 2.0, 0);
                } else {
                    size = CGSizeMake(adjustedSize.width, adjustedSize.width / desiredAspectRatio);
                    translate = CGAffineTransformMakeTranslation(0, -(adjustedSize.height - size.height) / 2.0);
                }
                CGAffineTransform newTransform = CGAffineTransformConcat(videoAssetTrack.preferredTransform, translate);
                [videoTrack setPreferredTransform:newTransform];
                
                // Check the output size - for best results use sizes that are multiples of 16
                // More info: http://stackoverflow.com/questions/22883525/avassetexportsession-giving-me-a-green-border-on-right-and-bottom-of-output-vide
                if (fmod(size.width, 4.0) != 0)
                    NSLog(@"NOTE: The video output width %0.1f is not a multiple of 4, which may cause a green line to appear at the edge of the video", size.width);
                if (fmod(size.height, 4.0) != 0)
                    NSLog(@"NOTE: The video output height %0.1f is not a multiple of 4, which may cause a green line to appear at the edge of the video", size.height);
            }
            
            time = CMTimeAdd(time, asset.duration);
        }];
        
        AVMutableVideoCompositionInstruction *vtemp = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        vtemp.timeRange = CMTimeRangeMake(kCMTimeZero, time);
        NSLog(@"\nInstruction vtemp's time range is %f %f", CMTimeGetSeconds( vtemp.timeRange.start),
              CMTimeGetSeconds(vtemp.timeRange.duration));
        
        // Also tried videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack
        AVMutableVideoCompositionLayerInstruction *vLayerInstruction = [AVMutableVideoCompositionLayerInstruction
                                                                        videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        
        [vLayerInstruction setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
        vtemp.layerInstructions = @[vLayerInstruction];
        
        AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
        videoComposition.renderSize = size;
        videoComposition.frameDuration = CMTimeMake(1,30);
        videoComposition.instructions = @[vtemp];
        
        // 4 - Get path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path =  [documentsDirectory stringByAppendingPathComponent:
                           [NSString stringWithFormat:@"mergeVideo-%d.mov",arc4random() % 1000]];
        NSURL *url = [NSURL fileURLWithPath:path];
        
        // 5 - Create exporter
        self.exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                              presetName:AVAssetExportPresetMediumQuality];
        self.exportSession.outputURL = url;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        self.exportSession.shouldOptimizeForNetworkUse = YES;
        self.exportSession.videoComposition = videoComposition;
        self.exportProgressBarTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self.delegate selector:@selector(updateProgress) userInfo:nil repeats:YES];
        
        __block id weakSelf = self;
        
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            NSLog (@"i is in your block, exportin. status is %ld",(long)self.exportSession.status);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
                AVAssetImageGenerator *generateImg = [[AVAssetImageGenerator alloc] initWithAsset:asset];
                NSError *error = NULL;
                CMTime time = CMTimeMake(1, 65);
                CGImageRef refImg = [generateImg copyCGImageAtTime:time actualTime:NULL error:&error];
                NSLog(@"error==%@, Refimage==%@", error, refImg);
                
                UIImage *FrameImage= [[UIImage alloc] initWithCGImage:refImg];
                UIImage *_FrameImage= [[UIImage alloc] initWithCGImage:refImg];
                UIImage *thumbnailImage = [_FrameImage thumbnailImage:86.0f transparentBorder:0.0f cornerRadius:42.0f interpolationQuality:kCGInterpolationDefault];
                NSData *imageData = UIImageJPEGRepresentation(FrameImage, 0.8f);
                PFFile *thumbnail = [PFFile fileWithData:imageData];
                NSData *_imageData = UIImageJPEGRepresentation(thumbnailImage, 0.8f);
                PFFile *_thumbnail = [PFFile fileWithData:_imageData];
                
                NSData *videoData = [[NSData alloc] initWithContentsOfURL:url];
                PFFile *videoFile = [PFFile fileWithData:videoData];
                NSLog(@"%@",[NSByteCountFormatter stringFromByteCount:videoData.length countStyle:NSByteCountFormatterCountStyleFile]);
                
                //Below section is what disallows current user to delete other users comments
                //PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
                //[ACL setPublicReadAccess:YES];
                //[ACL setPublicWriteAccess:YES];
                
                
                
                
                //PFObject *mention = [PFObject objectWithClassName:kESUserClassKey];
                /////////PFObject *mention = [PFObject objectWithClassName:kESUserClassKey];
                
                
                PFQuery *mentionQuery = [PFUser query];
                //[mentionQuery whereKey:@"usernameFix" equalTo:mentionString];
                //[mentionQuery whereKey:kESUserObjectIdKey notEqualTo:[PFUser currentUser].objectId];
                [mentionQuery whereKey:kESUserObjectIdKey equalTo:[PFUser currentUser].objectId];
                [mentionQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    if (!error) {
                        //[mention setObject:objects forKey:@"mentions"]; // Set toUser
                        //[mention setObject:kESActivityTypeMention forKey:kESActivityTypeKey];
                        //[mention setObject:photo forKey:kESActivityPhotoKey];
                        [[PFUser currentUser] setObject:videoFile forKey:kESUserVideoFileKey];
                        [[PFUser currentUser] setObject:thumbnail forKey:kESUserVideoFileThumbnailKey];
                        [[PFUser currentUser] setObject:_thumbnail forKey:kESUserVideoFileThumbnailRoundedKey];
                        //[mention saveInBackgroundWithBlock:^(BOOL result, NSError *error){
                        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            //if (error) {
                            //    [mention saveEventually];
                            //}
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadEnds" object:nil];
                            if (succeeded) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadSucceeds" object:nil];
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"reload_data" object:self];
                            }
                            else if (error) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadFails" object:nil];
                            }
                            
                        }];
                        [weakSelf exportDidFinish:self.exportSession withCompletionBlockComment:completion];
                    }
                }];
                
                
                
                
                
                
                
            });
        }];
    }
}
                
                
                
                


-(void)exportDidFinish:(AVAssetExportSession*)session withCompletionBlock:(void(^)(BOOL success))completion {
    self.exportSession = nil;
    
    __block id weakSelf = self;
    //delete stored pieces
    [self.assets enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(AVAsset *asset, NSUInteger idx, BOOL *stop) {
        
        NSURL *fileURL = nil;
        if ([asset isKindOfClass:AVURLAsset.class])
        {
            AVURLAsset *urlAsset = (AVURLAsset*)asset;
            fileURL = urlAsset.URL;
        }
        
        if (fileURL)
            [weakSelf removeFile:fileURL];
    }];
    
    [self.assets removeAllObjects];
    [self.delegate removeProgress];
    
    
    //The section below saves the video comment to the camera roll.
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
                //delete file from documents after saving to camera roll
                [weakSelf removeFile:outputURL];
                
                if (error) {
                    completion (NO);
                } else {
                    completion (YES);
                }
            }];
        }
    }
    [self.assets removeAllObjects];
}

//Video Comments
-(void)exportDidFinish:(AVAssetExportSession*)session withCompletionBlockComment:(void(^)(BOOL success))completion {
    self.exportSession = nil;
    
    __block id weakSelf = self;
    //delete stored pieces
    [self.assets enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(AVAsset *asset, NSUInteger idx, BOOL *stop) {
        
        NSURL *fileURL = nil;
        if ([asset isKindOfClass:AVURLAsset.class])
        {
            AVURLAsset *urlAsset = (AVURLAsset*)asset;
            fileURL = urlAsset.URL;
        }
        
        if (fileURL)
            [weakSelf removeFile:fileURL];
    }];
    
    [self.assets removeAllObjects];
    [self.delegate removeProgress];
    
    
    //The section below saves the video comment to the camera roll.
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            //[library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
                //delete file from documents after saving to camera roll
                [weakSelf removeFile:outputURL];
                
                //if (error) {
                //    completion (NO);
                //} else {
                    completion (YES);
                //}
            //}];
        }
    }
    [self.assets removeAllObjects];
}


#pragma mark Device Counts
- (NSUInteger) cameraCount
{
    NSLog(@"COUNT");
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (NSUInteger) micCount
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] count];
}


#pragma mark Camera Properties
// Perform an auto focus at the specified point. The focus mode will automatically change to locked once the auto focus is complete.
- (void) autoFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusPointOfInterest:point];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
        } else {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
            }
        }        
    }
}

// Switch to continuous auto focus mode at the specified point
- (void) continuousFocusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
	
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
		NSError *error;
		if ([device lockForConfiguration:&error]) {
			[device setFocusPointOfInterest:point];
			[device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
			[device unlockForConfiguration];
		} else {
			if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
			}
		}
	}
}


-(void) deleteLastAsset
{
    AVAsset *asset = [self.assets lastObject];
    
    [self.delegate removeTimeFromDuration:CMTimeGetSeconds(asset.duration)];
    
    NSURL *fileURL = nil;
    if ([asset isKindOfClass:AVURLAsset.class])
    {
        AVURLAsset *urlAsset = (AVURLAsset*)asset;
        fileURL = urlAsset.URL;
    }
    
    if (fileURL)
        [self removeFile:fileURL];
    
    [self.assets removeLastObject];
}
@end


#pragma mark -
@implementation CaptureManager (InternalUtilityMethods)

// Find a camera with the specificed AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

// Find a front facing camera, returning nil if one is not found
- (AVCaptureDevice *) frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

// Find a back facing camera, returning nil if one is not found
- (AVCaptureDevice *) backFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

// Find and return an audio device, returning nil if one is not found
- (AVCaptureDevice *) audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0) {
        return [devices objectAtIndex:0];
    }
    return nil;
}

- (NSURL *) tempFileURL
{
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"]];
}

- (void) removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
                [[self delegate] captureManager:self didFailWithError:error];
            }            
        }
    }
}

- (void) copyFileToDocuments:(NSURL *)fileURL
{
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
	NSString *destinationPath = [documentsDirectory stringByAppendingFormat:@"/output_%@.mov", [dateFormatter stringFromDate:[NSDate date]]];
    
	NSError	*error;
	if (![[NSFileManager defaultManager] copyItemAtURL:fileURL toURL:[NSURL fileURLWithPath:destinationPath] error:&error]) {
		if ([[self delegate] respondsToSelector:@selector(captureManager:didFailWithError:)]) {
			[[self delegate] captureManager:self didFailWithError:error];
		}
	}
    
    //add asset into the array or pieces
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:destinationPath]];
    [self.assets addObject:asset];
}

@end


#pragma mark -
@implementation CaptureManager (RecorderDelegate)

-(void)recorderRecordingDidBegin:(AVCamRecorder *)recorder
{
    if ([[self delegate] respondsToSelector:@selector(captureManagerRecordingBegan:)]) {
        [[self delegate] captureManagerRecordingBegan:self];
    }
}

-(void)recorder:(AVCamRecorder *)recorder recordingDidFinishToOutputFileURL:(NSURL *)outputFileURL error:(NSError *)error
{
    //save file in the app's Documents directory for this session
    [self copyFileToDocuments:outputFileURL];
    
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundRecordingID]];
    }
    
    if ([[self delegate] respondsToSelector:@selector(captureManagerRecordingFinished:)]) {
        [[self delegate] captureManagerRecordingFinished:self];
    }
}

@end
