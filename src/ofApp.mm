#include "ofApp.h"

#define CVC_ID 0
#define VVC_ID 1

#define VGRAB_W 360
#define VGRAB_H 480
//#define VGRAB_W 32
//#define VGRAB_H 48

//--------------------------------------------------------------
void ofApp::setup(){
    //SIZE VIEWS
    collapsedVC = 50;
    expandedVC  = 335;
    
    frameH = ofGetHeight()-collapsedVC;
    frameW = frameH*VGRAB_W/VGRAB_H;
    
    fbo.allocate(VGRAB_W,VGRAB_H);
    
    printf("w:%d, h:%d\n",ofGetWidth(), ofGetHeight());
    //VISION VIEW CONTROLLER
    vvc = [[VisionViewController alloc] initWithNibName:@"VisionViewController" bundle:nil];
    [vvc.view setBackgroundColor:[UIColor colorWithRed:0.9804 green:0.5922 blue:0.5334 alpha:1.0]];//250 151 136
    [vvc.view setFrame:CGRectMake(0, ofGetHeight()-(collapsedVC*2), ofGetWidth(), collapsedVC)];
    vvc.idn = VVC_ID;
    
    //COMMUNICATION VIEW CONTROLLER
    cvc = [[CommunicationViewController alloc] initWithNibName:@"CommunicationViewController" bundle:nil];
    [cvc.view setBackgroundColor:[UIColor colorWithRed:0.24 green:0.61 blue:0.84 alpha:1.0]];//61 156 215
    [cvc.view setFrame:CGRectMake(0, ofGetHeight()-collapsedVC, ofGetWidth(), collapsedVC)];
    cvc.idn = CVC_ID;
    
    
    //ADD VIEW CONTROLLERS TO SUPERVIEW
    
    [ofxiOSGetGLView() addSubview:vvc.view];
    [ofxiOSGetGLView() addSubview:cvc.view];
    
    
    //DEBUG IMAGE
    //debugImage.load("P1010044.JPG");
    
    //SETUP GRABBER
    videoFeed.setDeviceID(cameraID);
    videoFeed.setup(VGRAB_W, VGRAB_H, OF_PIXELS_BGRA);
    
    
    //ALLOCATE IMAGES FOR CV
    rawImage.allocate(VGRAB_W, VGRAB_H);
    grayImage.allocate(VGRAB_W, VGRAB_H);
    backgroundImage.allocate(VGRAB_W, VGRAB_H);
    
    thresholdImage.allocate(VGRAB_W, VGRAB_H);
    //newPixels=new unsigned char[(int)(backgroundImage.width*backgroundImage.height*3)];
    videoFeed.getGrabber<ofxiOSVideoGrabber>()->setAutofocusWithPointOfInterest(ofPoint(0.5,0.5));
    
    
    //HAAR FINDER
    finder.setup("haarcascade_frontalface_alt.xml");
    
    ofSetCircleResolution(128);
//    ofEnableAntiAliasing();
    ofSetFrameRate(30);
    
}

//--------------------------------------------------------------
void ofApp::update(){
    
    videoFeed.update();
    
    //PROCESS IMAGE
    if(videoFeed.isFrameNew()){
        
        rawImage.setFromPixels( videoFeed.getPixels() );
        
        if(isHaarActive)
        {
            finder.findHaarObjects(rawImage.getPixels());
            
            string json = "{\"m\":\"f\",\"a\":[";
            for(unsigned int i = 0; i < finder.blobs.size(); i++) {
                ofRectangle rTmp = finder.blobs[i].boundingRect;
                
                json+= ((i==0)?"[":",[");
                json+=ofToString(rTmp.x)+",";
                json+=ofToString(rTmp.y)+",";
                json+=ofToString(rTmp.width)+",";
                json+=ofToString(rTmp.height)+"]";
            }
            json+="]}";
            if(ofGetElapsedTimef()-timeSinceLastWSSent >intervalSendWS)
            {
                timeSinceLastWSSent = ofGetElapsedTimef();
                [[NetworkManager sharedManager] sendMessage:[NSString stringWithUTF8String:json.c_str()]];
            }
            return;
        }
        
        if(blur>1)
        {
            rawImage.blurGaussian((blur%2!=0)?blur:blur+1);
        }
        //the following line transforms the image to grayscale
        grayImage = rawImage;
        
        if(isBackgroundCaptured && bgGrayImage.bAllocated)
        {
            grayImage.absDiff(bgGrayImage);
        }
        thresholdImage=grayImage;
        if(isDilateActive)
        {
            thresholdImage.dilate();
        }
        
        
        if(!isBackgroundCaptured)
        {
            thresholdImage.invert();
        }
        thresholdImage.threshold(threshold);
        contourFinder.findContours(thresholdImage, min_blob_size, max_blob_size, max_num_blobs, true);
        
        //SEND TO PROCESSING
        if(ofGetElapsedTimef()-timeSinceLastWSSent >intervalSendWS)// || ofGetElapsedTimef()-timeSinceLastOSCSent >intervalSendOSC )
        {
            if(sendItem == BLOBS)
            {
                string json = "{\"m\":\"b\",\"a\":[";
                for(int i =0; i<contourFinder.nBlobs;i++)
                {
                    ofxCvBlob bTmp= contourFinder.blobs[i];
                    json+= ((i==0)?"[":",[");
                    for(int j=0;j<bTmp.nPts;j++)
                    {
                        json+= ofToString((j==0)?"":",")+ofToString(bTmp.pts[j].x) +","+ ofToString(bTmp.pts[j].y);
                    }
                    json+="]";
                }
                json+="]}";
                if(ofGetElapsedTimef()-timeSinceLastWSSent >intervalSendWS)
                {
                    timeSinceLastWSSent = ofGetElapsedTimef();
                    [[NetworkManager sharedManager] sendMessage:[NSString stringWithUTF8String:json.c_str()]];
                }
            }
            else if(sendItem == BB)
            {
                string json = "{\"m\":\"x\",\"a\":[";
                for(int i =0; i<contourFinder.nBlobs;i++)
                {
                    ofRectangle rTmp= contourFinder.blobs[i].boundingRect;
                    json+= ((i==0)?"[":",[");
                    json+=ofToString(rTmp.x)+",";
                    json+=ofToString(rTmp.y)+",";
                    json+=ofToString(rTmp.width)+",";
                    json+=ofToString(rTmp.height)+"]";
                }
                json+="]}";
                if(ofGetElapsedTimef()-timeSinceLastWSSent >intervalSendWS)
                {
                    timeSinceLastWSSent = ofGetElapsedTimef();
                    [[NetworkManager sharedManager] sendMessage:[NSString stringWithUTF8String:json.c_str()]];
                }
            }
        }
        
        //CREATE THE FRAME TO DISPLAY
        fbo.begin();
        ofClear(255, 255, 255, 255);
        switch (indexVizState) {
            case 0:
                
                if(blur>1)
                {
                    rawImage.draw(0, 0);
                }
                else
                {
                    videoFeed.draw(0, 0);
                }
                break;
            case 1:
                
                grayImage.draw(0,0);
                
                break;
            case 2:
                thresholdImage.draw(0,0);
                break;
            case 3:
                thresholdImage.draw(0,0);
                ofSetHexColor(0xff00ff);
                ofSetLineWidth(2.0);
                ofNoFill();
                for (int i=0; i<contourFinder.nBlobs; i++){
                    ofDrawRectangle( contourFinder.blobs[i].boundingRect);
                    ofxCvBlob bTmp= contourFinder.blobs[i];
                    bTmp.draw();
                    
                }
                break;
            case 4:
                
                break;
            default:
                break;
        }
        fbo.end();
    }
   
    if(currentSizeSnapshotButton>normalSizeSnapshotButton)
    {
        currentSizeSnapshotButton = currentSizeSnapshotButton-(currentSizeSnapshotButton*0.05);
    }
    
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofBackground(255);
    ofSetHexColor(0xffffff);
    if(isHaarActive)
    {
        rawImage.draw(0, 0);
        ofNoFill();
        ofSetHexColor(0xff00ff);
        for(unsigned int i = 0; i < finder.blobs.size(); i++) {
            ofRectangle cur = finder.blobs[i].boundingRect;
            
            ofDrawRectangle(cur.x, cur.y, cur.width, cur.height);
        }
        return;
    }
    fbo.draw(0, 0,frameW,frameH);
    
    //BUTTON
    ofFill();
    ofSetColor(255, 110);
    ofDrawCircle(frameW-115, frameH-80, currentSizeSnapshotButton);
    ofDrawCircle(frameW-115, frameH-80, currentSizeSnapshotButton-3);

    ofSetColor(255,255);
}
#pragma mark INTERFACE METHODS
//--------------------------------------------------------------
void ofApp::openVC(int idn){
    //OPEN VIEW CONTROLLER
    if(idn==VVC_ID)
    {
        //VISION
        [cvc collapseVC];
        [UIView animateWithDuration:0.2
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             
                             [vvc.view setFrame:CGRectMake(0, ofGetHeight()-(collapsedVC+expandedVC), ofGetWidth(), expandedVC)];
                             [cvc.view setFrame:CGRectMake(0, ofGetHeight()-(collapsedVC), ofGetWidth(), collapsedVC)];
                         }
                         completion:^(BOOL finished){
                             // Wait one second and then fade in the view
                         }];
        areVCsOpen = true;
        
    }
    else if(idn==CVC_ID)
    {
        //COMMUNICATION
        [vvc collapseVC];
        [UIView animateWithDuration:0.2
                              delay: 0.0
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [vvc.view setFrame:CGRectMake(0, ofGetHeight()-(collapsedVC+expandedVC), ofGetWidth(), collapsedVC)];
                             [cvc.view setFrame:CGRectMake(0, ofGetHeight()-(expandedVC), ofGetWidth(), expandedVC)];
                         }
                         completion:^(BOOL finished){
                             // Wait one second and then fade in the view
                         }];
        areVCsOpen = true;
    }
}
//--------------------------------------------------------------
void ofApp::collapseVCs(){
    [vvc collapseVC];
    [cvc collapseVC];
    [UIView animateWithDuration:0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [vvc.view setFrame:CGRectMake(0, ofGetHeight()-(collapsedVC*2), ofGetWidth(), collapsedVC)];
                         [cvc.view setFrame:CGRectMake(0, ofGetHeight()-collapsedVC, ofGetWidth(), collapsedVC)];
                     }
                     completion:^(BOOL finished){
                         // Wait one second and then fade in the view
                     }];
    areVCsOpen = false;
    
}
//--------------------------------------------------------------
void ofApp::syncWithVisionTab(int tagIndex){
    indexVizState = tagIndex;
}
#pragma mark CAMERA CONTROL METHODS
//--------------------------------------------------------------
void ofApp::reFocus(float x, float y)
{
    videoFeed.getGrabber<ofxiOSVideoGrabber>()->setAutofocusWithPointOfInterest(ofPoint(x,y));
}
//--------------------------------------------------------------
void ofApp::setLockAE(bool locked){
    if(locked)
    {
        videoFeed.getGrabber<ofxiOSVideoGrabber>()->lockExposure();
    }
    else{
         videoFeed.getGrabber<ofxiOSVideoGrabber>()->unlockExposure();
    }
}
//--------------------------------------------------------------
void ofApp::setCameraID(int newCameraID)
{
    if(cameraID != newCameraID)
    {
        cameraID = newCameraID;
        videoFeed.close();
        videoFeed.setDeviceID(newCameraID);
        videoFeed.setup(VGRAB_W, VGRAB_H, OF_PIXELS_BGRA);
    }
}
//--------------------------------------------------------------
void ofApp::setSendItem(int switchItem){
    sendItem = switchItem;
}
#pragma mark OTHER OPENFRAMEWORKS METHODS
//--------------------------------------------------------------
void ofApp::exit(){
    
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    if(!areVCsOpen)
    {
        if(ofDist(touch.x, touch.y, frameW-110, frameH-80)<normalSizeSnapshotButton)
        {
            saveSnapshot();
        }
    }
}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){
    //CLOSE VCs
    
    if(!areVCsOpen)
    {
        // printf("%f,%f\n",touch.x/ ofGetScreenWidth(),touch.y/ofGetScreenHeight());
        //reFocus(touch.x/ ofGetScreenWidth(),touch.y/ofGetScreenHeight());
    }
    if(cvc.isKeyboardOut)
    {
        if(touch.y<ofGetHeight()-cvc.keyboardHeight)
        {
            [cvc dismissKeyboard];
        }
    }
    else if(touch.y< (ofGetHeight()-(collapsedVC+expandedVC)))
    {
        collapseVCs();
    }
}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){
    
}
#pragma mark OTHER METHODS
//--------------------------------------------------------------
void ofApp::saveSnapshot(){
    //TAKE SNAPSHOP
    ofPixels pixels;
    fbo.readToPixels(pixels);
    
    imgToSave.setFromPixels(pixels);
    UIImage *imgTmp = UIImageFromOFImage(imgToSave);
    UIImageWriteToSavedPhotosAlbum(imgTmp, nil, nil, nil);
    
    //START ANIMATION BUTTON
    currentSizeSnapshotButton = 50;
}
//--------------------------------------------------------------
void ofApp::captureBackground(){
    backgroundImage.setFromPixels(rawImage.getPixels());
    bgGrayImage = grayImage;
    //backgroundImage.save("bg.png");
    ofBuffer photoBuffer;
    
    ofFile file;
    ofSaveImage(backgroundImage.getPixels(), photoBuffer);
    
    file.open(ofxiPhoneGetDocumentsDirectory() + "photo.png", ofFile::WriteOnly);
    file << photoBuffer;
    file.close();
    
    [vvc setCapturedBackgroundWith:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%s%@",ofxiPhoneGetDocumentsDirectory().c_str(),@"photo.png"]]];
    isBackgroundCaptured = true;
}

//--------------------------------------------------------------
void ofApp::removeBackground(){
    
    isBackgroundCaptured = false;
}
//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){
    
}
//--------------------------------------------------------------
UIImage* ofApp::UIImageFromOFImage( ofImage & img ){
    int width = img.getWidth();
    int height =img.getHeight();
    
    int nrOfColorComponents = 1;
    
    if (img.getImageType() == OF_IMAGE_GRAYSCALE) nrOfColorComponents = 1;
    else if (img.getImageType() == OF_IMAGE_COLOR) nrOfColorComponents = 3;
    else if (img.getImageType() == OF_IMAGE_COLOR_ALPHA) nrOfColorComponents = 4;
    
    int bitsPerColorComponent = 8;
    int rawImageDataLength = width * height * nrOfColorComponents;
    BOOL interpolateAndSmoothPixels = NO;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGDataProviderRef dataProviderRef;
    CGColorSpaceRef colorSpaceRef;
    CGImageRef imageRef;
    ofxCvColorImage bgImageTmp;
    //bgImageTmp.setFromPixels(img.getPixels().getData(),width,height);
    
    GLubyte *rawImageDataBuffer =  (unsigned char*)(img.getPixels().getData());
    dataProviderRef = CGDataProviderCreateWithData(NULL,  rawImageDataBuffer/*&img.getPixels()*rawImageDataBuffer*/, rawImageDataLength, nil);
    colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    imageRef = CGImageCreate(width, height, bitsPerColorComponent, bitsPerColorComponent * nrOfColorComponents, width * nrOfColorComponents, colorSpaceRef, bitmapInfo, dataProviderRef, NULL, interpolateAndSmoothPixels, renderingIntent);
    UIImage * uimg = [UIImage imageWithCGImage:imageRef];
    return uimg;
    
}

//--------------------------------------------------------------
UIImage* ofApp::UIImageFromOFImage(ofxCvGrayscaleImage img ){
    int width = img.getWidth();
    int height =img.getHeight();
    
    int nrOfColorComponents = 1;
    
    //    if (img.getImageType() == OF_IMAGE_GRAYSCALE) nrOfColorComponents = 1;
    //    else if (img.getImageType() == OF_IMAGE_COLOR) nrOfColorComponents = 3;
    //    else if (img.getImageType() == OF_IMAGE_COLOR_ALPHA) nrOfColorComponents = 4;
    
    int bitsPerColorComponent = 8;
    int rawImageDataLength = width * height * nrOfColorComponents;
    BOOL interpolateAndSmoothPixels = NO;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGDataProviderRef dataProviderRef;
    CGColorSpaceRef colorSpaceRef;
    CGImageRef imageRef;
    //ofxCvColorImage bgImageTmp;
    //bgImageTmp.setFromPixels(img.getPixels());
    
    GLubyte *rawImageDataBuffer =  img.getPixels().getData();
    dataProviderRef = CGDataProviderCreateWithData(NULL,  rawImageDataBuffer/*&img.getPixels()*rawImageDataBuffer*/, rawImageDataLength, nil);
    colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    imageRef = CGImageCreate(width, height, bitsPerColorComponent, bitsPerColorComponent * nrOfColorComponents, width * nrOfColorComponents, colorSpaceRef, bitmapInfo, dataProviderRef, NULL, interpolateAndSmoothPixels, renderingIntent);
    UIImage * uimg = [UIImage imageWithCGImage:imageRef];
    return uimg;
    
}
void ofApp::setFaceDetect(bool faceDetect){
    if(faceDetect)
    {
        isHaarActive = true;
    }
    else
    {
        isHaarActive = false;
    }
}
UIImage* ofApp::convertBitmapRGBA8ToUIImage(unsigned char * bufferData,float wtmp,float htmp) {
    unsigned char newData[(int)(wtmp*htmp*4)];
    int counter = 0;
    for(int i=0;i<wtmp*htmp*3;i+=3)
    {
        newData[counter]=bufferData[i];
        counter++;
        newData[counter]=bufferData[i+1];
        counter++;
        newData[counter]=bufferData[i+2];
        counter++;
        newData[counter]=255;
    }
    for(int i = 0; i<htmp*wtmp*4;i++)
    {
        printf("[%d ",bufferData[(int)(i)]);
    }
    /*    for(int i = 0;i<htmp;i++)
     {
     for(int k = 0; k<wtmp*3;k++)
     {
     printf("[%d ",bufferData[(int)(i*wtmp+k)]);
     printf("%d ",bufferData[(int)(i*wtmp+k+1)]);
     printf("%d ]",bufferData[(int)(i*wtmp+k+2)]);
     
     }
     printf("\n\n");
     }*/
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(
                                                              NULL,
                                                              newData,
                                                              htmp * wtmp * 4,
                                                              NULL);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGImageRef imageRef = CGImageCreate(wtmp,
                                        htmp,
                                        8,//bits per channel
                                        3 * 8,//bits per pixel
                                        wtmp*4,//bytes Per Row
                                        CGColorSpaceCreateDeviceRGB(),
                                        kCGImageAlphaNoneSkipLast,//kCGImageAlphaPremultipliedLast//kCGImageAlphaPremultipliedFirst
                                        provider,
                                        NULL,
                                        NO,
                                        renderingIntent);
    
    UIImage *uiImage = [UIImage imageWithCGImage:imageRef];
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    return uiImage;
    /*
     unsigned char newData[(int)(wtmp*htmp*4)];
     int counter = 0;
     for(int i=0;i<wtmp*htmp*3;i+=3)
     {
     newData[counter]=bufferData[i];
     counter++;
     newData[counter]=bufferData[i+1];
     counter++;
     newData[counter]=bufferData[i+2];
     counter++;
     newData[counter]=255;
     }
     
     for(int i = 0;i<htmp;i++)
     {
     for(int k = 0; k<wtmp*3;k++)
     {
     printf("[%d ",bufferData[(int)(i*wtmp+k)]);
     printf("%d ",bufferData[(int)(i*wtmp+k+1)]);
     printf("%d ]",bufferData[(int)(i*wtmp+k+2)]);
     
     }
     printf("\n\n");
     }
     
     int numOfChannels = 4;
     size_t bufferLength = wtmp * htmp * numOfChannels;
     CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, &newData, bufferLength, NULL);
     size_t bitsPerComponent = 8;
     size_t bitsPerPixel = 32;
     size_t bytesPerRow = numOfChannels * wtmp;
     
     CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
     if(colorSpaceRef == NULL) {
     NSLog(@"Error allocating color space");
     CGDataProviderRelease(provider);
     return nil;
     }
     
     CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
     CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
     
     CGImageRef iref = CGImageCreate(wtmp,
     htmp,
     bitsPerComponent,
     bitsPerPixel,
     bytesPerRow,
     colorSpaceRef,
     bitmapInfo,
     provider,   // data provider
     NULL,       // decode
     YES,            // should interpolate
     renderingIntent);
     
     uint32_t* pixels = (uint32_t*)malloc(bufferLength);
     
     if(pixels == NULL) {
     NSLog(@"Error: Memory not allocated for bitmap");
     CGDataProviderRelease(provider);
     CGColorSpaceRelease(colorSpaceRef);
     CGImageRelease(iref);
     return nil;
     }
     
     CGContextRef context = CGBitmapContextCreate(pixels,
     wtmp,
     htmp,
     bitsPerComponent,
     bytesPerRow,
     colorSpaceRef,
     bitmapInfo);
     
     if(context == NULL) {
     NSLog(@"Error context not created");
     free(pixels);
     return nil;
     }
     
     UIImage *image = nil;
     
     if(context) {
     
     CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, wtmp, htmp), iref);
     CGImageRef imageRef = CGBitmapContextCreateImage(context);
     //    Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
     if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
     // float scale = 1.0;//[[UIScreen mainScreen] scale];
     // image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
     } else {
     image = [UIImage imageWithCGImage:imageRef];
     }
     image = [UIImage imageWithCGImage:imageRef];
     
     CGImageRelease(imageRef);
     CGContextRelease(context);
     }
     
     CGColorSpaceRelease(colorSpaceRef);
     CGImageRelease(iref);
     CGDataProviderRelease(provider);
     
     if(pixels) {
     free(pixels);
     }
     return image;*/
}
