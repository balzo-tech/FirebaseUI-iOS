//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "FirebasePhoneAuthUI/Sources/FUIPhoneVerificationViewController.h"

#import <FirebaseAuth/FIRAuthUIDelegate.h>
#import <FirebaseAuth/FIRPhoneAuthProvider.h>
#import <FirebaseAuthUI/FirebaseAuthUI.h>

#import "FirebasePhoneAuthUI/Sources/Public/FirebasePhoneAuthUI/FUIPhoneAuth.h"
#import "FirebasePhoneAuthUI/Sources/Public/FirebasePhoneAuthUI/FUIPhoneAuthStyle.h"
#import "FirebasePhoneAuthUI/Sources/FUICodeField.h"
#import "FirebasePhoneAuthUI/Sources/FUIPhoneAuthStrings.h"
#import "FirebasePhoneAuthUI/Sources/FUIPhoneAuth_Internal.h"
#import "FirebasePhoneAuthUI/Sources/FUIPrivacyAndTermsOfServiceView+PhoneAuth.h"

NS_ASSUME_NONNULL_BEGIN

/** @var kNextButtonAccessibilityID
    @brief The Accessibility Identifier for the @c next button.
 */
static NSString *const kNextButtonAccessibilityID = @"NextButtonAccessibilityID";

static NSTimeInterval FUIDelayInSecondsBeforeShowingResendConfirmationCode = 60;

/** Regex pattern that matches for a TOS style link. For example: [Terms]. */
static NSString *const kLinkPlaceholderPattern = @"\\[([^\\]]+)\\]";

static const CGFloat kNextButtonInset = 16.0f;

@interface FUIPhoneVerificationViewController () <FUICodeFieldDelegate, FIRAuthUIDelegate>
@end

@implementation FUIPhoneVerificationViewController {
  __weak IBOutlet FUICodeField *_codeField;
  __weak IBOutlet UILabel *_resendConfirmationCodeTimerLabel;
  __weak IBOutlet UIButton *_resendCodeButton;
  __weak IBOutlet UILabel *_actionDescriptionLabel;
  __weak IBOutlet UIButton *_phoneNumberButton;
  __weak IBOutlet FUIPrivacyAndTermsOfServiceView *_tosView;
  __weak IBOutlet UIScrollView *_scrollView;
  NSString *_verificationID;
  NSTimer *_resendConfirmationCodeTimer;
  NSTimeInterval _resendConfirmationCodeSeconds;
  NSString *_phoneNumber;
    FUIPhoneVerificationStyle *_phoneVerificationStyle;
    NSLayoutConstraint *_nextButtonBottomConstraint;
    UIButton *_nextButton;
}

- (instancetype)initWithAuthUI:(FUIAuth *)authUI
                verificationID:(NSString *)verificationID
                   phoneNumber:(NSString *)phoneNumber{
  return [self initWithNibName:NSStringFromClass([self class])
                        bundle:[FUIPhoneAuth bundle]
                        authUI:authUI
                verificationID:verificationID
                   phoneNumber:phoneNumber];
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil
                         authUI:(FUIAuth *)authUI
                 verificationID:(NSString *)verificationID
                    phoneNumber:(NSString *)phoneNumber {

  self = [super initWithNibName:nibNameOrNil
                         bundle:nibBundleOrNil
                         authUI:authUI];
  if (self) {
    self.title = [_phoneVerificationStyle navigationBarTitleText] ?: FUIPhoneAuthLocalizedString(kPAStr_VerifyPhoneTitle);
    _verificationID = [verificationID copy];
    _phoneNumber = [phoneNumber copy];

      NSMutableDictionary<NSAttributedStringKey, id> *resendCodeButtonTextAttributes = [NSMutableDictionary new];
      if ([_phoneVerificationStyle resendButtonColor] != nil) {
          [resendCodeButtonTextAttributes setObject:[_phoneVerificationStyle resendButtonColor] forKey:NSForegroundColorAttributeName];
      }
      if ([_phoneVerificationStyle resendButtonFont] != nil) {
          [resendCodeButtonTextAttributes setObject:[_phoneVerificationStyle resendButtonFont] forKey:NSFontAttributeName];
      }
      if (_phoneVerificationStyle != nil && _phoneVerificationStyle.resendButtonUnderlined) {
          [resendCodeButtonTextAttributes setObject:[NSNumber numberWithInt:NSUnderlineStyleSingle] forKey:NSUnderlineStyleAttributeName];
      }
      NSString *resendCodeButtonText = [NSString stringWithFormat:[_phoneVerificationStyle resendButtonText] ?: FUIPhoneAuthLocalizedString(kPAStr_EnterCodeDescription),
                                        @(_codeField.codeLength)];
      
      NSAttributedString *attributedResendCodeButtonText = [[NSAttributedString alloc] initWithString:resendCodeButtonText attributes:resendCodeButtonTextAttributes];
      [_resendCodeButton setAttributedTitle:attributedResendCodeButtonText forState:UIControlStateNormal];
      
    _actionDescriptionLabel.text =
        [NSString stringWithFormat:[_phoneVerificationStyle instructionsText] ?: FUIPhoneAuthLocalizedString(kPAStr_EnterCodeDescription),
             @(_codeField.codeLength)];
      if ([_phoneVerificationStyle instructionsFont]) {
          _actionDescriptionLabel.font = [_phoneVerificationStyle instructionsFont];
      }
      if ([_phoneVerificationStyle instructionsColor]) {
          _actionDescriptionLabel.textColor = [_phoneVerificationStyle instructionsColor];
      }
      
    [_phoneNumberButton setTitle:_phoneNumber forState:UIControlStateNormal];
      if ([_phoneVerificationStyle phoneNumberColor]) {
          [_phoneNumberButton setTitleColor:[_phoneVerificationStyle phoneNumberColor] forState:UIControlStateNormal];
      }
      if ([_phoneVerificationStyle phoneNumberFont]) {
          [[_phoneNumberButton titleLabel] setFont:[_phoneVerificationStyle phoneNumberFont]];
      }

      if ([_phoneVerificationStyle codeTextFieldColor]) {
          _codeField.textColor = [_phoneVerificationStyle codeTextFieldColor];
      }
      
    [_codeField becomeFirstResponder];
    [self startResendTimer];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

    _phoneVerificationStyle = [[self authUI] phoneVerificationStyle];
    
    if ([_phoneVerificationStyle nextButtonImage] == nil) {
        UIBarButtonItem *nextButtonItem =
        [FUIAuthBaseViewController barItemWithTitle:FUIPhoneAuthLocalizedString(kPAStr_Next)
                                             target:self
                                             action:@selector(next)];
        nextButtonItem.accessibilityIdentifier = kNextButtonAccessibilityID;
        self.navigationItem.rightBarButtonItem = nextButtonItem;
    }
        
  _tosView.authUI = self.authUI;
  [_tosView useFooterMessage];
    
    if (_phoneVerificationStyle != nil) {
        [_tosView setHidden:!_phoneVerificationStyle.showPrivacyPolicy];
        if ([_phoneVerificationStyle backgroundColor] != nil) {
            self.view.backgroundColor = _phoneVerificationStyle.backgroundColor;
        }
        if (_phoneVerificationStyle.nextButtonImage != nil) {
            _nextButton = [UIButton new];
            [_nextButton setImage:_phoneVerificationStyle.nextButtonImage forState:UIControlStateNormal];
            if (_phoneVerificationStyle.nextButtonDisabledImage != nil) {
                [_nextButton setImage:_phoneVerificationStyle.nextButtonDisabledImage forState:UIControlStateDisabled];
            }
            [self.view addSubview:_nextButton];
            [_nextButton addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
            _nextButton.translatesAutoresizingMaskIntoConstraints = NO;
            _nextButtonBottomConstraint = [NSLayoutConstraint constraintWithItem:_nextButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:kNextButtonInset];
            NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:_nextButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:-kNextButtonInset];
            [self.view addConstraints:@[_nextButtonBottomConstraint, trailingConstraint]];
        }
    }
    [self setNextButtonEnabled:NO];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self registerForKeyboardNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self unregisterFromNotifications];
}

- (void)entryIsIncomplete {
    [self setNextButtonEnabled:NO];
}

- (void) entryIsCompletedWithCode:(NSString *)code {
    [self setNextButtonEnabled:YES];
}

#pragma mark - Actions
- (IBAction)onResendCode:(id)sender {
  [_codeField clearCodeInput];
  [self startResendTimer];
  [self incrementActivity];
  [_codeField resignFirstResponder];
  FIRPhoneAuthProvider *provider = [FIRPhoneAuthProvider providerWithAuth:self.auth];
  [provider verifyPhoneNumber:_phoneNumber
                   UIDelegate:self
                   completion:^(NSString *_Nullable verificationID, NSError *_Nullable error) {
    // Temporary fix to guarantee execution of the completion block on the main thread.
    // TODO: Remove temporary workaround when the issue is fixed in FirebaseAuth.
    dispatch_block_t completionBlock = ^() {
      [self decrementActivity];
      self->_verificationID = verificationID;
      [self->_codeField becomeFirstResponder];

      if (error) {
        UIAlertController *alertController = [FUIPhoneAuth alertControllerForError:error
                                                                     actionHandler:^{
                                               [self->_codeField clearCodeInput];
                                               [self->_codeField becomeFirstResponder];
                                             }];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
      }

      NSString *resultMessage =
          [NSString stringWithFormat:FUIPhoneAuthLocalizedString(kPAStr_ResendCodeResult),
              self->_phoneNumber];
      [self showAlertWithMessage:resultMessage];
    };
    if ([NSThread isMainThread]) {
      completionBlock();
    } else {
      dispatch_async(dispatch_get_main_queue(), completionBlock);
    }
  }];
}
- (IBAction)onPhoneNumberSelected:(id)sender {
  [self onBack];
}

- (void)next {
  [self onNext:_codeField.codeEntry];
}

- (void)onNext:(NSString *)verificationCode {
  if (!verificationCode.length) {
    [self showAlertWithMessage:FUIPhoneAuthLocalizedString(kPAStr_EmptyVerificationCode)];
    return;
  }

  FIRPhoneAuthProvider *provider = [FIRPhoneAuthProvider providerWithAuth:self.auth];

  FIRAuthCredential *credential =
    [provider credentialWithVerificationID:_verificationID verificationCode:verificationCode];

  [self incrementActivity];
  [_codeField resignFirstResponder];
    [self setNextButtonEnabled:NO];
  FUIPhoneAuth *delegate = [self.authUI providerWithID:FIRPhoneAuthProviderID];
  [delegate callbackWithCredential:credential
                             error:nil
                            result:^(FIRUser *_Nullable user, NSError *_Nullable error) {
    [self decrementActivity];
      [self setNextButtonEnabled:YES];
    if (!error ||
        error.code == FUIAuthErrorCodeUserCancelledSignIn ||
        error.code == FUIAuthErrorCodeMergeConflict) {
      [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
      UIAlertController *alertController = [FUIPhoneAuth alertControllerForError:error
                                                                   actionHandler:^{
                                             [self->_codeField clearCodeInput];
                                             [self->_codeField becomeFirstResponder];
                                           }];
      [self presentViewController:alertController animated:YES completion:nil];
    }
  }];

}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath
                      ofObject:(nullable id)object
                        change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(nullable void *)context {
  if (object == _codeField) {
      [self setNextButtonEnabled:(_codeField.codeEntry.length == _codeField.codeLength)];
  }
}

#pragma mark - Private

- (void)cancelAuthorization {
  NSError *error = [FUIAuthErrorUtils userCancelledSignInError];
  FUIPhoneAuth *delegate = [self.authUI providerWithID:FIRPhoneAuthProviderID];
  [delegate callbackWithCredential:nil
                             error:error
                            result:^(FIRUser *_Nullable user, NSError *_Nullable error) {
    if (!error || error.code == FUIAuthErrorCodeUserCancelledSignIn) {
      [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
      [self showAlertWithMessage:error.localizedDescription];
    }
  }];
}

- (void)startResendTimer {
  _resendConfirmationCodeSeconds = FUIDelayInSecondsBeforeShowingResendConfirmationCode;
  [self updateResendLabel];

  _resendCodeButton.hidden = YES;
  _resendConfirmationCodeTimerLabel.hidden = NO;

  _resendConfirmationCodeTimer =
      [NSTimer scheduledTimerWithTimeInterval:1.0
                                       target:self
                                     selector:@selector(resendConfirmationCodeTick:)
                                     userInfo:nil
                                      repeats:YES];
}

- (void)cleanUpTimer {
  [_resendConfirmationCodeTimer invalidate];
  _resendConfirmationCodeTimer = nil;
  _resendConfirmationCodeSeconds = 0;
  _resendConfirmationCodeTimerLabel.hidden = YES;
}

- (void)resendConfirmationCodeTick:(id)sender {
  _resendConfirmationCodeSeconds -= 1.0;
  if (_resendConfirmationCodeSeconds <= 0){
    _resendConfirmationCodeSeconds = 0;
    [self resendConfirmationCodeTimerFinished];
  }

  [self updateResendLabel];
}

- (void)resendConfirmationCodeTimerFinished {
  [self cleanUpTimer];

  _resendCodeButton.hidden = NO;
}

- (void)updateResendLabel {
  NSInteger minutes = (NSInteger)_resendConfirmationCodeSeconds / 60; // Integer type for truncation
  NSInteger seconds = (NSInteger)round(_resendConfirmationCodeSeconds) % 60;
  NSString *formattedTime = [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];

    NSMutableDictionary<NSAttributedStringKey, id> *resendCodeTimerTextAttributes = [NSMutableDictionary new];
    if ([_phoneVerificationStyle resendCounterColor] != nil) {
        [resendCodeTimerTextAttributes setObject:[_phoneVerificationStyle resendCounterColor] forKey:NSForegroundColorAttributeName];
    }
    if ([_phoneVerificationStyle resendCounterFont] != nil) {
        [resendCodeTimerTextAttributes setObject:[_phoneVerificationStyle resendCounterFont] forKey:NSFontAttributeName];
    }
    if (_phoneVerificationStyle != nil && _phoneVerificationStyle.resendCounterUnderlined) {
        [resendCodeTimerTextAttributes setObject:[NSNumber numberWithInt:NSUnderlineStyleSingle] forKey:NSUnderlineStyleAttributeName];
    }
    
    NSString *resendCodeTimerText = [NSString stringWithFormat:[_phoneVerificationStyle resendCounterText] ?: FUIPhoneAuthLocalizedString(kPAStr_ResendCodeTimer),
                                      formattedTime];
    
    NSAttributedString *attributedResendCodeTimerText = [[NSAttributedString alloc] initWithString:resendCodeTimerText attributes:resendCodeTimerTextAttributes];
    
    _resendConfirmationCodeTimerLabel.attributedText = attributedResendCodeTimerText;
}

- (void)setNextButtonEnabled:(BOOL)enabled {
    self.navigationItem.rightBarButtonItem.enabled = enabled;
    [_nextButton setEnabled:enabled];
}

#pragma mark - UIKeyboard observer methods

- (void)registerForKeyboardNotifications {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWasShown:)
                                               name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillBeHidden:)
                                               name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterFromNotifications {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
  NSDictionary* info = [aNotification userInfo];
  CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  CGFloat topOffset = self.navigationController.navigationBar.frame.size.height +
      [UIApplication sharedApplication].statusBarFrame.size.height;
  
  UIEdgeInsets contentInsets = UIEdgeInsetsMake(topOffset, 0.0, kbSize.height, 0.0);
  
  [UIView beginAnimations:nil context:NULL];
  
  NSDictionary *userInfo = [aNotification userInfo];
  [UIView setAnimationDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
  [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];

  _scrollView.contentInset = contentInsets;
  _scrollView.scrollIndicatorInsets = contentInsets;
  
  [_scrollView scrollRectToVisible:_codeField.frame animated:NO];

  [UIView commitAnimations];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
  UIEdgeInsets contentInsets = UIEdgeInsetsZero;
  CGFloat topOffset = self.navigationController.navigationBar.frame.size.height +
      [UIApplication sharedApplication].statusBarFrame.size.height;
  contentInsets.top = topOffset;

  [UIView beginAnimations:nil context:NULL];
  
  NSDictionary *userInfo = [aNotification userInfo];
  [UIView setAnimationDuration:[userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
  [UIView setAnimationCurve:[userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];

  _scrollView.contentInset = contentInsets;
  _scrollView.scrollIndicatorInsets = contentInsets;

  [UIView commitAnimations];
    
    NSTimeInterval duration = [self keyboardAnimationDurationFromUserInfo:aNotification.userInfo];
    [self keyboardWillHideWithDuration:duration];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (notification.userInfo != nil) {
        
        CGFloat height = [self keyboardHeightFromUserInfo:notification.userInfo];
        NSTimeInterval duration = [self keyboardAnimationDurationFromUserInfo:notification.userInfo];
        [self keyboardWillShowWithHeight:height duration:duration];
    }
}

-(CGFloat) keyboardHeightFromUserInfo:(NSDictionary *)userInfo {
    NSValue *value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    if (value != nil) {
        return [value CGRectValue].size.height;
    } else {
        return 0.0;
    }
}

-(NSTimeInterval) keyboardAnimationDurationFromUserInfo:(NSDictionary *)userInfo {
    NSNumber *value = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    if (value != nil) {
        return [value doubleValue];
    } else {
        return 0.0;
    }
}

- (void)keyboardWillShowWithHeight:(CGFloat)height duration:(NSTimeInterval)duration {
    __weak UIButton *nextButton = _nextButton;
    __weak NSLayoutConstraint *nextButtonBottomConstraint = _nextButtonBottomConstraint;
    __weak UIView *selfView = self.view;
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        if (nextButtonBottomConstraint != nil && nextButton != nil) {
            nextButtonBottomConstraint.constant = -kNextButtonInset - height;
            if (selfView != nil) {
                [selfView layoutIfNeeded];
            }
        }
    } completion: nil];
}

- (void)keyboardWillHideWithDuration:(NSTimeInterval)duration {
    __weak UIButton *nextButton = _nextButton;
    __weak NSLayoutConstraint *nextButtonBottomConstraint = _nextButtonBottomConstraint;
    __weak UIView *selfView = self.view;
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        if (nextButtonBottomConstraint != nil && nextButton != nil) {
            nextButtonBottomConstraint.constant = -kNextButtonInset;
            if (selfView != nil) {
                [selfView layoutIfNeeded];
            }
        }
    } completion: nil];
}

@end

NS_ASSUME_NONNULL_END
