local Swich =1

gpio.mode(i,gpio.OUTPUT)
gpio.write(i,gpio.LOW)

m = mqtt.Client("00021",5,"homekit","2000001218")
m:lwt("homebridge/to/set/reachability", "{\"name\": \"00021\", \"reachable\": false}", 0, 0)

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

end)