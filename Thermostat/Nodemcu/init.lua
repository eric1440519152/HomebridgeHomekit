local cycle = 300
local chipid = node.chipid()..""

local MQTT_Username = "homekit"
local MQTT_Password = "2000001218"

local sensor = 4

local Temper_Name = "温度传感器"
local Temper_Service = "TemperatureSensor"
local Temper_Characteristic = "CurrentTemperature"
local Humi_Name = "湿度传感器"
local Humi_Service = "HumiditySensor"
local Humi_Characteristic = "CurrentRelativeHumidity"

--初始化MQTT客户端
Temper_MQTT = mqtt.Client("Temper_MQTT"..chipid,cycle,MQTT_Username,MQTT_Password)
Humi_MQTT = mqtt.Client("Humi_MQTT"..chipid,cycle,MQTT_Username,MQTT_Password)
Therm_MQTT = mqtt.Client("Therm_MQTT"..chipid,5,MQTT_Username,MQTT_Password)

--设置离线遗言
Temper_MQTT:lwt("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-"..Temper_Name.."\", \"reachable\": false}", 0, 0)
Humi_MQTT:lwt("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-"..Humi_Name.."\", \"reachable\": false}", 0, 0)
Therm_MQTT:lwt("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-Thermostat\", \"reachable\": false}", 0, 0)

print("set up wifi mode")
wifi.setmode(wifi.STATION)
wifi.sta.config("ChinaNet-HomeWifi","hze20001218")
--here SSID and PassWord should be modified according your wireless router
wifi.sta.connect()

tmr.alarm(1, 1000, 1, 
function()
	
	if wifi.sta.getip()== nil then
		print("IP unavaiable, Waiting...")
	else
		tmr.stop(1)
		print("Config done, IP is "..wifi.sta.getip())
		
		m:connect("192.168.1.17",1883,0,1,
			function(client)
				m:subscribe("homebridge/from/set",0)
				m:publish("homebridge/to/add", "{\"name\": \"00021\", \"service\": \"Switch\"}", 0, 0)
				m:publish("homebridge/to/set/reachability", "{\"name\": \"00021\", \"reachable\": true}", 0,0) 
				--gpio.trig(monitor, "both", switching)
				print("MQTT REG")
				if gpio.read(i) == 1 then
					m:publish("homebridge/to/set","{\"name\":\"00021\", \"characteristic\":\"On\", \"value\":true}",0,0)
				else
					m:publish("homebridge/to/set","{\"name\":\"00021\", \"characteristic\":\"On\", \"value\":false}",0,0)
				end
			end,
			function(client, reason)
				print("failed reason: "..reason)
				node.restart()
			end
		)

		Temper_MQTT:connect("192.168.1.17", 1883, 0, 1,
			function(client)
				print("Temper_MQTT connected")
				-- Temper_MQTT:subscribe("homebridge/from/set",0, function(client) print("subscribe homebridge command success") end)    --订阅控制主题信息
				Temper_MQTT:publish("homebridge/to/add", "{\"name\": \""..chipid.."-"..Temper_Name.."\", \"service\": \""..Temper_Service.."\"}", 0, 0, function(client) print("try to add this "..Temper_Name.." node to homebridge") end)
				Temper_MQTT:publish("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-"..Temper_Name.."\", \"reachable\": true}", 0,0 , function(client) print("set this "..Temper_Name.." node to online in homebridge") end)
			end, 
			function(client, reason)
				print("failed reason: "..reason)
				node.restart()
			end
		)

		Humi_MQTT:connect("192.168.1.17", 1883, 0, 1,
			function(client)
				print("Humi_MQTT connected")
				-- Humi_MQTT:subscribe("homebridge/from/set",0, function(client) print("subscribe homebridge command success") end)    --订阅控制主题信息
				Humi_MQTT:publish("homebridge/to/add", "{\"name\": \""..chipid.."-"..Humi_Name.."\", \"service\": \""..Humi_Service.."\"}", 0, 0, function(client) print("try to add this "..Humi_Name.." node to homebridge") end)
				Humi_MQTT:publish("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-"..Humi_Name.."\", \"reachable\": true}", 0,0 , function(client) print("set this "..Humi_Name.." node to online in homebridge") end)
				end, 
			function(client, reason)
				print("failed reason: "..reason)
				node.restart()
			end
		)
		
		Therm_MQTT:connect("192.168.1.17", 1883, 0, 1,
			function(client)
				print("Therm_MQTT connected")
				Therm_MQTT:subscribe("homebridge/from/set",0)
				Therm_MQTT:publish("homebridge/to/add", "{\"name\":\"flex_lamp1487952\",\"service_name\":\"light\", \"service\": \"Thermostat\"}", 0, 0, function(client) print("try to add this Thermostat node to homebridge") end)
				Therm_MQTT:publish("homebridge/to/set/reachability", "{\"name\":\"flex_lamp1487952\",\"service_name\":\"light\", \"reachable\": true}", 0,0 , function(client) print("set this Thermostat node to online in homebridge") end)
				Therm_MQTT:publish("homebridge/to/set","{\"name\":\"flex_lamp1487952\",\"service_name\":\"light\",\"characteristic\":\"TargetHeatingCoolingState\",\"value\":0}",0,0, 
					function(client) 
						print("set off")
					end
				)
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
		
	m:on("message", 
		function(client, topic, data) 
			if data ~= nil then
				t = cjson.decode(data)
				if t["name"] == "00021" then
					if t["value"] == true then
						gpio.write(i, gpio.LOW)
					elseif t["value"] == false then
						gpio.write(i, gpio.HIGH)
					end
				end
			end
		end
	)
	
	Therm_MQTT:on("message", 
		function(client, topic, data)
			
			if data ~= nil then
				t = cjson.decode(data)
				if t["name"] == "flex_lamp1487952" then
					if t["characteristic"] == "TargetHeatingCoolingState" then
						if t["value"] == 0 then
						-- 关闭
						print("off")
						pwm.setup(5,500,100) 
						pwm.start(5)
						elseif t["value"] == 1 then
						-- 制热
						print("hot")
						pwm.setup(5,500,200)
						pwm.start(5)
						elseif t["value"] == 2 then
						-- 制冷
						print("cold")
						pwm.setup(5,500,300)
						pwm.start(5)
						elseif t["value"] == 3 then
						-- 自动
						print("auto")
						pwm.setup(5,500,400)
						pwm.start(5)
						end
					elseif t["characteristic"] == "TargetTemperature" then
						if  t["value"] <= 16 then
							pwm.setup(6,500,160)
							pwm.start(6)
						elseif t["value"] >= 31 then
							pwm.setup(6,500,310)
							pwm.start(6)
						else
							i = t["value"] 
							i = i * 10
							pwm.setup(6,500,i)
							pwm.start(6)
						end
						print(t["value"])
					end
				end
			end
		end
	)
	
	status, temp, humi, temp_dec, humi_dec = dht.read11(sensor)
	if status == dht.OK then
			Temper_MQTT:publish("homebridge/to/set","{\"name\": \""..chipid.."-"..Temper_Name.."\", \"characteristic\": \""..Temper_Characteristic.."\", \"value\": "..temp.."}",0,0, 
				function(client) 
					print("sent now "..Temper_Name..":"..temp) 
				end
			)
			Humi_MQTT:publish("homebridge/to/set","{\"name\": \""..chipid.."-"..Humi_Name.."\", \"characteristic\": \""..Humi_Characteristic.."\", \"value\": "..humi.."}",0,0, 
				function(client) 
					print("sent now "..Humi_Name..":"..humi) 
				end
			)
			Therm_MQTT:publish("homebridge/to/set","{\"name\": \"flex_lamp1487952\",\"service_name\":\"light\", \"characteristic\": \"CurrentTemperature\", \"value\": "..temp.."}",0,0, 
				function(client) 
					print("sent now") 
				end
			)
	elseif status == dht.ERROR_CHECKSUM then
			print( "Temper_MQTT DHT Checksum error." )
	elseif status == dht.ERROR_TIMEOUT then
			print( "Temper_MQTT DHT timed out." )
	end

end)