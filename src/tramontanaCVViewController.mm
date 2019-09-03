//
//  tramontanaCVViewController
//  tramontanaCVViewController
//
//  Created by Pierluigi Dalla Rosa on 8/1/17.
//
//

#import "tramontanaCVViewController.h"
#import "ofApp.h"

@interface tramontanaCVViewController ()
{
    ofApp* of_pointer;
}
@end

@implementation tramontanaCVViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    of_pointer = (ofApp*)ofGetAppPtr();
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)openVC:(id)sender{
    of_pointer->openVC(_idn);
    [UIView animateWithDuration:0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [_collapsedOverlay setAlpha:0];
                     }
                     completion:^(BOOL finished){
                         // Wait one second and then fade in the view
                     }];
}
-(void)collapseVC{
    [UIView animateWithDuration:0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [_collapsedOverlay setAlpha:1];
                     }
                     completion:^(BOOL finished){
                         // Wait one second and then fade in the view
                     }];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"collapseVC" object:nil];
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
