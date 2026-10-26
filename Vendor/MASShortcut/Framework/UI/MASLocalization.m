#import "MASLocalization.h"
#import "MASShortcut.h"

static NSString *const MASLocalizationTableName = @"Localizable";
static NSString *const MASPlaceholderLocalizationString = @"XXX";

// The CocoaPods trickery here is needed because when the code
// is built as a part of CocoaPods, it won’t make a separate framework
// and the Localized.strings file won’t be bundled correctly.
// See https://github.com/shpakovski/MASShortcut/issues/74
NSString *MASLocalizedString(NSString *key, NSString *comment) {
    static NSBundle *localizationBundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        #if SWIFT_PACKAGE
            // Rectangle Ultra: SwiftPM only looks at the .app root (codesign forbids files there) and an
            // absolute .build path. Look in Contents/Resources first, and never return nil: a nil bundle gives
            // nil strings, and [NSString stringWithFormat:nil] throws.
            NSURL *resourcesURL = [[NSBundle mainBundle] URLForResource:@"MASShortcut_MASShortcut" withExtension:@"bundle"];
            localizationBundle = (resourcesURL ? [NSBundle bundleWithURL:resourcesURL] : nil)
                ?: SWIFTPM_MODULE_BUNDLE ?: [NSBundle mainBundle];
        #else
            NSBundle *frameworkBundle = [NSBundle bundleForClass:[MASShortcut class]];
            // first we'll check if resources bundle was copied to MASShortcut framework bundle when !use_frameworks option is active
            NSURL *cocoaPodsBundleURL = [frameworkBundle URLForResource:@"MASShortcut" withExtension:@"bundle"];
            if (cocoaPodsBundleURL) {
                localizationBundle = [NSBundle bundleWithURL: cocoaPodsBundleURL];
            } else {
                // trying to fetch cocoapods bundle from main bundle
                cocoaPodsBundleURL = [[NSBundle mainBundle] URLForResource: @"MASShortcut" withExtension:@"bundle"];
                if (cocoaPodsBundleURL) {
                    localizationBundle = [NSBundle bundleWithURL: cocoaPodsBundleURL];
                } else {
                    // fallback to framework bundle
                    localizationBundle = frameworkBundle;
                }
            }
        #endif
    });
    return [localizationBundle localizedStringForKey:key
        value:MASPlaceholderLocalizationString
        table:MASLocalizationTableName];
}
