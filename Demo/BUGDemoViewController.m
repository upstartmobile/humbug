#import "BUGDemoViewController.h"
#import "BUGViewController.h"

@interface BUGDemoViewController ()

@end

@implementation BUGDemoViewController

- (IBAction)didTapShowDebugView:(id)sender {
    [BUGViewController createSharedInstanceWithLogFileData:nil trackerAPIToken:nil trackerProjectID:nil];
    [BUGViewController showHideDebugWindow];
}

@end
