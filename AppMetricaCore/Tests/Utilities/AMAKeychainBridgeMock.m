
#import "AMAKeychainBridgeMock.h"

@interface AMAKeychainBridgeMock ()

@property (nonatomic, readonly, strong) NSMutableDictionary *storage;

@end

@implementation AMAKeychainBridgeMock

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _storage = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)keyForQuery:(NSDictionary *)query
{
    return [NSString stringWithFormat:@"%@:%@",
            [self keyPrefixForQuery:query],
            query[(__bridge id)kSecAttrAccount]];
}

- (NSString *)keyPrefixForQuery:(NSDictionary *)query
{
    return [NSString stringWithFormat:@"%@:%@",
            query[(__bridge id)kSecAttrService],
            query[(__bridge id)kSecAttrAccessGroup]];
}

- (BOOL)isKeyWildcardedForQuery:(NSDictionary *)query
{
    return query[(__bridge id)kSecAttrAccount] == nil;
}

- (id)dataForQuery:(NSDictionary *)query
{
    return query[(__bridge id)kSecValueData];
}

- (OSStatus)addEntryWithAttributes:(NSDictionary *)attributes
{
    NSString *key = [self keyForQuery:attributes];
    if (self.storage[key] != nil) {
        return errSecDuplicateItem;
    }
    self.storage[key] = [self dataForQuery:attributes];
    return errSecSuccess;
}

- (OSStatus)updateEntryWithQuery:(NSDictionary *)query attributesToUpdate:(NSDictionary *)attributes
{
    NSString *key = [self keyForQuery:query];
    if (self.storage[key] == nil) {
        return errSecItemNotFound;
    }
    self.storage[key] = [self dataForQuery:attributes];
    return errSecSuccess;
}

- (OSStatus)deleteEntryWithQuery:(NSDictionary *)query
{
    if ([self isKeyWildcardedForQuery:query]) {
        NSString *prefix = [self keyPrefixForQuery:query];
        NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(NSString *key, NSDictionary *bindings) {
            return [key rangeOfString:prefix].location == 0;
        }];
        NSArray *keysToDelete = [self.storage.allKeys filteredArrayUsingPredicate:filter];
        [self.storage removeObjectsForKeys:keysToDelete];
    }
    else {
        self.storage[[self keyForQuery:query]] = nil;
    }
    return errSecSuccess;
}

- (OSStatus)copyMatchingEntryWithQuery:(NSDictionary *)query resultData:(NSData **)resultData
{
    NSData *data = self.storage[[self keyForQuery:query]];
    *resultData = data;
    return data == nil ? errSecItemNotFound : 0;
}

@end
