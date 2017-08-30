//
//  ViewController.m
//  RSCameraView
//
//  Created by WhatsXie on 2017/8/30.
//  Copyright © 2017年 StevenXie. All rights reserved.
//

#import "ViewController.h"
#import "RSCameraView.h"

@interface ViewController ()<RSCameraDelegate>
@property (nonatomic, strong) RSCameraView *camera;
@property (nonatomic, strong) UIImageView *cameraImageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _camera = [[RSCameraView alloc] initWithCameraPosition:AVCaptureDevicePositionFront captureFormat:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    _camera.delegate = self;
    [_camera startCapture];
}
// handle sampleBuffer
- (void)projectionImagesWith:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];
    UIImage *image = [UIImage imageWithCIImage:ciImage];
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.cameraImageView.image = image;
    });
}

// Delegate
- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self projectionImagesWith:sampleBuffer];
}
// lazy
- (UIImageView *)cameraImageView {
    if (_cameraImageView == nil) {
        _cameraImageView = [[UIImageView alloc] init];
        _cameraImageView.bounds = CGRectMake(0, 0, 300, 300);
        _cameraImageView.center = self.view.center;
//        _cameraImageView.layer.anchorPoint = CGPointMake(0, 0);
//        _cameraImageView.layer.position = CGPointMake(self.view.bounds.size.width, 0);
//        _cameraImageView.transform = CGAffineTransformMakeRotation(M_PI_2);
        [self.view addSubview:_cameraImageView];
    }
    return _cameraImageView;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
