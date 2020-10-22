import sys
import pika
import time

class StringSearchServer:
   def __init__(self, FileQueue, ResponseQueue, callback):
      file_connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
      file_channel = file_connection.channel()
      file_channel.queue_declare(queue=FileQueue)

      response_connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
      response_channel = response_connection.channel()
      response_channel.queue_declare(queue=ResponseQueue)

      self.regQueue=RegisteredQueue(FileQueue, ResponseQueue, callback, file_connection, file_channel, response_connection, response_channel)

      def callback(ch, method, properties, body):
           self.regQueue.callback(body)

      self.regQueue.file_channel.basic_consume(on_message_callback=callback, queue=FileQueue, auto_ack=True)
      

   def closeRabbitmq(self):
      rQueue.file_connection.close()
      rQueue.response_connection.close()

   def sendToErl(self, ResponseQueue, msg):
      self.regQueue.response_channel.basic_publish(exchange='', routing_key=ResponseQueue, body=msg)      

   def receiveFromErl(self):
      print('Waiting for task')
      self.regQueue.file_channel.start_consuming()

   def computeTask(self,body):  
        text = body.decode('utf-8')
        stop = len(text) - 3
        parsedText = text[3:stop].split("/", 1)
        if (len(parsedText) == 1):
        	self.regQueue.response_channel.basic_publish(exchange='', routing_key=self.regQueue.ResponseQueue, body=text)
        	return

        findResponse = parsedText[1].find(parsedText[0])

        if (findResponse != -1):
            response = "{true, " + str(findResponse) + "}"
        else:
            response = "{false, " + str(findResponse) + "}"
        self.regQueue.response_channel.basic_publish(exchange='', routing_key=self.regQueue.ResponseQueue, body=response)

class RegisteredQueue:
   def __init__(self, FileQueue,ResponseQueue, callback, file_connection, file_channel, response_connection, response_channel):
     self.FileQueue = FileQueue
     self.ResponseQueue = ResponseQueue
     self.callback = callback
     self.file_connection = file_connection
     self.file_channel = file_channel
     self.response_connection = response_connection
     self.response_channel = response_channel
