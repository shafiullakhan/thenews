//
//  DNFeedViewController.m
//  The News
//
//  Created by Tosin Afolabi on 25/03/2014.
//  Copyright (c) 2014 Tosin Afolabi. All rights reserved.
//

#import "DNManager.h"
#import "TNRefreshView.h"
#import "TNNotification.h"
#import "DNFeedViewCell.h"
#import "SVPullToRefresh.h"
#import "TNPostViewController.h"
#import "DNCommentsViewController.h"
#import "DNFeedViewController.h"

static int CELL_HEIGHT = 85;
static NSString *CellIdentifier = @"DNFeedCell";

__weak DNFeedViewController *weakself;

@interface DNFeedViewController () <TNFeedViewCellDelegate>

@property (nonatomic, strong) NSMutableArray *stories;
@property (nonatomic, strong) UITableView *feedView;

@end

@implementation DNFeedViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupRefreshControl];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    [self setFeedType:TNTypeDesignerNews];

    dnFeedType = DNFeedTypeTop;
    weakself = self;

    self.stories = [[NSMutableArray alloc] init];
    [self downloadFeedAndReset:NO];

	CGFloat navBarHeight = 64.0;
	CGSize screenSize = self.view.frame.size;
    CGRect contentViewFrame = CGRectMake(0, navBarHeight, screenSize.width, screenSize.height - navBarHeight);

	self.feedView = [[UITableView alloc] initWithFrame:contentViewFrame];
	[self.feedView setDelegate:self];
	[self.feedView setDataSource:self];
	[self.feedView setSeparatorInset:UIEdgeInsetsZero];
	[self.feedView setSeparatorColor:[UIColor tnLightGreyColor]];
	[self.feedView registerClass:[DNFeedViewCell class] forCellReuseIdentifier:CellIdentifier];

    UIImage *emptyState = [UIImage imageNamed:@"Loading"];
    UIImageView *emptyStateView = [[UIImageView alloc] initWithImage:emptyState];
    [emptyStateView setFrame:CGRectMake(50, 150, emptyState.size.width, emptyState.size.height)];

    //[self.view addSubview:emptyStateView];

	[self.view addSubview:self.feedView];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.stories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    DNFeedViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    DNStory *story = (self.stories)[[indexPath row]];

	[cell setForReuse];
	[cell setFrameHeight:CELL_HEIGHT];
    [cell setGestureDelegate:self];
    [cell configureForStory:story];

    if ([[DNManager sharedManager] isUserAuthenticated]) {

        [cell addUpvoteGesture];
    }

    [cell addViewCommentsGesture];
    [cell setSeparatorInset:UIEdgeInsetsZero];
    return cell;
}


#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return CELL_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DNStory *story = (self.stories)[[indexPath row]];
    TNPostViewController *postViewController = [[TNPostViewController alloc] initWithURL:[NSURL URLWithString:[story URL]] type:TNTypeDesignerNews];

    __weak DNFeedViewController *weakSelf = self;
    [postViewController setDismissAction:^{ [weakSelf.navigationController popViewControllerAnimated:YES]; }];

    [self.navigationController pushViewController:postViewController animated:YES];
}

#pragma mark - TNFeedView Delegate

- (void)upvoteActionForCell:(TNFeedViewCell *)cell
{
    DNFeedViewCell *dncell = (DNFeedViewCell *)cell;
    DNStory *story = [dncell story];
    [self upvoteStoryWithID:[story storyID]];
}

- (void)viewCommentsActionForCell:(TNFeedViewCell *)cell
{
    DNFeedViewCell *dncell = (DNFeedViewCell *)cell;
    DNStory *story = [dncell story];
    [self showCommentsForStory:story];
}

#pragma mark - Network Methods

- (void)downloadFeedAndReset:(BOOL)reset
{
    static int page = 0;

    if(reset) {
        page = 0;
    }

    page++;

    [[DNManager sharedManager] getStoriesOnPage:[NSString stringWithFormat:@"%d", page] feedType:dnFeedType success:^(NSArray *dnStories) {

        if (reset) {
            [self.stories removeAllObjects];
            [self.feedView.pullToRefreshView stopAnimating];
        }

        [self.stories addObjectsFromArray:dnStories];
        [self.feedView reloadData];


        [self.feedView.infiniteScrollingView stopAnimating];

    } failure:^(NSURLSessionDataTask *task, NSError *error) {

        NSLog(@"%@", [[error userInfo] objectForKey:@"NSLocalizedDescription"]);

    }];
}

- (void)upvoteStoryWithID:(NSNumber *)storyID
{
    TNNotification *notification = [[TNNotification alloc] init];

    [[DNManager sharedManager] upvoteStoryWithID:[storyID stringValue] success:^{

        [notification showSuccessNotification:@"Story Upvote Successful" subtitle:nil];

    } failure:^(NSURLSessionDataTask *task, NSError *error) {

        [notification showFailureNotification:@"Story Upvote Failed" subtitle:@"You can only upvote a story once."];

    }];
}

- (void)showCommentsForStory:(DNStory *)story
{
    DNCommentsViewController *vc = [[DNCommentsViewController alloc] initWithStory:story];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Private Methods

- (void)setupRefreshControl
{
    [self.feedView addPullToRefreshWithActionHandler:^{
        [weakself downloadFeedAndReset:YES];
    }];

    [self.feedView addInfiniteScrollingWithActionHandler:^{
        [weakself downloadFeedAndReset:NO];
    }];

    TNRefreshView *pulling = [[TNRefreshView alloc] initWithFrame:CGRectMake(0, 0, 320, 60) state:TNRefreshStatePulling];
    TNRefreshView *loading = [[TNRefreshView alloc] initWithFrame:CGRectMake(0, 0, 320, 60) state:TNRefreshStateLoading];

    [[self.feedView pullToRefreshView] setCustomView:pulling forState:SVPullToRefreshStateAll];
    [[self.feedView pullToRefreshView] setCustomView:loading forState:SVPullToRefreshStateLoading];
}

- (void)switchDnFeedType
{
    switch (dnFeedType) {

        case DNFeedTypeTop:
            dnFeedType = DNFeedTypeRecent;
            break;

        case DNFeedTypeRecent:
            dnFeedType = DNFeedTypeTop;
            break;

        default:
            break;
    }

    NSLog(@"%d", dnFeedType);
    
    [self downloadFeedAndReset:YES];
}

@end