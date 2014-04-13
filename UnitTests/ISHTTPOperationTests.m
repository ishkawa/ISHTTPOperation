#import "ISHTTPOperation.h"
#import "SenTestCase+Async.h"
#import "OHHTTPStubs/OHHTTPStubs.h"
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const ISHTTPOperationTestsURL = @"http://date.jsontest.com";

@interface ISHTTPOperationTests : XCTestCase {
    NSData *dummyData;
    NSError *dummyError;
    NSURLRequest *request;
    ISHTTPOperation *operation;
}

@end

@implementation ISHTTPOperationTests

- (void)setUp
{
    [super setUp];
    
    
    NSURL *URL = [NSURL URLWithString:ISHTTPOperationTestsURL];
    request = [NSURLRequest requestWithURL:URL];
    operation = [[ISHTTPOperation alloc] initWithRequest:request handler:nil];
    
    dummyData = [@"OK" dataUsingEncoding:NSUTF8StringEncoding];
    dummyError = [NSError errorWithDomain:NSURLErrorDomain
                                code:NSURLErrorTimedOut
                            userInfo:nil];
    
    [self stubSuccessResponse];
}

- (void)stubSuccessResponse
{
    [OHHTTPStubs removeAllStubs];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *receivedRequest) {
        return [receivedRequest.URL isEqual:request.URL];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *receivedRequest) {
        return [OHHTTPStubsResponse responseWithData:dummyData
                                          statusCode:200
                                             headers:nil];
    }];
}

- (void)stubErrorResponse
{
    [OHHTTPStubs removeAllStubs];
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *receivedRequest) {
        return [receivedRequest.URL isEqual:request.URL];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *reqceivedRequest) {
        return [OHHTTPStubsResponse responseWithError:dummyError];
    }];
}

- (void)tearDown
{
    [OHHTTPStubs removeAllStubs];
    [super tearDown];
}

#pragma mark - init

- (void)testDesignatedInitializer
{
    id mock = [OCMockObject partialMockForObject:operation];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"
    [[mock expect] initWithRequest:[OCMArg any] handler:[OCMArg any]];
    [operation init];
#pragma clang diagnostic pop
    
    XCTAssertNoThrow([mock verify], @"designated initializer was not called.");
}

- (void)testConcurrencyType
{
    XCTAssertTrue(operation.isConcurrent, @"operation is not concurrent.");
}

#pragma mark - serial tasks

- (void)testNormalConnection
{
    [self stubSuccessResponse];
    
    [ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
        XCTAssertEqualObjects(object, dummyData, @"response object does not match.");
        XCTAssertTrue([NSThread isMainThread]);
        [self stopWaiting];
    }];
    
    [self startWaiting];
}

- (void)testErrorConnection
{
    [self stubErrorResponse];
    
    [ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
        XCTAssertEqual(error.code, dummyError.code, @"error code does not match.");
        XCTAssertTrue([NSThread isMainThread]);
        [self stopWaiting];
    }];
    
    [self startWaiting];
}

#pragma mark - memory management

- (void)testDeallocOnCancelBeforeStart
{
    __block __weak ISHTTPOperation *weakOperation;
    
    @autoreleasepool {
        weakOperation = operation;
        [operation cancel];
        operation = nil;
    }
    
    [self waitUntilSatisfyingCondition:^BOOL{
        return weakOperation == nil;
    }];
}

- (void)testDeallocOnCancelAfterStart
{
    __block __weak ISHTTPOperation *weakOperation;
    
    @autoreleasepool {
        weakOperation = operation;
        [operation start];
        [operation cancel];
        operation = nil;
    }
    
    [self waitUntilSatisfyingCondition:^BOOL{
        return weakOperation == nil;
    }];
}

- (void)testCancelAsynchronously
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    dispatch_semaphore_t semaphore = [operation performSelector:@selector(semaphore)];
#pragma clang diagnostic po
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        [operation start];
    }];
    
    [queue addOperationWithBlock:^{
        [operation cancel];
    }];
    
    dispatch_semaphore_signal(semaphore);
    
    [queue waitUntilAllOperationsAreFinished];
    
    XCTAssertTrue([operation isCancelled], @"operation was not cancelled.");
}

#pragma mark - control

- (void)testQueueing
{
    NSUInteger limit = 10;
    
    for (NSInteger i=0; i<limit; i++) {
        [ISHTTPOperation sendRequest:request handler:nil];
    }
    
    NSOperationQueue *queue = [ISHTTPOperationQueue defaultQueue];
    XCTAssertEqual([queue operationCount], limit);
}

- (void)testCancel
{
    [operation start];
    
    NSOperationQueue *queue = [ISHTTPOperationQueue defaultQueue];
    [queue cancelAllOperations];
    
    [self waitUntilSatisfyingCondition:^BOOL{
        return [queue operationCount] == 0U;
    }];
}

@end
