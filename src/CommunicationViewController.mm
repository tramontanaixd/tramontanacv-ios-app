//
//  CommunicationViewController.m
//  libreTSPSWP
//
//  Created by Pierluigi Dalla Rosa on 8/1/17.
//
//

#import "CommunicationViewController.h"
#import "NetworkManager.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "ofApp.h"

#define MARGIN_TOP 66

@interface CommunicationViewController ()

@end

@implementation CommunicationViewController
{
    ofApp* of_pointer_CVC;
}
@synthesize arrayFields;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    of_pointer_CVC = (ofApp*)ofGetAppPtr();
    
    //START NETWORK MANAGER
    //_nm = [[NetworkManager alloc] init];
    // Do any additional setup after loading the view from its nib.
    for(int i =0;i<[_cViews count];i++)
    {
        [[_cViews objectAtIndex:i] setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0]];
        [[_cViews objectAtIndex:i] setFrame:CGRectMake(0, MARGIN_TOP, (int)( [[UIScreen mainScreen] bounds].size.width),(int)( [[_cViews objectAtIndex:i] frame].size.height ))];
        
        [[_cViews objectAtIndex:i] removeFromSuperview];
    }
    
    
    _isKeyboardOut = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    _indexOSCWebS = 0;
    [self.view addSubview:_cViews[_indexOSCWebS]];
    [self updateLabelIP];
    
    arrayFields = [NSArray arrayWithObjects: _oscPortField,_oscAddressField,_oscIPAddressField,_oscFrequencyField,_websocketPortField,_websocketFrequencyField, nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateWSServerStatus:) name:@"wsServerUpdate" object:nil];
    
    
    //INIT WS LABELS
    [_wsServerInfoSecondary setText:@""];
    [_wsServerInfo setText:@""];
    
    [_websocketPortField setDelegate:self];
    [_websocketFrequencyField setDelegate:self];
    [self.view setAlpha:1.0];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectFacesEnabled) name:@"detectFacesEnabled" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(detectFacesDisabled) name:@"detectFacesDisabled" object:nil];
    [_sendingFacesLabel setEnabled:NO];
    [_sendingFacesLabel setAlpha:0.0];
}
-(void)detectFacesEnabled{
    [_sendingFacesLabel setEnabled:YES];
    [_sendingFacesLabel setAlpha:1.0];
    [_sendingBBoxOrBlobs setEnabled:NO];
    [_sendingBBoxOrBlobs setAlpha:0.0];
}
-(void)detectFacesDisabled{
    [_sendingFacesLabel setEnabled:NO];
    [_sendingFacesLabel setAlpha:0.0];
    [_sendingBBoxOrBlobs setEnabled:YES];
    [_sendingBBoxOrBlobs setAlpha:1.0];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)chooseView:(id)sender{
    UISegmentedControl *segTmp = sender;
    if(_indexOSCWebS != segTmp.selectedSegmentIndex)
    {
        [_cViews[_indexOSCWebS] removeFromSuperview];
        _indexOSCWebS = segTmp.selectedSegmentIndex;
        
        //[_cViews[_indexOSCWebS] setFrame:CGRectMake(0, [_cViews[_indexOSCWebS] bounds].origin.y, [UIScreen mainScreen].bounds.size.width, [_cViews[_indexOSCWebS] bounds].size.height)];
        [self.view addSubview:_cViews[_indexOSCWebS]];
        
    }
    
    
}


#pragma mark INTERFACE
-(IBAction)selectBBoxOrBlobs:(id)sender{
    
    if(((UISegmentedControl*)sender).selectedSegmentIndex==0){
        of_pointer_CVC->setSendItem(BB);
    }
    else if(((UISegmentedControl*)sender).selectedSegmentIndex==1){
        of_pointer_CVC->setSendItem(BLOBS);
    }
}
-(void)updateLabelIP{
    [_ipLabel setText:[self getIPAddress]];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self updateLabelIP];
    });
}
-(void)updateWSServerStatus:(NSNotification*)notification{
    [_wsServerInfoSecondary setText:[_wsServerInfo text]];
    [_wsServerInfo setText:[notification.userInfo valueForKey:@"m"]];
}
#pragma mark UTILS
// Get IP Address
- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}

-(IBAction)changePort:(id)sender{
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Title" message:@"Please enter someth" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    //[av textFieldAtIndex:0].delegate = self;
    [av show];
}
#pragma mark OVERRIDE

-(void)collapseVC{
    [super collapseVC];
    
    for(int i=0;i<[arrayFields count];i++)
    {
        [[arrayFields objectAtIndex:i] resignFirstResponder];
    }
    _isKeyboardOut = NO;
}
#pragma mark TEXTFIELD DELEGATE

-(void) keyboardWillShow:(NSNotification *)note{
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    
    // Need to translate the bounds to account for rotation.
    
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    _keyboardHeight= keyboardBounds.size.height;
    
    _isKeyboardOut = YES;
    
    [UIView animateWithDuration:0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         [self.view setFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-(self.view.bounds.size.height+_keyboardHeight),self.view.bounds.size.width,self.view.bounds.size.height)];
                     }
                     completion:^(BOOL finished){
                         // Wait one second and then fade in the view
                     }];
}

-(void)dismissKeyboard{
    for(int i=0;i<[arrayFields count];i++)
    {
        [[arrayFields objectAtIndex:i] resignFirstResponder];
    }
    _isKeyboardOut = NO;
    [UIView animateWithDuration:0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         [self.view setFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height-(self.view.bounds.size.height),self.view.bounds.size.width,self.view.bounds.size.height)];
                     }
                     completion:^(BOOL finished){
                         // Wait one second and then fade in the view
                     }];
    
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    [UIView animateWithDuration:0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         
                         //                         [self.view setFrame:CGRectMake(0, ofGetHeight()-(collabsedVC+expandedVC), ofGetWidth(), expandedVC)];
                         //                         [self.view setFrame:CGRectMake(0, ofGetHeight()-(collabsedVC), ofGetWidth(), collabsedVC)];
                     }
                     completion:^(BOOL finished){
                         // Wait one second and then fade in the view
                     }];
    return YES;
    
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    if(textField == _websocketPortField)
    {
        NSLog(@"end editing port");
        [[NetworkManager sharedManager] startWSServerWithPort:[textField.text intValue]];
    }
    else if(textField == _websocketFrequencyField)
    {
        NSLog(@"frequency port");
        of_pointer_CVC->intervalSendWS = 1/([textField.text intValue]);
    }
    return YES;
}
- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string{
    
    if(textField == _websocketPortField)
    {
        
    }
    else if(textField == _websocketFrequencyField)
    {
        
    }
    
    return YES;
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
