--系统配置
local cycle = 300
local chipid = node.chipid()..""
--版本号
local vn = "v0.2.01"
wifi.setmode(wifi.STATION)
wifi.sta.config("esHome-2.4G","hze20001218")


--MQTT设置
local MQTT_IP = "192.168.0.120"
local MQTT_Username = "homekit"
local MQTT_Password = "2000001218"

--传感器接口设置
local Switch = 5
local sensor = 6

--附件类型预置
local Temper_Name = "温度传感器"
local Temper_Service = "TemperatureSensor"
local Temper_Characteristic = "CurrentTemperature"

--作为一个附件的附加Service注册
local Humi_Name = "湿度传感器"
local Humi_Service = "HumiditySensor"
local Humi_Characteristic = "CurrentRelativeHumidity"

local Switch_Name = "淋花阀门"
local Switch_Service = "Switch"

--预置所有附件NAME字段 作为ID
WaterSystem_ID = "\"Tokit_WaterSystem_"..chipid.."_"..vn.."\""
WaterSystem_ID_Raw = "Tokit_WaterSystem_"..chipid.."_"..vn

--初始化MQTT客户端
WaterSystem_MQTT = mqtt.Client("WaterSystem_MQTT"..chipid,5,MQTT_Username,MQTT_Password)

--设置离线遗言
WaterSystem_MQTT:lwt("homebridge/to/set/reachability", "{\"name\":"..WaterSystem_ID..", \"reachable\": false}", 0, 0)

--传感器初始化
gpio.mode(Switch,gpio.OUTPUT)

--连接Wifi
print("Set up Wifi")
wifi.sta.connect()

--初始化循环
tmr.alarm(1, 1000, 1, 
function()
	
	if wifi.sta.getip()== nil then
		print("IP unavaiable, Waiting...")
	else
		tmr.stop(1)
		print("Config done, IP is "..wifi.sta.getip())
		
		WaterSystem_MQTT:connect(MQTT_IP,1883,0,1,
			function(client)

				--订阅设置Topic
				WaterSystem_MQTT:subscribe("homebridge/from/set",0)

				--添加开关附件
				WaterSystem_MQTT:publish("homebridge/to/add", "{\"name\":"..WaterSystem_ID..",\"service_name\":\""..Switch_Name.."\", \"service\": \""..Switch_Service.."\"}", 0, 0)
				
				--添加湿度传感器Service
				WaterSystem_MQTT:publish("homebridge/to/add/service", "{\"name\":"..WaterSystem_ID..",\"service_name\":\""..Humi_Name.."\", \"service\": \""..Humi_Service.."\"}", 0, 0, function(client) print("HumiditySensor Added") end)

				--添加温度传感器Service
				WaterSystem_MQTT:publish("homebridge/to/add/service", "{\"name\":"..WaterSystem_ID..",\"service_name\":\""..Temper_Name.."\", \"service\": \""..Temper_Service.."\"}", 0, 0, function(client) print("HumiditySensor Added") end)
				
				
				--发送心跳
				WaterSystem_MQTT:publish("homebridge/to/set/reachability", "{\"name\":"..WaterSystem_ID..",\"service_name\":\""..Switch_Name.."\", \"reachable\": true}", 0,0) 
				WaterSystem_MQTT:publish("homebridge/to/set/reachability", "{\"name\":"..WaterSystem_ID..",\"service_name\":\""..Humi_Name.."\", \"reachable\": true}", 0,0 )
				WaterSystem_MQTT:publish("homebridge/to/set/reachability", "{\"name\":"..WaterSystem_ID..",\"service_name\":\""..Temper_Name.."\", \"reachable\": true}", 0,0 )
				
				--初始化
				print("MQTT REG")
				
				if gpio.read(Switch) == 1 then
					WaterSystem_MQTT:publish("homebridge/to/set","{\"name\":"..WaterSystem_ID..",\"service_name\":\""..Switch_Name.."\", \"characteristic\":\"On\", \"value\":true}",0,0)
				else
					WaterSystem_MQTT:publish("homebridge/to/set","{\"name\":"..WaterSystem_ID..",\"service_name\":\""..Switch_Name.."\", \"characteristic\":\"On\", \"value\":false}",0,0)
				end

			end,
			function(client, reason)
				print("failed reason: "..reason)
				node.restart()
			end
		)	
	end

end)

tmr.alarm(0,10000,tmr.ALARM_AUTO, 
function()
		
	WaterSystem_MQTT:on("message", 
		function(client, topic, data) 
			if data ~= nil then
				t = cjson.decode(data)
				if t["name"] == WaterSystem_ID_Raw and t["service_name"] == Switch_Name then
					if t["value"] == true then
						gpio.write(Switch, gpio.HIGH)
					elseif t["value"] == false then
						gpio.write(Switch, gpio.LOW)
					end
				end
			end
		end
	)

	-- 主动上传温度传感器及湿度传感器数据
	status, temp, humi, temp_dec, humi_dec = dht.read11(sensor)
	if status == dht.OK then

			--上传湿度传感器数据
			WaterSystem_MQTT:publish("homebridge/to/set","{\"name\": "..WaterSystem_ID..",\"service_name\":\""..Humi_Name.."\",\"characteristic\": \""..Humi_Characteristic.."\", \"value\": "..humi.."}",0,0, 
				function(client) 
					print("Sent_"..Humi_Service..":"..humi) 
				end
			)

			--上传恒温器的温度数据
			WaterSystem_MQTT:publish("homebridge/to/set","{\"name\": "..WaterSystem_ID..",\"service_name\":\""..Temper_Name.."\", \"characteristic\": \""..Temper_Characteristic.."\", \"value\": "..temp.."}",0,0, 
				function(client) 
					print("Sent_"..Temper_Service..":"..temp) 
				end
			)
			
	elseif status == dht.ERROR_CHECKSUM then
			print( "DHT Checksum error." )
	elseif status == dht.ERROR_TIMEOUT then
			print( "DHT timed out." )
	end

end)