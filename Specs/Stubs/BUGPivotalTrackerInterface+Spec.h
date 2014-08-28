#import "BUGPivotalTrackerInterface.h"

@interface BUGPivotalTrackerInterface (Spec)

+ (void)beginOpaqueTestMode;
+ (void)endOpaqueTestMode;

+ (void)completeCreateStoryWithSuccess;
+ (void)completeCreateStoryWithError:(NSError *)error;

@end
