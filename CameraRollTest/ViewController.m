#import "ViewController.h"
#import "CameraRollViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

-(IBAction)showCameraRoll:(id)sender
{
    CameraRollViewController *cameraRollView = [[CameraRollViewController alloc] init];
    [self presentModalViewController:cameraRollView animated:YES];
}

@end
