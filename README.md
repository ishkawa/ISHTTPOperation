# ISHTTPOperation [![Build Status](https://travis-ci.org/ishkawa/ISHTTPOperation.png?branch=master)](https://travis-ci.org/ishkawa/ISHTTPOperation) [![Coverage Status](https://coveralls.io/repos/ishkawa/ISHTTPOperation/badge.png?branch=master)](https://coveralls.io/r/ishkawa/ISHTTPOperation?branch=master)

a subclass of NSOperation to wrap asynchronous NSURLConnection.

## Requirements

- iOS 4.0 or later
- ARC

## Usage

```objectivec
NSURL *URL = [NSURL URLWithString:@"http://date.jsontest.com"];
NSURLRequest *request = [NSURLRequest requestWithURL:URL];
[ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
    if (error) {
        return;
    }
    // completion
}];
```

the operations made by `sendRequest:handler:` will be enqueued to `[NSOperationQueue defaultHTTPQueue]`.

### Cancel operations

```objectivec
[[ISHTTPOperationQueue defaultQueue] cancelAllOperations];
```

```objectivec
NSPredicate *predicate = [NSPredicate predicateWithFormat:@"request.HTTPMethod MATCHES %@", @"GET"];
[[ISHTTPOperationQueue defaultQueue] cancelOperationsUsingPredicate:predicate];
```

```objectivec
[[ISHTTPOperationQueue defaultQueue] cancelOperationsWithHTTPMethod:@"GET"];
[[ISHTTPOperationQueue defaultQueue] cancelOperationsWithHost:@"example.com"];
[[ISHTTPOperationQueue defaultQueue] cancelOperationsWithPath:@"/foo"];
```

## Installing

Add files under `ISHTTPOperation/` to your Xcode project.

### CocoaPods

If you use CocoaPods, you can install ISHTTPOperation by inserting config below.
```
pod 'ISHTTPOperation', '~> 1.1.1'
```

## Advanced 

### Manage network indicator visible

observe `operationCount` key of `[ISHTTPOperation sharedQueue]`.

```objectivec
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSOperationQueue *queue = [NSOperationQueue defaultHTTPQueue];
    [queue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];

    ...
}
```

```objectivec
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"operationCount"]) {
        UIApplication *application = [UIApplication sharedApplication];
        NSOperationQueue *queue = [NSOperationQueue defaultHTTPQueue];
        application.networkActivityIndicatorVisible = [queue operationCount] ? YES : NO;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
```

### Add data processing 

To add data processing to the operation, override `processData:`.  
This method is called in subthread.

ex. JSON parse

```objectivec
- (id)processData:(NSData *)data
{
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data
                                                options:NSJSONReadingAllowFragments
                                                  error:&error];
    if (error) {
        NSLog(@"JSON error: %@", error);
    }
    return object;
}
```

## License

Copyright (c) 2013 Yosuke Ishikawa

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

