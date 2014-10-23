#import "BUGDemoViewController.h"

#ifdef DEBUG
#import "BUGViewController.h"
#endif

@interface BUGDemoViewController ()

@end

@implementation BUGDemoViewController

- (IBAction)didTapShowDebugView:(id)sender {
    
#ifdef DEBUG
    [BUGViewController showHideDebugWindow];
#endif
    
}

@end
