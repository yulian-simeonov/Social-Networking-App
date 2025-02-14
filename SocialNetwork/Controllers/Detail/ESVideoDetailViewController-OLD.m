//
//  ESVideoDetailViewController.m
//  d'Netzwierk
//
//  Created by Eric Schanet on 11.12.14.
//
//
#import "ESVideoDetailViewController.h"
#import "ESBaseTextCell.h"
#import "ESActivityCell.h"
#import "ESPhotoDetailsFooterView.h"
#import "ESConstants.h"
#import "ESAccountViewController.h"
#import "ESLoadMoreCell.h"
#import "ESUtility.h"
#import "MBProgressHUD.h"
#import "AppDelegate.h"
#import "SCLAlertView.h"
#import "KILabel.h"
#import "ESHashtagTimelineViewController.h"
#import "ESVideoDetailsHeaderView.h"

enum ActionSheetTags {
    MainActionSheetTag = 0,
    ConfirmDeleteActionSheetTag = 1,
    ReportPhotoActionSheetTag = 2,
    ThisIsUserTag = 3,
    DeleteCommentTag = 4,
    ReportUserCommentTag = 5,
    ReportUserReasonTag = 6
    
};


static const CGFloat kESCellInsetWidth = 0.0f; //20

@implementation ESVideoDetailViewController

@synthesize commentTextField;
@synthesize video, headerView;


#pragma mark - Initialization

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ESUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:self.video];
}

- (id)initWithPhoto:(PFObject *)aVideo {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        // The className to query on
        self.parseClassName = kESActivityClassKey;
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of comments to show per page
        self.objectsPerPage = 30;
        
        //self.video = aVideo;
        
        
        //ADDED
        self.video = aVideo;
        AppDelegate *delegate = [AppDelegate getAppDelegate];
        delegate.object = aVideo;
        //
        

        
        self.likersQueryInProgress = NO;
    }
    return self;
}


#pragma mark - UIViewController
- (void)updateBarButtonItems:(CGFloat)alpha
{
    [self.navigationItem.leftBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem* item, NSUInteger i, BOOL *stop) {
        item.customView.alpha = alpha;
    }];
    self.navigationItem.titleView.alpha = alpha;
    self.navigationController.navigationBar.tintColor = [self.navigationController.navigationBar.tintColor colorWithAlphaComponent:alpha];
}
-(void)viewWillAppear:(BOOL)animated {
    self.tableView.tag = 3;
    self.navigationController.navigationBar.frame = CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, 44);
    [appDelegate removeTabBar];
    
    [self updateBarButtonItems:1];
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.container.panMode = MFSideMenuPanModeNone;
    
    [appDelegate.window addSubview:footerView];
    self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, delegate.window.bounds.size.height - footerView.frame.size.height);
    
    
}
- (void)viewDidLoad {
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
    self.refreshControl.tintColor = [UIColor darkGrayColor];
    [super viewDidLoad];
    sectionfooterheight=50;
    appDelegate = (AppDelegate* )[[UIApplication sharedApplication] delegate];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LogoNavigationBar"]];
    
    // Set table view properties
    //self.tableView.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1];
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    
    
    // Set table header
    self.headerView = [[ESVideoDetailsHeaderView alloc] initWithFrame:[ESVideoDetailsHeaderView rectForView] video:self.video];
    self.headerView.delegate = self;
    
    self.tableView.tableHeaderView = self.headerView;
    
    footerView = [[ESPhotoDetailsFooterView alloc] initWithFrame:[ESPhotoDetailsFooterView rectForView]];
    
    footerView.backgroundColor=[UIColor colorWithRed:233.0/255.0 green:233.0/255.0 blue:233.0/255.0 alpha:1.0];
    
    commentTextField = footerView.commentField;
    
    footerView.commentField.delegate = self;
    
    [footerView setFrame:CGRectMake(0, appDelegate.window.frame.size.height -  51, footerView.frame.size.width, footerView.frame.size.height)];
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonAction:)];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLikedOrUnlikedPhoto:) name:ESUtilityUserLikedUnlikedPhotoCallbackFinishedNotification object:self.video];
}

-(void)viewWillDisappear:(BOOL)animated
{
    
    [appDelegate showTabBar];
    [footerView removeFromSuperview];
    
    
}

//ADDED for video commet
- (void) videoUploadSucceeds {
    
    [self loadObjects];
}
//

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.headerView reloadLikeBar];
    
    // we will only hit the network if we have no cached data for this photo
    BOOL hasCachedLikers = [[ESCache sharedCache] attributesForPhoto:self.video] != nil;
    if (!hasCachedLikers) {
        [self loadLikers];
    }
}




#pragma mark - --------------------------------------
#pragma mark Keyboard show hide

-(void) keyboardWillShow:(NSNotification *)note{
    
    // get keyboard size and loctaion
    
    sectionfooterheight=0;
    [self.tableView reloadData];
    
    CGRect keyboardBounds;
    
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    keyboardBounds = [self.view convertRect:keyboardBounds toView:nil];
    
    CGRect containerFrame = footerView.frame;
    
    containerFrame.origin.y = self.view.bounds.size.height - (keyboardBounds.size.height + containerFrame.size.height);
    
    
    
    // animations settings
    
    [UIView beginAnimations:nil context:NULL];
    
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    [UIView setAnimationDuration:[duration doubleValue]];
    
    [UIView setAnimationCurve:[curve intValue]];
    
    // set views with new info
    
    footerView.frame = containerFrame;
    
    
    [footerView setFrame:CGRectMake(0, (([UIScreen mainScreen].bounds.size.height - keyboardBounds.size.height)-footerView.frame.size.height), footerView.frame.size.width, footerView.frame.size.height)];
    
    
    if ([self.objects count] > 0) {
        
        self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, ( footerView.frame.origin.y));
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(self.objects.count - 1) inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    
    
}



-(void) keyboardWillHide:(NSNotification *)note{
    
    NSNumber *duration = [note.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    
    NSNumber *curve = [note.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    CGRect containerFrame = footerView.frame;
    
    containerFrame.origin.y = self.view.bounds.size.height - containerFrame.size.height;
    
    [UIView beginAnimations:nil context:NULL];
    
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    [UIView setAnimationDuration:[duration doubleValue]];
    
    [UIView setAnimationCurve:[curve intValue]];
    
    footerView.frame = containerFrame;
    
    [UIView commitAnimations];
    sectionfooterheight=0;
    [self.tableView reloadData];
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, delegate.window.bounds.size.height - footerView.frame.size.height);
    
    [footerView setFrame:CGRectMake(0, delegate.window.bounds.size.height - footerView.frame.size.height, footerView.frame.size.width, footerView.frame.size.height)];
    
}



- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height

{
    
    float diff = (growingTextView.frame.size.height - height);
    
    CGRect r = footerView.frame;
    
    r.size.height -= diff;
    
    r.origin.y += diff;
    
    footerView.frame = r;
    
    
    
    
    [footerView setFrame:CGRectMake(0, footerView.frame.origin.y, footerView.frame.size.width, footerView.frame.size.height)];
    
    self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, footerView.frame.origin.y);
    
    if ([self.objects count] > 0) {
        
        self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, ( footerView.frame.origin.y));
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(self.objects.count - 1) inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) { // A comment row
        //NSLog(@"self.objects.count ====== %u",self.objects.count);
        PFObject *object = [self.objects objectAtIndex:indexPath.row];
        //NSLog(@" %@ object ====== %@",indexPath,object);
        
        if (object) {
            NSString *commentString;
            if([[object objectForKey:kESActivityTypeKey] isEqualToString:@"comment-video"]){
                commentString = [self.objects[indexPath.row] objectForKey:kESActivityContentKey];
                return 100.0f;
            }
            if([[object objectForKey:kESActivityTypeKey] isEqualToString:@"comment"]) {
                commentString = [self.objects[indexPath.row] objectForKey:kESActivityContentKey];
            }
            
            
            PFUser *commentAuthor = (PFUser *)[object objectForKey:kESActivityFromUserKey];
            NSString *nameString = @"";
            if (commentAuthor) {
                nameString = [commentAuthor objectForKey:kESUserDisplayNameKey];
                //NSLog(@"nameString ======= %@", nameString);
            }
            
            return [ESActivityCell heightForCellWithName:nameString contentString:commentString cellInsetWidth:kESCellInsetWidth];
        }
    }
    
    // The pagination row
    return 44.0f;
    
    
    /*
     if (indexPath.row < self.objects.count) { // A comment row
     PFObject *object = [self.objects objectAtIndex:indexPath.row];
     
     if (object) {
     NSString *commentString = [self.objects[indexPath.row] objectForKey:kESActivityContentKey];
     
     PFUser *commentAuthor = (PFUser *)[object objectForKey:kESActivityFromUserKey];
     
     NSString *nameString = @"";
     if (commentAuthor) {
     nameString = [commentAuthor objectForKey:kESUserDisplayNameKey];
     }
     
     return [ESActivityCell heightForCellWithName:nameString contentString:commentString cellInsetWidth:kESCellInsetWidth];
     }
     }
     
     // The pagination row
     return 44.0f;
     */
    
    
    
    
}


#pragma mark - PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:kESActivityPhotoKey equalTo:self.video];
    [query whereKeyDoesNotExist:@"noneread"];
    [query includeKey:kESActivityFromUserKey];
    
    
    
    
    //ADDED for Video Comment
    PFQuery *queryTxtComment = [PFQuery queryWithClassName:self.parseClassName];
    PFQuery *queryVideoCommnet = [PFQuery queryWithClassName:self.parseClassName];
    PFQuery *querySelectedPhoto = [PFQuery queryWithClassName:self.parseClassName];
    [queryTxtComment whereKey:kESActivityTypeKey equalTo:kESActivityTypeCommentPhoto];
    [queryVideoCommnet whereKey:kESActivityTypeKey equalTo:kESActivityTypeCommentVideo];
    [querySelectedPhoto whereKey:kESActivityPhotoKey equalTo:self.video];
    query = [PFQuery  orQueryWithSubqueries:@[queryTxtComment,queryVideoCommnet]];
    [query whereKey:kESActivityPhotoKey equalTo:self.video];
    [query includeKey:kESActivityFromUserKey];
    //
    
    //Commented out the below line for the Video Comment
    //[query whereKey:kESActivityTypeKey equalTo:kESActivityTypeCommentVideo];
    [query orderByAscending:@"createdAt"];
    //[query orderByDescending:@"createdAt"];
    
    
    
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    //
    // If there is no network connection, we will hit the cache first.
    if (self.objects.count == 0 || ![[UIApplication sharedApplication].delegate performSelector:@selector(isParseReachable)]) {
        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    }
    
    return query;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    [self.headerView reloadLikeBar];
    [self loadLikers];
}

# pragma mark - UITableView delegate and data source


-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section

{
    
    return  sectionfooterheight;
    
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section

{
    
    UIView *customView=[[UIView alloc]init];
    
    [customView setBackgroundColor:[UIColor clearColor]];
    
    return customView;
    
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *cellID = @"CommentCell";
    
    // Try to dequeue a cell and create one if necessary
    ESBaseTextCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[ESBaseTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.cellInsetWidth = kESCellInsetWidth;
        cell.delegate = self;
    }
    
    //Displays the comment users avatar and name.
    [cell setUser:[object objectForKey:kESActivityFromUserKey]];
    
    if ([[object objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeCommentVideo]) {
        //Displays the thumbnailImage of videocomment
        
        //Below is what is causing the null
        [cell setContentText:[object objectForKey:kESActivityContentKey]];
        
        [cell setContentImage:[object objectForKey:kESActivityVideoFileThumbnailKey]];
        cell.videoThumbnailFile = [object objectForKey:kESActivityVideoFileKey];
    }else{
        //Displays the comment users comment that was left.
        [cell setContentText:[object objectForKey:kESActivityContentKey]];
        [cell setContentImage:nil];
        cell.videoThumbnailFile = nil;
        
    }
    //    if([[object objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeCommentPhoto]){
    //
    //    }
    
    
    //////[cell setContentText:[object objectForKey:kESActivityContentKey]];
    
    //Displays the timestamp for the comment left.
    [cell setDate:[object createdAt]];
    
    if ([[(PFUser *)[object objectForKey:kESActivityFromUserKey] objectId] isEqualToString:[PFUser currentUser].objectId]) {
        cell.replyButton.hidden = YES;
    }
    
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"NextPage";
    
    ESLoadMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[ESLoadMoreCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.cellInsetWidth = kESCellInsetWidth;
        cell.hideSeparatorTop = YES;
    }
    
    return cell;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
}
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PFObject *object = [self.objects objectAtIndex:indexPath.row];
    if ([[[object objectForKey:@"fromUser"] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
        UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Delete", nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            // show UIActionSheet
            UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:NSLocalizedString(@"Do you really want to delete this comment?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete", nil) otherButtonTitles: nil];
            [actionSheet showInView:self.view];
            actionSheet.tag = DeleteCommentTag;
            savedIndexPath = indexPath;
            
        }];
        deleteAction.backgroundColor = [UIColor redColor];
        return @[deleteAction];
        
    }
    else {
        UITableViewRowAction *reportAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:NSLocalizedString(@"Report User", nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
            // show UIActionSheet
            UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:NSLocalizedString(@"Do you really want to report this user?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Report", nil) otherButtonTitles: nil];
            [actionSheet showInView:self.view];
            actionSheet.tag = ReportUserCommentTag;
            savedIndexPath = indexPath;
            
        }];
        reportAction.backgroundColor = [UIColor redColor];
        return @[reportAction];
        
    }
    
    
}



#pragma mark - UITextFieldDelegate


- (BOOL)growingTextViewShouldReturn:(HPGrowingTextView *)growingTextView
{
    
    NSString *dummyComment = [growingTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *trimmedComment = [NSString stringWithFormat:@"%@ ",dummyComment];
    
    if (trimmedComment.length != 0 && [self.video objectForKey:kESPhotoUserKey]) {
        
        NSRegularExpression *_regex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:nil];
        NSArray *_matches = [_regex matchesInString:trimmedComment options:0 range:NSMakeRange(0, trimmedComment.length)];
        NSMutableArray *hashtagsArray = [[NSMutableArray alloc]init];
        for (NSTextCheckingResult *match in _matches) {
            NSRange wordRange = [match rangeAtIndex:1];
            NSString* word = [trimmedComment substringWithRange:wordRange];
            [hashtagsArray addObject:[word lowercaseString]];
            
        }
        
        PFObject *comment = [PFObject objectWithClassName:kESActivityClassKey];
        [comment setObject:trimmedComment forKey:kESActivityContentKey]; // Set comment text
        [comment setObject:[self.video objectForKey:kESPhotoUserKey] forKey:kESActivityToUserKey]; // Set toUser
        [comment setObject:[PFUser currentUser] forKey:kESActivityFromUserKey]; // Set fromUser
        [comment setObject:kESActivityTypeCommentVideo forKey:kESActivityTypeKey];
        [comment setObject:self.video forKey:kESActivityPhotoKey];
        if (hashtagsArray.count > 0) {
            [comment setObject:hashtagsArray forKey:@"hashtags"];
            
            for (int i = 0; i < hashtagsArray.count; i++) {
                NSString *hash = [[hashtagsArray objectAtIndex:i] lowercaseString];
                PFQuery *hashQuery = [PFQuery queryWithClassName:@"Hashtags"];
                [hashQuery whereKey:@"hashtag" equalTo:hash];
                [hashQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error) {
                        if (objects.count == 0) {
                            PFObject *hashtag = [PFObject objectWithClassName:@"Hashtags"];
                            [hashtag setObject:hash forKey:@"hashtag"];
                            [hashtag saveInBackground];
                        }
                    }
                }];
            }
        }
        
        
        
        //PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
        //[ACL setPublicReadAccess:YES];
        //[ACL setWriteAccess:YES forUser:[PFUser currentUser]];
        //comment.ACL = ACL;
        
        [[ESCache sharedCache] incrementCommentCountForPhoto:self.video];
        
        // Show HUD view
        [MBProgressHUD showHUDAddedTo:self.view.superview animated:YES];
        
        
        // If more than 5 seconds pass since we post a comment, stop waiting for the server to respond
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:8.0f target:self selector:@selector(handleCommentTimeout:) userInfo:@{@"comment": comment} repeats:NO];
        
        PFObject *mention = [PFObject objectWithClassName:kESActivityClassKey];
        [mention setObject:[PFUser currentUser] forKey:kESActivityFromUserKey]; // Set fromUser
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:nil];
        NSArray *matches = [regex matchesInString:trimmedComment options:0 range:NSMakeRange(0, trimmedComment.length)];
        NSMutableArray *mentionsArray = [[NSMutableArray alloc]init];
        for (NSTextCheckingResult *match in matches) {
            NSRange wordRange = [match rangeAtIndex:1];
            NSString* word = [trimmedComment substringWithRange:wordRange];
            [mentionsArray addObject:word];
            
            
        }
        if (mentionsArray.count > 0 ) {
            PFQuery *mentionQuery = [PFUser query];
            [mentionQuery whereKey:@"usernameFix" containedIn:mentionsArray];
            [mentionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    [mention setObject:objects forKey:@"mentions"]; // Set toUser
                    [mention setObject:kESActivityTypeMention forKey:kESActivityTypeKey];
                    [mention setObject:self.video forKey:kESActivityPhotoKey];
                    [mention saveEventually];
                }
            }];
        }
        
        
        [comment saveEventually:^(BOOL succeeded, NSError *error) {
            [timer invalidate];
            
            if (error && error.code == kPFErrorObjectNotFound) {
                [[ESCache sharedCache] decrementCommentCountForPhoto:self.video];
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                [alert showError:self.tabBarController title:NSLocalizedString(@"Hold On...", nil)
                        subTitle:NSLocalizedString(@"We were unable to post your comment because this video is no longer available.", nil)
                closeButtonTitle:@"OK" duration:0.0f];                [self.navigationController popViewControllerAnimated:YES];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:ESPhotoDetailsViewControllerUserCommentedOnPhotoNotification object:self.video userInfo:@{@"comments": @(self.objects.count + 1)}];
            
            [MBProgressHUD hideHUDForView:self.view.superview animated:YES];
            [self loadObjects];
        }];
    }
    
    
    [footerView.commentField setText:@""];
    growingTextView.text=@"";
    return [growingTextView resignFirstResponder];
    
    
    
    
    
    
    
}



- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *dummyComment = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *trimmedComment = [NSString stringWithFormat:@"%@ ",dummyComment];
    if (trimmedComment.length != 0 && [self.video objectForKey:kESPhotoUserKey]) {
        
        NSRegularExpression *_regex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:nil];
        NSArray *_matches = [_regex matchesInString:trimmedComment options:0 range:NSMakeRange(0, trimmedComment.length)];
        NSMutableArray *hashtagsArray = [[NSMutableArray alloc]init];
        for (NSTextCheckingResult *match in _matches) {
            NSRange wordRange = [match rangeAtIndex:1];
            NSString* word = [trimmedComment substringWithRange:wordRange];
            [hashtagsArray addObject:[word lowercaseString]];
            
        }
        
        PFObject *comment = [PFObject objectWithClassName:kESActivityClassKey];
        [comment setObject:trimmedComment forKey:kESActivityContentKey]; // Set comment text
        [comment setObject:[self.video objectForKey:kESPhotoUserKey] forKey:kESActivityToUserKey]; // Set toUser
        [comment setObject:[PFUser currentUser] forKey:kESActivityFromUserKey]; // Set fromUser
        [comment setObject:kESActivityTypeCommentVideo forKey:kESActivityTypeKey];
        [comment setObject:self.video forKey:kESActivityPhotoKey];
        if (hashtagsArray.count > 0) {
            [comment setObject:hashtagsArray forKey:@"hashtags"];
            
            for (int i = 0; i < hashtagsArray.count; i++) {
                NSString *hash = [[hashtagsArray objectAtIndex:i] lowercaseString];
                PFQuery *hashQuery = [PFQuery queryWithClassName:@"Hashtags"];
                [hashQuery whereKey:@"hashtag" equalTo:hash];
                [hashQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error) {
                        if (objects.count == 0) {
                            PFObject *hashtag = [PFObject objectWithClassName:@"Hashtags"];
                            [hashtag setObject:hash forKey:@"hashtag"];
                            [hashtag saveInBackground];
                        }
                    }
                }];
            }
        }
        
        
        
        //PFACL *ACL = [PFACL ACLWithUser:[PFUser currentUser]];
        //[ACL setPublicReadAccess:YES];
        //[ACL setWriteAccess:YES forUser:[PFUser currentUser]];
        //comment.ACL = ACL;
        
        [[ESCache sharedCache] incrementCommentCountForPhoto:self.video];
        
        // Show HUD view
        [MBProgressHUD showHUDAddedTo:self.view.superview animated:YES];
        
        
        // If more than 5 seconds pass since we post a comment, stop waiting for the server to respond
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:8.0f target:self selector:@selector(handleCommentTimeout:) userInfo:@{@"comment": comment} repeats:NO];
        
        PFObject *mention = [PFObject objectWithClassName:kESActivityClassKey];
        [mention setObject:[PFUser currentUser] forKey:kESActivityFromUserKey]; // Set fromUser
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@(\\w+)" options:0 error:nil];
        NSArray *matches = [regex matchesInString:trimmedComment options:0 range:NSMakeRange(0, trimmedComment.length)];
        NSMutableArray *mentionsArray = [[NSMutableArray alloc]init];
        for (NSTextCheckingResult *match in matches) {
            NSRange wordRange = [match rangeAtIndex:1];
            NSString* word = [trimmedComment substringWithRange:wordRange];
            [mentionsArray addObject:word];
            
            
        }
        if (mentionsArray.count > 0 ) {
            PFQuery *mentionQuery = [PFUser query];
            [mentionQuery whereKey:@"usernameFix" containedIn:mentionsArray];
            [mentionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    [mention setObject:objects forKey:@"mentions"]; // Set toUser
                    [mention setObject:kESActivityTypeMention forKey:kESActivityTypeKey];
                    [mention setObject:self.video forKey:kESActivityPhotoKey];
                    [mention saveEventually];
                }
            }];
        }
        
        
        [comment saveEventually:^(BOOL succeeded, NSError *error) {
            [timer invalidate];
            
            if (error && error.code == kPFErrorObjectNotFound) {
                [[ESCache sharedCache] decrementCommentCountForPhoto:self.video];
                SCLAlertView *alert = [[SCLAlertView alloc] init];
                [alert showError:self.tabBarController title:NSLocalizedString(@"Hold On...", nil)
                        subTitle:NSLocalizedString(@"We were unable to post your comment because this video is no longer available.", nil)
                closeButtonTitle:@"OK" duration:0.0f];                [self.navigationController popViewControllerAnimated:YES];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:ESPhotoDetailsViewControllerUserCommentedOnPhotoNotification object:self.video userInfo:@{@"comments": @(self.objects.count + 1)}];
            
            [MBProgressHUD hideHUDForView:self.view.superview animated:YES];
            [self loadObjects];
        }];
    }
    
    [textField setText:@""];
    return [textField resignFirstResponder];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (actionSheet.tag == MainActionSheetTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to report this video? This can not be undone and might have consequences for the author.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Yes, report this video", nil) otherButtonTitles:nil];
            actionSheet.tag = ReportPhotoActionSheetTag;
            [actionSheet showFromTabBar:self.tabBarController.tabBar];
        }
    }
    else if (actionSheet.tag == ThisIsUserTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {
            // prompt to delete
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this video? This can not be undone.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Yes, delete video", nil) otherButtonTitles:nil];
            actionSheet.tag = ConfirmDeleteActionSheetTag;
            [actionSheet showFromTabBar:self.tabBarController.tabBar];
        }
    }
    else if (actionSheet.tag == ConfirmDeleteActionSheetTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {
            
            [self shouldDeleteVideo];
        }
    } else if (actionSheet.tag == ReportPhotoActionSheetTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {
            
            [self shouldReportVideo];
        }
    }
    else if (actionSheet.tag == DeleteCommentTag) {
        if ([actionSheet destructiveButtonIndex] == buttonIndex) {
            PFObject *object = [self.objects objectAtIndex:savedIndexPath.row];
            [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (error) {
                    SCLAlertView *alert = [[SCLAlertView alloc] init];
                    [alert showError:self.tabBarController title:NSLocalizedString(@"Hold On...", nil)
                            subTitle:NSLocalizedString(@"We were unable to delete your comment, retry later", nil)
                    closeButtonTitle:@"OK" duration:0.0f];
                    
                }
                else {
                    SCLAlertView *alert = [[SCLAlertView alloc] init];
                    alert.soundURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/right_answer.mp3", [[NSBundle mainBundle] resourcePath]]];
                    [alert showSuccess:self.tabBarController title:NSLocalizedString(@"Congratulations", nil) subTitle:NSLocalizedString(@"Your comment has been successfully deleted", nil) closeButtonTitle:NSLocalizedString(@"Done", nil) duration:0.0f];
                    
                    [self loadObjects];
                    [self.tableView reloadData];
                }
            }];
        }
        
    }
    else if (actionSheet.tag == ReportUserCommentTag) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"What do you want the user to be reported for?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Sexual content", nil), NSLocalizedString(@"Offensive content", nil), NSLocalizedString(@"Spam", nil), NSLocalizedString(@"Other", nil), nil];
        //actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        actionSheet.tag = ReportUserReasonTag;
        [actionSheet showInView:self.view];
        
    }
    else if (actionSheet.tag == ReportUserReasonTag) {
        PFObject *object = [self.objects objectAtIndex:savedIndexPath.row];
        PFUser *user = [object objectForKey:kESActivityFromUserKey];
        if (buttonIndex == 0) {
            [ESUtility reportUser:0 withUser:user andObject:object];
        }
        else if (buttonIndex == 1) {
            [ESUtility reportUser:1 withUser:user andObject:object];
        }
        else if (buttonIndex == 2) {
            [ESUtility reportUser:2 withUser:user andObject:object];
        }
        else if (buttonIndex == 3) {
            [ESUtility reportUser:3 withUser:user andObject:object];
        }
    }
}



#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [commentTextField resignFirstResponder];
}

#pragma mark - ESBaseTextCellDelegate

- (void)cell:(ESBaseTextCell *)cellView didTapUserButton:(PFUser *)aUser {
    [self shouldPresentAccountViewForUser:aUser];
}
- (void)cell:(ESBaseTextCell *)cellView didTapReplyButton:(PFUser *)aUser {
    NSString *string = [NSString stringWithFormat:@"@%@ ",[aUser objectForKey:@"usernameFix"]];
    [commentTextField setText:string];
    [commentTextField becomeFirstResponder];
    
}

//ADDED for video comments
- (void)cell:(ESBaseTextCell *)cellView didTapVideoThumbnailImage:(PFFile *)vieoFile{
    [self shouldPresentVideoPlayer:vieoFile];
}
//


#pragma mark - ESPhotoDetailsHeaderViewDelegate

-(void)videoDetailsHeaderView:(ESVideoDetailsHeaderView *)headerView didTapUserButton:(UIButton *)button user:(PFUser *)user {
    [self shouldPresentAccountViewForUser:user];
}

- (void)actionButtonAction:(id)sender {
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;
    
    if ([self currentUserOwnsPhoto]) {
        // Else we only want to show an action button if the user owns the photo and has permission to delete it.
        actionSheet.destructiveButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Delete Video", nil)];
        actionSheet.tag = ThisIsUserTag;
    }
    else {
        actionSheet.destructiveButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Report Video", nil)];
        actionSheet.tag = MainActionSheetTag;
    }
    
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
    
}

#pragma mark - ()

- (void)handleCommentTimeout:(NSTimer *)aTimer {
    [MBProgressHUD hideHUDForView:self.view.superview animated:YES];
    SCLAlertView *alert = [[SCLAlertView alloc] init];
    [alert showError:self.tabBarController title:NSLocalizedString(@"Hold On...", nil)
            subTitle:NSLocalizedString(@"Your comment will be posted next time there is an Internet connection.", nil)
    closeButtonTitle:@"OK" duration:0.0f];
}

- (void)shouldPresentAccountViewForUser:(PFUser *)user {
    ESAccountViewController *accountViewController = [[ESAccountViewController alloc] initWithStyle:UITableViewStylePlain];
    [accountViewController setUser:user];
    [self.navigationController pushViewController:accountViewController animated:YES];
}

//ADDED for video comment
- (void)shouldPresentVideoPlayer:(PFFile *)videoFile{
    //showing the video play viewcontroller
    if (videoFile) {
        [videoFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"MyFile.m4v"];
                [data writeToFile:appFile atomically:YES];
                NSURL *movieUrl = [NSURL fileURLWithPath:appFile];
                
                MPMoviePlayerViewController *movie = [[MPMoviePlayerViewController alloc] initWithContentURL:movieUrl];
                //When the video comment opens full screen it is auto playing
                //movie.moviePlayer.shouldAutoplay = YES;
                //movie.moviePlayer.controlStyle = MPMovieControlStyleNone;
                
                [[NSNotificationCenter defaultCenter] removeObserver:movie  name:MPMoviePlayerPlaybackDidFinishNotification object:movie.moviePlayer];
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(videoFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:movie.moviePlayer];
                [self presentMoviePlayerViewControllerAnimated:movie];
            }
        }];
    }
}
-(void)videoFinished:(NSNotification*)aNotification{
    int value = [[aNotification.userInfo valueForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    if (value == MPMovieFinishReasonUserExited) {
        [self dismissMoviePlayerViewControllerAnimated];
    }
}
//


- (void)backButtonAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)userLikedOrUnlikedPhoto:(NSNotification *)note {
    [self.headerView reloadLikeBar];
}



- (void)loadLikers {
    if (self.likersQueryInProgress) {
        return;
    }
    
    self.likersQueryInProgress = YES;
    PFQuery *query = [ESUtility queryForActivitiesOnVideo:video cachePolicy:kPFCachePolicyNetworkOnly];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.likersQueryInProgress = NO;
        if (error) {
            [self.headerView reloadLikeBar];
            return;
        }
        
        NSMutableArray *likers = [NSMutableArray array];
        NSMutableArray *commenters = [NSMutableArray array];
        
        BOOL isLikedByCurrentUser = NO;
        
        for (PFObject *activity in objects) {
            if (([[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeLikePhoto] || [[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeLikeVideo])&& [activity objectForKey:kESActivityFromUserKey]) {
                [likers addObject:[activity objectForKey:kESActivityFromUserKey]];
            } else if (([[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeCommentPhoto]||[[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeCommentVideo]) && [activity objectForKey:kESActivityFromUserKey]) {
                [commenters addObject:[activity objectForKey:kESActivityFromUserKey]];
            }
            
            if ([[[activity objectForKey:kESActivityFromUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                if ([[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeLikePhoto] || [[activity objectForKey:kESActivityTypeKey] isEqualToString:kESActivityTypeLikeVideo]) {
                    isLikedByCurrentUser = YES;
                }
            }
        }
        
        [[ESCache sharedCache] setAttributesForPhoto:video likers:likers commenters:commenters likedByCurrentUser:isLikedByCurrentUser];
        [self.headerView reloadLikeBar];
    }];
    
    if ([self.objects count] > 0) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(self.objects.count - 1) inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (BOOL)currentUserOwnsPhoto {
    return [[[self.video objectForKey:kESPhotoUserKey] objectId] isEqualToString:[[PFUser currentUser] objectId]];
}

- (void)shouldDeleteVideo {
    // Delete all activites related to this photo
    PFQuery *query = [PFQuery queryWithClassName:kESActivityClassKey];
    [query whereKey:kESActivityPhotoKey equalTo:self.video];
    [query findObjectsInBackgroundWithBlock:^(NSArray *activities, NSError *error) {
        if (!error) {
            for (PFObject *activity in activities) {
                [activity deleteEventually];
            }
        }
        
        // Delete photo
        [self.video deleteEventually];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:ESPhotoDetailsViewControllerUserDeletedPhotoNotification object:[self.video objectId]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)shouldReportVideo {
    PFObject *object = [PFObject objectWithClassName:@"Report"];
    [object setObject:video forKey:@"ReportedPhoto"];
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            alert.backgroundType = Blur;
            [alert showNotice:self.tabBarController title:NSLocalizedString(@"Notice", nil) subTitle:NSLocalizedString(@"Video has been successfully reported.", nil) closeButtonTitle:@"OK" duration:0.0f];
        }
        else {
            SCLAlertView *alert = [[SCLAlertView alloc] init];
            [alert showError:self.tabBarController title:NSLocalizedString(@"Hold On...", nil)
                    subTitle:NSLocalizedString(@"Check your internet connection.", nil)
            closeButtonTitle:@"OK" duration:0.0f];
            
            NSLog(@"error %@",error);
        }
        
    }];
    
}
- (void)useNotificationWithString:(NSNotification *)notification //use notification method and logic
{    NSString *key = @"CommunicationStringValue";
    NSDictionary *dictionary = [notification userInfo];
    NSString *stringValueToUse = [dictionary valueForKey:key];
    ESHashtagTimelineViewController *hashtagSearch = [[ESHashtagTimelineViewController alloc] initWithStyle:UITableViewStyleGrouped andHashtag:stringValueToUse];
    [self.navigationController pushViewController:hashtagSearch animated:YES];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}


@end
