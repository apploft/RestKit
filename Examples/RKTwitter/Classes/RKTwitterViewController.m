//
//  RKTwitterViewController.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTwitterViewController.h"
#import "RKTweet.h"

@interface RKTwitterViewController (Private)
- (void)loadData;
@end

@implementation RKTwitterViewController

- (void)loadTimeline
{
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth2/token"]];
    request.HTTPMethod = @"POST";
    NSString *consumerKey = @"";
    NSString *consumerSecret = @"";
    NSString *creds = [NSString stringWithFormat:@"%@:%@", consumerKey, consumerSecret];
    NSString *base64Encoded = [[creds dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    
    [request setValue:[NSString stringWithFormat:@"Basic %@", base64Encoded] forHTTPHeaderField:@"Authorization"];
    request.HTTPBody = [@"grant_type=client_credentials" dataUsingEncoding:NSUTF8StringEncoding];
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];        
        [self loadTweets:JSON[@"access_token"]];
        
    }] resume];
}

- (void)loadTweets:(NSString*)token{
    
    // Load the object model via RestKit
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    [objectManager.HTTPClient setDefaultHeader:@"Authorization" value:[NSString stringWithFormat: @"Bearer %@", token]];

    NSDictionary *params = @{
                             @"screen_name" : @"RestKit"
                             };

    [objectManager getObjectsAtPath:@"/statuses/user_timeline"
                         parameters:params
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                              NSArray* statuses = [mappingResult array];
                              NSLog(@"Loaded statuses: %@", statuses);
                              _statuses = statuses;
                              if(self.isViewLoaded)
                                [_tableView reloadData];
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                               message:[error localizedDescription]
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil];
                              [alert show];
                              NSLog(@"Hit error: %@", error);
                            }];
}

- (void)loadView
{
    [super loadView];
    
    self.automaticallyAdjustsScrollViewInsets = YES;
    self.view.backgroundColor = [UIColor whiteColor];

    // Setup View and Table View
    self.title = @"RestKit Tweets";
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadTimeline)];

    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStylePlain];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];

    [self loadTimeline];
}


#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = [[[_statuses objectAtIndex:indexPath.row] text] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(300, 9000)];
    return size.height + 50;
}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return [_statuses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = @"Tweet Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 0;
    }
    RKTweet* status = [_statuses objectAtIndex:indexPath.row];
    cell.textLabel.text = [status text];
    cell.detailTextLabel.text = status.user.screenName;
    return cell;
}

@end
