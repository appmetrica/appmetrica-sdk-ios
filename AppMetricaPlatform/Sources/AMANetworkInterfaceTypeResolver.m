
#import "AMANetworkInterfaceTypeResolver.h"
#import <Network/Network.h>

@implementation AMANetworkInterfaceTypeResolver

+ (void)isCellularConnection:(void (^)(BOOL))completion
{
    nw_path_monitor_t monitor = nw_path_monitor_create();
    
    nw_path_monitor_set_update_handler(monitor, ^(nw_path_t path) {
        BOOL isCellular = nw_path_uses_interface_type(path, nw_interface_type_cellular);
        
        if (completion) {
            completion(isCellular);
        }
        nw_path_monitor_cancel(monitor);
    });
    
    nw_path_monitor_start(monitor);
}

@end
