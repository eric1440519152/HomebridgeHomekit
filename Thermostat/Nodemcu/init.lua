i=1
local cycle = 300
local chipid = node.chipid()..""
local sensor = 4

local Temper_Name = "temperature"
local Temper_Service = "TemperatureSensor"
local Temper_Characteristic = "CurrentTemperature"
local m2_name = "humidity"
local m2_service = "HumiditySensor"
local m2_characteristic = "CurrentRelativeHumidity"

gpio.mode(i,gpio.OUTPUT)
gpio.write(i,gpio.LOW)

m = mqtt.Client("00021",5,"homekit","2000001218")
m1 = mqtt.Client(chipid.."m1",cycle,"homekit","2000001218")
m2 = mqtt.Client(chipid.."m2",cycle,"homekit","2000001218")
m3 = mqtt.Client("flex_lamp1487952",5,"homekit","2000001218")
m:lwt("homebridge/to/set/reachability", "{\"name\": \"00021\", \"reachable\": false}", 0, 0)
m1:lwt("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-"..Temper_Name.."\", \"reachable\": false}", 0, 0)
m2:lwt("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-"..m2_name.."\", \"reachable\": false}", 0, 0)
m3:lwt("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-Thermostat\", \"reachable\": false}", 0, 0)

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

		m1:connect("192.168.1.17", 1883, 0, 1,
			function(client)
				print("m1 connected")
				-- m1:subscribe("homebridge/from/set",0, function(client) print("subscribe homebridge command success") end)    --订阅控制主题信息
				m1:publish("homebridge/to/add", "{\"name\": \""..chipid.."-"..Temper_Name.."\", \"service\": \""..Temper_Service.."\"}", 0, 0, function(client) print("try to add this "..Temper_Name.." node to homebridge") end)
				m1:publish("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-"..Temper_Name.."\", \"reachable\": true}", 0,0 , function(client) print("set this "..Temper_Name.." node to online in homebridge") end)
			end, 
			function(client, reason)
				print("failed reason: "..reason)
				node.restart()
			end
		)

		m2:connect("192.168.1.17", 1883, 0, 1,
			function(client)
				print("m2 connected")
				-- m2:subscribe("homebridge/from/set",0, function(client) print("subscribe homebridge command success") end)    --订阅控制主题信息
				m2:publish("homebridge/to/add", "{\"name\": \""..chipid.."-"..m2_name.."\", \"service\": \""..m2_service.."\"}", 0, 0, function(client) print("try to add this "..m2_name.." node to homebridge") end)
				m2:publish("homebridge/to/set/reachability", "{\"name\": \""..chipid.."-"..m2_name.."\", \"reachable\": true}", 0,0 , function(client) print("set this "..m2_name.." node to online in homebridge") end)
				end, 
			function(client, reason)
				print("failed reason: "..reason)
				node.restart()
			end
		)
		
		m3:connect("192.168.1.17", 1883, 0, 1,
			function(client)
				print("m3 connected")
				m3:subscribe("homebridge/from/set",0)
				m3:publish("homebridge/to/add", "{\"name\":\"flex_lamp1487952\",\"service_name\":\"light\", \"service\": \"Thermostat\"}", 0, 0, function(client) print("try to add this Thermostat node to homebridge") end)
				m3:publish("homebridge/to/set/reachability", "{\"name\":\"flex_lamp1487952\",\"service_name\":\"light\", \"reachable\": true}", 0,0 , function(client) print("set this Thermostat node to online in homebridge") end)
				m3:publish("homebridge/to/set","{\"name\":\"flex_lamp1487952\",\"service_name\":\"light\",\"characteristic\":\"TargetHeatingCoolingState\",\"value\":0}",0,0, 
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
	
	m3:on("message", 
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
			m1:publish("homebridge/to/set","{\"name\": \""..chipid.."-"..Temper_Name.."\", \"characteristic\": \""..Temper_Characteristic.."\", \"value\": "..temp.."}",0,0, 
				function(client) 
					print("sent now "..Temper_Name..":"..temp) 
				end
			)
			m2:publish("homebridge/to/set","{\"name\": \""..chipid.."-"..m2_name.."\", \"characteristic\": \""..m2_characteristic.."\", \"value\": "..humi.."}",0,0, 
				function(client) 
					print("sent now "..m2_name..":"..humi) 
				end
			)
			m3:publish("homebridge/to/set","{\"name\": \"flex_lamp1487952\",\"service_name\":\"light\", \"characteristic\": \"CurrentTemperature\", \"value\": "..temp.."}",0,0, 
				function(client) 
					print("sent now") 
				end
			)
	elseif status == dht.ERROR_CHECKSUM then
			print( "m1 DHT Checksum error." )
	elseif status == dht.ERROR_TIMEOUT then
			print( "m1 DHT timed out." )
	end

end)