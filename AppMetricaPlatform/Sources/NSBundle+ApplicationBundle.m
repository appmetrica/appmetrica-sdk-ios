#import "NSBundle+ApplicationBundle.h"

@implementation NSBundle (ApplicationBundle)


- (NSBundle *)applicationBundle
{
    NSString *path = self.bundlePath;

    while ([path length] > 0 && ![path isEqualToString:@"/"] && ![path hasSuffix:@".app"]) {
        path = [path stringByDeletingLastPathComponent];
    }

    if ([path hasSuffix:@".app"]) {
        NSURL *url = [NSURL fileURLWithPath:path];
        return [NSBundle bundleWithURL:url];
    } else {
        return nil;
    }
}

@end
