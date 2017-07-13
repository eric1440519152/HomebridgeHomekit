--系统配置
local cycle = 300
local chipid = node.chipid()..""
--led个数
local led= 100

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

--全局状态变量
local R = 0
local G = 0
local B = 0
local RGBlight_Switch = "False"
local RGBlight_last_R = 0
local RGBlight_last_G = 0
local RGBlight_last_B = 0
local RGBlight_last_brightness = 0

--初始化MQTT客户端
RGBlight_MQTT = mqtt.Client("RGBlight_MQTT_"..chipid,5,MQTT_Username,MQTT_Password)

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
             
            print("Config done, IP is "..wifi.sta.getip())
            
            RGBlight_MQTT:connect(MQTT_IP,1883,0,1,
                function(client)

                    --订阅设置Topic
				    RGBlight_MQTT:subscribe("tokit/rgblight/set",0)
					print("MQTT Connect!")
					
					tmr.stop(1)
                end,
                function(client, reason)
                    print("failed reason: "..reason)
                    node.restart()
			    end
            )
        end
    end
)
tmr.alarm(0,1000,tmr.ALARM_AUTO, 
	function()
	RGBlight_MQTT:on("message",
		function(client, topic, data)
			if data ~= nil then
				t = cjson.decode(data)
				if t["state"] == "OFF" then
					--关灯
					ws2812.init()
					i, buffer = 0, ws2812.newBuffer(led,3)
					tmr.alarm(0,led,1,function()
						buffer:fill(0,0,0)
						ws2812.write(buffer)
					end)
				else
					if t["brightness"] ~= nil then
						--调节亮度
						Y = 0.30 * RGBlight_last_R + 0.59 * RGBlight_last_G + 0.11 * RGBlight_last_B
						U = 0.493 * (RGBlight_last_B - Y)
						V = 0.877 * (RGBlight_last_R - Y)
						Y = t["brightness"]
						print("Y:"..Y)
						print("U:"..U)
						print("V:"..V)
						
						R = Y + 1.14 * V
						G = Y - 0.39 * U - 0.58 * V
						B = Y + 2.03 * U
						
						print("R:"..R)
						print("G:"..G)
						print("B:"..B)
						
						ws2812.init()
						i,buffer = 0,ws2812.newBuffer(led,3)
						buffer:fade(2)
						buffer:fill(G,R,B)
						tmr.alarm(0,10,1,
							function()
								ws2812.write(buffer)
							end
						)
						
					elseif t["color"] ~= nil then
						--设置颜色
						R = t["color"]["r"]
						G = t["color"]["g"]
						B = t["color"]["b"]
						ws2812.init()
						i,buffer = 0,ws2812.newBuffer(led,3)
						print("R:"..R)
						print("G:"..G)
						print("B:"..B)
						buffer:fade(2)
						buffer:fill(G,R,B)
						tmr.alarm(0,10,1,
							function()
								ws2812.write(buffer)
							end
						)
						RGBlight_last_R = R
						RGBlight_last_G = G
						RGBlight_last_B = B
						
					end
				end
			end
		end
	)
	end
)