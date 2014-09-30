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

+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL))completion {
    [self animateWithDuration:duration animations:animations completion:completion];
}

@end
