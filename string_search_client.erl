-module(string_search_client).
-compile(export_all).
-behaviour(gen_server).

-include_lib("amqp_client/include/amqp_client.hrl").
-record(state, {registeredQueue=[]}).

start_link(FileQueue, ResponseQueue, Callback)-> 
{ok, _Pid} = gen_server:start_link({local, ?MODULE}, ?MODULE, [FileQueue, ResponseQueue, Callback], []).

stop()-> gen_server:call(?MODULE, stop).
         
init([FileQueue, ResponseQueue, Callback])-> 
    {ok, FileConnection} = amqp_connection:start(#amqp_params_network{host = "localhost"}),
    {ok, FileChannel} = amqp_connection:open_channel(FileConnection),
    amqp_channel:call(FileChannel, #'queue.declare'{queue = FileQueue}),

    {ok, ResponseConnection} = amqp_connection:start(#amqp_params_network{host = "localhost"}),
    {ok, ResponseChannel} = amqp_connection:open_channel(ResponseConnection),
    amqp_channel:call(ResponseChannel, #'queue.declare'{queue = ResponseQueue}),
    amqp_channel:subscribe(ResponseChannel, #'basic.consume'{queue = ResponseQueue, no_ack = true}, self()),
    {ok, #state{registeredQueue=[{FileQueue, ResponseQueue, FileChannel, FileConnection, ResponseChannel, ResponseConnection, Callback}]}}.

contains_string(FileQueue, SearchString, FileName)-> 
    {ok, File} = file:read_file(FileName),
    Content = unicode:characters_to_list(File),
    Msg = SearchString ++ "/" ++ Content,
    gen_server:call(?MODULE, {send, FileQueue, list_to_binary(Msg)}).


handle_call({send, FileQueue, Msg}, _From, #state{registeredQueue=RegQueue}=State)-> 
    case lists:keyfind(FileQueue, 1, RegQueue) of 
        {FileQueue, _ResponseQueue, FileChannel, _FileConnection, _ResponseChannel, _ResponseConnection, _Callback}-> 
            FormatedMsg = io_lib:format("~p", [Msg]),
            FlattenedMsg = lists:flatten(FormatedMsg),
            amqp_channel:cast(FileChannel,
                #'basic.publish'{exchange = <<"">>,routing_key = FileQueue},
                #amqp_msg{payload = list_to_binary(FlattenedMsg)}
            ),
            {reply, {ok, Msg}, State};
        false -> 
          {reply, nok, State}
    end;

handle_call(stop, _From, #state{registeredQueue=[{_FileQueue,_ResponseQueue, FileChannel, FileConnection, ResponseChannel, ResponseConnection, _Callback}]}=State)->
    ok = amqp_channel:close(FileChannel),
    ok = amqp_connection:close(FileConnection),
    ok = amqp_channel:close(ResponseChannel),
    ok = amqp_connection:close(ResponseConnection),
    {stop, normal, ok, State};
 
handle_call(_Msg, _From, State)->
    {noreply, State}.


handle_info({#'basic.deliver'{}, #amqp_msg{payload=Body}}, #state{registeredQueue=[{_FileQueue,_ResponseQueue, _FileChannel, _FileConnection, _ResponseChannel, _ResponseConnection, Callback}]}= State) ->
    Response = binary_to_list(Body),
    {ok, Ms, _} = erl_scan:string(Response ++ "."),
    {ok, ErlTerm} = erl_parse:parse_term(Ms),

    Callback(ErlTerm),
  
    {noreply, State};

handle_info( #'basic.consume_ok'{}, State)->
    {noreply, State};

handle_info(Msg, State) ->
    io:format("~p ~n", [Msg]),
    {noreply, State}.

handle_cast(_Msg, State)->
    {noreply, State}.

terminate(normal, _State)-> ok.

code_change(_OldVsn, State, _Extra)->
    {ok, State}.
