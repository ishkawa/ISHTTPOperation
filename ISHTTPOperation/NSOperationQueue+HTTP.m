#import "NSOperationQueue+HTTP.h"

@implementation NSOperationQueue (HTTP)

+ (NSOperationQueue *)defaultHTTPQueue
{
    static NSOperationQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
    });
    
    return queue;
}

@end
