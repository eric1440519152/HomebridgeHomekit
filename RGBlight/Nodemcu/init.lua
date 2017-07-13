--系统配置
local cycle = 300
local chipid = node.chipid()..""

--版本号
local vn = "v0.1.01"
wifi.setmode(wifi.STATION)
wifi.sta.config("ChinaNet-HomeWifi","hze20001218")


--MQTT设置
local MQTT_IP = "192.168.1.17"
local MQTT_Username = "homekit"
local MQTT_Password = "2000001218"

--预制字段
RGBlight_ID = "\"Tokit_RGBlight_"..chipid.."_"..vn.."\""
RGBlight_ID_Raw = "Tokit_RGBlight_"..chipid.."_"..vn

--初始化MQTT客户端
RGBlight_MQTT = mqtt.Client("RGBlight_MQTT"..chipid,5,MQTT_Username,MQTT_Password)

--设置MQTT遗言
RGBlight_MQTT:lwt("tokit/rgblight/set", "{\"state\":\"OFF\", \"brightness\": 0}", 0, 0)

--连接Wifi
print("Connect Wifi")
wifi.sta.connect()

--初始化循环
tmr.alarm(1,1000,1,
    function()
        if wifi.sta.getip() == nil then
            print("IP unavaiable, Waiting...")
        else
            tmr.stop(1) 
            print("Config done, IP is "..wifi.sta.getip())
            
            RGBlight_MQTT:connect(MQTT_IP,1883,0,1,
                function(client)

                    --订阅设置Topic
				    WaterSystem_MQTT:subscribe("tokit/rgblight/set",0)
                end,
                function(client, reason)
                    print("failed reason: "..reason)
                    node.restart()
			    end
            )
        end
    end
)