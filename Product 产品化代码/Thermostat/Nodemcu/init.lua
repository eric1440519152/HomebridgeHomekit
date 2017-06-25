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


--传感器接口设置
local sensor = 4
local MotionSensor = 3

--数据通信口设置
local Thermostat_Temper_Arduino = 1
local Thermostat_Mode_Arduino = 2

--附件类型预置
--温度部分直接跟恒温器整合，应该用不上
local Temper_Name = "温度传感器"
local Temper_Service = "TemperatureSensor"
local Temper_Characteristic = "CurrentTemperature"

--主附件服务
local Therm_Name = "恒温器"
local Therm_Service = "Thermostat"

--作为一个附件的附加Service注册
local Humi_Name = "湿度传感器"
local Humi_Service = "HumiditySensor"
local Humi_Characteristic = "CurrentRelativeHumidity"

local Moti_Name = "动作传感器"
local Moti_Service = "MotionSensor"


--全局状态变量
local MotionSensor_State = "False"

--预置所有附件NAME字段 作为ID
Therm_ID = "\"Tokit_"..Therm_Service.."System_"..chipid.."_"..vn.."\""
Therm_ID_Raw = "Tokit_"..Therm_Service.."System_"..chipid.."_"..vn

--初始化MQTT客户端
Therm_MQTT = mqtt.Client("Therm_MQTT_"..chipid,5,MQTT_Username,MQTT_Password)

--设置离线遗言
Therm_MQTT:lwt("homebridge/to/set/reachability", "{\"name\":"..Therm_ID..", \"reachable\": false}", 0, 0)

--传感器初始化
gpio.mode(MotionSensor,gpio.INPUT)
gpio.mode(Thermostat_Mode_Arduino,gpio.OUTPUT)
gpio.mode(Thermostat_Temper_Arduino,gpio.OUTPUT)

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
		
		--连接恒温器MQTT
		Therm_MQTT:connect(MQTT_IP, 1883, 0, 1,
			function(client)
				print("Therm_MQTT connected")

				--订阅设置Topic
				Therm_MQTT:subscribe("homebridge/from/set",0)

				--添加恒温器附件
				Therm_MQTT:publish("homebridge/to/add", "{\"name\":"..Therm_ID..",\"service_name\":\""..Therm_Name.."\", \"service\": \""..Therm_Service.."\"}", 0, 0, function(client) print("ThermostatSystem Added") end)
				
				--添加湿度传感器Service
				Therm_MQTT:publish("homebridge/to/add/service", "{\"name\":"..Therm_ID..",\"service_name\":\""..Humi_Name.."\", \"service\": \""..Humi_Service.."\"}", 0, 0, function(client) print("HumiditySensor Added") end)
				
				--添加动作传感器Service
				Therm_MQTT:publish("homebridge/to/add/service", "{\"name\":"..Therm_ID..",\"service_name\":\""..Moti_Name.."\", \"service\": \""..Moti_Service.."\"}", 0, 0, function(client) print("MotionSensor Added") end)

				--发送心跳
				Therm_MQTT:publish("homebridge/to/set/reachability", "{\"name\":"..Therm_ID..",\"service_name\":\""..Therm_Name.."\", \"reachable\": true}", 0,0 , function(client) print("Thermostat Ping") end)
				Therm_MQTT:publish("homebridge/to/set/reachability", "{\"name\":"..Therm_ID..",\"service_name\":\""..Humi_Name.."\", \"reachable\": true}", 0,0 , function(client) print("HumiditySensor Ping") end)
				Therm_MQTT:publish("homebridge/to/set/reachability", "{\"name\":"..Therm_ID..",\"service_name\":\""..Moti_Name.."\", \"reachable\": true}", 0,0 , function(client) print("MotionSensor Ping") end)

				--初始化MQTT设置
				--设置关机
				Therm_MQTT:publish("homebridge/to/set","{\"name\":"..Therm_ID..",\"service_name\":\""..Therm_Name.."\",\"characteristic\":\"TargetHeatingCoolingState\",\"value\":0}",0,0, 
					
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

--主循环
tmr.alarm(0,1500,tmr.ALARM_AUTO, 
function()
		
	--恒温器收到指令
	Therm_MQTT:on("message", 
		function(client, topic, data)
			
			if data ~= nil then
				t = cjson.decode(data)
				if t["name"] == Therm_ID_Raw  and t["service_name"] == Therm_Name then
					if t["characteristic"] == "TargetHeatingCoolingState" then
						if t["value"] == 0 then
						-- 关闭
						print("off")
						pwm.setup(Thermostat_Mode_Arduino,500,100) 
						pwm.start(Thermostat_Mode_Arduino)
						elseif t["value"] == 1 then
						-- 制热
						print("hot")
						pwm.setup(Thermostat_Mode_Arduino,500,200)
						pwm.start(Thermostat_Mode_Arduino)
						elseif t["value"] == 2 then
						-- 制冷
						print("cold")
						pwm.setup(Thermostat_Mode_Arduino,500,300)
						pwm.start(Thermostat_Mode_Arduino)
						elseif t["value"] == 3 then
						-- 自动
						print("auto")
						pwm.setup(Thermostat_Mode_Arduino,500,400)
						pwm.start(Thermostat_Mode_Arduino)
						end
					elseif t["characteristic"] == "TargetTemperature" then
						if  t["value"] <= 16 then
							pwm.setup(Thermostat_Temper_Arduino,500,160)
							pwm.start(Thermostat_Temper_Arduino)
						elseif t["value"] >= 31 then
							pwm.setup(Thermostat_Temper_Arduino,500,310)
							pwm.start(Thermostat_Temper_Arduino)
						else
							i = t["value"] 
							i = i * 10
							pwm.setup(Thermostat_Temper_Arduino,500,i)
							pwm.start(Thermostat_Temper_Arduino)
						end
						print("Sent_Set_Temper:"..t["value"])
					end
				end
			end
		end
	)
	
	-- 主动上传温度传感器及湿度传感器数据
	status, temp, humi, temp_dec, humi_dec = dht.read11(sensor)
	if status == dht.OK then

			--上传湿度传感器数据
			Therm_MQTT:publish("homebridge/to/set","{\"name\": "..Therm_ID..",\"service_name\":\""..Humi_Name.."\",\"characteristic\": \""..Humi_Characteristic.."\", \"value\": "..humi.."}",0,0, 
				function(client) 
					print("Sent_"..Humi_Service..":"..humi) 
				end
			)

			--上传恒温器的温度数据
			Therm_MQTT:publish("homebridge/to/set","{\"name\": "..Therm_ID..",\"service_name\":\""..Therm_Name.."\", \"characteristic\": \"CurrentTemperature\", \"value\": "..temp.."}",0,0, 
				function(client) 
					print("Sent_"..Temper_Service..":"..temp) 
				end
			)
			
	elseif status == dht.ERROR_CHECKSUM then
			print( "DHT Checksum error." )
	elseif status == dht.ERROR_TIMEOUT then
			print( "DHT timed out." )
	end

	
	--动作传感器


	--读取动作传感器数据
	if gpio.read(MotionSensor) == 1 then
		--检测到人
		MotionSensor_State = "true"
	elseif gpio.read(MotionSensor) == 0 then
		--未检测到人
		MotionSensor_State = "false"
	else
		--其他错误
		MotionSensor_State = "Err"
	end

	--上传动作传感器数据
	Therm_MQTT:publish("homebridge/to/set","{\"name\": "..Therm_ID..",\"service_name\":\""..Moti_Name.."\", \"characteristic\": \"MotionDetected\", \"value\": "..MotionSensor_State.."}",0,0, 
		function(client) 
			print("Sent_"..Moti_Service..":"..MotionSensor_State) 
		end
	)

end)