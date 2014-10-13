-module(udp_thrift_sup).
-behaviour(supervisor).
-export([start_link/0, init/1]).

start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
  Port = case application:get_env(udp_thrift, port) of
    { ok, Value } ->
      Value;
    undefined ->
      { error, no_port }
  end,
  PeerPort = case application:get_env(udp_thrift, peer_port) of
    { ok, Value2 } ->
      Value2;
    undefined ->
      { error, no_peer_port }
  end,
  case application:get_env(udp_thrift, name) of
    { ok, Name } ->
        {ok, {{one_for_all, 10, 10},
          [
            {
              udp_thrift_messaging,
              {udp_thrift_messaging, start_link, [ {127,0,0,1}, Port, Name, PeerPort ]},
              permanent,
              brutal_kill,
              worker,
              []
            }, {
              udp_thrift_serialization,
              {udp_thrift_serialization, start_link, []},
              permanent,
              brutal_kill,
              worker,
              []
            }
          ]
        }
      };
    undefined ->
      { error, no_name_given }
  end.