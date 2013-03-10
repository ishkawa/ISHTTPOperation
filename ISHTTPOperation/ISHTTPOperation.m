#import "ISHTTPOperation.h"

@interface ISHTTPOperation () <NSURLConnectionDataDelegate>

@property BOOL isExecuting;
@property BOOL isFinished;

@property (nonatomic, strong) NSURLConnection   *connection;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) NSMutableData     *data;

@end

@implementation ISHTTPOperation

#pragma mark -

+ (void)sendRequest:(NSURLRequest *)request handler:(void (^)(NSHTTPURLResponse *, id, NSError *))handler
{
    [self sendRequest:request
                queue:[NSOperationQueue defaultHTTPQueue]
              handler:handler];
}

+ (void)sendRequest:(NSURLRequest *)request
              queue:(NSOperationQueue *)queue
            handler:(void (^)(NSHTTPURLResponse *, id, NSError *))handler
{
    ISHTTPOperation *operation = [[[self class] alloc] initWithRequest:request handler:handler];
    [queue addOperation:operation];
}

- (id)initWithRequest:(NSURLRequest *)request handler:(void (^)(NSHTTPURLResponse *response, id object, NSError *error))handler
{
    self = [super init];
    if (self) {
        self.request = request;
        self.handler = handler;
    }
    return self;
}

#pragma mark - KVO

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@"isExecuting"] || [key isEqualToString:@"isFinished"]) {
        return YES;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

- (BOOL)isConcurrent
{
    return YES;
}

#pragma mark -

- (void)start
{
    if (self.isCancelled) {
        self.isExecuting = NO;
        self.isFinished = YES;
        return;
    }
    
    self.isExecuting = YES;
    
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request
                                                      delegate:self
                                              startImmediately:NO];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [self.connection start];
        
        do {
            if (self.isCancelled) {
                self.isExecuting = NO;
                self.isFinished = YES;
                break;
            }
            [[NSRunLoop currentRunLoop] run];
        } while (self.isExecuting);
    });
}

- (void)cancel
{
    [self.connection cancel];
    self.connection = nil;
    
    [super cancel];
}

#pragma mark - override in subclasses

- (id)processData:(NSData *)data
{
    return data;
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.response = (NSHTTPURLResponse *)response;
    self.data = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    id object = [self processData:self.data];
    if (self.handler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.handler(self.response, object, nil);
        });
    }
    
    self.isExecuting = NO;
    self.isFinished = YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.handler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.handler(self.response, nil, error);
        });
    }
    
    self.isExecuting = NO;
    self.isFinished = YES;
}

@end
