#import "NSOperationQueue+HTTP.h"
#import "ISHTTPOperationQueue.h"

@implementation NSOperationQueue (HTTP)

+ (NSOperationQueue *)defaultHTTPQueue
{
    return [ISHTTPOperationQueue defaultQueue];
}

@end
