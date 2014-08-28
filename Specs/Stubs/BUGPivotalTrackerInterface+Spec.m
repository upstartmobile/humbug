#import "BUGPivotalTrackerInterface+Spec.h"
#import "JRSwizzle.h"

@implementation BUGPivotalTrackerInterface (Spec)

static BOOL opaqueTestMode__;
static CompletionBlock createStoryCompletion__;

+ (void)afterEach {
    [self endOpaqueTestMode];
}

+ (void)beginOpaqueTestMode {
    if (opaqueTestMode__) { return; }
    [self toggleOpaqueTestMode];
    opaqueTestMode__ = YES;
}

+ (void)endOpaqueTestMode {
    if (!opaqueTestMode__) { return; }
    [self toggleOpaqueTestMode];
    opaqueTestMode__ = NO;
}

+ (void)toggleOpaqueTestMode {
    NSError *error;
    
    [[self class] jr_swizzleMethod:@selector(createStoryWithStoryTitle:storyDescription:image:text:completion:) withMethod:@selector(replacementCreateStoryWithStoryTitle:storyDescription:image:text:completion:) error:&error];
    if (error) {
        [NSException exceptionWithName:@"SwizzleError" reason:[NSString stringWithFormat:@"Error swizzling: %@", error.description] userInfo:nil];
    }
}

- (void)replacementCreateStoryWithStoryTitle:(NSString *)title storyDescription:(NSString *)description image:(NSData *)jpegImageData text:(NSData *)textData completion:(CompletionBlock)completion {
    createStoryCompletion__ = completion;
}

+ (void)completeCreateStoryWithSuccess {
    if (createStoryCompletion__) {
        createStoryCompletion__(YES, nil);
    }
}

+ (void)completeCreateStoryWithError:(NSError *)error {
    if (createStoryCompletion__) {
        createStoryCompletion__(NO, error);
    }
}

@end
