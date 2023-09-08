
#import <Foundation/Foundation.h>

@interface AMARequestParametersTestHelper : NSObject

@property (nonatomic, assign) BOOL isIPad;
@property (nonatomic, copy) NSString *appPlatform;
@property (nonatomic, copy) NSString *manufacturer;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy) NSString *screenWidth;
@property (nonatomic, copy) NSString *screenHeight;
@property (nonatomic, copy) NSString *scalefactor;
@property (nonatomic, copy) NSString *screenDPI;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *APIKey;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *appFramework;

- (void)configureStubs;

@end
