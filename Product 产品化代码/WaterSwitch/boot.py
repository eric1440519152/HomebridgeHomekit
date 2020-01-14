import network

def do_connect():
    import network
    sta_if = network.WLAN(network.STA_IF)
    sta_if.disconnect()
    if not sta_if.isconnected():
        print('connecting to network...')
        sta_if.active(True)
        sta_if.connect('esHome-2.4G', 'hze20001218')
        while not sta_if.isconnected():
            pass
    print('network config:', sta_if.ifconfig())

do_connect()