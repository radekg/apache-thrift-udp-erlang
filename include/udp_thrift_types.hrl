-ifndef(_udp_thrift_types_included).
-define(_udp_thrift_types_included, yeah).

%% struct digestEnvelope

-record(digestEnvelope, {payload_type :: string() | binary(),
                         bin_payload :: string() | binary()}).

%% struct digest

-record(digest, {name :: string() | binary(),
                 port :: integer(),
                 heartbeat :: integer(),
                 id :: string() | binary()}).

%% struct digestAck

-record(digestAck, {name :: string() | binary(),
                    heartbeat :: integer(),
                    reply_id :: string() | binary()}).

-endif.
