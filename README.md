# RSCameraView
自定义的摄像头预览视图（AVCaptureVideoPreviewLayer底层实现）

![](https://img.shields.io/badge/platform-iOS-red.svg) 
![](https://img.shields.io/badge/language-Objective--C-orange.svg) 
![](https://img.shields.io/badge/download-791K-brightgreen.svg)
![](https://img.shields.io/badge/license-MIT%20License-brightgreen.svg) 

封装获取摄像头数据流工具，为直播推流做准备，可单独使用于自定义摄像预览窗口。


## Advantage 框架的优势
* 1.文件少，代码简洁
* 2.不依赖任何其他第三方库
* 3.具备较高自定义性
* 4.逻辑清晰，线程安全

## Requirements 要求
* iOS 7+
* Xcode 8+


## Usage 使用方法
### 第一步 引入头文件
```
#import "RSCameraView.h"
```
### 第二步 <RSCameraDelegate>和声明属性
```
@property (nonatomic, strong) RSCameraView *camera;
@property (nonatomic, strong) UIImageView *cameraImageView;
```
### 第三步 RSCameraView 使用
```
_camera = [[RSCameraView alloc] initWithCameraPosition:AVCaptureDevicePositionFront captureFormat:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
_camera.delegate = self;
[_camera startCapture];
```

## Introduction 简介
### 直播预览层(AVCaptureVideoPreviewLayer)底层实现

1.分析sampleBuffer(帧数据)

通过设置AVCaptureVideoDataOutput的代理，就能获取捕获到一帧一帧数据

```
[videoOutput setSampleBufferDelegate:self queue:videoQue];
```

2.拿到这一帧一帧数据(sampleBuffer)怎么显示到屏幕上了
```
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
```

### sampleBuffer(帧数据)

* 视频本质是由很多帧图片组成
* 表示一帧视频/音频数据
* 通过sampleBuffer可以获取当前帧信息
* CVImageBufferRef(CMSampleBufferGetImageBuffer):编码前，解码后，图片信息
* CMSampleBufferGetDuration获取当前帧播放时间:用于记录视频播放时间
* CMSampleBufferGetPresentationTimeStamp获取当前帧开始时间(PTS):用于做音视频同步
    * PTS：Presentation Time Stamp。PTS主要用于度量解码后的视频帧什么时候被显示出来
    * DTS：Decode Time Stamp。DTS主要是标识读入内存中的比特流在什么时候开始送入解码器中进行解码
* (CMVideoFormatDescription)CMSampleBufferGetFormatDescription:视频编码，解码格式描述信息,通过它能获取sps,pps，编码成H264，就会生成一段NALU,这里面就包含sps，pps。
* (CMBlockBuffer)CMSampleBufferGetDataBuffer:编码后，图像数据；
* 视频帧的格式，可以在采集端的AVCaptureVideoDataOutput配置

```
// RGB
   videoOutput.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) }
// YUV(Full)
[videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
// YUV
[videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
```

### 显示原理

* 预览层实现原理：
    * 取出捕获到的帧(CMSampleBufferRef) -> 获取帧里面图片信息(CVImageBufferRef) -> 转换成UIImage -> 设置为UIImageView的image就能实时显示捕获的画面.
    * 因为是连续采集,每一帧都会变成图片显示出来，就相当于一串连贯的图片在播放，就形成视频了。
* CVImageBufferRef 如何转换成 UIImage
    * 使用CoreImage框架,前提CVImageBufferRef是RGB格式
    * CVImageBufferRef -> CIImage -> UIImage
* 注意点：设置UIImageView一定要放在主线程，默认接收到CMSampleBufferRef的代理方法不在主线程

```
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (_videoConnection == connection) {
        // 获取图片信息
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

        // 转换为CIImage
        CIImage *ciImage = [CIImage imageWithCVImageBuffer:imageBuffer];

        // 转换UIImage
        UIImage *image = [UIImage imageWithCIImage:ciImage];

        // 回到主线程更新UI
        dispatch_sync(dispatch_get_main_queue(), ^{

            self.imageView.image = image;

        });
    }
}
```

* 注意点二：CIImage和UIView坐标系是反的，需要设置UIImageView宽度为屏幕高度，长度为屏幕宽度，在旋转90度,还得设置锚点,自己画图就知道怎么旋转了

```
- (UIImageView *)imageView
{
    if (_imageView == nil) {
        _imageView = [[UIImageView alloc] init];
        _imageView.bounds = CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width);
        _imageView.layer.anchorPoint = CGPointMake(0, 0);
        _imageView.layer.position = CGPointMake(self.view.bounds.size.width, 0);
        _imageView.transform = CGAffineTransformMakeRotation(M_PI_2);

        [self.view addSubview:_imageView];
    }
    return _imageView;
}
```

### YUV与RGB视频格式讲解

* YUV:流媒体的常用编码方式, 对于图像每一点，Y确定其亮度，UV确认其彩度.
    * 为什么流媒体需要用到YUV，相对于RGB24（RGB三个分量各8个字节）的编码格式，只需要一半的存储容量。在流数据传输时降低了带宽压力。
    * YUV存储方式主要分为两种：Packeted 和 Planar。
    * Packeted方式类似RGB的存储方式,以像素矩阵为存储方式。
    * Planar方式将YUV分量分别存储到矩阵，每一个分量矩阵称为一个平面。
    * YUV420即以平面方式存储，色度抽样为4:2:0的色彩编码格式。其中YUV420P为三平面存储，YUV420SP为两平面存储。
* RGB:在渲染时，不管是OpenGL还是iOS，都不支持直接渲染YUV数据，底层都是转为RGB，所以在显示到屏幕，必须用RGB.


使用简单、效率高效、进程安全~~~如果你有更好的建议,希望不吝赐教!


## License 许可证
RSCameraView 使用 MIT 许可证，详情见 LICENSE 文件。


## Contact 联系方式:
* WeChat : WhatsXie
* Email : ReverseScale@iCloud.com
* Blog : https://reversescale.github.io

