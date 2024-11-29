/* Generated by the protocol buffer compiler.  DO NOT EDIT! */
/* Generated from: EventNameHashesCollection.proto */

#ifndef PROTOBUF_C_EventNameHashesCollection_2eproto__INCLUDED
#define PROTOBUF_C_EventNameHashesCollection_2eproto__INCLUDED

#include <AppMetricaProtobuf/AppMetricaProtobuf.h>

PROTOBUF_C__BEGIN_DECLS

#if PROTOBUF_C_VERSION_NUMBER < 1000000
# error This file was generated by a newer version of protoc-c which is incompatible with your libprotobuf-c headers. Please update your headers.
#elif 1005000 < PROTOBUF_C_MIN_COMPILER_VERSION
# error This file was generated by an older version of protoc-c which is incompatible with your libprotobuf-c headers. Please regenerate this file with a newer version of protoc-c.
#endif


typedef struct Ama__EventNameHashesCollection Ama__EventNameHashesCollection;


/* --- enums --- */


/* --- messages --- */

struct  Ama__EventNameHashesCollection
{
  ProtobufCMessage base;
  ProtobufCBinaryData current_version;
  uint32_t hashes_count_from_current_version;
  ama_protobuf_c_boolean handle_new_events_as_unknown;
  size_t n_event_name_hashes;
  uint64_t *event_name_hashes;
};
#define AMA__EVENT_NAME_HASHES_COLLECTION__INIT \
 { PROTOBUF_C_MESSAGE_INIT (&ama__event_name_hashes_collection__descriptor) \
    , {0,NULL}, 0, 0, 0,NULL }


/* Ama__EventNameHashesCollection methods */
void   ama__event_name_hashes_collection__init
                     (Ama__EventNameHashesCollection         *message);
size_t ama__event_name_hashes_collection__get_packed_size
                     (const Ama__EventNameHashesCollection   *message);
size_t ama__event_name_hashes_collection__pack
                     (const Ama__EventNameHashesCollection   *message,
                      uint8_t             *out);
size_t ama__event_name_hashes_collection__pack_to_buffer
                     (const Ama__EventNameHashesCollection   *message,
                      ProtobufCBuffer     *buffer);
Ama__EventNameHashesCollection *
       ama__event_name_hashes_collection__unpack
                     (ProtobufCAllocator  *allocator,
                      size_t               len,
                      const uint8_t       *data);
void   ama__event_name_hashes_collection__free_unpacked
                     (Ama__EventNameHashesCollection *message,
                      ProtobufCAllocator *allocator);
/* --- per-message closures --- */

typedef void (*Ama__EventNameHashesCollection_Closure)
                 (const Ama__EventNameHashesCollection *message,
                  void *closure_data);

/* --- services --- */


/* --- descriptors --- */

extern const ProtobufCMessageDescriptor ama__event_name_hashes_collection__descriptor;

PROTOBUF_C__END_DECLS


#endif  /* PROTOBUF_C_EventNameHashesCollection_2eproto__INCLUDED */
