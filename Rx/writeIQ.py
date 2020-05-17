#!usr/bin/env python2

# Author: Kareem Attiah/ Ammar Alhosainy
# Date: Nov 15th, 2017/ March 3rd, 2018

from gnuradio import gr
from gnuradio import uhd
from gnuradio import blocks
import sys
import threading
import time

global inaddr
global name 
global runFor #sec

class writeIQ(gr.top_block):

    def __init__(self):
        gr.top_block.__init__(self)

        global name, runFor, inaddr
        deviceaddr = "addr=192.168.10"+inaddr

        # Define variables and their default values
        self.samp_rate = 20e6
        self.cbw = 20e6
        self.gain = 50
        self.cfreq = 5.765e9 #ch153/20=5.765e9, ch36/20=5.180e9, ch153/40=5.755e9
        self.antenna = "RX2"
        self.file_name = 'Receive' + name +'.bin'
        # Define blocks
        # 1) USRP Block
        self.usrpSource = uhd.usrp_source(
                ",".join(("", "")),
                uhd.stream_args(
                    cpu_format="fc32",
                    channels=range(1),
                ),
            )

        # self.usrpSource = uhd.usrp_source(
        #     device_addr="addr=192.168.10.3",
        #     io_type=uhd.io_type.COMPLEX_FLOAT32,
        #     num_channels=1,
        # )

        # 2) Set default parameters
        self.usrpSource.set_samp_rate(self.samp_rate)
        self.usrpSource.set_center_freq(self.cfreq, 0)
        self.usrpSource.set_gain(self.gain, 0)
        self.usrpSource.set_antenna(self.antenna, 0)
        self.usrpSource.set_bandwidth(self.cbw, 0)


        # 2) File Sink
        self.fileSnk = blocks.file_sink(gr.sizeof_gr_complex*1, self.file_name, False)


        # Define connections
        self.connect((self.usrpSource, 0), (self.fileSnk, 0))

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate
        self.usrpSource.set_samp_rate(self.samp_rate)

    def get_gain(self):
        return self.gain

    def set_gain(self, gain):
        self.gain = gain
        self.usrpSource.set_gain(self.gain, 0)

    def get_cfreq(self):
        return self.center_frequency

    def set_cfreq(self, cfreq):
        self.cfreq = cfreq
        self.usrpSource.set_center_freq(self.cfreq, 0)

    def get_cbw(self):
        return self.cbw

    def set_cbw(self, cbw):
        self.cbw = cbw
        self.usrpSource.set_bandiwdth(self.cbw, 0)


def doWork():
    classInst = writeIQ()
    classInst.run()

def main():
    global name, runFor, inaddr
    name = '0'
    runFor = 2.5  # sec
    inaddr = ".2"
    if len(sys.argv) > 1:
        inaddr = sys.argv[1]
        name = sys.argv[2]
        runFor = float(sys.argv[3])  # sec
    t = threading.Thread(target=doWork)
    t.daemon = True
    t.start()
    # time.sleep(1.9828)   #to initiate the device on HP laptop
    time.sleep(runFor)
    print '## END READING ## Duration =', runFor, ' s'
    quit()

if __name__  == '__main__':
    main()


