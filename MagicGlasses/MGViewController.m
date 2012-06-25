//
//  MGViewController.m
//  MagicGlasses
//
//  Created by Roman Smirnov on 24.06.12.
//  Copyright (c) 2012 Roman Smirnov. All rights reserved.
//

#import "MGViewController.h"
#import <CoreVideo/CoreVideo.h>

@interface MGViewController () {
    AVCaptureSession *_session;
    AVCaptureDevice *_captureDevice;
    AVCaptureDeviceInput *_captureDeviceInput;
    AVCaptureVideoDataOutput *_videoOutput;
}


@property (strong, nonatomic) EAGLContext *context;

@end

@implementation MGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    // создаем сессию
    _session = [[AVCaptureSession alloc] init];
    
    [_session beginConfiguration];

    _session.sessionPreset = AVCaptureSessionPresetMedium;
    
    // Создаем девайс, с которого будем захватывать изображение
    _captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error = nil;
    _captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice
                                                                error:&error];
    if (!_captureDeviceInput){
        NSLog(@"%@ : %@ Warning! Failed to create device input. error: %@", self, NSStringFromSelector(_cmd), error);
    } else {
        [_session addInput:_captureDeviceInput];
    }
    
    // создаем Output
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_session addOutput:_videoOutput];
    _videoOutput.videoSettings =
    [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    
    dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
    [_videoOutput setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    [_session commitConfiguration];
    [_session startRunning];
}

- (void)viewDidUnload
{    
    [super viewDidUnload];
        
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    NSLog(@"%@ : %@", self, NSStringFromSelector(_cmd));
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%@ : %@", self, NSStringFromSelector(_cmd));
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{

}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0, 0.5, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
}

@end
