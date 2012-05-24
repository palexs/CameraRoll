#import "CameraRollViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "UIImage+RoundedCorner.h"

@interface CameraRollViewController ()
{
    NSMutableArray *framesArray;
}

@property (nonatomic, retain) NSArray *scrollViewThumbnailViews;
@property (nonatomic, retain) UIBarButtonItem* backItem;

@end

@implementation CameraRollViewController

@synthesize assets, scrollView, navBar, scrollViewThumbnailViews, backItem;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        assets = [NSMutableArray new];
        framesArray = [NSMutableArray new];
        scrollViewThumbnailViews = [NSArray new];
    }
    return self;
}

+ (ALAssetsLibrary *)defaultAssetsLibrary {
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    
    return library;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_back.png"] style:UIBarButtonItemStylePlain target:nil action:@selector(goBack:)];
                                
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@"Camera Roll"];
    item.leftBarButtonItem = backItem;
    [self.navBar pushNavigationItem:item animated:NO];
    
    UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)]; 
    singleFingerTap.numberOfTapsRequired = 1;
    [self.scrollView addGestureRecognizer:singleFingerTap];
    
    UITapGestureRecognizer *singleNavBarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleNavBarTap:)]; 
    singleFingerTap.numberOfTapsRequired = 1;
    singleNavBarTap.delegate = self;
    [self.navBar addGestureRecognizer:singleNavBarTap];
    
    [self loadAssets]; 
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    self.assets = nil;
    self.scrollView = nil;
    self.navBar = nil;
    self.scrollViewThumbnailViews = nil;
    self.backItem = nil;
}

-(void)addAsset:(id)anAsset {
    [self.assets addObject:anAsset];
}

-(void)loadAssets
{
    void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if(result != NULL) {
            [self addAsset:result];
        }
    };
    
    void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
        [group setAssetsFilter:[ALAssetsFilter allVideos]];
        
        if(group != nil) {
            [group enumerateAssetsUsingBlock:assetEnumerator];
        } else {
            //[self.assets addObject:[NSNull null]];
            NSLog(@"Finished polling.");
            [self addThumbnailsToScrollView];
        }
    };
    
    ALAssetsLibrary *library = [CameraRollViewController defaultAssetsLibrary];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:assetGroupEnumerator failureBlock:^(NSError *error) {
        NSLog(@"*** %@", error);
        // TODO Handle - alert with instructions
    }];
    
}

- (void)addThumbnailsToScrollView
{
    NSArray *reversedAssetsArray = [[self.assets reverseObjectEnumerator] allObjects];
    
    scrollView.backgroundColor = [UIColor whiteColor];
	scrollView.pagingEnabled = NO;
    int kPictsPerRow = 5;
    int kNumOfPictures = [reversedAssetsArray count];
    
    CGSize thumbSize = CGSizeMake(80.0, 80.0);
    const CGFloat xSpace = (scrollView.frame.size.width - (thumbSize.width * kPictsPerRow)) / (kPictsPerRow + 1);
    const CGFloat xInc = thumbSize.width + xSpace;
    const CGFloat yInc = thumbSize.height + 15.0f;
    CGFloat x = xSpace, y = 10.0f;
    
    int rowWatcher = 0;
    
    for (int i = 0; i < kNumOfPictures; i++)
    {
        ALAsset *asset = [reversedAssetsArray objectAtIndex:i];
        
        if(asset) {
            UIImage *thumbnailImg = [UIImage imageWithCGImage:[asset thumbnail]];
            UIImage *resizedThumbnailImage = [thumbnailImg roundedCornerImage:10 borderSize:0];
            UIImageView *pv = [[UIImageView alloc] initWithImage:resizedThumbnailImage];
            CGRect rect = CGRectMake(x, y, thumbSize.width, thumbSize.height);
            [pv setFrame:rect];
            [framesArray addObject:[NSValue valueWithCGRect:rect]];
            
            // add label with duration
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 80, 20)];
            lbl.textAlignment = UITextAlignmentCenter;
            lbl.textColor = [UIColor blackColor];
            lbl.text = [self getDurationStringFromAsset:asset];
            [lbl setAlpha:0.5];
            [pv addSubview:lbl];
            [scrollView addSubview:pv];
            x += xInc;

            if(rowWatcher == kPictsPerRow - 1) {
                y += yInc, x = xSpace;
                rowWatcher = 0;
            } else {
                rowWatcher++;
            }
        } else {
            NSLog(@"*** ASSET error!!!");
            // TODO Handle
        }
    }
    
    self.scrollViewThumbnailViews = [scrollView.subviews copy]; // save thumbnails views only array for further use
    
    int rows_num = kNumOfPictures / kPictsPerRow;
    int rest = fmod(kNumOfPictures, kPictsPerRow);
    int contentSizeY;
    
    if (rest != 0) {
        contentSizeY = yInc * (rows_num + 1);
    } else {
        contentSizeY = yInc * rows_num;
    }
    
    // Add info labal at the bottom of the scroll view
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, contentSizeY, 480, 40)];
    [infoLabel setText:[NSString stringWithFormat:@"Video files: %i, Total duration: %@", [assets count], [self getTotalDurationStringFromAssetsArray:assets]]];
    [infoLabel setTextAlignment:UITextAlignmentCenter];
    [infoLabel setTextColor:[UIColor grayColor]];
    [scrollView addSubview:infoLabel];
    
    scrollView.contentSize = CGSizeMake(xInc * kPictsPerRow, contentSizeY + infoLabel.frame.size.height);
}

- (NSString*)getDurationStringFromAsset:(ALAsset*)anAsset
{
    //Get the URL location of the video
    ALAssetRepresentation *representation = [anAsset defaultRepresentation];
    NSURL *url = [representation url];

    //Create an AVAsset from the given URL
    NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVAsset *avAsset = [[AVURLAsset alloc] initWithURL:url options:asset_options];
    //[AVURLAsset URLAssetWithURL:url options:asset_options];

    CMTime duration = avAsset.duration;
    float seconds = CMTimeGetSeconds(duration);
    NSString *durationString = [self convertToTimerString:(int)seconds];
    
    return durationString;
}

- (NSString*)getTotalDurationStringFromAssetsArray:(NSArray*)assetsArray
{
    float seconds = 0;
    
    for (ALAsset *anAsset in assetsArray) {
        //Get the URL location of the video
        ALAssetRepresentation *representation = [anAsset defaultRepresentation];
        NSURL *url = [representation url];
        
        //Create an AVAsset from the given URL
        NSDictionary *asset_options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVAsset *avAsset = [[AVURLAsset alloc] initWithURL:url options:asset_options];
        //[AVURLAsset URLAssetWithURL:url options:asset_options];
        
        CMTime duration = avAsset.duration;
        seconds += CMTimeGetSeconds(duration);
    }
    
    NSString *totalDurationString = [self convertToTimerString:(int)seconds];
    
    return totalDurationString;
}

#pragma mark - MPMoviePlayer

- (void)playVideo:(NSURL*)aVideoUrl
{
    MPMoviePlayerViewController *playerVC = [[MPMoviePlayerViewController alloc] initWithContentURL:aVideoUrl];
    
    // Remove the movie player view controller from the "playback did finish" notification observers
    [[NSNotificationCenter defaultCenter] removeObserver:playerVC name:MPMoviePlayerPlaybackDidFinishNotification object:playerVC.moviePlayer];
    
    // Register this class as an observer instead
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieFinishedCallback:) name:MPMoviePlayerPlaybackDidFinishNotification object:playerVC.moviePlayer];
    
    playerVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [playerVC.moviePlayer setShouldAutoplay:NO];
    
    [self presentModalViewController:playerVC animated:YES];
    
}

- (void)movieFinishedCallback:(NSNotification*)aNotification
{
    // Obtain the reason why the movie playback finished
    NSNumber *finishReason = [[aNotification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    
    // Dismiss the view controller ONLY when the reason is not "playback ended"
    if ([finishReason intValue] != MPMovieFinishReasonPlaybackEnded)
    {
        MPMoviePlayerController *moviePlayer = [aNotification object];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:moviePlayer];
        
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)handleTapGesture:(UIGestureRecognizer *)recognizer
{
    CGPoint currentLocation = [recognizer locationInView:self.scrollView];
    int i = 0;

    // Need to reverse it so that indexes correspond to the ones in assets array
    NSArray *reversedFramesArray = [[framesArray reverseObjectEnumerator] allObjects];
    
    for (NSValue *obj in reversedFramesArray) {
        CGRect rect = [obj CGRectValue];
    
        if (CGRectContainsPoint(rect, currentLocation)) {
            break;
        }
        
        i++;
    }
    
    ALAsset *asset = [self.assets objectAtIndex:i];
    NSURL *url = asset.defaultRepresentation.url;
    
    
    NSArray *reversedThumbnailsViewsArray = [[self.scrollViewThumbnailViews reverseObjectEnumerator] allObjects];
    
    UIView *selectedThumbnail = [reversedThumbnailsViewsArray objectAtIndex:i];
    [UIView animateWithDuration:0.3 animations:^{
        [selectedThumbnail.layer setBorderColor:[UIColor blueColor].CGColor];
        [selectedThumbnail.layer setBorderWidth:3.0];
    } completion:^(BOOL finished){
        [self playVideo:url];
        [selectedThumbnail.layer setBorderColor:[UIColor clearColor].CGColor];
        [selectedThumbnail.layer setBorderWidth:0.0];
    }];
}

- (void)handleNavBarTap:(UIGestureRecognizer *)recognizer
{
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
}

- (IBAction)goBack:(id)sender
{
    
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint touchedPoint = [touch locationInView:self.navBar];
    
    if (touchedPoint.x < 40) { // 40 represents back button width
        [self goBack:self];
    }

    return YES;
}

- (NSString*)convertToTimerString:(int)timeInSeconds
{
    NSString *hchar, *mchar, *schar;
    
    hchar = @"";
    mchar = @"";
    schar = @"";
    
    int hours = timeInSeconds / 3600;
    int remainder = fmod(timeInSeconds, 3600);
    int minutes = remainder / 60;
    int seconds = fmod(remainder, 60);
    
    if(hours < 10) {
        hchar = @"0";
    }
    
    if(minutes < 10) {
        mchar = @"0";
    }
    
    if(seconds < 10) {
        schar = @"0";
    }
    
    if (timeInSeconds < 3600) { // less than an hour
        return [NSString stringWithFormat:@"%@%i:%@%i", mchar, minutes, schar, seconds];
    } else {
        return [NSString stringWithFormat:@"%@%i:%@%i:%@%i", hchar, hours, mchar, minutes, schar, seconds];
    }
}

@end
