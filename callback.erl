-module(callback).
-compile(export_all).

callback(Response) ->
  case Response of
  	  {Found, Position}->
          IsFoundFormated = io_lib:format("~p", [Found]),
          IsFoundFlattened = lists:flatten(IsFoundFormated),
          io:format("Found: ~p, Index: ~p~n", [IsFoundFlattened, Position]),
          {ok, ok};
  	  _-> io:format("Unexpected Response ~n")
  end.