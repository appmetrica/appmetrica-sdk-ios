
#pragma once

#import <Foundation/Foundation.h>

// Shared test state — reset in each -setUp
extern NSString * _Nullable gIronSourceSDKVersion;
extern NSString * _Nullable gLevelPlaySDKVersion;
extern NSMutableArray * _Nullable gIronSourceRegisteredDelegates;
extern NSMutableArray * _Nullable gLevelPlayRegisteredDelegates;

void AMAIronSourceTestSDKStubsReset(void);
