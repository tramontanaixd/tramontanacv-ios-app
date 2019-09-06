#pragma once

#include "ofxiOS.h"
#include "VisionViewController.h"
#include "CommunicationViewController.h"
#include "ofxOpenCv.h"
#include "NetworkManager.h"
#include "ofxCvHaarFinder.h"

#define BLOBS 0
#define BB   1

class ofApp : public ofxiOSApp {
    
public:
    void setup();
    void update();
    void draw();
    void exit();
    
    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);
    
    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
    
    //VIEW CONTROLLERS
    VisionViewController* vvc;
    CommunicationViewController* cvc;
    bool areVCsOpen = false;
    
    //SIZE
    int collapsedVC;
    int expandedVC;
    void openVC(int idn);
    void collapseVCs();
    
    //INTERFACE IMAGE
    int frameW, frameH;
    ofFbo fbo;
    
    //DEBUG IMAGE
   // ofImage debugImage;
    
    //COMPUTER VISION
    int threshold = 128;    //number 0-255
    
    int blur = 0;           //percentage
    int pixelAmount = 100;  //percentage
    
    int max_num_blobs = 15; //number
    int min_blob_size = 1;  //percentage
    int max_blob_size = 25000; //percentage
    
    
    ofVideoGrabber videoFeed;
    int cameraID = 0;
    void setCameraID(int newCameraID);
    
    ofImage workingImage;
    ofImage colorBackground;
    ofImage videoCurrentFrame;
    
    ofxCvColorImage rawImage;
    ofxCvColorImage backgroundImage;
    
    ofxCvGrayscaleImage bgGrayImage, grayImage, thresholdImage;
    ofxCvContourFinder  contourFinder;
    
    ofxCvHaarFinder finder;
    bool isHaarActive = false;
    void setFaceDetect(bool faceDetect);

    
    //INTERFACE
    void syncWithVisionTab(int tagIndex);
    int indexVizState = 0;
    int isBackgroundCaptured = false;
    bool isDilateActive = false;
    void captureBackground();
    void removeBackground();
    UIImage* UIImageFromOFImage( ofImage & img );
    
    UIImage* UIImageFromOFImage( ofxCvGrayscaleImage img );
    UIImage* convertBitmapRGBA8ToUIImage(unsigned char * bufferData,float wtmp,float htmp);
    
    int currentSizeSnapshotButton = 22;
    const int normalSizeSnapshotButton = 22;
    ofImage imgToSave;
    void saveSnapshot();
    
    //CAMERA CONTROLS
    void reFocus(float x, float y);
    void setLockAE(bool locked);
    
    //COMMUNICATION
    float timeSinceLastWSSent   = 0;
    float timeSinceLastOSCSent  = 0;
    float intervalSendWS        = 0.5;
    float intervalSendOSC       = 0.5;
    int   sendItem              = BB;
    void setSendItem(int switchItem);
    

};


