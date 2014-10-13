-module(udp_thrift_common).

-export([
  get_timestamp/0,
  get_message_id_as_string/0 ]).

get_timestamp() ->
  {Mega,Sec,Micro} = os:timestamp(),
  trunc( ((Mega*1000000+Sec)*1000000+Micro) / 1000000 ).

get_message_id_as_string() ->
  lists:flatten( io_lib:format( "~p", [ make_ref() ] ) ).