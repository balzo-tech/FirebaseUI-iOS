//
//  FUIPhoneAuthStyle.m
//  FirebasePhoneAuthUI
//
//  Created by Leonardo Passeri on 08/09/21.
//

#import "FirebasePhoneAuthUI/Sources/Public/FirebasePhoneAuthUI/FUIPhoneAuthStyle.h"

@implementation FUIPhoneStyle

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    FUIPhoneStyle *newStyle = [[[self class] allocWithZone: zone] init];
    [newStyle setNavigationBarColor:[self navigationBarColor]];
    [newStyle setNavigationBarCancelImage:[self navigationBarCancelImage]];
    [newStyle setNavigationBarBackText:[self navigationBarBackText]];
    [newStyle setNavigationBarTitleColor:[self navigationBarTitleColor]];
    [newStyle setNavigationBarTitleFont:[self navigationBarTitleFont]];
    [newStyle setNavigationBarTintColor:[self navigationBarTintColor]];
    return newStyle;
}

@end

@implementation FUIPhoneEntryStyle

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    FUIPhoneEntryStyle *newStyle = [[[self class] allocWithZone: zone] init];
    [newStyle setBackgroundColor:[self backgroundColor]];
    [newStyle setNavigationBarTitleText:[self navigationBarTitleText]];
    [newStyle setTextFieldTextColor:[self textFieldTextColor]];
    [newStyle setTextFieldTextFont:[self textFieldTextFont]];
    [newStyle setTextFieldDisclosureIndicatorImage:[self textFieldDisclosureIndicatorImage]];
    [newStyle setTextFieldBackgroundColor:[self textFieldBackgroundColor]];
    [newStyle setTextFieldDescriptionColor:[self textFieldDescriptionColor]];
    [newStyle setTextFieldDescriptionFont:[self textFieldDescriptionFont]];
    [newStyle setTextFieldPlaceholderColor:[self textFieldPlaceholderColor]];
    [newStyle setTextFieldPlaceholderFont:[self textFieldPlaceholderFont]];
    [newStyle setCountryTextFieldDescriptionText:[self countryTextFieldDescriptionText]];
    [newStyle setPhoneTextFieldDescriptionText:[self phoneTextFieldDescriptionText]];
    [newStyle setPhoneTextFieldPlaceholderText:[self phoneTextFieldPlaceholderText]];
    [newStyle setNextButtonImage:[self nextButtonImage]];
    [newStyle setNextButtonDisabledImage:[self nextButtonDisabledImage]];
    [newStyle setShowSeparatorView:[self showSeparatorView]];
    return newStyle;
}

@end

@implementation FUIPhoneVerificationStyle

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    FUIPhoneVerificationStyle *newStyle = [[[self class] allocWithZone: zone] init];
    [newStyle setBackgroundColor:[self backgroundColor]];
    [newStyle setNavigationBarTitleText:[self navigationBarTitleText]];
    [newStyle setInstructionsText:[self instructionsText]];
    [newStyle setInstructionsColor:[self instructionsColor]];
    [newStyle setInstructionsFont:[self instructionsFont]];
    [newStyle setCodeTextFieldColor:[self codeTextFieldColor]];
    [newStyle setPhoneNumberColor:[self phoneNumberColor]];
    [newStyle setPhoneNumberFont:[self phoneNumberFont]];
    [newStyle setResendCounterText:[self resendCounterText]];
    [newStyle setResendCounterColor:[self resendCounterColor]];
    [newStyle setResendCounterFont:[self resendCounterFont]];
    [newStyle setResendCounterUnderlined:[self resendCounterUnderlined]];
    [newStyle setResendButtonText:[self resendButtonText]];
    [newStyle setResendButtonColor:[self resendButtonColor]];
    [newStyle setResendButtonFont:[self resendButtonFont]];
    [newStyle setResendButtonUnderlined:[self resendButtonUnderlined]];
    [newStyle setNextButtonImage:[self nextButtonImage]];
    [newStyle setNextButtonDisabledImage:[self nextButtonDisabledImage]];
    [newStyle setShowPrivacyPolicy:[self showPrivacyPolicy]];
    return newStyle;
}

@end
