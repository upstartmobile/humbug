#import <Foundation/Foundation.h>

typedef void (^CompletionBlock)(BOOL success, NSError *error);

@interface BUGPivotalTrackerInterface : NSObject

- (instancetype)initWithAPIToken:(NSString *)token trackerProjectID:(NSString *)projectID;

- (void)createStoryWithStoryTitle:(NSString *)title storyDescription:(NSString *)description image:(NSData *)jpegImageData text:(NSData *)textData completion:(CompletionBlock)completion;

- (void)cancel;

@end
