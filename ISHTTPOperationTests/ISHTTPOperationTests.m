#import "ISHTTPOperation.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

static NSString *const ISHTTPOperationTestsURL = @"http://date.jsontest.com";

#import <SenTestingKit/SenTestingKit.h>

@interface ISHTTPOperationTests : SenTestCase {
    NSURLRequest *request;
    NSError *connectionError;
    NSData *responseData;
    BOOL waiting;
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
    
    waiting = NO;
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

- (void)startWaiting
{
    waiting = YES;
    
    do {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    } while (waiting);
}

- (void)stopWaiting
{
    waiting = NO;
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
    __weak ISHTTPOperation *woperation;
    
    @autoreleasepool {
        ISHTTPOperation *operation = [[ISHTTPOperation alloc] initWithRequest:request handler:nil];
        woperation = operation;
        [operation cancel];
        [NSThread sleepForTimeInterval:.1];
    }
    
    STAssertNil(woperation, nil);
}

- (void)testDeallocOnCancelAfterStart
{
    __weak ISHTTPOperation *woperation;
    
    @autoreleasepool {
        ISHTTPOperation *operation = [[ISHTTPOperation alloc] initWithRequest:request handler:nil];
        woperation = operation;
        [operation start];
        [operation cancel];
        [NSThread sleepForTimeInterval:.1];
    }
    
    STAssertNil(woperation, nil);
}

#pragma mark - control

- (void)testQueueing
{
    NSUInteger limit = 10;
    for (NSInteger i=0; i<limit; i++) {
        [ISHTTPOperation sendRequest:request handler:nil];
    }
    
    NSOperationQueue *queue = [NSOperationQueue defaultHTTPQueue];
    STAssertEquals([queue operationCount], limit, nil);
}

- (void)testCancel
{
    [ISHTTPOperation sendRequest:request handler:nil];
    
    NSOperationQueue *queue = [NSOperationQueue defaultHTTPQueue];
    [queue cancelAllOperations];
    
    [NSThread sleepForTimeInterval:.1];
    STAssertEquals([queue operationCount], 0U, nil);
}

@end
