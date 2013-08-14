#import "SenTestCase+Async.h"
#import <objc/runtime.h>

static char SenTestCaseWaitingKey;

@implementation SenTestCase (Async)

- (BOOL)isWaiting
{
    return [objc_getAssociatedObject(self, &SenTestCaseWaitingKey) boolValue];
}

- (void)setWaiting:(BOOL)waiting
{
    objc_setAssociatedObject(self, &SenTestCaseWaitingKey, @(waiting), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)startWaiting
{
    self.waiting = YES;
    
    do {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    } while (self.isWaiting);
}

- (void)stopWaiting
{
    self.waiting = NO;
}

- (void)waitUntilSatisfyingCondition:(BOOL (^)(void))conditionBlock
{
    NSTimeInterval timeout = 1.0;
    NSDate *startedDate = [NSDate date];
    
    do {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            if ([[NSDate date] timeIntervalSinceDate:startedDate] > timeout) {
                STFail(@"timed out.");
                break;
            }
        }
    } while (!conditionBlock());
}

@end
