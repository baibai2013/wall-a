import usbmux

print "walltalk starting"
mux = usbmux.USBMux()

print "Waiting for devices..."
if not mux.devices:
    mux.process(1.0)
if not mux.devices:
    print "No device found"

dev = mux.devices[0]
print "connection to device %s" % str(dev)

psock = mux.connect(dev,2345)

done = False
while not done:
    msg = psock.recv(17)
    print "Received:%s" % msg


psock.close()