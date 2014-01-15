#import "ISHTTPOperation.h"
#import "SenTestCase+Async.h"
#import "OHHTTPStubs/OHHTTPStubs.h"
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

static NSString *const ISHTTPOperationTestsURL = @"http://date.jsontest.com";

@interface ISHTTPOperation ()

@property (nonatomic, strong) NSURLConnection   *connection;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableData     *data;
#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
#else
@property (nonatomic, assign) dispatch_semaphore_t semaphore;
#endif

@end

@interface ISHTTPOperationTests : XCTestCase {
    NSURLRequest *request;
    NSError *connectionError;
    NSData *responseData;
    BOOL shouldReturnErrorResponse;
}

@end

@implementation ISHTTPOperationTests

- (void)setUp
{
    [super setUp];
    
    NSURL *URL = [NSURL URLWithString:ISHTTPOperationTestsURL];
    request = [NSURLRequest requestWithURL:URL];
    responseData = [@"OK" dataUsingEncoding:NSUTF8StringEncoding];
    connectionError = [NSError errorWithDomain:NSURLErrorDomain
                                          code:-1003
                                      userInfo:nil];
    
    shouldReturnErrorResponse = NO;
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        OHHTTPStubsResponse *response;
        if (shouldReturnErrorResponse) {
            response = [OHHTTPStubsResponse responseWithError:connectionError];
        } else {
            response = [OHHTTPStubsResponse responseWithData:responseData
                                                  statusCode:200
                                                     headers:nil];
        }
        return response;
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
    ISHTTPOperation *operation = [[ISHTTPOperation alloc] init];
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
    ISHTTPOperation *operation = [[ISHTTPOperation alloc] init];
    XCTAssertTrue(operation.isConcurrent, @"operation is not concurrent.");
}

#pragma mark - serial tasks

- (void)testNormalConnection
{
    [ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
        XCTAssertEqualObjects(object, responseData, @"response object does not match.");
        XCTAssertTrue([NSThread isMainThread]);
        [self stopWaiting];
    }];
    
    [self startWaiting];
}

- (void)testErrorConnection
{
    shouldReturnErrorResponse = YES;
    
    [ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
        XCTAssertEqual(error.code, connectionError.code, @"error code does not match.");
        XCTAssertTrue([NSThread isMainThread]);
        [self stopWaiting];
    }];
    
    [self startWaiting];
}

#pragma mark - memory management

- (void)testDeallocOnCancelBeforeStart
{
    __block __weak ISHTTPOperation *woperation;
    
    @autoreleasepool {
        ISHTTPOperation *operation = [[ISHTTPOperation alloc] initWithRequest:request handler:nil];
        woperation = operation;
        [operation cancel];
    }
    
    [self waitUntilSatisfyingCondition:^BOOL{
        return woperation == nil;
    }];
}

- (void)testDeallocOnCancelAfterStart
{
    __block __weak ISHTTPOperation *woperation;
    
    @autoreleasepool {
        ISHTTPOperation *operation = [[ISHTTPOperation alloc] initWithRequest:request handler:nil];
        woperation = operation;
        [operation start];
        [operation cancel];
    }
    
    [self waitUntilSatisfyingCondition:^BOOL{
        return woperation == nil;
    }];
}

- (void)testCancelAsynchronously
{
    ISHTTPOperation *operation = [[ISHTTPOperation alloc] initWithRequest:request handler:nil];
    dispatch_semaphore_t semaphore = operation.semaphore;
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
    XCTAssertNil([operation performSelector:@selector(connection)], @"operation should not start connection.");
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
    [ISHTTPOperation sendRequest:request handler:nil];
    
    NSOperationQueue *queue = [ISHTTPOperationQueue defaultQueue];
    [queue cancelAllOperations];
    
    [self waitUntilSatisfyingCondition:^BOOL{
        return [queue operationCount] == 0U;
    }];
}

@end
