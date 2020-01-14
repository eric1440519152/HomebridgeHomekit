import time
from machine import Pin
from umqtt.robust import MQTTClient

#实例化所有对象
switch=Pin(4,Pin.OUT)
led=Pin(2,Pin.OUT)
c = MQTTClient("WaterSwitchEEF", "192.168.0.155",0,'eric','HzE20001218')

def GetMsg(topic, msg):
    print(topic, msg)
    if topic==b'esHome/garden/waterSwitch/set':
        if msg==b'ON':
            switch.on()
            Flash()
        if msg==b'OFF':
            switch.off()
            Flash()

def Flash(times=1):
    i = 0
    while i<times:
        led.off()
        time.sleep(0.2)
        led.on()
        time.sleep(0.2)
        i=i+1

c.set_callback(GetMsg)
c.connect()
Flash(2)

c.subscribe(b"esHome/garden/waterSwitch/set")
c.publish('esHome/garden/waterSwitch/available','online')

#初始化状态
switch.off()

while True:
    c.check_msg()
    if switch.value()==1:
        c.publish('esHome/garden/waterSwitch/state','ON')
    if switch.value()==0:
        c.publish('esHome/garden/waterSwitch/state','OFF')
    time.sleep(1)