//
//  FUIPhoneAuthStyle.h
//  Pods
//
//  Created by Leonardo Passeri on 08/09/21.
//

@interface FUIPhoneEntryStyle : NSObject <NSCopying>

@property(nonatomic, copy, nullable) UIColor *backgroundColor;
@property(nonatomic, copy, nullable) UIColor *navigationBarColor;
@property(nonatomic, copy, nullable) NSString *navigationBarBackText;
@property(nonatomic, copy, nullable) UIImage *navigationBarCancelImage;
@property(nonatomic, copy, nullable) NSString *navigationBarTitleText;
@property(nonatomic, copy, nullable) UIColor *navigationBarTitleColor;
@property(nonatomic, copy, nullable) UIFont *navigationBarTitleFont;
@property(nonatomic, copy, nullable) UIColor *navigationBarTintColor;
@property(nonatomic, copy, nullable) UIColor *textFieldTextColor;
@property(nonatomic, copy, nullable) UIFont *textFieldTextFont;
@property(nonatomic, copy, nullable) UIImage *textFieldDisclosureIndicatorImage;
@property(nonatomic, copy, nullable) UIColor *textFieldBackgroundColor;
@property(nonatomic, copy, nullable) UIColor *textFieldDescriptionColor;
@property(nonatomic, copy, nullable) UIFont *textFieldDescriptionFont;
@property(nonatomic, copy, nullable) UIColor *textFieldPlaceholderColor;
@property(nonatomic, copy, nullable) UIFont *textFieldPlaceholderFont;
@property(nonatomic, copy, nullable) NSString *countryTextFieldDescriptionText;
@property(nonatomic, copy, nullable) NSString *phoneTextFieldDescriptionText;
@property(nonatomic, copy, nullable) NSString *phoneTextFieldPlaceholderText;
@property(nonatomic, copy, nullable) UIImage *nextButtonImage;
@property(nonatomic, copy, nullable) UIImage *nextButtonDisabledImage;
@property(nonatomic, assign) BOOL showPrivacyPolicy;
@property(nonatomic, assign) BOOL showSeparatorView;

@end
