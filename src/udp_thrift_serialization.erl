-module(udp_thrift_serialization).
-behaviour(gen_server).

-export([start_link/0, stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).

-include("udp_thrift_types.hrl").

-record(binary_protocol, {transport,
                          strict_read=true,
                          strict_write=true }).
-record(memory_buffer, {buffer}).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
  {ok, OutThriftTransport} = thrift_memory_buffer:new(),
  {ok, OutThriftProtocol} = thrift_binary_protocol:new(OutThriftTransport),
  {ok, { serialization, OutThriftProtocol }}.

stop() -> gen_server:cast(?MODULE, stop).

handle_info({ serialize, DigestType, Digest, CallerPid }, LoopData) ->
  self() ! { serialize, DigestType, Digest, udp_thrift_types:struct_info(DigestType), CallerPid },
  {noreply, LoopData};

handle_info({ serialize, DigestType, Digest, StructInfo, CallerPid }, { serialization, OutThriftProtocol }) ->
  CallerPid ! { message_serialized, { ok, digest_to_binary( #digestEnvelope{
                                                        payload_type = atom_to_list(DigestType),
                                                        bin_payload = digest_to_binary(Digest, StructInfo, OutThriftProtocol) },
                                                      udp_thrift_types:struct_info(digestEnvelope),
                                                      OutThriftProtocol ) } },
  {noreply, { serialization, OutThriftProtocol } };

handle_info({ deserialize, BinaryDigest, CallerPid }, LoopData) ->
  try
    case digest_from_binary(digestEnvelope, BinaryDigest) of
      {ok, DecodedResult} ->
        case payload_type_as_known_atom(DecodedResult#digestEnvelope.payload_type) of
          { ok, PayloadTypeAtom } ->
            case digest_from_binary(PayloadTypeAtom, DecodedResult#digestEnvelope.bin_payload) of
              { ok, DecodedResult2 } ->
                CallerPid ! { message_deserialized, { ok, PayloadTypeAtom, DecodedResult2 } };
              _ ->
                error_logger:error_msg("Message could not be decoded."),
                CallerPid ! { message_deserialized, { error, decode_binary_content_failed } }
            end;
          { error, UnsupportedPayloadType } ->
            error_logger:error_msg("Unsupprted message ~p.", [UnsupportedPayloadType]),
            CallerPid ! { message_deserialized, {error, unsuppoted_payload_type} }
        end;
      _ ->
        error_logger:error_msg("Could not open digestEnvelope."),
        CallerPid ! { message_deserialized, {error, digest_envelope_open_failed} }
    end
  catch
    _Error:Reason ->
      gossiper_log:err("Error while reading digest: ~p.", [Reason]),
      CallerPid ! { message_deserialized, { error, digest_read } }
  end,
  {noreply, LoopData};

handle_info(_Info, LoopData) ->
  {noreply, LoopData}.

digest_to_binary(Digest, StructInfo, OutThriftProtocol) ->
  {PacketThrift, ok} = thrift_protocol:write(OutThriftProtocol,
                                             {{struct, element(2, StructInfo)}, Digest}),
  {protocol, _, OutProtocol} = PacketThrift,
  {transport, _, OutTransport} = OutProtocol#binary_protocol.transport,
  iolist_to_binary(OutTransport#memory_buffer.buffer).

digest_from_binary(DigestType, BinaryDigest) ->
  {ok, InTransport} = thrift_memory_buffer:new(BinaryDigest),
  {ok, InProtocol} = thrift_binary_protocol:new(InTransport),
  case thrift_protocol:read( InProtocol, {struct, element(2, udp_thrift_types:struct_info(DigestType))}, DigestType) of
    {_, {ok, DecodedResult}} ->
      {ok, DecodedResult};
    _ ->
      {error, not_thrift}
  end.

payload_type_as_known_atom(DigestTypeBin) ->
  KnownDigestTypes = [
    { <<"digest">>, digest },
    { <<"digestAck">>, digestAck } ],
  case lists:keyfind( DigestTypeBin, 1, KnownDigestTypes ) of
    false -> { error, DigestTypeBin };
    { _Bin, Atom } -> { ok, Atom }
  end.

handle_call(_Msg, _From, LoopData) ->
  {reply, ok, LoopData}.

handle_cast(stop, LoopData) ->
  {noreply, LoopData}.

terminate(_Reason, _LoopData) ->
  {ok}.
  
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.