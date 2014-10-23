#import "BUGViewController.h"
#import "BUGPivotalTrackerInterface.h"
#import "MBProgressHUD.h"
#import "FLEXManager.h"

@interface BUGViewController () <UITextViewDelegate, UITextFieldDelegate>

@property (assign, nonatomic, readwrite) BOOL windowIsVisible;
@property (weak, nonatomic, readwrite) UIWindow *originalKeyWindow;
@property (strong, nonatomic, readwrite) UIWindow *window;
@property (strong, nonatomic, readwrite) UIImage *screenShot;
@property (strong, nonatomic, readwrite) BUGPivotalTrackerInterface *trackerInterface;
@property (strong, nonatomic, readwrite) UINavigationController *navigationController;
@property (copy, nonatomic) NSData * (^logFileData)();
@end

BUGViewController  *debugViewController__;

@implementation BUGViewController

static NSString *storyTitlePlaceholderText = @"Bug Title";
static NSString *storyDescriptionPlaceholderText = @"Bug Description";

+ (void)showHideDebugWindow {
    if (!debugViewController__.windowIsVisible) {
        [debugViewController__ captureScreenShot];
        debugViewController__.originalKeyWindow = [UIApplication sharedApplication].keyWindow;
        debugViewController__.window.tintColor = debugViewController__.originalKeyWindow.tintColor;
        [debugViewController__.window makeKeyAndVisible];
        debugViewController__.windowIsVisible = YES;
        debugViewController__.window.alpha = 0;
        [UIView animateWithDuration:.2 animations:^{
            debugViewController__.window.alpha = 1;
        }];
    } else {
        [debugViewController__.view endEditing:YES];
        [debugViewController__.originalKeyWindow makeKeyAndVisible];
        [UIView animateWithDuration:.2 animations:^{
            debugViewController__.window.alpha = 0;
        } completion:^(BOOL finished) {
            [debugViewController__.window setHidden:YES];
            debugViewController__.windowIsVisible = NO;
        }];
    }
}

+ (instancetype)createSharedInstanceWithLogFileData:(NSData * (^)())logData trackerAPIToken:(NSString *)token trackerProjectID:(NSString *)projectID {
    return debugViewController__ = [[BUGViewController alloc] initWithLogFileData:logData trackerAPIToken:token trackerProjectID:projectID];
}

+ (instancetype)sharedInstance {
    if (!debugViewController__) {
        [NSException raise:@"BUGViewController" format:@"The BUGViewController must first be created with createSharedInstanceWithLogFileData:trackerAPIToken:trackerProjectID:"];
    }
    return debugViewController__;
}

- (instancetype)initWithLogFileData:(NSData * (^)())logData trackerAPIToken:(NSString *)token trackerProjectID:(NSString *)projectID {
    if (self = [super init]) {
        self.trackerInterface = [[BUGPivotalTrackerInterface alloc] initWithAPIToken:token trackerProjectID:projectID];
        self.title = @"Debug";
        self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        self.window.windowLevel = UIWindowLevelStatusBar;
        self.navigationController = [[UINavigationController alloc] initWithRootViewController:self];
        self.window.rootViewController = self.navigationController;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Submit" style:UIBarButtonItemStylePlain target:self action:@selector(didTapSubmitButton)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(didTapCancelButton)];
        [self configureBarButtonItems];
        self.logFileData = logData;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.storyTitleTextView.editable = YES;
    self.storyTitleTextView.backgroundColor = [UIColor whiteColor];
    self.storyTitleTextView.layer.borderColor = [self lightGreyColor].CGColor;
    self.storyTitleTextView.layer.borderWidth = 1;
    self.storyTitleTextView.layer.cornerRadius = 4;
    
    self.storyDescriptionTextView.editable = YES;
    self.storyDescriptionTextView.backgroundColor = [UIColor whiteColor];
    self.storyDescriptionTextView.layer.borderColor = [self lightGreyColor].CGColor;
    self.storyDescriptionTextView.layer.borderWidth = 1;
    self.storyDescriptionTextView.layer.cornerRadius = 4;

    self.flexButton.layer.borderColor = self.flexButton.tintColor.CGColor;
    self.flexButton.layer.borderWidth = 1.0f;
    self.flexButton.layer.cornerRadius = 6.0f;
    self.flexButton.backgroundColor = [UIColor whiteColor];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.945 green:0.953 blue:0.957 alpha:1.0];
    
    [self configureTextFontAndColor];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureDidRecognize:)];
    gesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:gesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [self setDefaultViewConfiguration];
}

- (void)viewDidLayoutSubviews {
    if (self.scrollView.contentInset.top > 0) {
        self.scrollView.contentInset = UIEdgeInsetsZero;
    }
}

- (void)configureBarButtonItems {
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:17.0f]} forState:UIControlStateNormal];
    [self.navigationItem.leftBarButtonItem setTitleTextAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17.0f]} forState:UIControlStateNormal];
}

- (void)configureTextFontAndColor {
    self.trackerTitleLabel.font = [UIFont systemFontOfSize:19];
    self.trackerTitleLabel.textColor = [self darkGreyColor];
    
    self.attachmentsLabel.font = [UIFont systemFontOfSize:17];
    self.attachmentsLabel.textColor = [self darkGreyColor];
    
    self.screenShotAttachmentLabel.font = [UIFont systemFontOfSize:17];
    self.screenShotAttachmentLabel.textColor = [self darkGreyColor];
    
    self.logsAttachmentLabel.font = [UIFont systemFontOfSize:17];
    self.logsAttachmentLabel.textColor = [self darkGreyColor];
    
    self.storyTitleTextView.font = [UIFont systemFontOfSize:14];
    self.storyTitleTextView.textColor = [self darkGreyColor];
    
    self.storyDescriptionTextView.font = [UIFont systemFontOfSize:14];
    self.storyDescriptionTextView.textColor = [self darkGreyColor];
    
    self.storyTitlePlaceholderLabel.font = [UIFont systemFontOfSize:14];
    self.storyTitlePlaceholderLabel.textColor = [self lightGreyColor];
    
    self.storyDescriptionPlaceholderLabel.font = [UIFont systemFontOfSize:14];
    self.storyDescriptionPlaceholderLabel.textColor = [self lightGreyColor];
    
    self.requestorNameTextField.font = [UIFont systemFontOfSize:14];
    self.requestorNameTextField.textColor = [self darkGreyColor];
    
    self.flexButton.titleLabel.font = [UIFont systemFontOfSize:22.0];
}

- (void)setDefaultViewConfiguration {
    self.storyTitleTextView.text = nil;
    self.storyDescriptionTextView.text = nil;
    self.storyTitlePlaceholderLabel.text = storyTitlePlaceholderText;
    self.storyDescriptionPlaceholderLabel.text = storyDescriptionPlaceholderText;
    self.attachLogsSwitch.on = NO;
    self.attachScreenShotSwitch.on = NO;
    self.requestorNameTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"humbug.requestorsName"];
}

- (UIColor *)darkGreyColor {
    return [UIColor colorWithRed:43/255.f green:44/255.f blue:44/255.f alpha:1.f];
}

- (UIColor *)lightGreyColor {
    return [UIColor colorWithRed:140/255.f green:146/255.f blue:153/255.f alpha:1.f];
}

#pragma mark - Tracker Story Creation

- (BOOL)validateStory {
    if ([self.storyTitleTextView.text isEqualToString:@""]) {
        [[[UIAlertView alloc] initWithTitle:@"Bugs need names" message:@"Please add a descriptive title." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [self.storyTitleTextView becomeFirstResponder];
        return NO;
    } else if ([self.requestorNameTextField.text isEqualToString:@""]) {
        [[[UIAlertView alloc] initWithTitle:@"Requestor" message:@"Please provide your name." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [self.requestorNameTextField becomeFirstResponder];
        return NO;
    }
    return YES;
}

- (void)validateTextLenghtForTextField:(UITextView *)textView {
    if (textView == self.storyTitleTextView && textView.text.length > 5000) {
        textView.text = [textView.text substringToIndex:5000];
    } else if (textView == self.storyDescriptionTextView && textView.text.length > 20000) {
        textView.text = [textView.text substringToIndex:20000];
    }
}

- (void)createStory {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    NSData *imageData;
    if (self.attachScreenShotSwitch.on) { imageData = UIImagePNGRepresentation(self.screenShot); }
    
    NSData *logData;
    if (self.attachLogsSwitch.on) {
        if (self.logFileData) {
            logData = self.logFileData();
        }
    }

    NSString *descriptionText = [NSString stringWithFormat:@"%@\r\n%@\r\n%@\r\n\r\n%@", [self requestorName], [self currentDateAndTime], [self appVersionInfo], self.storyDescriptionTextView.text];

    __weak __typeof(self)weakSelf = self;
    [self.trackerInterface createStoryWithStoryTitle:self.storyTitleTextView.text storyDescription:descriptionText image:imageData text:logData completion:^(BOOL success, NSError *error) {
        if (success) {
            [weakSelf setDefaultViewConfiguration];
            hud.labelText = @"Success";
            if (self.windowIsVisible) {
                [BUGViewController showHideDebugWindow];
            }
        } else {
            hud.labelText = @"Failed";
        }
        [hud hide:YES afterDelay:.75];
    }];
}

- (void)captureScreenShot {
    if ([[UIApplication sharedApplication].keyWindow respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        UIGraphicsBeginImageContextWithOptions([UIApplication sharedApplication].keyWindow.frame.size, YES, 0.0);
        if ([[UIApplication sharedApplication].keyWindow drawViewHierarchyInRect:[UIApplication sharedApplication].keyWindow.frame afterScreenUpdates:NO]) {
            self.screenShot = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
    }
}

- (NSString *)appVersionInfo {
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *version = [bundleInfo objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [bundleInfo objectForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:@"Version: %@ (%@)", version, buildNumber];
}

- (NSString *)currentDateAndTime {
    NSString *dateAndTime = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    return [NSString stringWithFormat:@"Date: %@", dateAndTime];
}

- (NSString *)requestorName {
    return [NSString stringWithFormat:@"Requestor: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"humbug.requestorsName"]];
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [self.scrollView scrollRectToVisible:textView.frame animated:YES];
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView == self.storyTitleTextView) {
        if ([textView.text isEqual:@""]) {
            self.storyTitlePlaceholderLabel.text = storyTitlePlaceholderText;
        } else {
            self.storyTitlePlaceholderLabel.text = nil;
            [self validateTextLenghtForTextField:textView];
        }
    } else if (textView == self.storyDescriptionTextView) {
        if ([textView.text isEqual:@""]) {
            self.storyDescriptionPlaceholderLabel.text = storyDescriptionPlaceholderText;
        } else {
            self.storyDescriptionPlaceholderLabel.text = nil;
            [self validateTextLenghtForTextField:textView];
        }
    }
}

#pragma mark - UITextFieldDelegate protocol

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [self.scrollView scrollRectToVisible:textField.frame animated:YES];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.requestorNameTextField) {
        [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:@"humbug.requestorsName"];
    }
}

#pragma mark - Keyboard Handling

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    CGFloat keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    NSTimeInterval animationDuration = ((NSNumber *)notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue;
    UIViewAnimationCurve animationCurve = ((NSNumber *)notification.userInfo[UIKeyboardAnimationCurveUserInfoKey]).integerValue;

    if (animationDuration <= 0) {
        animationDuration = .25;
    }

    __weak __typeof(self)weakSelf = self;
    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:(animationCurve << 16) // From UIView.h
                     animations:^{
                         UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardHeight, 0.0);
                         weakSelf.scrollView.contentInset = contentInsets;
                         weakSelf.scrollView.scrollIndicatorInsets = contentInsets;
                         [weakSelf.scrollView scrollRectToVisible:[weakSelf firstResponder].frame animated:NO];
                     } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSTimeInterval animationDuration = ((NSNumber *)notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue;
    UIViewAnimationCurve animationCurve = ((NSNumber *)notification.userInfo[UIKeyboardAnimationCurveUserInfoKey]).integerValue;
    __weak __typeof(self)weakSelf = self;
    [UIView animateWithDuration:animationDuration
                          delay:0.0
                        options:(animationCurve << 16) // From UIView.h
                     animations:^{
                         UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
                         weakSelf.scrollView.contentInset = contentInsets;
                         weakSelf.scrollView.scrollIndicatorInsets = contentInsets;
                         [weakSelf.contentView layoutIfNeeded];
                     } completion:nil];
}

- (UIView *)firstResponder {
    for (UIView *view in self.contentView.subviews) {
        if ([view isFirstResponder]) {
            return view;
        }
    }
    return nil;
}

#pragma mark - Target Action

- (void)didTapSubmitButton {
    [self.view endEditing:YES];
    if ([self validateStory]) {
        [self createStory];
    }
}

- (void)didTapCancelButton {
    [self.view endEditing:YES];
    [BUGViewController showHideDebugWindow];
    [self setDefaultViewConfiguration];
    [self.trackerInterface cancel];
}

- (IBAction)didTapFlexButton:(id)sender {
    if ([FLEXManager sharedManager].isHidden) {
        [[FLEXManager sharedManager] showExplorer];
    } else {
        [[FLEXManager sharedManager] hideExplorer];
    }
}

- (IBAction)didToggleSwitch:(id)sender {
    [self.view endEditing:YES];
}

- (void)tapGestureDidRecognize:(UITapGestureRecognizer *)recognizer {
    [self.view endEditing:YES];
}

@end
