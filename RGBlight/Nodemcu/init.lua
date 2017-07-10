--系统配置

local cycle = 300
local chipid = node.chipid()..""

--版本号
local vn = "v0.2.01"
wifi.setmode(wifi.STATION)
wifi.sta.config("ChinaNet-HomeWifi","hze20001218")


--MQTT设置

local MQTT_IP = "192.168.1.17"
local MQTT_Username = "homekit"
local MQTT_Password = "2000001218"

--初始化MQTT客户端
RGBlight_MQTT = mqtt.Client("RGBlight_MQTT"..chipid,5,MQTT_Username,MQTT_Password)

--连接Wifi
print("Connect Wifi")
wifi.sta.connect()

--