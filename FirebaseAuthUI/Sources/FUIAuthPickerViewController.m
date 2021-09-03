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

#import "FirebaseAuthUI/Sources/Public/FirebaseAuthUI/FUIAuthPickerViewController.h"

#import <AuthenticationServices/AuthenticationServices.h>
#import <FirebaseAuth/FirebaseAuth.h>

#import "FirebaseAuthUI/Sources/Public/FirebaseAuthUI/FUIAuthBaseViewController_Internal.h"
#import "FirebaseAuthUI/Sources/FUIAuthSignInButton.h"
#import "FirebaseAuthUI/Sources/Public/FirebaseAuthUI/FUIAuthStrings.h"
#import "FirebaseAuthUI/Sources/Public/FirebaseAuthUI/FUIAuthUtils.h"
#import "FirebaseAuthUI/Sources/Public/FirebaseAuthUI/FUIAuth_Internal.h"
#import "FirebaseAuthUI/Sources/Public/FirebaseAuthUI/FUIPrivacyAndTermsOfServiceView.h"
#import "FirebaseAuthUI/Sources/Public/FirebaseAuthUI/FUIAuthStyle.h"

/** @var kSignInButtonHorizontalMargins
    @brief The horizontal margin between sign in buttons and the leading and trailing margins of the content view.
 */
static const CGFloat kSignInButtonHorizontalMargins = 32.0f;

/** @var kSignInButtonHeight
    @brief The height of the sign in buttons.
 */
static const CGFloat kSignInButtonHeight = 44.0f;

/** @var kSignInButtonVerticalMargin
    @brief The vertical margin between sign in buttons.
 */
static const CGFloat kSignInButtonVerticalMargin = 24.0f;

/** @var kButtonContainerBottomMargin
    @brief The magin between sign in buttons and the bottom of the content view.
 */
static const CGFloat kButtonContainerBottomMargin = 48.0f;

/** @var kButtonContainerTopMargin
    @brief The margin between sign in buttons and the top of the content view.
 */
static const CGFloat kButtonContainerTopMargin = 16.0f;

/** @var kTOSViewBottomMargin
    @brief The margin between privacy policy and TOS view and the bottom of the content view.
 */
static const CGFloat kTOSViewBottomMargin = 48.0f;

/** @var kTOSViewHorizontalMargin
    @brief The margin between privacy policy and TOS view and the left or right of the content view.
 */
static const CGFloat kTOSViewHorizontalMargin = 16.0f;

@implementation FUIAuthPickerViewController {
  UIView *_buttonContainerView;

  IBOutlet FUIPrivacyAndTermsOfServiceView *_privacyPolicyAndTOSView;

  IBOutlet UIView *_contentView;

  IBOutlet UIScrollView *_scrollView;
}

- (instancetype)initWithAuthUI:(FUIAuth *)authUI {
  return [self initWithNibName:@"FUIAuthPickerViewController"
                        bundle:[FUIAuthUtils authUIBundle]
                        authUI:authUI];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
                         authUI:(FUIAuth *)authUI {

  self = [super initWithNibName:nibNameOrNil
                         bundle:nibBundleOrNil
                         authUI:authUI];
  if (self) {
    self.title = FUILocalizedString(kStr_AuthPickerTitle);
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // Makes sure that embedded scroll view properly handles translucent navigation bar
  if (!self.navigationController.navigationBar.isTranslucent) {
    self.extendedLayoutIncludesOpaqueBars = true;
  }

  if (!self.authUI.shouldHideCancelButton) {
    UIBarButtonItem *cancelBarButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(cancelAuthorization)];
    self.navigationItem.leftBarButtonItem = cancelBarButton;
  }
  if (@available(iOS 13, *)) {
    if (!self.authUI.interactiveDismissEnabled) {
      self.modalInPresentation = YES;
    }
  }

  self.navigationItem.backBarButtonItem =
      [[UIBarButtonItem alloc] initWithTitle:FUILocalizedString(kStr_Back)
                                       style:UIBarButtonItemStylePlain
                                      target:nil
                                      action:nil];
    
    if (self.authUI.authPickerStyle) {
        self.view.backgroundColor = self.authUI.authPickerStyle.backgroundColor;
        _contentView.backgroundColor = UIColor.clearColor;
    }
    
    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 50;
    [_scrollView addSubview: stackView];
    
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *horizontalConstraint = [NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeTop multiplier:1 constant:170];
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeBottom multiplier:1 constant:100];
    NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeLeading multiplier:1 constant:32];
    NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint constraintWithItem:stackView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:_scrollView attribute:NSLayoutAttributeTrailing multiplier:1 constant:-32];
    [_scrollView addConstraints:@[horizontalConstraint, topConstraint, leadingConstraint, trailingConstraint, bottomConstraint]];
    
    if ([[self.authUI authPickerStyle] headerImage] != nil) {
        UIImageView *headerImageView = [UIImageView new];
        headerImageView.contentMode = UIViewContentModeScaleAspectFit;
        headerImageView.image = [[self.authUI authPickerStyle] headerImage];
        headerImageView.tintColor = [[self.authUI authPickerStyle] headerImageTint];
        [stackView addArrangedSubview: headerImageView];
        
        headerImageView.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:headerImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:92];
        [headerImageView addConstraint: heightConstraint];
    }
    
    if ([[self.authUI authPickerStyle] titleText] != nil) {
        UILabel *titleText = [UILabel new];
        titleText.text = [[self.authUI authPickerStyle] titleText];
        titleText.numberOfLines = 0;
        titleText.textAlignment = NSTextAlignmentCenter;
        titleText.font = [[self.authUI authPickerStyle] titleFont];
        titleText.textColor = [[self.authUI authPickerStyle] titleTextColor];
        [stackView addArrangedSubview: titleText];
    }
    
    UIStackView *buttonsStackView = [UIStackView new];
    buttonsStackView.axis = UILayoutConstraintAxisVertical;
    buttonsStackView.spacing = kSignInButtonVerticalMargin;
    [stackView addArrangedSubview: buttonsStackView];
    
    
    for (id<FUIAuthProvider> providerUI in self.authUI.providers) {
        providerUI.buttonAlignment = FUIButtonAlignmentCenter;
        UIFont *font = [[self.authUI authPickerStyle] signInButtonsFont];
        UIButton *providerButton =
        [[FUIAuthSignInButton alloc] initWithFrame:CGRectZero providerUI:providerUI font: font];
        [providerButton addTarget:self
                           action:@selector(didTapSignInButton:)
                 forControlEvents:UIControlEventTouchUpInside];
        [buttonsStackView addArrangedSubview:providerButton];
        
        providerButton.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:providerButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:44];
        [providerButton addConstraint: heightConstraint];
    }
    
    _privacyPolicyAndTOSView.authUI = self.authUI;
    [_privacyPolicyAndTOSView useFullMessage];
    [_contentView bringSubviewToFront:_privacyPolicyAndTOSView];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  // For backward compatibility. The old auth picker view does not have a scroll view and its
  // customized class put the button container view directly into self.view. The following is the
  // old layout behavior.
  if (!_scrollView) {
    CGFloat distanceFromCenterToBottom =
        CGRectGetHeight(_buttonContainerView.frame) / 2.0f + kButtonContainerBottomMargin + kTOSViewBottomMargin;
    CGFloat centerY = CGRectGetHeight(self.view.bounds) - distanceFromCenterToBottom;
    // Compensate for bounds adjustment if any.
    centerY += self.view.bounds.origin.y;
    _buttonContainerView.center = CGPointMake(self.view.center.x, centerY);
    return;
  }

  CGFloat buttonContainerHeight = CGRectGetHeight(_buttonContainerView.frame);
  CGFloat buttonContainerWidth = CGRectGetWidth(_buttonContainerView.frame);
  CGFloat contentViewHeight = kButtonContainerTopMargin + buttonContainerHeight
      + kButtonContainerBottomMargin + kTOSViewBottomMargin;
  CGFloat contentViewWidth = CGRectGetWidth(self.view.bounds);
  _scrollView.frame = self.view.frame;
  CGFloat scrollViewHeight;
  if (@available(iOS 11.0, *)) {
    scrollViewHeight = CGRectGetHeight(_scrollView.frame) - _scrollView.safeAreaInsets.top;
  } else {
    scrollViewHeight = CGRectGetHeight(_scrollView.frame)
        - CGRectGetHeight(self.navigationController.navigationBar.frame)
        - CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
  }
  CGFloat contentViewY = scrollViewHeight - contentViewHeight;
  if (contentViewY < 0) {
    contentViewY = 0;
  }
  _contentView.frame = CGRectMake(0, contentViewY, contentViewWidth, contentViewHeight);
  _scrollView.contentSize = CGSizeMake(contentViewWidth, contentViewY + contentViewHeight);
  CGFloat buttonContainerLeftMargin = (contentViewWidth - buttonContainerWidth) / 2.0f;
  _buttonContainerView.frame =CGRectMake(buttonContainerLeftMargin,
                                         kButtonContainerTopMargin,
                                         buttonContainerWidth,
                                         buttonContainerHeight);
  CGFloat privacyViewHeight = CGRectGetHeight(_privacyPolicyAndTOSView.frame);
  _privacyPolicyAndTOSView.frame = CGRectMake(kTOSViewHorizontalMargin, contentViewHeight
                                              - privacyViewHeight - kTOSViewBottomMargin,
                                              contentViewWidth - kTOSViewHorizontalMargin*2,
                                              privacyViewHeight);
}

#pragma mark - Actions

- (void)didTapSignInButton:(FUIAuthSignInButton *)button {
  [self.authUI signInWithProviderUI:button.providerUI
           presentingViewController:self
                       defaultValue:nil];
}

@end
