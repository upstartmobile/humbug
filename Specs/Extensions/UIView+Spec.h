#import <UIKit/UIKit.h>

@interface UIView (Spec)

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL))completion;

@end
