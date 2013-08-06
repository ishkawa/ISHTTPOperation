#import <SenTestingKit/SenTestingKit.h>

@interface SenTestCase (Async)

@property (nonatomic, getter = isWaiting) BOOL waiting;

- (void)startWaiting;
- (void)stopWaiting;

- (void)waitUntilSatisfyingCondition:(BOOL (^)(void))conditionBlock;

@end
