#import <Foundation/Foundation.h>

@interface ISHTTPOperation : NSOperation

@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, copy) void (^handler)(NSHTTPURLResponse *response, id object, NSError *error);

+ (NSOperationQueue *)sharedQueue;
+ (void)sendRequest:(NSURLRequest *)request handler:(void (^)(NSHTTPURLResponse *response, id object, NSError *error))handler;

- (id)initWithRequest:(NSURLRequest *)request handler:(void (^)(NSHTTPURLResponse *response, id object, NSError *error))handler;
- (id)processData:(NSData *)data;

@end
