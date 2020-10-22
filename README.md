# erlang-python-search-pipeline
This project demonstrates the connection of an erlang process with a python process through rabbitmq. 


Use case: read a file in erlang and find out if a given string exists in the file and the position. The search job is delegated to the python process. Upon completion, python process communicates to erlang the result.


Installation:
Make sure you have the Rabbitmq Erlang Client installed:
https://www.rabbitmq.com/download.html

Note: to successfully run erlang code it's important to have amqp_client, rabbit_common and recon inside deps folder.
https://www.rabbitmq.com/erlang-client-user-guide.html#deployment

Install pika: https://pika.readthedocs.io/en/stable/


Start erlang shell:
```
ERL_LIBS=deps erl -pa ebin
```
Create a gen_server process:
```
> string_search_client:start_link(<<"request_queue">>, <<"response_queue">>, fun(Response)-> callback:callback(Response) end).
```
Search for a string:
```
> string_search_client:contains_string(<<"request_queue">>, "Lorem", "test.txt").
```

Start python shell:
```
python3
>>> import string_search_server
>>> v=string_search_server.StringSearchServer('request_queue', 'response_queue',  lambda msg: v.computeTask(msg))
>>> v.receiveFromErl()
```


