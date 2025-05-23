/* Generated by the protocol buffer compiler.  DO NOT EDIT! */
/* Generated from: AppMetrica.proto */

#ifndef PROTOBUF_C_AppMetrica_2eproto__INCLUDED
#define PROTOBUF_C_AppMetrica_2eproto__INCLUDED

#include <AppMetricaProtobuf/AppMetricaProtobuf.h>

PROTOBUF_C__BEGIN_DECLS

#if PROTOBUF_C_VERSION_NUMBER < 1003000
# error This file was generated by a newer version of protobuf-c which is incompatible with your libprotobuf-c headers. Please update your headers.
#elif 1005001 < PROTOBUF_C_MIN_COMPILER_VERSION
# error This file was generated by an older version of protobuf-c which is incompatible with your libprotobuf-c headers. Please regenerate this file with a newer version of protobuf-c.
#endif


typedef struct Ama__RequestParameters Ama__RequestParameters;
typedef struct Ama__Time Ama__Time;
typedef struct Ama__ReportMessage Ama__ReportMessage;
typedef struct Ama__ReportMessage__Location Ama__ReportMessage__Location;
typedef struct Ama__ReportMessage__Session Ama__ReportMessage__Session;
typedef struct Ama__ReportMessage__Session__SessionDesc Ama__ReportMessage__Session__SessionDesc;
typedef struct Ama__ReportMessage__Session__Event Ama__ReportMessage__Session__Event;
typedef struct Ama__ReportMessage__Session__Event__ExtrasEntry Ama__ReportMessage__Session__Event__ExtrasEntry;
typedef struct Ama__ReportMessage__EnvironmentVariable Ama__ReportMessage__EnvironmentVariable;


/* --- enums --- */

typedef enum _Ama__ReportMessage__Session__SessionDesc__SessionType {
  AMA__REPORT_MESSAGE__SESSION__SESSION_DESC__SESSION_TYPE__SESSION_FOREGROUND = 0,
  AMA__REPORT_MESSAGE__SESSION__SESSION_DESC__SESSION_TYPE__SESSION_BACKGROUND = 1,
  AMA__REPORT_MESSAGE__SESSION__SESSION_DESC__SESSION_TYPE__SESSION_DIAGNOSTIC = 2
    PROTOBUF_C__FORCE_ENUM_TO_BE_INT_SIZE(AMA__REPORT_MESSAGE__SESSION__SESSION_DESC__SESSION_TYPE)
} Ama__ReportMessage__Session__SessionDesc__SessionType;
typedef enum _Ama__ReportMessage__Session__Event__EventType {
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_INIT = 1,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_START = 2,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_CRASH = 3,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_CLIENT = 4,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_REFERRER = 5,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_ERROR = 6,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_ALIVE = 7,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_FIRST = 13,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_OPEN = 16,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_UPDATE = 17,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_PROFILE = 20,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_REVENUE = 21,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_PROTOBUF_ANR = 25,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_PROTOBUF_CRASH = 26,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_PROTOBUF_ERROR = 27,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_CLEANUP = 29,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_ECOMMERCE = 35,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_ASA_TOKEN = 37,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_WEBVIEW_SYNC = 38,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_AD_REVENUE = 40,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_APPLE_PRIVACY = 41,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE__EVENT_CLIENT_EXTERNAL_ATTRIBUTION = 42
    PROTOBUF_C__FORCE_ENUM_TO_BE_INT_SIZE(AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_TYPE)
} Ama__ReportMessage__Session__Event__EventType;
typedef enum _Ama__ReportMessage__Session__Event__EncodingType {
  AMA__REPORT_MESSAGE__SESSION__EVENT__ENCODING_TYPE__NONE = 0,
  AMA__REPORT_MESSAGE__SESSION__EVENT__ENCODING_TYPE__RSA_AES_CBC = 1,
  AMA__REPORT_MESSAGE__SESSION__EVENT__ENCODING_TYPE__GZIP = 2
    PROTOBUF_C__FORCE_ENUM_TO_BE_INT_SIZE(AMA__REPORT_MESSAGE__SESSION__EVENT__ENCODING_TYPE)
} Ama__ReportMessage__Session__Event__EncodingType;
typedef enum _Ama__ReportMessage__Session__Event__EventSource {
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE__NATIVE = 0,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE__JS = 1,
  AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE__SDK_SYSTEM = 2
    PROTOBUF_C__FORCE_ENUM_TO_BE_INT_SIZE(AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE)
} Ama__ReportMessage__Session__Event__EventSource;
typedef enum _Ama__ReportMessage__OptionalBool {
  AMA__REPORT_MESSAGE__OPTIONAL_BOOL__OPTIONAL_BOOL_UNDEFINED = -1,
  AMA__REPORT_MESSAGE__OPTIONAL_BOOL__OPTIONAL_BOOL_FALSE = 0,
  AMA__REPORT_MESSAGE__OPTIONAL_BOOL__OPTIONAL_BOOL_TRUE = 1
    PROTOBUF_C__FORCE_ENUM_TO_BE_INT_SIZE(AMA__REPORT_MESSAGE__OPTIONAL_BOOL)
} Ama__ReportMessage__OptionalBool;

/* --- messages --- */

struct  Ama__RequestParameters
{
  ProtobufCMessage base;
  char *uuid;
  char *device_id;
};
#define AMA__REQUEST_PARAMETERS__INIT \
 { PROTOBUF_C_MESSAGE_INIT (&ama__request_parameters__descriptor) \
    , NULL, NULL }


struct  Ama__Time
{
  ProtobufCMessage base;
  uint64_t timestamp;
  int32_t time_zone;
};
#define AMA__TIME__INIT \
 { PROTOBUF_C_MESSAGE_INIT (&ama__time__descriptor) \
    , 0, 0 }


struct  Ama__ReportMessage__Location
{
  ProtobufCMessage base;
  double lat;
  double lon;
  ama_protobuf_c_boolean has_timestamp;
  uint64_t timestamp;
  ama_protobuf_c_boolean has_precision;
  uint32_t precision;
  ama_protobuf_c_boolean has_direction;
  uint32_t direction;
  ama_protobuf_c_boolean has_speed;
  uint32_t speed;
  ama_protobuf_c_boolean has_altitude;
  int32_t altitude;
};
#define AMA__REPORT_MESSAGE__LOCATION__INIT \
 { PROTOBUF_C_MESSAGE_INIT (&ama__report_message__location__descriptor) \
    , 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }


struct  Ama__ReportMessage__Session__SessionDesc
{
  ProtobufCMessage base;
  Ama__Time *start_time;
  char *locale;
  ama_protobuf_c_boolean has_session_type;
  Ama__ReportMessage__Session__SessionDesc__SessionType session_type;
};
#define AMA__REPORT_MESSAGE__SESSION__SESSION_DESC__INIT \
 { PROTOBUF_C_MESSAGE_INIT (&ama__report_message__session__session_desc__descriptor) \
    , NULL, NULL, 0, AMA__REPORT_MESSAGE__SESSION__SESSION_DESC__SESSION_TYPE__SESSION_FOREGROUND }


struct  Ama__ReportMessage__Session__Event__ExtrasEntry
{
  ProtobufCMessage base;
  ama_protobuf_c_boolean has_key;
  ProtobufCBinaryData key;
  ama_protobuf_c_boolean has_value;
  ProtobufCBinaryData value;
};
#define AMA__REPORT_MESSAGE__SESSION__EVENT__EXTRAS_ENTRY__INIT \
 { PROTOBUF_C_MESSAGE_INIT (&ama__report_message__session__event__extras_entry__descriptor) \
    , 0, {0,NULL}, 0, {0,NULL} }


struct  Ama__ReportMessage__Session__Event
{
  ProtobufCMessage base;
  uint64_t number_in_session;
  uint64_t time;
  uint32_t type;
  char *name;
  ama_protobuf_c_boolean has_value;
  ProtobufCBinaryData value;
  Ama__ReportMessage__Location *location;
  char *environment;
  ama_protobuf_c_boolean has_bytes_truncated;
  uint32_t bytes_truncated;
  ama_protobuf_c_boolean has_encoding_type;
  Ama__ReportMessage__Session__Event__EncodingType encoding_type;
  ama_protobuf_c_boolean has_location_tracking_enabled;
  Ama__ReportMessage__OptionalBool location_tracking_enabled;
  ama_protobuf_c_boolean has_profile_id;
  ProtobufCBinaryData profile_id;
  ama_protobuf_c_boolean has_first_occurrence;
  Ama__ReportMessage__OptionalBool first_occurrence;
  ama_protobuf_c_boolean has_global_number;
  uint64_t global_number;
  ama_protobuf_c_boolean has_number_of_type;
  uint64_t number_of_type;
  ama_protobuf_c_boolean has_source;
  Ama__ReportMessage__Session__Event__EventSource source;
  ama_protobuf_c_boolean has_attribution_id_changed;
  ama_protobuf_c_boolean attribution_id_changed;
  ama_protobuf_c_boolean has_open_id;
  uint64_t open_id;
  size_t n_extras;
  Ama__ReportMessage__Session__Event__ExtrasEntry **extras;
};
#define AMA__REPORT_MESSAGE__SESSION__EVENT__INIT \
 { PROTOBUF_C_MESSAGE_INIT (&ama__report_message__session__event__descriptor) \
    , 0, 0, 0, NULL, 0, {0,NULL}, NULL, NULL, 0, 0, 0, AMA__REPORT_MESSAGE__SESSION__EVENT__ENCODING_TYPE__NONE, 0, AMA__REPORT_MESSAGE__OPTIONAL_BOOL__OPTIONAL_BOOL_UNDEFINED, 0, {0,NULL}, 0, AMA__REPORT_MESSAGE__OPTIONAL_BOOL__OPTIONAL_BOOL_UNDEFINED, 0, 0, 0, 0, 0, AMA__REPORT_MESSAGE__SESSION__EVENT__EVENT_SOURCE__NATIVE, 0, 0, 0, 1ull, 0,NULL }


struct  Ama__ReportMessage__Session
{
  ProtobufCMessage base;
  uint64_t id;
  Ama__ReportMessage__Session__SessionDesc *session_desc;
  size_t n_events;
  Ama__ReportMessage__Session__Event **events;
};
#define AMA__REPORT_MESSAGE__SESSION__INIT \
 { PROTOBUF_C_MESSAGE_INIT (&ama__report_message__session__descriptor) \
    , 0, NULL, 0,NULL }


struct  Ama__ReportMessage__EnvironmentVariable
{
  ProtobufCMessage base;
  char *name;
  char *value;
};
#define AMA__REPORT_MESSAGE__ENVIRONMENT_VARIABLE__INIT \
 { PROTOBUF_C_MESSAGE_INIT (&ama__report_message__environment_variable__descriptor) \
    , NULL, NULL }


struct  Ama__ReportMessage
{
  ProtobufCMessage base;
  size_t n_sessions;
  Ama__ReportMessage__Session **sessions;
  Ama__RequestParameters *report_request_parameters;
  size_t n_app_environment;
  Ama__ReportMessage__EnvironmentVariable **app_environment;
};
#define AMA__REPORT_MESSAGE__INIT \
 { PROTOBUF_C_MESSAGE_INIT (&ama__report_message__descriptor) \
    , 0,NULL, NULL, 0,NULL }


/* Ama__RequestParameters methods */
void   ama__request_parameters__init
                     (Ama__RequestParameters         *message);
size_t ama__request_parameters__get_packed_size
                     (const Ama__RequestParameters   *message);
size_t ama__request_parameters__pack
                     (const Ama__RequestParameters   *message,
                      uint8_t             *out);
size_t ama__request_parameters__pack_to_buffer
                     (const Ama__RequestParameters   *message,
                      ProtobufCBuffer     *buffer);
Ama__RequestParameters *
       ama__request_parameters__unpack
                     (ProtobufCAllocator  *allocator,
                      size_t               len,
                      const uint8_t       *data);
void   ama__request_parameters__free_unpacked
                     (Ama__RequestParameters *message,
                      ProtobufCAllocator *allocator);
/* Ama__Time methods */
void   ama__time__init
                     (Ama__Time         *message);
size_t ama__time__get_packed_size
                     (const Ama__Time   *message);
size_t ama__time__pack
                     (const Ama__Time   *message,
                      uint8_t             *out);
size_t ama__time__pack_to_buffer
                     (const Ama__Time   *message,
                      ProtobufCBuffer     *buffer);
Ama__Time *
       ama__time__unpack
                     (ProtobufCAllocator  *allocator,
                      size_t               len,
                      const uint8_t       *data);
void   ama__time__free_unpacked
                     (Ama__Time *message,
                      ProtobufCAllocator *allocator);
/* Ama__ReportMessage__Location methods */
void   ama__report_message__location__init
                     (Ama__ReportMessage__Location         *message);
/* Ama__ReportMessage__Session__SessionDesc methods */
void   ama__report_message__session__session_desc__init
                     (Ama__ReportMessage__Session__SessionDesc         *message);
/* Ama__ReportMessage__Session__Event__ExtrasEntry methods */
void   ama__report_message__session__event__extras_entry__init
                     (Ama__ReportMessage__Session__Event__ExtrasEntry         *message);
/* Ama__ReportMessage__Session__Event methods */
void   ama__report_message__session__event__init
                     (Ama__ReportMessage__Session__Event         *message);
/* Ama__ReportMessage__Session methods */
void   ama__report_message__session__init
                     (Ama__ReportMessage__Session         *message);
/* Ama__ReportMessage__EnvironmentVariable methods */
void   ama__report_message__environment_variable__init
                     (Ama__ReportMessage__EnvironmentVariable         *message);
/* Ama__ReportMessage methods */
void   ama__report_message__init
                     (Ama__ReportMessage         *message);
size_t ama__report_message__get_packed_size
                     (const Ama__ReportMessage   *message);
size_t ama__report_message__pack
                     (const Ama__ReportMessage   *message,
                      uint8_t             *out);
size_t ama__report_message__pack_to_buffer
                     (const Ama__ReportMessage   *message,
                      ProtobufCBuffer     *buffer);
Ama__ReportMessage *
       ama__report_message__unpack
                     (ProtobufCAllocator  *allocator,
                      size_t               len,
                      const uint8_t       *data);
void   ama__report_message__free_unpacked
                     (Ama__ReportMessage *message,
                      ProtobufCAllocator *allocator);
/* --- per-message closures --- */

typedef void (*Ama__RequestParameters_Closure)
                 (const Ama__RequestParameters *message,
                  void *closure_data);
typedef void (*Ama__Time_Closure)
                 (const Ama__Time *message,
                  void *closure_data);
typedef void (*Ama__ReportMessage__Location_Closure)
                 (const Ama__ReportMessage__Location *message,
                  void *closure_data);
typedef void (*Ama__ReportMessage__Session__SessionDesc_Closure)
                 (const Ama__ReportMessage__Session__SessionDesc *message,
                  void *closure_data);
typedef void (*Ama__ReportMessage__Session__Event__ExtrasEntry_Closure)
                 (const Ama__ReportMessage__Session__Event__ExtrasEntry *message,
                  void *closure_data);
typedef void (*Ama__ReportMessage__Session__Event_Closure)
                 (const Ama__ReportMessage__Session__Event *message,
                  void *closure_data);
typedef void (*Ama__ReportMessage__Session_Closure)
                 (const Ama__ReportMessage__Session *message,
                  void *closure_data);
typedef void (*Ama__ReportMessage__EnvironmentVariable_Closure)
                 (const Ama__ReportMessage__EnvironmentVariable *message,
                  void *closure_data);
typedef void (*Ama__ReportMessage_Closure)
                 (const Ama__ReportMessage *message,
                  void *closure_data);

/* --- services --- */


/* --- descriptors --- */

extern const ProtobufCMessageDescriptor ama__request_parameters__descriptor;
extern const ProtobufCMessageDescriptor ama__time__descriptor;
extern const ProtobufCMessageDescriptor ama__report_message__descriptor;
extern const ProtobufCMessageDescriptor ama__report_message__location__descriptor;
extern const ProtobufCMessageDescriptor ama__report_message__session__descriptor;
extern const ProtobufCMessageDescriptor ama__report_message__session__session_desc__descriptor;
extern const ProtobufCEnumDescriptor    ama__report_message__session__session_desc__session_type__descriptor;
extern const ProtobufCMessageDescriptor ama__report_message__session__event__descriptor;
extern const ProtobufCMessageDescriptor ama__report_message__session__event__extras_entry__descriptor;
extern const ProtobufCEnumDescriptor    ama__report_message__session__event__event_type__descriptor;
extern const ProtobufCEnumDescriptor    ama__report_message__session__event__encoding_type__descriptor;
extern const ProtobufCEnumDescriptor    ama__report_message__session__event__event_source__descriptor;
extern const ProtobufCMessageDescriptor ama__report_message__environment_variable__descriptor;
extern const ProtobufCEnumDescriptor    ama__report_message__optional_bool__descriptor;

PROTOBUF_C__END_DECLS


#endif  /* PROTOBUF_C_AppMetrica_2eproto__INCLUDED */
