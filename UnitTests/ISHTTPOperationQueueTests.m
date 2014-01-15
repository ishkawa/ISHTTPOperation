#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ISHTTPOperation.h"

static NSString *const ISHTTPOperationTestsURL        = @"http://www.example1.com/1";
static NSString *const ISHTTPOperationAnotherTestsURL = @"http://www.example2.com/2";

@interface ISHTTPOperationQueueTests : XCTestCase {
    ISHTTPOperationQueue *queue;
    ISHTTPOperation *operation;
    ISHTTPOperation *anotherOperation;
    id mock;
    id anotherMock;
}

@end

@implementation ISHTTPOperationQueueTests

- (void)setUp
{
    [super setUp];
    
    queue = [[ISHTTPOperationQueue alloc] init];
    
    NSURL *URL = [NSURL URLWithString:ISHTTPOperationTestsURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"GET";
    operation = [[ISHTTPOperation alloc] initWithRequest:request handler:nil];
    mock = [OCMockObject partialMockForObject:operation];
    [[mock expect] cancel];
    
    NSURL *anotherURL = [NSURL URLWithString:ISHTTPOperationAnotherTestsURL];
    NSMutableURLRequest *anotherRequest = [NSMutableURLRequest requestWithURL:anotherURL];
    request.HTTPMethod = @"POST";
    anotherOperation = [[ISHTTPOperation alloc] initWithRequest:anotherRequest handler:nil];
    anotherMock = [OCMockObject partialMockForObject:anotherOperation];
    [[anotherMock expect] cancel];
    
    [queue addOperation:operation];
    [queue addOperation:anotherOperation];
}

- (void)tearDown
{
    queue = nil;
    operation = nil;
    anotherOperation = nil;
    mock = nil;
    anotherMock = nil;
    
    [super tearDown];
}

- (void)testDefaultQueue
{
    XCTAssertEqualObjects([ISHTTPOperationQueue defaultQueue], [ISHTTPOperationQueue defaultQueue]);
}

- (void)testCancelOperationsWithHTTPMethod
{
    [queue cancelOperationsWithHTTPMethod:operation.request.HTTPMethod];
    
    XCTAssertNoThrow([mock verify]);
    XCTAssertThrows([anotherMock verify]);
}

- (void)testCancelOperationsWithHost
{
    [queue cancelOperationsWithHost:operation.request.URL.host];
    
    XCTAssertNoThrow([mock verify]);
    XCTAssertThrows([anotherMock verify]);
}

- (void)testCancelOperationsWithPath
{
    [queue cancelOperationsWithPath:operation.request.URL.path];
    
    XCTAssertNoThrow([mock verify]);
    XCTAssertThrows([anotherMock verify]);
}

- (void)testCancelOperationsWithURL
{
    [queue cancelOperationsWithURL:operation.request.URL];
    
    XCTAssertNoThrow([mock verify]);
    XCTAssertThrows([anotherMock verify]);
}

@end
