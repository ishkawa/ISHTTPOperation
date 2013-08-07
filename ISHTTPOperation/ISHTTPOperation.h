#import <Foundation/Foundation.h>
#import "ISHTTPOperationQueue.h"
#import "NSOperationQueue+HTTP.h"

@interface ISHTTPOperation : NSOperation <NSURLConnectionDataDelegate> {
    BOOL _executing;
    BOOL _finished;
}

@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, copy) void (^handler)(NSHTTPURLResponse *response, id object, NSError *error);

+ (void)sendRequest:(NSURLRequest *)request
            handler:(void (^)(NSHTTPURLResponse *response, id object, NSError *error))handler;

+ (void)sendRequest:(NSURLRequest *)request
              queue:(NSOperationQueue *)queue
            handler:(void (^)(NSHTTPURLResponse *response, id object, NSError *error))handler;

- (id)initWithRequest:(NSURLRequest *)request handler:(void (^)(NSHTTPURLResponse *response, id object, NSError *error))handler;
- (id)processData:(NSData *)data;
- (void)completeOperation;

@end
