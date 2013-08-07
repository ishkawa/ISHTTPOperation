#import "ISHTTPOperationQueue.h"

@implementation ISHTTPOperationQueue

+ (instancetype)defaultQueue
{
    static ISHTTPOperationQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[ISHTTPOperationQueue alloc] init];
    });
    
    return queue;
}

- (void)cancelOperationsUsingPredicate:(NSPredicate *)predicate
{
    NSArray *operations = [self.operations filteredArrayUsingPredicate:predicate];
    for (NSOperation *operation in operations) {
        [operation cancel];
    }
}

- (void)cancelOperationsWithHTTPMethod:(NSString *)method
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"request.HTTPMethod MATCHES %@", method];
    [self cancelOperationsUsingPredicate:predicate];
}

- (void)cancelOperationsWithHost:(NSString *)host
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"request.URL.host MATCHES %@", host];
    [self cancelOperationsUsingPredicate:predicate];
}

- (void)cancelOperationsWithPath:(NSString *)path
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"request.URL.path MATCHES %@", path];
    [self cancelOperationsUsingPredicate:predicate];
}

- (void)cancelOperationsWithURL:(NSURL *)URL
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"request.URL.absoluteString MATCHES %@", URL.absoluteString];
    [self cancelOperationsUsingPredicate:predicate];
}

@end
