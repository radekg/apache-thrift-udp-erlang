-module(udp_thrift_messaging).
-behaviour(gen_server).
-export([start_link/4, stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).

-define(SERVER, ?MODULE).

-include("udp_thrift_types.hrl").

start_link(BindAddress, BindPort, Name, PeerPort) ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [BindAddress, BindPort, Name, PeerPort], []).

stop() -> gen_server:cast(?MODULE, stop).

init([BindAddress, BindPort, Name, PeerPort]) ->
  case gen_udp:open(BindPort, [binary, {ip, BindAddress}]) of
    {ok, Socket} ->
      erlang:send_after(2000, self(), { contact_peer, BindPort }),
      {ok, {messaging, Socket, Name, PeerPort}};
    {error, Reason} ->
      {error, Reason}
  end.

terminate(_Reason, {messaging, Socket, _}) ->
  gen_udp:close(Socket).

handle_cast(stop, LoopData) ->
  {noreply, LoopData}.

%% SENDING

handle_info({ contact_peer, Port }, { messaging, Socket, Name, PeerPort }) ->
  error_logger:info_msg( "Sending digest to ~p.", [ PeerPort ] ),
  Digest = #digest{
    name = Name,
    port = Port,
    heartbeat = udp_thrift_common:get_timestamp(),
    id = udp_thrift_common:get_message_id_as_string() },
  udp_thrift_serialization ! { serialize, digest, Digest, self() },
  erlang:send_after(2000, self(), { contact_peer, Port }),
  {noreply, { messaging, Socket, Name, PeerPort }};

handle_info({ message_serialized, { ok, SerializedMessage } }, { messaging, Socket, Name, PeerPort }) ->
  gen_udp:send(
    Socket,
    { 127,0,0,1 },
    PeerPort,
    SerializedMessage ),
  {noreply, { messaging, Socket, Name, PeerPort } };

%% RECEIVING

handle_info({udp, _ClientSocket, _ClientIp, _ClientPort, Msg}, { messaging, Socket, Name, PeerPort }) ->
  udp_thrift_serialization ! { deserialize, Msg, self() },
  {noreply, { messaging, Socket, Name, PeerPort }};

handle_info({ message_deserialized, { ok, DecodedPayloadType, DecodedPayload } }, { messaging, Socket, Name, PeerPort }) ->
  self() ! { message, DecodedPayloadType, DecodedPayload },
  {noreply, { messaging, Socket, Name, PeerPort }};

handle_info({ message, digest, DecodedPayload }, { messaging, Socket, Name, PeerPort }) ->
  error_logger:info_msg("Received digest from ~p. Replying to ~p", [ DecodedPayload#digest.name, DecodedPayload#digest.port ]),
  DigestAck = #digestAck{
    name = Name,
    heartbeat = udp_thrift_common:get_timestamp(),
    reply_id = DecodedPayload#digest.id },
  udp_thrift_serialization ! { serialize, digestAck, DigestAck, self() },
  {noreply, { messaging, Socket, Name, PeerPort }};

handle_info({ message, digestAck, DecodedPayload }, { messaging, Socket, Name, PeerPort }) ->
  error_logger:info_msg("Received digestAck to digest ~p.", [ DecodedPayload#digestAck.reply_id ]),
  {noreply, { messaging, Socket, Name, PeerPort }};

%% ERROR HANDLING

handle_info({ message_deserialized, {error, Reason} }, { messaging, Socket, Name, PeerPort }) ->
  error_logger:error_msg("Message decode failed. Reason ~p.", [Reason]),
  {noreply, { messaging, Socket, Name, PeerPort }};

handle_info(Msg, LoopData) ->
  error_logger:info_msg("Unhandled handle_info ~p", [Msg]),
  {noreply, LoopData}.

%% REMAINDER OF GEN_SERVER BEHAVIOUR

handle_call({message, _Msg}, _From, LoopData) ->
  {reply, ok, LoopData}.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.