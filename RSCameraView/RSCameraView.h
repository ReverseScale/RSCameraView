//
//  RSCameraView.h
//  RSCameraView
//
//  Created by WhatsXie on 2017/8/30.
//  Copyright © 2017年 StevenXie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol RSCameraDelegate <NSObject>

- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

@interface RSCameraView : NSObject
@property (nonatomic, assign) id<RSCameraDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL isFrontCamera;
@property (nonatomic, copy) dispatch_queue_t captureQueue;

- (instancetype)initWithCameraPosition:(AVCaptureDevicePosition)cameraPosition captureFormat:(int)captureFormat;

- (void)startUp;

- (void)startCapture;

- (void)stopCapture;

- (void)changeCameraInputDeviceisFront:(BOOL)isFront;

@end




