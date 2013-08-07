#import "ISHTTPOperation.h"
#import "SenTestCase+Async.h"
#import "OHHTTPStubs/OHHTTPStubs.h"

static NSString *const ISHTTPOperationTestsURL = @"http://date.jsontest.com";

#import <SenTestingKit/SenTestingKit.h>

@interface ISHTTPOperationTests : SenTestCase {
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
    
    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck) {
        OHHTTPStubsResponse *response;
        if (shouldReturnErrorResponse) {
            response = [OHHTTPStubsResponse responseWithError:connectionError];
        } else {
            response = [OHHTTPStubsResponse responseWithData:responseData
                                                  statusCode:200
                                                responseTime:0.1
                                                     headers:nil];
        }
        return response;
    }];
}

- (void)tearDown
{
    [OHHTTPStubs removeAllRequestHandlers];
    [super tearDown];
}

#pragma mark - serial tasks

- (void)testNormalConnection
{
    [ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
        STAssertEqualObjects(object, responseData, @"response object does not match.");
        STAssertTrue([NSThread isMainThread], nil);
        [self stopWaiting];
    }];
    
    [self startWaiting];
}

- (void)testErrorConnection
{
    shouldReturnErrorResponse = YES;
    
    [ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
        STAssertEquals(error.code, connectionError.code, @"error code does not match.");
        STAssertTrue([NSThread isMainThread], nil);
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

#pragma mark - control

- (void)testQueueing
{
    NSUInteger limit = 10;
    for (NSInteger i=0; i<limit; i++) {
        [ISHTTPOperation sendRequest:request handler:nil];
    }
    
    NSOperationQueue *queue = [ISHTTPOperationQueue defaultQueue];
    STAssertEquals([queue operationCount], limit, nil);
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
