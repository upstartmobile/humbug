#import "UIView+Spec.h"

@implementation UIView (Spec)

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL))completion {
    if (animations) {
        animations();
    }
    if (completion) {
        completion(YES);
    }
}

@end
