//
//  FUIAuthStyle.h
//  Pods
//
//  Created by Leonardo Passeri on 03/09/21.
//

//#ifndef FUIAuthStyle_h
//#define FUIAuthStyle_h

NS_ASSUME_NONNULL_BEGIN

@interface FUIAuthSignInButtonStyle : NSObject <NSCopying>

@property(nonatomic, copy, nullable) UIColor *textColor;
@property(nonatomic, copy, nullable) UIColor *backgroundColor;

@end

@interface FUIAuthPickerStyle : NSObject <NSCopying>

@property(nonatomic, copy, nullable) UIColor *backgroundColor;
@property(nonatomic, copy, nullable) UIImage *headerImage;
@property(nonatomic, copy, nullable) UIColor *headerImageTint;
@property(nonatomic, copy, nullable) NSString *titleText;
@property(nonatomic, copy, nullable) UIColor *titleTextColor;
@property(nonatomic, copy, nullable) UIFont *titleFont;
@property(nonatomic, copy, nullable) UIFont *signInButtonsFont;
@property(nonatomic, copy, nullable) UIColor *privacyTOSTextColor;
@property(nonatomic, copy, nullable) UIFont *privacyTOSFont;

@end

NS_ASSUME_NONNULL_END

//#endif /* FUIAuthStyle_h */
