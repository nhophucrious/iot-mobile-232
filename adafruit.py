import serial.tools.list_ports
import os
import sys
import time
from Adafruit_IO import MQTTClient
import os

class adafruit_server:
    AIO_FEED_ID = ['mixer1', 'mixer2', 'mixer3', 'soil_temp', 'soil_moist']
    AIO_USER_NAME = os.environ.get('user_name')
    AIO_KEY = os.environ.get('key')

    def connected(self,client):
        for top in adafruit_server.AIO_FEED_ID:
            print(f'Ket noi thanh cong toi {top}')
            self.client.subscribe(top)

    def subscribe(self,client, userdata, mid, granted_qos):
        print(f'Subcribe thanh cong...')

    def disconnected(self,client):
        print("Ngat ket noi...")
        sys.exit(1)

    def message(self, client, feed_id, payload):
        print(f"Nhan du lieu from {feed_id} with {payload}")
        if feed_id == 'mixer1' and payload == 'ON':
            if self.callBack is not None:
                self.callBack()

    def setCallBack(self, func):
        self.callBack = func
        
    def __init__(self):
        self.callBack = None
        self.client = MQTTClient(adafruit_server.AIO_USER_NAME, adafruit_server.AIO_KEY)
        self.client.on_connect = self.connected
        self.client.on_disconnect = self.disconnected
        self.client.on_message = self.message
        self.client.on_subscribe = self.subscribe
        self.client.connect()
        self.client.loop_background()
    
    


   
