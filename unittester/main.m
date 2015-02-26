/*
  iOS app that runs D unittests and outputs to a TextView.

  The unittests are started in a separate thread so that the app runloop can
  do its stuff to interact with the user.  D unittest output goes to stdout
  which is captured by redirecting it (fd 1) to a pipe.  The other end of the
  pipe is read by the run loop, put into a UITestView and written on stderr
  so it will show on the Xcode console.

  The end result:
    stdout -> console and UITextView
    stderr -> console

  Everything is contained in this one file.
*/

#import <UIKit/UIKit.h>
#include <pthread.h>

// pipe used to redirect stdout into UITestView
static int pipefd[2];

static void *threadMain(void *arg)
{
    // pthread main for running the D unittests declared in unittest.d
    extern int runUnitTests();

    NSLog(@"Unittest thread has started");
    runUnitTests();
    fclose(stdout);
    return NULL;
}

static bool initUnittestThread()
{
    // Create pipe for stdout and start a thread for running unittests
    NSLog(@"redirect stdout");

    // reassign stdout to a pipe write end
    if (pipe(pipefd) == -1) {
        perror("pipe");
        return false;
    }

    if (dup2(pipefd[1], 1) == -1) {
        perror("dup2");
        return false;
    }

    // close this so stdout is only fd to write end of pipe.  This allows
    // close of stdout to indicate pipe is closed to reader below
    close(pipefd[1]);

    // make line buffered
    setvbuf(stdout, NULL, _IOLBF, 0);

    NSLog(@"creating thread");
    
    pthread_t tid;
    if (pthread_create(&tid, NULL, &threadMain, NULL) != 0) {
        perror("pthread_create");
        return false;
    }
    pthread_detach(tid);

    return true;
}

@interface UnittestViewController : UIViewController
{
    NSMutableString *log;
    UITextView *textView;
}
@end

@implementation UnittestViewController
- (void) loadView
{
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
    
    // A place to save unittest output
    log = [[NSMutableString alloc] initWithCapacity:1024];
    
    // Create a scrolling text view
    textView = [[UITextView alloc] initWithFrame:self.view.frame];
    textView.font = [UIFont fontWithName:@"Futura" size:10.0f];
    textView.editable = NO;
    self.view = textView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!initUnittestThread()) {
        textView.text = @"This is not going as planned";
        return;
    }

    dispatch_source_t readSource =
        dispatch_source_create(DISPATCH_SOURCE_TYPE_READ,
                               pipefd[0],
                               0,
                               dispatch_get_main_queue());
    if (!readSource) {
        textView.text = @"This is not my day";
        NSLog(@"Failed to create source to read from unittest pipe");
        return;
    }
    
    dispatch_source_set_event_handler
    (readSource,
     ^{
         size_t estimated = dispatch_source_get_data(readSource);
         // Read the data into a text buffer.
         char* buffer = (char*)malloc(estimated);

         if (buffer) {
             ssize_t actual = read(pipefd[0], buffer, estimated);
             //NSLog(@"read %ld, estimate %lu\n", actual, estimated);
             fprintf(stderr, "%.*s", (int)actual, buffer);

             if (actual > 0) {
                 [log appendFormat:@"%.*s", (int)actual, buffer];
                 textView.text = log;
                 // There are many ways to scroll textview to bottom, but only
                 // this seems to work correctly on iOS 7
                [textView scrollRangeToVisible:NSMakeRange([textView.text length], 0)];
                [textView setScrollEnabled:NO];
                [textView setScrollEnabled:YES];
             }
             else {
                 dispatch_source_cancel(readSource);
             }
             // Release the buffer when done.
             free(buffer);
         }
     });
    
    // Start reading the file.
    dispatch_resume(readSource);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}
@end

@interface UnittestAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
}
@end

@implementation UnittestAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // This is in libunittest-(release|debug).a
    extern const char *unittest_configname;
    
    UnittestViewController *vc = [[UnittestViewController alloc] init];
    vc.title = [NSString stringWithFormat:@"D runtime/phobos %s Utest",
                         unittest_configname];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];

    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];    
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    return YES;
}
@end

int main(int argc, char *argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, @"UnittestAppDelegate");
    }
}
