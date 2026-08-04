
//TODO: https://nda.ya.ru/t/l-kNX_kW75Z8zh
#ifdef AMA_SPM_TRAITS_SUPPORTED

    #ifdef AMA_ENABLE_DEBUG
        #define AMA_ALLOW_DESCRIPTIONS 1
        #define AMA_ALLOW_INTERNAL_LOG 1
        #define AMA_ALLOW_BACKTRACE_LOG 1
    #else
        #define AMA_ALLOW_DESCRIPTIONS 0
        #define AMA_ALLOW_INTERNAL_LOG 0
        #define AMA_ALLOW_BACKTRACE_LOG 0
    #endif

#else

    #ifndef NDEBUG
        #define AMA_ALLOW_BACKTRACE_LOG 1
        #define AMA_ALLOW_DESCRIPTIONS 1
    #else /* NDEBUG */
        #define AMA_ALLOW_BACKTRACE_LOG 0
        #define AMA_ALLOW_DESCRIPTIONS 0
    #endif /* NDEBUG */

    #define AMA_ALLOW_INTERNAL_LOG 0

#endif
