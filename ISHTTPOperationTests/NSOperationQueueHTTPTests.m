#import <SenTestingKit/SenTestingKit.h>
#import "ISHTTPOperation.h"

@interface NSOperationQueueHTTPTests : SenTestCase

@end

@implementation NSOperationQueueHTTPTests

- (void)testDefaultHTTPQueue
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    STAssertEqualObjects([NSOperationQueue defaultHTTPQueue], [ISHTTPOperationQueue defaultQueue], nil);
#pragma clang diagnostic pop
}

@end
