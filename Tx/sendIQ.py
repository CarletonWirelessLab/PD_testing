#!/usr/bin/env python2
# -*- coding: utf-8 -*-
##################################################
# GNU Radio Python Flow Graph
# Title: Top Block
# Generated: Fri Feb  7 15:10:50 2020
##################################################

from gnuradio import blocks
from gnuradio import eng_notation
from gnuradio import gr
from gnuradio import uhd
from gnuradio.eng_option import eng_option
from gnuradio.filter import firdes
from optparse import OptionParser
import pmt
import sys
import time

global inaddr

class sendIQ(gr.top_block):

    def __init__(self):
        gr.top_block.__init__(self, "Top Block")
        global inaddr
        deviceAddress = "addr=192.168.10"+inaddr
        # File source
        # self.file_source = blocks.file_source(gr.sizeof_gr_complex*1, 'JamSignalFrame.bin', True)
        self.file_source = blocks.file_source(gr.sizeof_gr_complex*1, 'testingSignal.bin', True)

        # self.file_source.set_begin_tag(pmt.PMT_NIL)
        self.USRP_TX = uhd.usrp_sink(
        	",".join((deviceAddress, "")),
        	uhd.stream_args(
        		cpu_format="fc32",
        		#'sc16',
        		channels=range(1),
        	),
        )

        self.USRP_TX.set_samp_rate(20e6)
        self.USRP_TX.set_bandwidth(20e6, 0)
        self.USRP_TX.set_center_freq(5.765e9, 0)
        # self.USRP_TX.set_normalized_gain(.75, 0)  # max is 1
        self.USRP_TX.set_gain(25, 0)
        self.USRP_TX.set_antenna('TX/RX', 0)
        # self.USRP_TX.set_clock_rate(200e6, uhd.ALL_MBOARDS)
        # self.USRP_TX.set_clock_source('internal', 0)

        ##################################################
        # Connections
        ##################################################
        self.connect((self.file_source, 0), (self.USRP_TX, 0))

    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate


def main(send=sendIQ, options=None):
    global inaddr
    inaddr = '.2'
    if len(sys.argv) > 1:
        inaddr = sys.argv[1]
    tb = send()
    # time.sleep(2)
    tb.start()
    # tb.wait()
    time.sleep(400000000)
    print 'End Transmission'
    quit()


if __name__ == '__main__':
    main()
