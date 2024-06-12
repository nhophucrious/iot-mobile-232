from threading import Thread
from adafruit import adafruit_server
from Adafruit_IO import MQTTClient
import time
import sys
import os
import serial.tools.list_ports
from threading import Thread, Event

server = adafruit_server()

class farm_sched:
    def __init__(self, client):
        self.client = client
        self.relay_format = {
            'relay1_ON': [2, 6, 0, 0, 0, 255, 201, 185],
            'relay1_OFF': [2, 6, 0, 0, 0, 0, 137, 249],
            'relay2_ON': [3, 6, 0, 0, 0, 255, 200, 104],
            'relay2_OFF': [3, 6, 0, 0, 0, 0, 136, 40],
            'relay3_ON': [4, 6, 0, 0, 0, 255, 201, 223],
            'relay3_OFF': [4, 6, 0, 0, 0, 0, 137, 159],
        }
        self.sensor_format = {
            "soil_temperature": [1,3,0,6,0,1,100,11],
            "soil_moisture": [1,3,0,7,0,1,53, 203]
        }
        try:
            portName = "/dev/ttyUSB0"
            self.ser = serial.Serial(port=portName, baudrate=9600)
            print("Open successfully")
        except:
            print("Can not open the port")
    

    def serial_read_data(self):
        time.sleep(0.1)
        bytesToRead = self.ser.inWaiting()
        if bytesToRead > 0:
            out = self.ser.read(bytesToRead)
            data_array = [b for b in out]
            if len(data_array) >= 7:
                array_size = len(data_array)
                value = data_array[array_size - 4] * 256 + data_array[array_size - 3] #255: ON, 0:OFF
                return value
            else:
                return -1
        return -2
    
    def setMixer1(self, state):
        if state:
            self.ser.write(self.relay_format['relay1_ON'])
            value = self.serial_read_data()
            if value == 255:
                self.client.publish('mixer1', 'ON')
            else:
                print("Cannot turn mixer 1 on")
                self.client.publish('mixer1', 'OFF')
        else:
            self.ser.write(self.relay_format['relay1_OFF'])
            value = self.serial_read_data()
            if value == 0:
                self.client.publish('mixer1', 'OFF')
            else:
                print("Cannot turn mixer 1 off")
                self.client.publish('mixer1', 'ON')

        
    def setMixer2(self, state):
        if state:
            self.ser.write(self.relay_format['relay2_ON'])
            self.client.publish('mixer2', 'ON')
            value = self.serial_read_data()
            if value == 255:
                self.client.publish('mixer2', 'ON')
            else:
                print("Cannot turn mixer 2 on")
                self.client.publish('mixer2', 'OFF')                
        else:
            self.ser.write(self.relay_format['relay2_OFF'])
            value = self.serial_read_data()
            if value == 0:
                self.client.publish('mixer2', 'OFF')
            else:
                print("Cannot turn mixer 2 off")
                self.client.publish('mixer2', 'ON')


    def setMixer3(self, state):
        if state:
            self.ser.write(self.relay_format['relay3_ON'])
            self.client.publish('mixer3', 'ON')
            value = self.serial_read_data()
            if value == 255:
                self.client.publish('mixer3', 'ON')
            else:
                print("Cannot turn mixer 3 on")
                self.client.publish('mixer3', 'OFF')
        else:
            self.ser.write(self.relay_format['relay3_OFF'])
            value = self.serial_read_data()
            if value == 0:
                self.client.publish('mixer3', 'OFF')
            else:
                print("Cannot turn mixer 3 off")
                self.client.publish('mixer3', 'ON')

    def readSensor(self, mode):
        self.serial_read_data()
        if mode == 'soil_temperature':
            self.ser.write(self.sensor_format['soil_temperature'])
            soil_temp = self.serial_read_data(self.ser)
            soil_temp = self.serial_read_data()
            soil_temp_val = 0
            if soil_temp > 2000:
               soil_temp_val = 24
            else:
               soil_temp_val = 20

            self.client.publish('soil_temp', soil_temp_val)
        elif mode == 'soil_moisture':
            self.ser.write(self.sensor_format['soil_moisture'])
            soil_moist = self.serial_read_data()
            soil_moist_val = 0
            if soil_moist > 0:
               soil_moist_val = 80
            else:
               soil_moist_val = 50

            self.client.publish('soil_moist', soil_moist_val)
    
    def sensor_reading_loop(self):
        while True:
            self.readSensor('soil_temperature')
            time.sleep(10)  # Adjust the interval as needed
            self.readSensor('soil_moisture')
            time.sleep(10)  # Adjust the interval as needed
    
    def sched_whole_process(self):
        time.sleep(5)
        self.setMixer1(False)
        self.setMixer2(True)
        time.sleep(5)
        self.setMixer2(False)
        
        self.setMixer3(True)
        time.sleep(5)
        self.setMixer3(False)


def farm_sched_thread(event, sched):
    while True:
        event.wait()
        sched.sched_whole_process()
        event.clear()


server = adafruit_server()
f = farm_sched(server.client)


def client_sched():
    event.set()


server.setCallBack(client_sched)

if __name__ == '__main__':
    event = Event()

    t2 = Thread(target=farm_sched_thread, args=(event, f))
    t3 = Thread(target=f.sensor_reading_loop)  # New thread for reading sensors

    t2.start()
    t3.start()

    while True:
        time.sleep(1)
