#import "BUGViewController.h"

@implementation UIWindow (BUG)

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
        [BUGViewController showHideDebugWindow];
    }
}

@end
