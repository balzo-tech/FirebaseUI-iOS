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

#import "FirebasePhoneAuthUI/Sources/FUIPhoneEntryViewController.h"

#import <FirebaseAuth/FirebaseAuth.h>
#import <FirebaseAuth/FIRAuthUIDelegate.h>
#import <FirebaseAuth/FIRPhoneAuthProvider.h>
#import <FirebaseAuthUI/FirebaseAuthUI.h>

#import "FirebasePhoneAuthUI/Sources/Public/FirebasePhoneAuthUI/FUIPhoneAuth.h"
#import "FirebasePhoneAuthUI/Sources/Public/FirebasePhoneAuthUI/FUIPhoneAuthStyle.h"
#import "FirebasePhoneAuthUI/Sources/FUICountryTableViewController.h"
#import "FirebasePhoneAuthUI/Sources/FUIFeatureSwitch.h"
#import "FirebasePhoneAuthUI/Sources/FUIPhoneAuthStrings.h"
#import "FirebasePhoneAuthUI/Sources/FUIPhoneAuth_Internal.h"
#import "FirebasePhoneAuthUI/Sources/FUIPhoneNumber.h"
#import "FirebasePhoneAuthUI/Sources/FUIPhoneVerificationViewController.h"
#import "FirebasePhoneAuthUI/Sources/FUIPrivacyAndTermsOfServiceView+PhoneAuth.h"


NS_ASSUME_NONNULL_BEGIN

NS_ENUM(NSInteger, FUIPhoneEntryRow) {
  FUIPhoneEntryRowCountrySelector = 0,
  FUIPhoneEntryRowPhoneNumber
};

/** @var kCellReuseIdentifier
    @brief The reuse identifier for table view cell.
 */
static NSString *const kCellReuseIdentifier = @"cellReuseIdentifier";

/** @var kPhoneNumberCellAccessibilityID
    @brief The Accessibility Identifier for the phone number cell.
 */
static NSString *const kPhoneNumberCellAccessibilityID = @"PhoneNumberCellAccessibilityID";

/** @var kNextButtonAccessibilityID
    @brief The Accessibility Identifier for the @c next button.
 */
static NSString *const kNextButtonAccessibilityID = @"NextButtonAccessibilityID";

static const CGFloat kNextButtonInset = 16.0f;

@interface FUIPhoneEntryViewController () <UITextFieldDelegate,
                                           UITabBarDelegate,
                                           UITableViewDataSource,
                                           FUICountryTableViewDelegate,
                                           FIRAuthUIDelegate>
@end

@implementation FUIPhoneEntryViewController  {
  /** @var _phoneNumberField
      @brief The @c UITextField that user enters phone number.
   */
  UITextField *_phoneNumberField;
  UITextField *_countryCodeField;
  FUICountryCodeInfo *_selectedCountryCode;
  __weak IBOutlet UITableView *_tableView;
  __weak IBOutlet FUIPrivacyAndTermsOfServiceView *_tosView;
  FUICountryCodes *_countryCodes;
  FUIPhoneNumber *_phoneNumber;
    FUIPhoneStyle *_phoneStyle;
    FUIPhoneEntryStyle *_phoneEntryStyle;
    NSLayoutConstraint *_nextButtonBottomConstraint;
    UIButton *_nextButton;
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil
                         authUI:(FUIAuth *)authUI {
  return [self initWithNibName:nibNameOrNil
                        bundle:nibBundleOrNil
                        authUI:authUI
                   phoneNumber:nil
                  countryCodes:nil];
}

- (instancetype)initWithAuthUI:(FUIAuth *)authUI {
  return [self initWithNibName:NSStringFromClass([self class])
                        bundle:[FUIPhoneAuth bundle]
                        authUI:authUI
                   phoneNumber:nil
                  countryCodes:nil];
}

- (instancetype)initWithAuthUI:(FUIAuth *)authUI
                   phoneNumber:(nullable NSString *)phoneNumber
                  countryCodes:(nullable FUICountryCodes *)countryCodes {
  return [self initWithNibName:NSStringFromClass([self class])
                        bundle:[FUIPhoneAuth bundle]
                        authUI:authUI
                   phoneNumber:phoneNumber
                  countryCodes:countryCodes];
}

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil
                         authUI:(FUIAuth *)authUI
                    phoneNumber:(nullable NSString *)phoneNumber
                   countryCodes:(nullable FUICountryCodes *)countryCodes {

  self = [super initWithNibName:nibNameOrNil
                         bundle:nibBundleOrNil
                         authUI:authUI];
  if (self) {
      self.title = [_phoneEntryStyle navigationBarTitleText] ?: FUIPhoneAuthLocalizedString(kPAStr_EnterPhoneTitle);
    _countryCodes = countryCodes ?: [[FUICountryCodes alloc] init];
    if (phoneNumber.length) {
      _phoneNumber = [[FUIPhoneNumber alloc] initWithNormalizedPhoneNumber:phoneNumber
                                                              countryCodes:_countryCodes];
    }
    _selectedCountryCode = _phoneNumber.countryCode ?:
        [_countryCodes defaultCountryCodeInfo];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
    
    _phoneStyle = [[self authUI] phoneStyle];
    _phoneEntryStyle = [[self authUI] phoneEntryStyle];
    
    if ([_phoneEntryStyle nextButtonImage] == nil) {
        UIBarButtonItem *nextButtonItem =
        [FUIAuthBaseViewController barItemWithTitle:FUIPhoneAuthLocalizedString(kPAStr_Verify)
                                             target:self
                                             action:@selector(next)];
        nextButtonItem.accessibilityIdentifier = kNextButtonAccessibilityID;
        self.navigationItem.rightBarButtonItem = nextButtonItem;
    }

  NSString *backLabel = [_phoneStyle navigationBarBackText] ?: FUIPhoneAuthLocalizedString(kPAStr_Back);
  UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:backLabel
                                                               style:UIBarButtonItemStylePlain
                                                              target:nil
                                                              action:nil];
  [self.navigationItem setBackBarButtonItem:backItem];
  _tosView.authUI = self.authUI;
  [_tosView useFullMessageWithSMSRateTerm];

  [self enableDynamicCellHeightForTableView:_tableView];
    
    if (_phoneEntryStyle != nil) {
        [_tosView setHidden:!_phoneEntryStyle.showPrivacyPolicy];
        if ([_phoneEntryStyle backgroundColor] != nil) {
            self.view.backgroundColor = _phoneEntryStyle.backgroundColor;
            _tableView.backgroundColor = _phoneEntryStyle.backgroundColor;
        }
        if (_phoneEntryStyle.showSeparatorView == NO) {
            _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        }
        if (_phoneEntryStyle.nextButtonImage != nil) {
            _nextButton = [UIButton new];
            [_nextButton setImage:_phoneEntryStyle.nextButtonImage forState:UIControlStateNormal];
            if (_phoneEntryStyle.nextButtonDisabledImage != nil) {
                [_nextButton setImage:_phoneEntryStyle.nextButtonDisabledImage forState:UIControlStateDisabled];
            }
            [self.view addSubview:_nextButton];
            [_nextButton addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchUpInside];
            _nextButton.translatesAutoresizingMaskIntoConstraints = NO;
            _nextButtonBottomConstraint = [NSLayoutConstraint constraintWithItem:_nextButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:kNextButtonInset];
            NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:_nextButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:-kNextButtonInset];
            [self.view addConstraints:@[_nextButtonBottomConstraint, trailingConstraint]];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if (self.navigationController.viewControllers.firstObject == self) {
    if (self.authUI.providers.count != 1){
        UIBarButtonItem *cancelBarButton;
        if ([_phoneStyle navigationBarCancelImage] != nil) {
            cancelBarButton = [[UIBarButtonItem alloc] initWithImage:_phoneStyle.navigationBarCancelImage style:UIBarButtonItemStylePlain target:self action:@selector(cancelAuthorization)];
        } else {
            cancelBarButton = [[UIBarButtonItem alloc] initWithTitle:[_phoneStyle navigationBarBackText] ?: FUILocalizedString(kStr_Back)
                                           style:UIBarButtonItemStylePlain
                                          target:self
                                          action:@selector(cancelAuthorization)];
        }
      self.navigationItem.leftBarButtonItem = cancelBarButton;
    } else if (!self.authUI.shouldHideCancelButton) {
        UIBarButtonItem *cancelBarButton;
        if ([_phoneStyle navigationBarCancelImage] != nil) {
            cancelBarButton = [[UIBarButtonItem alloc] initWithImage:_phoneStyle.navigationBarCancelImage style:UIBarButtonItemStylePlain target:self action:@selector(cancelAuthorization)];
        } else {
            cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(cancelAuthorization)];
        }
        self.navigationItem.leftBarButtonItem = cancelBarButton;
    }
    self.navigationItem.backBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:[_phoneStyle navigationBarBackText] ?: FUILocalizedString(kStr_Back)
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];

    if (@available(iOS 13, *)) {
      if (!self.authUI.isInteractiveDismissEnabled) {
        self.modalInPresentation = YES;
      }
    }
      if ([_phoneStyle navigationBarColor] != nil) {
          [self.navigationController.navigationBar setTranslucent: NO];
          self.navigationController.navigationBar.backgroundColor = _phoneStyle.navigationBarColor;
          self.navigationController.navigationBar.barTintColor = _phoneStyle.navigationBarColor;
      }
      if ([_phoneStyle navigationBarTintColor] != nil) {
          self.navigationController.navigationBar.tintColor = _phoneStyle.navigationBarTintColor;
      }
      NSMutableDictionary<NSAttributedStringKey, id> *titleTextAttributes = [NSMutableDictionary new];
      if ([_phoneStyle navigationBarTitleColor] != nil) {
          [titleTextAttributes setObject:[_phoneStyle navigationBarTitleColor] forKey:NSForegroundColorAttributeName];
      }
      if ([_phoneStyle navigationBarTitleFont] != nil) {
          [titleTextAttributes setObject:[_phoneStyle navigationBarTitleFont] forKey:NSFontAttributeName];
      }
      self.navigationController.navigationBar.titleTextAttributes = titleTextAttributes;
  }
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Actions

- (void)next {
  [self onNext:_phoneNumberField.text];
}

- (void)onNext:(NSString *)phoneNumber {
  if (!phoneNumber.length) {
    [self showAlertWithMessage:FUIPhoneAuthLocalizedString(kPAStr_EmptyPhoneNumber)];
    return;
  }

  [_phoneNumberField resignFirstResponder];
  [self incrementActivity];
    [self setNextButtonEnabled: NO];
  FIRPhoneAuthProvider *provider = [FIRPhoneAuthProvider providerWithAuth:self.auth];
  NSString *selectedCountryCodeString =
    [NSString stringWithFormat:@"+%@", _selectedCountryCode.dialCode];
  BOOL isPhoneNumberAlreadyPrefixed = [phoneNumber hasPrefix:selectedCountryCodeString];
  NSString *phoneNumberWithCountryCode;
  if (isPhoneNumberAlreadyPrefixed) {
    phoneNumberWithCountryCode = phoneNumber;
  } else {
    phoneNumberWithCountryCode =
        [NSString stringWithFormat:@"%@%@", selectedCountryCodeString, phoneNumber];
  }
  [provider verifyPhoneNumber:phoneNumberWithCountryCode
                   UIDelegate:self
                   completion:^(NSString *_Nullable verificationID, NSError *_Nullable error) {
    // Temporary fix to guarantee execution of the completion block on the main thread.
    // TODO: Remove temporary workaround when the issue is fixed in FirebaseAuth.
    dispatch_block_t completionBlock = ^() {
      [self decrementActivity];
        [self setNextButtonEnabled: YES];

      if (error) {
        [self->_phoneNumberField becomeFirstResponder];

        UIAlertController *alertController = [FUIPhoneAuth alertControllerForError:error
                                                                     actionHandler:nil];
        [self presentViewController:alertController animated:YES completion:nil];
        
        FUIPhoneAuth *delegate = [self.authUI providerWithID:FIRPhoneAuthProviderID];
        [delegate callbackWithCredential:nil error:error result:nil];
        return;
      }

      UIViewController *controller =
          [[FUIPhoneVerificationViewController alloc] initWithAuthUI:self.authUI
                                                      verificationID:verificationID
                                                         phoneNumber:phoneNumberWithCountryCode];

      [self pushViewController:controller];
    };
    if ([NSThread isMainThread]) {
      completionBlock();
    } else {
      dispatch_async(dispatch_get_main_queue(), completionBlock);
    }
  }];
}

- (void)onBack {
  [super onBack];
}

- (void)textFieldDidChange {
  [self didChangePhoneNumber:_phoneNumberField.text];
}

- (void)didChangePhoneNumber:(NSString *)phoneNumber {
    [self setNextButtonEnabled: (phoneNumber.length > 0)];
}

- (void)setNextButtonEnabled:(BOOL)enabled {
    self.navigationItem.rightBarButtonItem.enabled = enabled;
    [_nextButton setEnabled:enabled];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (notification.userInfo != nil) {
        
        CGFloat height = [self keyboardHeightFromUserInfo:notification.userInfo];
        NSTimeInterval duration = [self keyboardAnimationDurationFromUserInfo:notification.userInfo];
        [self keyboardWillShowWithHeight:height duration:duration];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (notification.userInfo != nil) {
        
        NSTimeInterval duration = [self keyboardAnimationDurationFromUserInfo:notification.userInfo];
        [self keyboardWillHideWithDuration:duration];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  FUIAuthTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier];
  if (!cell) {
    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([FUIAuthTableViewCell class])
                                    bundle:[FUIAuthUtils authUIBundle]];
    [tableView registerNib:cellNib forCellReuseIdentifier:kCellReuseIdentifier];
    cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier];
  }
  if (indexPath.row == FUIPhoneEntryRowCountrySelector) {
      if ([_phoneEntryStyle textFieldBackgroundColor] != nil) {
          cell.backgroundColor = [_phoneEntryStyle textFieldBackgroundColor];
      }
    cell.label.text = [_phoneEntryStyle countryTextFieldDescriptionText] ?: FUIPhoneAuthLocalizedString(kPAStr_Country);
      if ([_phoneEntryStyle textFieldDescriptionColor] != nil) {
          cell.label.textColor = [_phoneEntryStyle textFieldDescriptionColor];
      }
      if ([_phoneEntryStyle textFieldDescriptionFont] != nil) {
          cell.label.font = [_phoneEntryStyle textFieldDescriptionFont];
      }
      if ([_phoneEntryStyle textFieldTextColor] != nil) {
          cell.textField.textColor = [_phoneEntryStyle textFieldTextColor];
      }
      if ([_phoneEntryStyle textFieldTextFont] != nil) {
          cell.textField.font = [_phoneEntryStyle textFieldTextFont];
      }
    cell.textField.enabled = NO;
      if ([_phoneEntryStyle textFieldDisclosureIndicatorImage] != nil) {
          cell.accessoryView = [[UIImageView alloc] initWithImage:[_phoneEntryStyle textFieldDisclosureIndicatorImage]];
      }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    _countryCodeField = cell.textField;
    [self setCountryCodeValue];
  } else if (indexPath.row == FUIPhoneEntryRowPhoneNumber) {
      if ([_phoneEntryStyle textFieldBackgroundColor] != nil) {
          cell.backgroundColor = [_phoneEntryStyle textFieldBackgroundColor];
      }
    cell.accessoryType = UITableViewCellAccessoryNone;
      cell.label.text = [_phoneEntryStyle phoneTextFieldDescriptionText] ?: FUIPhoneAuthLocalizedString(kPAStr_PhoneNumber);
      if ([_phoneEntryStyle textFieldDescriptionColor] != nil) {
          cell.label.textColor = [_phoneEntryStyle textFieldDescriptionColor];
      }
      if ([_phoneEntryStyle textFieldDescriptionFont] != nil) {
          cell.label.font = [_phoneEntryStyle textFieldDescriptionFont];
      }
      if ([_phoneEntryStyle textFieldTextColor] != nil) {
          cell.textField.textColor = [_phoneEntryStyle textFieldTextColor];
      }
      if ([_phoneEntryStyle textFieldTextFont] != nil) {
          cell.textField.font = [_phoneEntryStyle textFieldTextFont];
      }
    cell.textField.enabled = YES;
    cell.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
      NSMutableDictionary<NSAttributedStringKey, id> *placeholderTextAttributes = [NSMutableDictionary new];
      if ([_phoneEntryStyle textFieldPlaceholderColor] != nil) {
          [placeholderTextAttributes setObject:[_phoneEntryStyle textFieldPlaceholderColor] forKey:NSForegroundColorAttributeName];
      }
      if ([_phoneEntryStyle textFieldPlaceholderFont] != nil) {
          [placeholderTextAttributes setObject:[_phoneEntryStyle textFieldPlaceholderFont] forKey:NSFontAttributeName];
      }
      NSString *placeholderText = [_phoneEntryStyle phoneTextFieldPlaceholderText] ?: FUIPhoneAuthLocalizedString(kPAStr_EnterYourPhoneNumber);
      cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText attributes:placeholderTextAttributes];
    cell.textField.delegate = self;
    cell.accessibilityIdentifier = kPhoneNumberCellAccessibilityID;
    _phoneNumberField = cell.textField;
    _phoneNumberField.secureTextEntry = NO;
    _phoneNumberField.autocorrectionType = UITextAutocorrectionTypeNo;
    _phoneNumberField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _phoneNumberField.returnKeyType = UIReturnKeyNext;
    _phoneNumberField.keyboardType = UIKeyboardTypeNumberPad;
    if (@available(iOS 10.0, *)) {
      _phoneNumberField.textContentType = UITextContentTypeTelephoneNumber;
    }
    [_phoneNumberField becomeFirstResponder];
    if (_phoneNumber) {
      _phoneNumberField.text = _phoneNumber.rawPhoneNumber;
    } else {
      _phoneNumberField.text = nil;
    }
    [cell.textField addTarget:self
                       action:@selector(textFieldDidChange)
             forControlEvents:UIControlEventEditingChanged];
    [self didChangePhoneNumber:_phoneNumberField.text];
  }
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row == FUIPhoneEntryRowCountrySelector) {
    FUICountryTableViewController* countryTableViewController =
        [[FUICountryTableViewController alloc] initWithCountryCodes:_countryCodes];
    countryTableViewController.delegate = self;
    [self.navigationController pushViewController:countryTableViewController animated:YES];
  }
}
- (nullable id<FUIAuthProvider>)bestProviderFromProviderIDs:(NSArray<NSString *> *)providerIDs {
  NSArray<id<FUIAuthProvider>> *providers = self.authUI.providers;
  for (NSString *providerID in providerIDs) {
    for (id<FUIAuthProvider> provider in providers) {
      if ([providerID isEqual:provider.providerID]) {
        return provider;
      }
    }
  }
  return nil;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField == _phoneNumberField) {
    [self onNext:_phoneNumberField.text];
  }
  return NO;
}

#pragma mark - CountryCodeDelegate

- (void)didSelectCountry:(FUICountryCodeInfo*)countryCodeInfo {
  _selectedCountryCode = countryCodeInfo;
  [self setCountryCodeValue];
  [_tableView reloadData];
}

- (void)setCountryCodeValue {
  NSString *countruCode;
  if ([FUIFeatureSwitch isCountryFlagEmojiEnabled]) {
    NSString *countryFlag = [_selectedCountryCode countryFlagEmoji];
    countruCode = [NSString stringWithFormat:@"%@ +%@ (%@)", countryFlag,
                      _selectedCountryCode.dialCode, _selectedCountryCode.localizedCountryName];
  } else {
    countruCode = [NSString stringWithFormat:@"+%@ (%@)", _selectedCountryCode.dialCode,
                      _selectedCountryCode.localizedCountryName];
  }
  _countryCodeField.text = countruCode;
}

#pragma mark - Private

- (void)cancelAuthorization {
  NSError *error = [FUIAuthErrorUtils userCancelledSignInError];
  FUIPhoneAuth *delegate = [self.authUI providerWithID:FIRPhoneAuthProviderID];
  [delegate callbackWithCredential:nil error:error result:^(FIRUser *_Nullable user,
                                                            NSError *_Nullable error) {
    if (!error || error.code == FUIAuthErrorCodeUserCancelledSignIn) {
      [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
      [self showAlertWithMessage:error.localizedDescription];
    }
  }];
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
