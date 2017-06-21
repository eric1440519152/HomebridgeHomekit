local Swich =1

gpio.mode(i,gpio.OUTPUT)
gpio.write(i,gpio.LOW)

m = mqtt.Client("00021",5,"homekit","2000001218")
m:lwt("homebridge/to/set/reachability", "{\"name\": \"00021\", \"reachable\": false}", 0, 0)