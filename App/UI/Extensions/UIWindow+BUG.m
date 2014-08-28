#import "BUGWackerViewController.h"

@implementation UIWindow (BUG)

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
        [BUGWackerViewController showHideDebugWindow];
    }
}

@end
