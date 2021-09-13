//
//  DataUsageViewController.m
//  MesiboUIHelper

#import "DataUsageViewController.h"
#import "CommonAppUtils.h"
#import "MesiboMessengerSwift-Bridging-Header.h"
#import "MesiboMessenger-Swift.h"


@interface DataUsageViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *mAutoMedia;
@property (weak, nonatomic) IBOutlet UISwitch *mAutoDownloadSwitch;

@end

@implementation DataUsageViewController

{
    BOOL mAutoMediaFlag;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    mAutoMediaFlag =  [SampleAPIInstance getMediaAutoDownload]; 
    
    [_mAutoDownloadSwitch addTarget:self action:@selector(mediaAutoDownloadActionChanged:) forControlEvents:UIControlEventValueChanged];
    
    
    UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[CommonAppUtils imageNamed:@"ic_arrow_back_white.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(backButtonPressed)forControlEvents:UIControlEventTouchUpInside];
    [button setFrame:CGRectMake(0, 0, 24, 24)];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = barButton;
    
}


- (void) backButtonPressed {
    [self.navigationController popViewControllerAnimated:YES ];
    
}

+(BOOL) isAutoDownload {
    return YES;
}

- (IBAction)mediaAuto:(id)sender {
    mAutoMediaFlag = [(UISwitch *)sender isOn];
    [self.tableView reloadData];
    [SampleAPIInstance setMediaAutoDownload:mAutoMediaFlag];
}


- (void)mediaAutoDownloadActionChanged:(UISwitch *)sender {
    mAutoMediaFlag = [(UISwitch *)sender isOn];
    [self.tableView reloadData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 17;
}*/

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    
    //TBD, currently hiding all cell below by returning height 0
    if (indexPath.row >= 2) {
        return 0;
    }
    
    if (indexPath.row >= 2 && mAutoMediaFlag) {
        height = 44;
    }
    return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.row >= 1  && mAutoMediaFlag) {
        UISwitch *swith = (UISwitch*)[cell viewWithTag:100 ];
        cell.userInteractionEnabled = NO;
        if(nil != swith)
            swith.enabled = NO;
    } else {
        
        UISwitch *swith = (UISwitch*)[cell viewWithTag:100 ];
        cell.alpha = 1;
        cell.userInteractionEnabled = YES;
        if(nil != swith)
            swith.enabled = YES;
        
        if(indexPath.row == 0 && swith)
            [swith setOn:mAutoMediaFlag];
            
    }
    return cell;
}

@end
