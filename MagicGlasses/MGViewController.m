//
//  MGViewController.m
//  MagicGlasses
//
//  Created by Roman Smirnov on 24.06.12.
//  Copyright (c) 2012 Roman Smirnov. All rights reserved.
//

#define SCREEN_SCALE_FACTOR (4.0)

#import "MGViewController.h"
#import <CoreVideo/CoreVideo.h>

@interface MGViewController () {
    AVCaptureSession *_session;
    AVCaptureDevice *_captureDevice;
    AVCaptureDeviceInput *_captureDeviceInput;
    AVCaptureVideoDataOutput *_videoOutput;
    CVOpenGLESTextureRef _videoTexture;
    CVOpenGLESTextureCacheRef _videoTextureCache;
    BOOL isDetectorDetecting;
    
    CIImage *redSkyImage;
    
    CIFilter *affineTransformFilter;
    CIFilter *redSkyFilter;
    CIFilter *pixelateFilter;
    CIFilter *monstersInsteadFaces;
    
    NSArray *faces;
    
    GLuint currentDrawingTexture;
    GLuint drawingToTextureFramebuffer;
    GLuint drawingToTextureDepthRenderBuffer;
}


@property (strong, nonatomic) EAGLContext *glcontext;
@property (strong, nonatomic) CIContext *cicontext;
@property (strong, nonatomic) CIImage *ciimage;
@property (strong, nonatomic) CIDetector *detector;



@end

@implementation MGViewController

@synthesize detector = _detector;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.glcontext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.glcontext) {
        NSLog(@"Failed to create ES context");
    } else {
        self.cicontext = [CIContext contextWithEAGLContext:self.glcontext];
        
        if (!self.cicontext){
            NSLog(@"Failed to create CI context");
        }
    }
    
    GLKView *view = (GLKView *)self.view;
    self.view.contentScaleFactor = 1.0 / SCREEN_SCALE_FACTOR;
    view.context = self.glcontext;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    //-- Create CVOpenGLESTextureCacheRef for optimal CVImageBufferRef to GLES texture conversion.
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.glcontext, NULL, &_videoTextureCache);
    if (err) 
    {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }
    
    // создаем сессию
    _session = [[AVCaptureSession alloc] init];
    
    [_session beginConfiguration];

    _session.sessionPreset = AVCaptureSessionPreset640x480;
//    _session.sessionPreset = AVCaptureSessionPreset1280x720;

    
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
        
    [_videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];

    
    [_session commitConfiguration];
    [_session startRunning];
    
    
    NSDictionary *options = [NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy];
    self.detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                       context:self.cicontext
                                       options:options];
    
    [self createFilters];
    [self loadTextures];
    
}

- (void)createFilters
{
    redSkyFilter = [CIFilter filterWithName:@"CIOverlayBlendMode"];
    [redSkyFilter setDefaults];
    
    monstersInsteadFaces = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [redSkyFilter setDefaults];

    pixelateFilter = [CIFilter filterWithName:@"CIPixellate"];
    [pixelateFilter setDefaults];
    
    affineTransformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
    [affineTransformFilter setDefaults];
    
//    NSLog(@"filterNamesInCategory:kCICategoryStylize = %@", [CIFilter filterNamesInCategory:kCICategoryCompositeOperation]);
    NSLog(@"[monstersInsteadFaces attributes] = %@", [monstersInsteadFaces attributes]);
}

- (void)loadTextures
{
//    UIImage *tempImage = [UIImage imageNamed:@"RedSky.png"];
//    
//    UIImageView *newView = [[UIImageView alloc]initWithImage:tempImage];
//    newView.frame = CGRectMake(10, 10, 100, 200);
//    
//    [self.view addSubview:newView];
//    
//    
//    redSkyImage = [CIImage imageWithCGImage:(__bridge CGImageRef)(tempImage.CIImage)];
    
//    redSkyImage = [CIImage imageWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"RedSky" withExtension:@"png"]];
    UIImage *tempImage = [UIImage imageNamed:@"RedSky.png"];
    
    UIGraphicsBeginImageContext(CGSizeMake(640, 480));
    
    [tempImage drawInRect:CGRectMake(0, 0, 640, 480)];
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    redSkyImage = [CIImage imageWithCGImage:newImage.CGImage];
    
    
//    float scaleX = 512.0 / redSkyImage.extent.size.width;
//    float scaleY = (768.0/2.0) / redSkyImage.extent.size.height;
//    
//    [affineTransformFilter setValue:redSkyImage forKey:@"inputImage"];
//    [affineTransformFilter setValue:[NSValue valueWithCGAffineTransform:CGAffineTransformMakeScale(scaleX, scaleY)] forKey:@"inputTransform"];
//    redSkyImage = [affineTransformFilter valueForKey:@"outputImage"];
//    [affineTransformFilter setValue:nil forKey:@"inputImage"];
    

}

- (void)viewDidUnload
{
    [super viewDidUnload];
        
    if ([EAGLContext currentContext] == self.glcontext) {
        [EAGLContext setCurrentContext:nil];
    }
	self.glcontext = nil;
    self.cicontext = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [EAGLContext setCurrentContext:self.glcontext];
        
	// Generate and bind a render buffer which will become a depth buffer shared between our two FBOs
	glGenRenderbuffers(1, &drawingToTextureDepthRenderBuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, drawingToTextureDepthRenderBuffer);
    
	/*
     Currently it is unknown to GL that we want our new render buffer to be a depth buffer.
     glRenderbufferStorage will fix this and in this case will allocate a depth buffer
     m_i32TexSize by m_i32TexSize.
     */
    
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, 1024, 1024);
    
	// Create a texture for rendering to
	glGenTextures(1, &currentDrawingTexture);
    
    
    glBindTexture(GL_TEXTURE_2D, currentDrawingTexture);
        
    GLubyte *newDrawingTexture = (GLubyte *)malloc(1024 * 1024 * 4 * sizeof(GLubyte));
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_RGBA, GL_UNSIGNED_BYTE, newDrawingTexture);
    free(newDrawingTexture);
    
    //	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 1024, 1024, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, 0);
    
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    
    //	[self loadDrawingTexture];
    
	// Create the object that will allow us to render to the aforementioned texture
	glGenFramebuffers(1, &drawingToTextureFramebuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, drawingToTextureFramebuffer);
    
    
	// Attach the texture to the FBO
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, currentDrawingTexture, 0);
    
	// Attach the depth buffer we created earlier to our FBO.
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, drawingToTextureDepthRenderBuffer);
    
	// Check that our FBO creation was successful
	GLuint uStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
	if(uStatus != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"ERROR: Failed to initialise FBO. uStatus = %x", uStatus);
	}
    
    switch (uStatus) {
        case GL_FRAMEBUFFER_COMPLETE:
        {
            NSLog(@"uStatus = GL_FRAMEBUFFER_COMPLETE");
            break;
        }

        case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
        {
            NSLog(@"uStatus = GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT");
            break;
        }
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
        {
            NSLog(@"uStatus = GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT");
            break;
        }
        case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
        {
            NSLog(@"uStatus = GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS");
            break;
        }
        case GL_FRAMEBUFFER_UNSUPPORTED:
        {
            NSLog(@"uStatus = GL_FRAMEBUFFER_UNSUPPORTED");
            break;
        }

        default:
        {
            NSLog(@"UNKNOWN uStatus");
            break;
        }
    }
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
//    } else {
//        return YES;
//    }
}

- (void)cleanUpTextures
{    
    
    if (_videoTexture)
    {
        CFRelease(_videoTexture);
        _videoTexture = NULL;
    }
    
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
}

- (void)detectFacesOnImage:(CIImage *)image{
    
//    NSLog(@"%@ : %@", self, NSStringFromSelector(_cmd));
    
    @autoreleasepool {
        
        faces = nil;
        
        faces = [self.detector featuresInImage:image];
        
//        if ([faces count] > 0){
//            NSLog(@"%@ : %@ found %d faces", self, NSStringFromSelector(_cmd), [faces count]);
//        }
        
//        for (CIFaceFeature *feature in faces){
//            NSLog(@"feature %d", [faces indexOfObject:feature]);
//            if (feature.hasMouthPosition)
//                NSLog(@"mouth position = (%f, %f)", feature.mouthPosition.x, feature.mouthPosition.y);
//            if (feature.hasLeftEyePosition)
//                NSLog(@"mouth position = (%f, %f)", feature.leftEyePosition.x, feature.leftEyePosition.y);
//            if (feature.hasRightEyePosition)
//                NSLog(@"mouth position = (%f, %f)", feature.rightEyePosition.x, feature.rightEyePosition.y);
//        }
        
        
        isDetectorDetecting = NO;
        
    }
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate methods

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVReturn err;
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    if (!_videoTextureCache)
    {
        NSLog(@"No video texture cache");
        return;
    }
    
    [self cleanUpTextures];
    
    // CVOpenGLESTextureCacheCreateTextureFromImage will create GLES texture
    // optimally from CVImageBufferRef.
    
//    glActiveTexture(GL_TEXTURE0);
//    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
//                                                       _videoTextureCache,
//                                                       pixelBuffer,
//                                                       NULL,
//                                                       GL_TEXTURE_2D,
//                                                       GL_RGBA,
//                                                       width,
//                                                       height,
//                                                       GL_RGBA,
//                                                       GL_UNSIGNED_BYTE,
//                                                       0,
//                                                       &_videoTexture);
//    if (err)
//    {
//        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
//    }
//    
//    glBindTexture(CVOpenGLESTextureGetTarget(_videoTexture), CVOpenGLESTextureGetName(_videoTexture));
//	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // on iPhone iOS 5.1.1 works UNSTABLE %(
    self.ciimage = [CIImage imageWithCVPixelBuffer:pixelBuffer];

//    self.ciimage = [CIImage imageWithTexture:CVOpenGLESTextureGetName(_videoTexture)
//                                                       size:CGSizeMake(width, height)
//                                                    flipped:NO
//                                                 colorSpace:CGColorSpaceCreateDeviceRGB()];
    
//    NSLog(@"self.ciimage.extent = (%f, %f, %f, %f)", self.ciimage.extent.origin.x, self.ciimage.extent.origin.y, self.ciimage.extent.size.width, self.ciimage.extent.size.height);
//
//    NSLog(@"redSkyImage.extent = (%f, %f, %f, %f)", redSkyImage.extent.origin.x, redSkyImage.extent.origin.y, redSkyImage.extent.size.width, redSkyImage.extent.size.height);


    
    [redSkyFilter setValue:redSkyImage forKey:@"inputImage"];
    [redSkyFilter setValue:self.ciimage forKey:@"inputBackgroundImage"];
    self.ciimage = [redSkyFilter valueForKey:@"outputImage"];
    
    // рисуем монстров вместо лиц
    // устанавливаем текстуру в которую будем рисовать
    
    
    // для каждого найденного лица рисуем ciimage в текстуру
    
    for (CIFaceFeature *feature in faces){
        
        
        if (feature.hasMouthPosition)
            NSLog(@"mouth position = (%f, %f)", feature.mouthPosition.x, feature.mouthPosition.y);
        if (feature.hasLeftEyePosition)
            NSLog(@"mouth position = (%f, %f)", feature.leftEyePosition.x, feature.leftEyePosition.y);
        if (feature.hasRightEyePosition)
            NSLog(@"mouth position = (%f, %f)", feature.rightEyePosition.x, feature.rightEyePosition.y);
    }
    

    
    [pixelateFilter setValue:self.ciimage forKey: @"inputImage"];
    self.ciimage = [pixelateFilter valueForKey:@"outputImage"];
    
    
    [pixelateFilter setValue:nil forKey: @"inputImage"];
    
    [redSkyFilter setValue:nil forKey:@"inputImage"];
    [redSkyFilter setValue:nil forKey:@"inputBackgroundImage"];

    
    

//    получаем CIImage по-разному в зависимости от версии iOS
//    
//    CIImage *tempImage = [[CIImage alloc] init];
//    if ([tempImage respondsToSelector:@selector(initWithTexture:size:flipped:colorSpace:)])
//    {
//        // iOS 6 branch
//        if (_videoTexture){
//            self.ciimage = [[CIImage alloc] initWithTexture:CVOpenGLESTextureGetName(_videoTexture)
//                                                       size:CGSizeMake(width, height)
//                                                    flipped:NO
//                                                 colorSpace:CGColorSpaceCreateDeviceRGB()];
//        }
//    }
//    else {
//        // iOS 5 branch
//
//        // on iPhone works only in Portrait mode
//        self.ciimage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
//    }
//    tempImage = nil;

//    detect faces

    if (!isDetectorDetecting){
        isDetectorDetecting = YES;
        [self performSelectorInBackground:@selector(detectFacesOnImage:) withObject:self.ciimage];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    NSLog(@"%@ : %@", self, NSStringFromSelector(_cmd));
    
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{

}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // рисуем в текстуру
    CIImage *newCIImage = nil;
    
    GLint defaultFBO;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, &defaultFBO);
    
    if (self.cicontext && self.ciimage){
        
        glBindTexture(GL_TEXTURE_2D, 0);
        
        glBindFramebuffer(GL_FRAMEBUFFER, drawingToTextureFramebuffer);
        
        glClearColor(0.5, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        
        [self.cicontext drawImage:self.ciimage
                           inRect:CGRectMake(0, 0, 350, 350)
                         fromRect:self.ciimage.extent];
    }
    
    
    // рисуем полученную текстуру
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFBO);
    
    newCIImage = [CIImage imageWithTexture:currentDrawingTexture
                                      size:CGSizeMake(1024, 1024)
                                   flipped:NO
                                colorSpace:CGColorSpaceCreateDeviceRGB()];

    
    glClearColor(0.0, 0.5, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    [self.cicontext drawImage:newCIImage
                       inRect:CGRectMake(0, 0, 100, 100)
                     fromRect:newCIImage.extent];

    newCIImage = nil;
    
}

@end
