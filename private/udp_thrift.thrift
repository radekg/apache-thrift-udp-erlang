namespace erl udp_thrift

struct DigestEnvelope {
  1: required string payload_type;
  2: required string bin_payload;
}

struct Digest {
  1: required string name;
  2: required i32 port;
  3: required i64 heartbeat;
  4: required string id;
}

struct DigestAck {
  1: required string name;
  2: required i64 heartbeat;
  3: required string reply_id;
}