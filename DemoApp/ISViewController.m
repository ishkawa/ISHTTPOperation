#import "ISViewController.h"
#import <ISHTTPOperation/ISHTTPOperation.h>

@implementation ISViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"ISHTTPOperation";
        self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                      target:self
                                                      action:@selector(stop)];
        
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(refresh)];
    }
    return self;
}

#pragma mark -

- (void)stop
{
    [[ISHTTPOperation sharedQueue] cancelAllOperations];
}

- (void)refresh
{
    NSURL *URL = [NSURL URLWithString:@"http://date.jsontest.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [ISHTTPOperation sendRequest:request handler:^(NSHTTPURLResponse *response, id object, NSError *error) {
        if (error) {
            NSLog(@"error: %@", error);
            return;
        }
        
        NSError *parseError = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:object
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:&parseError];
        if (error) {
            NSLog(@"parse error: %@", error);
        }
        
        self.array = [@[dictionary] arrayByAddingObjectsFromArray:self.array];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationTop];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:Identifier];
    }
    NSDictionary *dictionary = [self.array objectAtIndex:indexPath.row];
    cell.textLabel.text = [dictionary objectForKey:@"date"];
    cell.detailTextLabel.text = [dictionary objectForKey:@"time"];
    
    return cell;
}

@end
