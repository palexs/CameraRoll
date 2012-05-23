#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface CameraRollViewController : ViewController <UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSMutableArray *assets;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UINavigationBar *navBar;

- (IBAction)goBack:(id)sender;
+ (ALAssetsLibrary *)defaultAssetsLibrary; // *** The lifetimes of objects you get back from a library instance are tied to the lifetime of the library instance. ***

@end
