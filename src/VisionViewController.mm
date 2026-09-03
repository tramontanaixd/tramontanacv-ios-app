//
//  VisionViewController.m
//  libreTSPSWP
//
//  Created by Pierluigi Dalla Rosa on 8/1/17.2
//
//

#import "VisionViewController.h"
#import "ofApp.h"

#define MARGIN_TOP 66
#define ICONSELECTOR_SIZE 49
#define ICONSEL_MARGIN 8
@interface VisionViewController ()
{
    ofApp* of_pointer;
}
@end

@implementation VisionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    of_pointer = (ofApp*)ofGetAppPtr();
    
    _selectedIndex = -1;
    
    //MAKE Vision Views transparent and remove them from superview.
    for(int i =0;i<[_vViews count];i++)
    {
        [[_vViews objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0]];
        
        [[_vViews objectAtIndex:i] setFrame:CGRectMake(0, MARGIN_TOP, (int) [[UIScreen mainScreen] bounds].size.width,(int) [[_vViews objectAtIndex:i] frame].size.height )];
        [[_vViews objectAtIndex:i] removeFromSuperview];
    }
    
    
    [self.view setAlpha:1.0];
    _isBackgroundSet = NO;
    
    //CONNECT DETECT SWITCH
    if (@available(iOS 11.0, *)) {
        //ENABLE FACE DETECTION
        [_detectFacesSwitch addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
    } else {
        //DISABLE FACE DETECTION
        [_detectFacesSwitch setEnabled:FALSE];
    }
    
    
    
    //Control Received from WS
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(controlMessageReceived:) name:@"controlMsgReceived" object:nil];
}
- (IBAction)openVC:(id)sender{
    [super openVC:sender];
    [self.view setAlpha:0.95];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(_selectedIndex == -1)
        {
            [self changeView:nil];
        }
    });
   // NSLog(@"width frame %f",((UIView*)[_vViews objectAtIndex:_selectedIndex]).frame.size.width );
}
- (IBAction)collapseVC{
    [super collapseVC];
    [self.view setAlpha:1.0];
}
-(IBAction)setIsDilate:(id)sender{
    if([((UISwitch*)sender) isOn])
    {
        of_pointer->isDilateActive = true;
    }
    else
    {
        of_pointer->isDilateActive = false;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)changeView:(id)sender{
    
    if(sender == nil)
    {
        _selectedIndex = 0;
    }
    else
    {
        [[_vViews objectAtIndex:_selectedIndex] removeFromSuperview];
        _selectedIndex = ((UIView*)sender).tag;
    }
    of_pointer->syncWithVisionTab(_selectedIndex);
    [self.view addSubview:[_vViews objectAtIndex:_selectedIndex]];
     NSLog(@"width frame %f",((UIView*)[_vViews objectAtIndex:_selectedIndex]).frame.size.width );
}
-(void)goBackToFirstScreen{
    [[_vViews objectAtIndex:_selectedIndex] removeFromSuperview];
    _selectedIndex = 0;
    of_pointer->syncWithVisionTab(_selectedIndex);
    [self.view addSubview:[_vViews objectAtIndex:_selectedIndex]];
}
-(IBAction)changeCamera:(id)sender{
    printf("%d\n",(int)_frontBackCameraControl.selectedSegmentIndex);
    of_pointer->setCameraID((int)_frontBackCameraControl.selectedSegmentIndex);
}
-(IBAction)captureBackground:(id)sender{
    if(!_isBackgroundSet)
    {
        [(UIButton*)sender setTitle:@"Remove Background" forState:UIControlStateNormal];
        _isBackgroundSet=YES;
        [_bgShow setAlpha:1.0];
        of_pointer->captureBackground();
    }
    else
    {
        [(UIButton*)sender setTitle:@"Capture Background" forState:UIControlStateNormal];
        _isBackgroundSet=NO;
        [_bgShow setAlpha:0.3];
        of_pointer->removeBackground();
    }
}
-(void)setCapturedBackgroundWith:(UIImage*)bgNewImage//UIImageFromOFImage
{
    
    
    
    [_bgShow setImage:bgNewImage];
    
    int wTmp = bgNewImage.size.width;
    int hTmp = bgNewImage.size.height;
    
//    if(wTmp>ofGetWidth())
//    {
        if(hTmp>(_bgShow.frame.size.height))
        {
            hTmp = (_bgShow.frame.size.height);
            wTmp = wTmp*hTmp/bgNewImage.size.height;
        }
        else
        {
            wTmp = ofGetWidth();
            hTmp = wTmp*hTmp/bgNewImage.size.width;
        }
//    }
    [_bgShow setFrame:CGRectMake((ofGetWidth()/2)-(wTmp/2), _bgShow.frame.origin.y, wTmp, hTmp)];
    [_bgShow setNeedsDisplay];
}

-(IBAction)valueChanged:(id)sender{
    int indexSlider = ((UISlider*)sender).tag;
    
    switch (indexSlider) {
        case 1:
            //blur
            of_pointer->blur            = (int) ((UISlider*)sender).value;
            [_blurLabel setText:[NSString stringWithFormat:@"%d",of_pointer->blur]];
            break;
        case 2:
            //threshold
            of_pointer->threshold       = (int) ((UISlider*)sender).value;
            [_thresholdLabel setText:[NSString stringWithFormat:@"%d",of_pointer->threshold]];
            break;
        case 3:
            //min blob size
            of_pointer->min_blob_size   = (int) ((UISlider*)sender).value;
            [_minBlobSizeLabel setText:[NSString stringWithFormat:@"%d",of_pointer->min_blob_size]];
            break;
        case 4:
            //max blob size
            of_pointer->max_blob_size   = (int) ((UISlider*)sender).value;
            [_maxBlobSizeLabel setText:[NSString stringWithFormat:@"%d",of_pointer->max_blob_size]];
            break;
        case 5:
            //max blob num
            of_pointer->max_num_blobs   = (int) ((UISlider*)sender).value;
            [_maxNumBlobsLabel setText:[NSString stringWithFormat:@"%d",of_pointer->max_num_blobs]];
            break;
        case 6:
            //pixelate
            of_pointer->pixelAmount     = (int) ((UISlider*)sender).value;
            [_pixelateLabel setText:[NSString stringWithFormat:@"%d",of_pointer->pixelAmount]];
            break;
            
        default:
            break;
    }
}
-(IBAction)changeAELock:(id)sender{
    if([sender isOn])
    {
        of_pointer->setLockAE(true);
    }
    else
    {
        of_pointer->setLockAE(false);
    }
}
- (void)changeSwitch:(id)sender{
    if([sender isOn]){
        [self morphUIFaceDetect];
    } else{
        [self morphUIBlobDetect];
    }
}
-(void)morphUIFaceDetect{
    of_pointer->setFaceDetect(true);
    int counterTmp = 0;
    //SEND NOTIFACTION
    [[NSNotificationCenter defaultCenter] postNotificationName:@"detectFacesEnabled" object:nil];
    //MAKE SELECTORS DISAPPEAR
    for(int i=[_vSelectors count]-2;i>0;i--)
    {
        [[_vSelectors objectAtIndex:i] setUserInteractionEnabled:NO];
        [UIView animateWithDuration:0.2
                              delay: 0.1*counterTmp
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [[_vSelectors objectAtIndex:i] setAlpha:0.0f];
                         }
                         completion:^(BOOL finished){
                             // Wait one second and then fade in the view
                         }];
        counterTmp++;
    }
    //ANIMATE SELECTOR CONTAINER
    [UIView animateWithDuration:0.6
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         int newSize = 2*ICONSEL_MARGIN+ICONSELECTOR_SIZE;
                         NSLog(@"%d",newSize);
                         [_vContainer setFrame:CGRectMake( ([UIScreen mainScreen].bounds.size.width/2)- (newSize/2),_vContainer.frame.origin.y   ,newSize,_vContainer.frame.size.height )];
                         [_blurSlider setAlpha:0.3];
                         [_aeLockSwitch setAlpha:0.3];
                     }
     
                     completion:^(BOOL finished){
                         // Wait one second and then fade in the view
                     }];
    //DISABLE BLUR
    [_blurSlider setUserInteractionEnabled:NO];
    of_pointer->blur = 0.0;
    
    //DISABLE UI ELEMENTS
    [_aeLockSwitch setUserInteractionEnabled:NO];
    [_aeLockSwitch setOn:NO animated:YES];
    of_pointer->setLockAE(false);
    
}
-(void)morphUIBlobDetect{
    of_pointer->setFaceDetect(false);
    //SEND NOTIFACTION
    [[NSNotificationCenter defaultCenter] postNotificationName:@"detectFacesDisabled" object:nil];
    for(int i=1;i<[_vSelectors count]-1;i++)
    {
        [[_vSelectors objectAtIndex:i] setUserInteractionEnabled:YES];
        [UIView animateWithDuration:0.2
                              delay: 0.1*i
                            options: UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [[_vSelectors objectAtIndex:i] setAlpha:1.0f];
                         }
                         completion:^(BOOL finished){
                             // Wait one second and then fade in the view
                         }];
    }
    [UIView animateWithDuration:0.6
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         int newSize =( ([_vSelectors count]-1) *(ICONSEL_MARGIN+ICONSELECTOR_SIZE))+ICONSEL_MARGIN;
                         
                         [_vContainer setFrame:CGRectMake( ([UIScreen mainScreen].bounds.size.width/2)- (newSize/2),_vContainer.frame.origin.y   ,newSize ,_vContainer.frame.size.height )];
                         [_blurSlider setAlpha:1.0];
                         [_aeLockSwitch setAlpha:1.0];
                     }
     
                     completion:^(BOOL finished){
                         // Wait one second and then fade in the view
                         
                     }];
    //ENABLE BLUR
    [_blurSlider setUserInteractionEnabled:YES];
    of_pointer->blur            = (int) _blurSlider.value;
    
    //ENABLE UI ELEMENTS
    [_aeLockSwitch setUserInteractionEnabled:YES];
    
}
-(void) controlMessageReceived:(NSNotification*)notification{
    NSDictionary* dict = notification.userInfo;
    
    if([[dict objectForKey:@"m"] isEqualToString:@"lockAE"])
    {
        of_pointer->setLockAE(true);
        [_aeLockSwitch setOn:YES];
    }
    else if([[dict objectForKey:@"m"] isEqualToString:@"unlockAE"])
    {
        of_pointer->setLockAE(false);
        [_aeLockSwitch setOn:NO];
    }
    else if([[dict objectForKey:@"m"] isEqualToString:@"captureBg"])
    {
        [self captureBackground:nil];
    }
    else if([[dict objectForKey:@"m"] isEqualToString:@"blur"])
    {
        float val = [[dict objectForKey:@"v"] floatValue];
        [_blurSlider setValue: val];
        of_pointer->blur = val;
    }
    else if([[dict objectForKey:@"m"] isEqualToString:@"threshold"])
    {
        int val = [[dict objectForKey:@"v"] intValue];
        [_thresholdSlider setValue: val];
        [_thresholdLabel setText:[NSString stringWithFormat:@"%d",val]];
        of_pointer->threshold = val;
    }
    else if([[dict objectForKey:@"m"] isEqualToString:@"blobs"])
    {
        of_pointer->min_blob_size   = [[dict objectForKey:@"min"] intValue];
        [_minBlobSizeLabel setText:[NSString stringWithFormat:@"%d",of_pointer->min_blob_size]];
        [_minBlobSizeSlider setValue:of_pointer->min_blob_size];
        
        of_pointer->max_blob_size = [[dict objectForKey:@"max"] intValue];
        [_maxBlobSizeLabel setText:[NSString stringWithFormat:@"%d",of_pointer->max_blob_size]];
        [_maxBlobSizeSlider setValue:of_pointer->max_blob_size];
        
        of_pointer->max_num_blobs =[[dict objectForKey:@"num"] intValue];
        [_maxNumBlobsLabel setText:[NSString stringWithFormat:@"%d",of_pointer->max_num_blobs]];
        [_maxNumBlobsSlider setValue:of_pointer->max_num_blobs];
    }
    else if([[dict objectForKey:@"m"] isEqualToString:@"save"])
    {
        of_pointer->saveSnapshot();
    }
    else if([[dict objectForKey:@"m"] isEqualToString:@"cam"])
    {
        int camId = [[dict objectForKey:@"id"] intValue];
        if(camId<2 && camId>=0)
        {
            of_pointer->setCameraID(camId);
            _frontBackCameraControl.selectedSegmentIndex = camId;
        }
    }
    else if([[dict objectForKey:@"m"] isEqualToString:@"mCV"])
    {
        [self morphUIBlobDetect];
        [_detectFacesSwitch setOn:NO];
        [self goBackToFirstScreen];
    }
    else if([[dict objectForKey:@"m"] isEqualToString:@"mFac"])
    {
        [self morphUIFaceDetect];
        [_detectFacesSwitch setOn:YES];
        [self goBackToFirstScreen];
    }

}

@end
