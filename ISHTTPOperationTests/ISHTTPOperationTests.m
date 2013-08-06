#import "ISHTTPOperation.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

static NSString *const ISHTTPOperationTestsURL = @"http://date.jsontest.com";

#import <SenTestingKit/SenTestingKit.h>

@interface ISHTTPOperationTests : SenTestCase {
    NSURLRequest *request;
    BOOL finished;
}

@end

@implementation ISHTTPOperationTests

- (void)setUp
{
    [super setUp];
    
    NSURL *URL = [NSURL URLWithString:ISHTTPOperationTestsURL];
    request = [NSURLRequest requestWithURL:URL];
    finished = NO;
    
    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck) {
        NSData *data = [@"OK" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:200
                                        responseTime:0.1
                                             headers:nil];
    }];
}

- (void)tearDown
{
    do {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    } while (!finished);
    
    [OHHTTPStubs removeAllRequestHandlers];
    
    [super tearDown];
}

#pragma mark - tests

- (void)testCompletionHandlerIsCalledOnMainThread
{
    [ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
        STAssertTrue([NSThread isMainThread], nil);
        finished = YES;
    }];
}

- (void)testFailureHandlerIsCalledOnMainThread
{
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:-1003
                                     userInfo:nil];
    
    [OHHTTPStubs removeAllRequestHandlers];
    [OHHTTPStubs addRequestHandler:^OHHTTPStubsResponse *(NSURLRequest *request, BOOL onlyCheck) {
        return [OHHTTPStubsResponse responseWithError:error];
    }];
    
    [ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
        STAssertNotNil(error, nil);
        STAssertTrue([NSThread isMainThread], nil);
        finished = YES;
    }];
}

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
    finished = YES;
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
    finished = YES;
}

- (void)testQueueing
{
    NSUInteger limit = 10;
    for (NSInteger i=0; i<limit; i++) {
        [ISHTTPOperation sendRequest:request handler:nil];
    }
    
    NSOperationQueue *queue = [NSOperationQueue defaultHTTPQueue];
    STAssertEquals([queue operationCount], limit, nil);
    finished = YES;
}

- (void)testCancel
{
    [ISHTTPOperation sendRequest:request handler:nil];
    
    NSOperationQueue *queue = [NSOperationQueue defaultHTTPQueue];
    [queue cancelAllOperations];
    
    [NSThread sleepForTimeInterval:.1];
    STAssertEquals([queue operationCount], 0U, nil);
    finished = YES;
}

@end
