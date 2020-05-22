# Preamble Detection Test

<!-- In the IEEE 802.11 standard, each device should detect and extract the information in the preamble  to be able to determine whether the signal is noise or not. In addition, to avoid the packets collision during the transmission. The frame length in the preamble should be determined, where the device can know the period to be silent within. In this test, we check the compliance of commercial WiFi networking devices to the IEEE 802.11 standard. -->


The goal of this work is to develop an experimental
hardware testbed for verifying the compliance of the commercial
Unit Under Test (UUT)  with the preamble  frames that share the same communication  channel in IEEE 802.11 standard. In this experiment, we use  Universal Software Radio Peripheral (USRP) to capture and down-convert the Wi-Fi frames to the base-band. The captured data  by the USRP is utilized to extract the behavior of  different UUTs when they receive the preamble frames. The  standard states that each device should detect and extract the information in the preamble  to be able to determine whether the signal is noise or not. Moreover, to avoid the packets collision during the transmission. The frame length in the preamble should be determined, where the device can obtain the silent period to stop transmitting. In this test, we check the compliance of commercial WiFi networking devices to the IEEE 802.11 standard.


**Note**: This project is under active development, and a stable release branch has not yet been established.
The ```master``` branch is where the most stable version can be found, but interface and functionality contained therein are not yet guaranteed to be consistent or fully operational.

## Hardware Requirements

The following is a list of essential components for the preamble detection test:

* One or more wireless networking devices, known as the Unit(s) Under Test (UUTs) with USB and/or Gigabit Ethernet LAN connectivity
* One or two modern computers with USB 3.0 and Gigabit Ethernet ports (see Installation and Test Setup for the single-machine method)
* A software-defined radio capable of transmitting and receiving on the same wireless bands as the UUTs
* An anechoic chamber, or alternatively a series of shielded cabling to connect the devices in use

Preamble test was originally developed and tested using the [Ettus Research X300](https://www.ettus.com/all-products/X300-KIT/) software-defined radio device, which is the core measurement tool that senses the wireless channel and collects the data for further processing. No other devices are currently supported (although additional devices are on the roadmap). The (UUT) in a typical test setup is a either a commercially-available USB WiFi device, or a wireless router.

Below is a diagram showing an example test setup previously used at the Carleton Broadband Networks Laboratory:

![alt text](docs/images/System_model.jpg "  Preambl Test Setup ")

## Software Requirements

Preamble test was written and tested on systems running Fedora 28 and Ubuntu 16.04, but it should work on any modern Linux operating system with the following installed:

* Python 3 (written and tested on 3.6.5 and later 3.7.x)
* gnuradio (for the core writeIQ script)
* Matlab

<!--
Additionally, one script (```utils/writeIQ.py```) is currently written in Python 2, but will be updated as part of the project goals.
Early versions of the tool relied upon the use of the [MATLAB Engine for Python](https://www.mathworks.com/help/matlab/matlab-engine-for-python.html); however a significant effort was undertaken by the members of the Carleton University Broadband Networks Laboratory to rewrite the prototypical scripts in Python 3. Copies of the original MATLAB code are contained in the ```matlab``` folder for reference.-->

## Test Setup
Network Setup:
1. Connect the client PC to the Access point via Ethernet  
2. Establish a wireless connection from the server PC to the Access point
3. Enable the IPERF traffic on the server PC
4. Start the IPERF traffic from the client PC to the server PC

USRP Setup: 

We use two USRPs, namely, Jammer (Tx)and  Sampler (Rx)

Jammer:
1. Connect the Jammer according to the aforementioned figure
2. Using MATLAB, generate the IQ components required to by sent by the Jammer
3. Run sendIQ.py to send the IQ components

Sampler:
1. Connect the Sampler according to the aforementioned figure
2. Run writeIQ.py for x amount of seconds (preferably 2 seconds) to sample the medium
3. The IQ components will be stored in a (---.bin) file

Processing:
1. Using MATLAB, edit the MAC address of the UUT (UUT_MAC) in windowAnalyze_p2.m
2. Run windowAnalyze to process the samples and generate the results




## Test Examples

We provide two examples for the preamble detection test. As seen in the passed test below, the UUT succeeded to detect the preamble and stoped transmitting until the end of the preamble.
![alt text](docs/images/pass_test.jpg "  Passed test  )

<!--<img src= "docs/images/pass_test.jpg " width="200" height="200">-->

While in the failed test, the UUT intervened the communication channel and transmitted in the silent period.
![alt text](docs/images/failed_test.jpg "  Failed test ")



## Authors

* **Ammar Alhosainy**
* **Shady Elkamhawy**
* **Yousef Alnagar**
