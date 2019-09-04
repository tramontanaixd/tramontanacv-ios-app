//
//  VisionViewController.h
//  libreTSPSWP
//
//  Created by Pierluigi Dalla Rosa on 8/1/17.
//
//

#import <UIKit/UIKit.h>
#import "tramontanaCVViewController.h"

@interface VisionViewController : tramontanaCVViewController


@property (strong,nonatomic) IBOutletCollection(UIView) NSArray* vViews;
@property (strong,nonatomic) IBOutletCollection(UIButton) NSArray* vSelectors;
@property (strong,nonatomic) IBOutlet UIView* vContainer;

@property (assign) int selectedIndex;


//CONTROLS
//original/background
@property (strong, nonatomic) UIImage* bg;
@property (strong,nonatomic)IBOutlet UIImageView* bgShow;
@property (assign)BOOL isBackgroundSet;
-(IBAction)captureBackground:(id)sender;
-(IBAction)setIsDilate:(id)sender;
-(void)setCapturedBackgroundWith:(UIImage*)bgNewImage;
@property (strong,nonatomic) IBOutlet UISwitch* aeLockSwitch;
-(IBAction)changeAELock:(id)sender;

//sliders
-(IBAction)valueChanged:(id)sender;

//detectFace switch
-(void)changeSwitch:(id)sender;
-(void)morphUIFaceDetect;
-(void)morphUIBlobDetect;

//bw/blur
@property(strong,nonatomic)IBOutlet UISwitch* detectFacesSwitch;
@property(strong,nonatomic)IBOutlet UISlider* blurSlider;
@property(strong,nonatomic)IBOutlet UILabel*  blurLabel;


//threshold
@property(strong,nonatomic)IBOutlet UISlider* thresholdSlider;
@property(strong,nonatomic)IBOutlet UILabel*  thresholdLabel;

//cv
@property(strong,nonatomic)IBOutlet UISlider* minBlobSizeSlider;
@property(strong,nonatomic)IBOutlet UILabel*  minBlobSizeLabel;

@property(strong,nonatomic)IBOutlet UISlider* maxBlobSizeSlider;
@property(strong,nonatomic)IBOutlet UILabel*  maxBlobSizeLabel;

@property(strong,nonatomic)IBOutlet UISlider* maxNumBlobsSlider;
@property(strong,nonatomic)IBOutlet UILabel*  maxNumBlobsLabel;

//pixelate
@property(strong,nonatomic)IBOutlet UISlider* pixelateSlider;
@property(strong,nonatomic)IBOutlet UILabel*  pixelateLabel;

//control received via WS
-(void) controlMessageReceived:(NSNotification*)notification;



@end
