/* Generated by the protocol buffer compiler.  DO NOT EDIT! */
/* Generated from: LegacyEventExtras.proto */

#ifndef PROTOBUF_C_LegacyEventExtras_2eproto__INCLUDED
#define PROTOBUF_C_LegacyEventExtras_2eproto__INCLUDED

#include <AppMetricaProtobuf/AppMetricaProtobuf.h>

PROTOBUF_C__BEGIN_DECLS

#if PROTOBUF_C_VERSION_NUMBER < 1000000
# error This file was generated by a newer version of protoc-c which is incompatible with your libprotobuf-c headers. Please update your headers.
#elif 1005000 < PROTOBUF_C_MIN_COMPILER_VERSION
# error This file was generated by an older version of protoc-c which is incompatible with your libprotobuf-c headers. Please regenerate this file with a newer version of protoc-c.
#endif


typedef struct Ama__LegacyEventExtras Ama__LegacyEventExtras;


/* --- enums --- */


/* --- messages --- */

struct  Ama__LegacyEventExtras
{
  ProtobufCMessage base;
  char *id;
  char *type;
  char *options;
};
#define AMA__LEGACY_EVENT_EXTRAS__INIT \
 { PROTOBUF_C_MESSAGE_INIT (&ama__legacy_event_extras__descriptor) \
    , NULL, NULL, NULL }


/* Ama__LegacyEventExtras methods */
void   ama__legacy_event_extras__init
                     (Ama__LegacyEventExtras         *message);
size_t ama__legacy_event_extras__get_packed_size
                     (const Ama__LegacyEventExtras   *message);
size_t ama__legacy_event_extras__pack
                     (const Ama__LegacyEventExtras   *message,
                      uint8_t             *out);
size_t ama__legacy_event_extras__pack_to_buffer
                     (const Ama__LegacyEventExtras   *message,
                      ProtobufCBuffer     *buffer);
Ama__LegacyEventExtras *
       ama__legacy_event_extras__unpack
                     (ProtobufCAllocator  *allocator,
                      size_t               len,
                      const uint8_t       *data);
void   ama__legacy_event_extras__free_unpacked
                     (Ama__LegacyEventExtras *message,
                      ProtobufCAllocator *allocator);
/* --- per-message closures --- */

typedef void (*Ama__LegacyEventExtras_Closure)
                 (const Ama__LegacyEventExtras *message,
                  void *closure_data);

/* --- services --- */


/* --- descriptors --- */

extern const ProtobufCMessageDescriptor ama__legacy_event_extras__descriptor;

PROTOBUF_C__END_DECLS


#endif  /* PROTOBUF_C_LegacyEventExtras_2eproto__INCLUDED */
