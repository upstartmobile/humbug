#import "BUGDemoViewController.h"
#import "BUGWackerViewController.h"

@interface BUGDemoViewController ()

@end

@implementation BUGDemoViewController

- (IBAction)didTapShowDebugView:(id)sender {
    [BUGWackerViewController createSharedInstanceWithLogFileData:nil trackerAPIToken:nil trackerProjectID:nil];
    [BUGWackerViewController showHideDebugWindow];
}

@end
