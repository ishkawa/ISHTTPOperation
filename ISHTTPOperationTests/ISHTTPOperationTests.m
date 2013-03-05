#import "ISHTTPOperationTests.h"
#import "ISHTTPOperation.h"

static NSString *const ISTestURL = @"http://date.jsontest.com";

@implementation ISHTTPOperationTests

- (void)setUp
{
    [super setUp];
    
    self.isFinished = NO;
}

- (void)tearDown
{
    do {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    } while (!self.isFinished);
    
    [super tearDown];
}

#pragma mark - tests

- (void)testCompletionHandlerIsCalledOnMainThread
{
    NSURL *URL = [NSURL URLWithString:ISTestURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
        STAssertTrue([NSThread isMainThread], nil);
        self.isFinished = YES;
    }];
}

- (void)testFailureHandlerIsCalledOnMainThread
{
    NSURL *URL = [NSURL URLWithString:@"http://fsdafkjlfasda.org"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
        STAssertNotNil(error, nil);
        STAssertTrue([NSThread isMainThread], nil);
        self.isFinished = YES;
    }];
}

- (void)testDeallocOnCancelBeforeStart
{
    __weak ISHTTPOperation *woperation;
    
    @autoreleasepool {
        NSURL *URL = [NSURL URLWithString:ISTestURL];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        ISHTTPOperation *operation = [[ISHTTPOperation alloc] initWithRequest:request handler:nil];
        woperation = operation;
        [operation cancel];
        [NSThread sleepForTimeInterval:.1];
    }
    
    STAssertNil(woperation, nil);
    self.isFinished = YES;
}

- (void)testDeallocOnCancelAfterStart
{
    __weak ISHTTPOperation *woperation;
    
    @autoreleasepool {
        NSURL *URL = [NSURL URLWithString:ISTestURL];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        ISHTTPOperation *operation = [[ISHTTPOperation alloc] initWithRequest:request handler:nil];
        woperation = operation;
        [operation start];
        [operation cancel];
        [NSThread sleepForTimeInterval:.1];
    }
    
    STAssertNil(woperation, nil);
    self.isFinished = YES;
}

- (void)testQueueing
{
    NSUInteger limit = 10;
    NSURL *URL = [NSURL URLWithString:ISTestURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    for (NSInteger i=0; i<limit; i++) {
        [ISHTTPOperation sendRequest:request handler:nil];
    }
    
    NSOperationQueue *queue = [ISHTTPOperation sharedQueue];
    STAssertEquals([queue operationCount], limit, nil);
    self.isFinished = YES;
}

- (void)testCancel
{
    NSURL *URL = [NSURL URLWithString:ISTestURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [ISHTTPOperation sendRequest:request handler:nil];
    
    NSOperationQueue *queue = [ISHTTPOperation sharedQueue];
    [queue cancelAllOperations];
    
    [NSThread sleepForTimeInterval:.1];
    STAssertEquals([queue operationCount], 0U, nil);
    self.isFinished = YES;
}

@end
