//
//  FUIAuthStyle.m
//  FirebaseAuthUI
//
//  Created by Leonardo Passeri on 03/09/21.
//

#import "FirebaseAuthUI/Sources/Public/FirebaseAuthUI/FUIAuthStyle.h"

@implementation FUIAuthSignInButtonStyle

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    FUIAuthSignInButtonStyle *newStyle = [[[self class] allocWithZone: zone] init];
    [newStyle setBackgroundColor:[self backgroundColor]];
    [newStyle setTextColor:[self textColor]];
    return newStyle;
}

@end

@implementation FUIAuthPickerStyle

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    FUIAuthPickerStyle *newStyle = [[[self class] allocWithZone: zone] init];
    [newStyle setBackgroundColor:[self backgroundColor]];
    [newStyle setHeaderImage:[self headerImage]];
    [newStyle setHeaderImageTint:[self headerImageTint]];
    [newStyle setTitleText:[self titleText]];
    [newStyle setTitleTextColor:[self titleTextColor]];
    [newStyle setTitleFont:[self titleFont]];
    [newStyle setSignInButtonsFont:[self signInButtonsFont]];
    [newStyle setPrivacyTOSTextColor:[self privacyTOSTextColor]];
    [newStyle setPrivacyTOSFont:[self privacyTOSFont]];
    return newStyle;
}

@end
