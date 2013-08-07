#import <Foundation/Foundation.h>

@interface ISHTTPOperationQueue : NSOperationQueue

+ (instancetype)defaultQueue;

- (void)cancelOperationsUsingPredicate:(NSPredicate *)predicate;
- (void)cancelOperationsWithHTTPMethod:(NSString *)method;
- (void)cancelOperationsWithHost:(NSString *)host;
- (void)cancelOperationsWithPath:(NSString *)path;
- (void)cancelOperationsWithURL:(NSURL *)URL;

@end
