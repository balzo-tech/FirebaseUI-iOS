//
//  FUIPhoneAuthStyle.m
//  FirebasePhoneAuthUI
//
//  Created by Leonardo Passeri on 08/09/21.
//

#import "FirebasePhoneAuthUI/Sources/Public/FirebasePhoneAuthUI/FUIPhoneAuthStyle.h"

@implementation FUIPhoneEntryStyle

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    FUIPhoneEntryStyle *newStyle = [[[self class] allocWithZone: zone] init];
    [newStyle setBackgroundColor:[self backgroundColor]];
    [newStyle setNavigationBarColor:[self navigationBarColor]];
    [newStyle setNavigationBarCancelImage:[self navigationBarCancelImage]];
    [newStyle setNavigationBarBackText:[self navigationBarBackText]];
    [newStyle setNavigationBarTitleText:[self navigationBarTitleText]];
    [newStyle setNavigationBarTitleColor:[self navigationBarTitleColor]];
    [newStyle setNavigationBarTitleFont:[self navigationBarTitleFont]];
    [newStyle setNavigationBarTintColor:[self navigationBarTintColor]];
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
