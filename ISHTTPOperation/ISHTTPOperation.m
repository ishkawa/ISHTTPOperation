#import "ISHTTPOperation.h"

@interface ISHTTPOperation ()

@property (nonatomic, readonly) NSURLConnection *connection;
@property (nonatomic, readonly) NSMutableData *buffer;
#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
#else
@property (nonatomic, assign) dispatch_semaphore_t semaphore;
#endif

@end

@implementation ISHTTPOperation

#pragma mark -

+ (void)sendRequest:(NSURLRequest *)request handler:(void (^)(NSHTTPURLResponse *, id, NSError *))handler
{
    [self sendRequest:request
                queue:[ISHTTPOperationQueue defaultQueue]
              handler:handler];
}

+ (void)sendRequest:(NSURLRequest *)request
              queue:(NSOperationQueue *)queue
            handler:(void (^)(NSHTTPURLResponse *, id, NSError *))handler
{
    ISHTTPOperation *operation = [[[self class] alloc] initWithRequest:request handler:handler];
    [queue addOperation:operation];
}

- (id)init
{
    return [self initWithRequest:nil handler:nil];
}

- (id)initWithRequest:(NSURLRequest *)request handler:(void (^)(NSHTTPURLResponse *response, id object, NSError *error))handler
{
    self = [super init];
    if (self) {
        _request = request;
        _handler = handler;
        _semaphore = dispatch_semaphore_create(1);
        
        _finished = NO;
        _executing = NO;
    }
    return self;
}

- (void)dealloc
{
#if !OS_OBJECT_USE_OBJC
    dispatch_release(self.semaphore);
#endif
}

#pragma mark - accessor

- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isFinished
{
    return _finished;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (NSData *)receivedData
{
    return [self.buffer copy];
}

#pragma mark -

- (void)start
{
    if (self.isCancelled || !self.request) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main
{
    @autoreleasepool {
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        if (self.isCancelled) {
            [self completeOperation];
            dispatch_semaphore_signal(self.semaphore);
            return;
        }
        _connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
        dispatch_semaphore_signal(self.semaphore);
    }
    
    do {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            if (self.isCancelled) {
                [self completeOperation];
            }
        }
    } while (self.isExecuting && !self.isFinished);
}

- (void)cancel
{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self.connection cancel];
    _connection = nil;
    _handler = nil;
    dispatch_semaphore_signal(self.semaphore);
    
    [super cancel];
}

- (void)completeOperation
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    _finished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark - override in subclasses

- (id)processData:(NSData *)data
{
    return data;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _response = (NSHTTPURLResponse *)response;
    _buffer = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.buffer appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    id object = [self processData:self.buffer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.handler) {
            self.handler(self.response, object, nil);
        }
    });
    
    [self completeOperation];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.handler) {
            self.handler(self.response, nil, error);
        }
    });
    
    [self completeOperation];
}

@end
