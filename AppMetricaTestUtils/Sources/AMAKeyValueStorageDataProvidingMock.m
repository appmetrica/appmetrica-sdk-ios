#import "AMAKeyValueStorageDataProvidingMock.h"

@interface AMAKeyValueStorageDataProvidingMock()

@end

@implementation AMAKeyValueStorageDataProvidingMock

- (BOOL)fillError:(NSError *__autoreleasing  _Nullable * _Nullable)error 
{
    if (self.error != nil) {
        if (error != nil) {
            *error = self.error;
        }
        return NO;
    }
    return YES;
}

- (nullable NSArray<NSString *> *)allKeysWithError:(NSError *__autoreleasing  _Nullable * _Nullable)error 
{
    if ([self fillError:error]) {
        return self.storage.allKeys;
    }
    return nil;
}

- (nullable id)objectForKey:(nonnull NSString *)key error:(NSError *__autoreleasing  _Nullable * _Nullable)error 
{
    if ([self fillError:error]) {
        return self.storage[key];
    }
    return nil;
}

- (nullable NSDictionary<NSString *,id> *)objectsForKeys:(nonnull NSArray *)keys error:(NSError *__autoreleasing  _Nullable * _Nullable)error 
{
    if ([self fillError:error]) {
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        for (NSString *key in keys) {
            if (self.storage[key] != nil) {
                result[key] = self.storage[key];
            }
        }
        return [result copy];
    }
    return nil;
}

- (BOOL)removeKey:(nonnull NSString *)key error:(NSError *__autoreleasing  _Nullable * _Nullable)error 
{
    if ([self fillError:error]) {
        NSMutableDictionary *dictionary = [self.storage mutableCopy];
        [dictionary removeObjectForKey:key];
        self.storage = dictionary;
    }
    return nil;
}

- (BOOL)saveObject:(nullable id)object forKey:(nonnull NSString *)key error:(NSError *__autoreleasing  _Nullable * _Nullable)error 
{
    if ([self fillError:error]) {
        NSMutableDictionary *dictionary = [self.storage mutableCopy];
        dictionary[key] = object;
        self.storage = dictionary;
    }
    return nil;
}

- (BOOL)saveObjectsDictionary:(nonnull NSDictionary<NSString *,id> *)objectsDictionary error:(NSError *__autoreleasing  _Nullable * _Nullable)error 
{
    if ([self fillError:error]) {
        NSMutableDictionary *dictionary = [self.storage mutableCopy];
        [dictionary addEntriesFromDictionary:objectsDictionary];
        self.storage = dictionary;
    }
    return nil;
}

@end
