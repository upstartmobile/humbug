#import "BUGAppDelegate.h"
#import "BUGDemoViewController.h"

#ifdef DEBUG
#import "BUGViewController.h"
#endif

@implementation BUGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[BUGDemoViewController alloc] init];
    [self.window makeKeyAndVisible];
    
#ifdef DEBUG
    [BUGViewController createSharedInstanceWithLogFileData:nil trackerAPIToken:nil trackerProjectID:nil];
#endif
    
    return YES;
}

@end
