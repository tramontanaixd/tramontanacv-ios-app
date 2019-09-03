//
//  CommunicationViewController.h
//  libreTSPSWP
//
//  Created by Pierluigi Dalla Rosa on 8/1/17.
//
//

#import <UIKit/UIKit.h>
#import "tramontanaCVViewController.h"
#import "NetworkManager.h"
#import "SaveAndLoadTextField.h"
@interface CommunicationViewController : tramontanaCVViewController<UITextFieldDelegate>

-(IBAction)changePort:(id)sender;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray* cViews;

@property (strong, nonatomic) IBOutlet SaveAndLoadTextField * oscPortField;
@property (strong, nonatomic) IBOutlet SaveAndLoadTextField * oscAddressField;
@property (strong, nonatomic) IBOutlet SaveAndLoadTextField * oscIPAddressField;
@property (strong, nonatomic) IBOutlet SaveAndLoadTextField * oscFrequencyField;

@property (strong, nonatomic) IBOutlet SaveAndLoadTextField * websocketPortField;
@property (strong, nonatomic) IBOutlet SaveAndLoadTextField * websocketFrequencyField;

@property (strong, nonatomic) NSArray<SaveAndLoadTextField*>* arrayFields;

@property (strong, nonatomic) IBOutlet UILabel * ipLabel;

@property (strong,nonatomic) IBOutlet UILabel * wsServerInfo;
@property (strong,nonatomic) IBOutlet UILabel * wsServerInfoSecondary;

@property (strong,nonatomic) IBOutlet UILabel *sendingFacesLabel;
@property (strong,nonatomic) IBOutlet UISegmentedControl* sendingBBoxOrBlobs;

@property (assign) int indexOSCWebS;

-(void)collapseVC;
@property (assign)BOOL isKeyboardOut;
@property (assign)int  keyboardHeight;
-(void)dismissKeyboard;
-(void)updateWSServerStatus:(NSNotification*)notification;
-(IBAction)selectBBoxOrBlobs:(id)sender;

@end
