#import <XCTest/XCTest.h>
#import "ISHTTPOperation.h"

@interface NSOperationQueueHTTPTests : XCTestCase

@end

@implementation NSOperationQueueHTTPTests

- (void)testDefaultHTTPQueue
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    XCTAssertEqualObjects([NSOperationQueue defaultHTTPQueue], [ISHTTPOperationQueue defaultQueue]);
#pragma clang diagnostic pop
}

@end
