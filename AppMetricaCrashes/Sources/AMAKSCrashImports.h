
#if __has_include(<KSCrash/KSCrash.h>)
// Cocoapods imports
    #import <KSCrash/KSCrash.h>
    #import <KSCrash/KSCrashReportFields.h>
    #import <KSCrash/KSDynamicLinker.h>
    #import <KSCrash/KSSymbolicator.h>
#else
// SPM imports
    @import KSCrash_Recording;
#endif
