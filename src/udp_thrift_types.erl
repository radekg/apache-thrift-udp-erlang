%%
%% Autogenerated by Thrift Compiler (0.9.1)
%%
%% DO NOT EDIT UNLESS YOU ARE SURE THAT YOU KNOW WHAT YOU ARE DOING
%%

-module(udp_thrift_types).

-include("udp_thrift_types.hrl").

-export([struct_info/1, struct_info_ext/1]).

struct_info('digestEnvelope') ->
  {struct, [{1, string},
          {2, string}]}
;

struct_info('digest') ->
  {struct, [{1, string},
          {2, i32},
          {3, i64},
          {4, string}]}
;

struct_info('digestAck') ->
  {struct, [{1, string},
          {2, i64},
          {3, string}]}
;

struct_info('i am a dummy struct') -> undefined.

struct_info_ext('digestEnvelope') ->
  {struct, [{1, required, string, 'payload_type', undefined},
          {2, required, string, 'bin_payload', undefined}]}
;

struct_info_ext('digest') ->
  {struct, [{1, required, string, 'name', undefined},
          {2, required, i32, 'port', undefined},
          {3, required, i64, 'heartbeat', undefined},
          {4, required, string, 'id', undefined}]}
;

struct_info_ext('digestAck') ->
  {struct, [{1, required, string, 'name', undefined},
          {2, required, i64, 'heartbeat', undefined},
          {3, required, string, 'reply_id', undefined}]}
;

struct_info_ext('i am a dummy struct') -> undefined.
