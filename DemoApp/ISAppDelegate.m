#import "ISAppDelegate.h"
#import "ISViewController.h"
#import <ISHTTPOperation/ISHTTPOperation.h>

@implementation ISAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSOperationQueue *queue = [ISHTTPOperationQueue defaultQueue];
    [queue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    
    ISViewController *viewController = [[ISViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] init];
    navigationController.viewControllers = @[viewController];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSOperationQueue *queue = [ISHTTPOperationQueue defaultQueue];
    [queue removeObserver:self forKeyPath:@"operationCount"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"operationCount"]) {
        UIApplication *application = [UIApplication sharedApplication];
        NSOperationQueue *queue = [ISHTTPOperationQueue defaultQueue];
        application.networkActivityIndicatorVisible = [queue operationCount] ? YES : NO;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
