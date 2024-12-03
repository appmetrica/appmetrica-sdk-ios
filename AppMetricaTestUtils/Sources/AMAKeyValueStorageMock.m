
#import "AMAKeyValueStorageMock.h"

@implementation AMAKeyValueStorageMock

- (BOOL)fillError:(NSError *__autoreleasing *)error
{
    if (self.error != nil) {
        if (error != nil) {
            *error = self.error;
        }
        return NO;
    }
    return YES;
}

- (void)insertValue:(id)value forKey:(NSString*)key
{
    NSMutableDictionary *d = [self.storage mutableCopy] ?: [NSMutableDictionary dictionary];
    d[key] = value;
    self.storage = d;
}

- (NSNumber *)boolNumberForKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        return self.storage[key];
    }
    return nil;
}

- (NSData *)dataForKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        return self.storage[key];
    }
    return nil;
}

- (NSDate *)dateForKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        return self.storage[key];
    }
    return nil;
}

- (NSNumber *)doubleNumberForKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        return self.storage[key];
    }
    return nil;
}

- (NSArray *)jsonArrayForKey:(NSString *)key error:(NSError *__autoreleasing *)error { 
    if ([self fillError:error]) {
        return self.storage[key];
    }
    return nil;
}

- (NSDictionary *)jsonDictionaryForKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        return self.storage[key];
    }
    return nil;
}

- (NSNumber *)longLongNumberForKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        return self.storage[key];
    }
    return nil;
}

- (NSString *)stringForKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        return self.storage[key];
    }
    return nil;
}

- (NSNumber *)unsignedLongLongNumberForKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        return self.storage[key];
    }
    return nil;
}

- (BOOL)saveBoolNumber:(NSNumber *)value forKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        [self insertValue:value forKey:key];
        return YES;
    }
    return NO;
}

- (BOOL)saveData:(NSData *)data forKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        [self insertValue:data forKey:key];
        return YES;
    }
    return NO;
}

- (BOOL)saveDate:(NSDate *)date forKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        [self insertValue:date forKey:key];
        return YES;
    }
    return NO;
}

- (BOOL)saveDoubleNumber:(NSNumber *)value forKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        [self insertValue:value forKey:key];
        return YES;
    }
    return NO;
}

- (BOOL)saveJSONArray:(NSArray *)value forKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        [self insertValue:value forKey:key];
        return YES;
    }
    return NO;
}

- (BOOL)saveJSONDictionary:(NSDictionary *)value forKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        [self insertValue:value forKey:key];
        return YES;
    }
    return NO;
}

- (BOOL)saveLongLongNumber:(NSNumber *)value forKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        [self insertValue:value forKey:key];
        return YES;
    }
    return NO;
}

- (BOOL)saveString:(NSString *)string forKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        [self insertValue:string forKey:key];
        return YES;
    }
    return NO;
}

- (BOOL)saveUnsignedLongLongNumber:(NSNumber *)value forKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    if ([self fillError:error]) {
        [self insertValue:value forKey:key];
        return YES;
    }
    return NO;
}

- (BOOL)removeValueForKey:(nonnull NSString *)key error:(NSError *__autoreleasing  _Nullable * _Nullable)error
{ 
    if ([self fillError:error]) {
        [self insertValue:nil forKey:key];
        return YES;
    }
    return NO;
}


@end
