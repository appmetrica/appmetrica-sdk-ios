
#import <Foundation/Foundation.h>
#import "AMAKeychainMock.h"

@implementation AMAKeychainMock

- (BOOL)fillLockedError:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    if (self.isLocked) {
        if (error != nil) {
            NSError *result = [NSError errorWithDomain:kAMAKeychainErrorDomain
                                                  code:AMAKeychainErrorCodeLocked
                                              userInfo:@{
                kAMAKeychainErrorKeyCode: @(errSecDatabaseLocked)
            }];
            *error = result;
        }
        return NO;
    }
    return YES;
}

- (BOOL)setStringValue:(nonnull NSString *)value forKey:(nonnull NSString *)key error:(NSError * _Nullable __autoreleasing * _Nullable)error 
{
    if ([self fillLockedError:error]) {
        NSMutableDictionary *d = [self.storage mutableCopy] ?: [NSMutableDictionary dictionary];
        d[key] = value;
        self.storage = [d copy];
        return YES;
    }
    return NO;
}

- (nullable NSString *)stringValueForKey:(nonnull NSString *)key error:(NSError * _Nullable __autoreleasing * _Nullable)error 
{
    if ([self fillLockedError:error]) {
        return self.storage[key];
    }
    return nil;
}

- (BOOL)addStringValue:(nonnull NSString *)value forKey:(nonnull NSString *)key error:(NSError * _Nullable __autoreleasing * _Nullable)error { 
    if ([self fillLockedError:error]) {
        NSMutableDictionary *d = [self.storage mutableCopy] ?: [NSMutableDictionary dictionary];
        if (d[key] == nil) {
            d[key] = value;
            self.storage = [d copy];
            return YES;
        } else {
            NSError *err = [NSError errorWithDomain:kAMAKeychainErrorDomain
                                               code:AMAKeychainErrorCodeDuplicate
                                           userInfo:nil];
            if (error != nil) {
                *error = err;
            }
        }
    }
    return NO;
}


- (BOOL)removeStringValueForKey:(nonnull NSString *)key error:(NSError * _Nullable __autoreleasing * _Nullable)error { 
    if ([self fillLockedError:error]) {
        NSMutableDictionary *d = [self.storage mutableCopy] ?: [NSMutableDictionary dictionary];
        [d removeObjectForKey:key];
        self.storage = [d copy];
        return YES;
    }
    return NO;
}


@end
