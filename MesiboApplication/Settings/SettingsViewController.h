//
//  SettingsViewController.h
//  MesiboUI
//
//  Created by Mesibo on 28/11/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LogoutDelegate <NSObject>   //define delegate protocol
- (void) logoutFromApplication: (UIViewController *) sender;  //define delegate method to be implemented within another class
@end //end protocol


@interface SettingsViewController : UITableViewController

@property (nonatomic, strong) id <LogoutDelegate> delegate;
@property (nonatomic, strong) id mParent;
@property (weak, nonatomic) IBOutlet UINavigationItem *mNavigationItem;

@end
