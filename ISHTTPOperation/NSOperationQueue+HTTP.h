#import <Foundation/Foundation.h>

@interface NSOperationQueue (HTTP)

// use [ISHTTPOperationQueue defaultQueue] instead.
+ (NSOperationQueue *)defaultHTTPQueue DEPRECATED_ATTRIBUTE;

@end
