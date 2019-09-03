//
//  tramontanaCVViewController
//  tramontanaCVViewController
//
//  Created by Pierluigi Dalla Rosa on 8/1/17.
//
//

#import <UIKit/UIKit.h>


@interface tramontanaCVViewController : UIViewController


@property(assign)int idn;
@property(strong,nonatomic)IBOutlet UIButton* collapsedOverlay;



-(IBAction)openVC:(id)sender;
-(void)collapseVC;



@end
