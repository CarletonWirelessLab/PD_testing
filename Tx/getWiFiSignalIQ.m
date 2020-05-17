function [dataIQ] = getWiFiSignalIQ(PSDUlength, scale, MCS)
% for -60dBm, scale should be 1.2
% for -80dBm, scale should be 0.1

% Generates WiFi frame with sepcific length and power (scale), 
formatConf = wlanNonHTConfig;

qosDataCfg = wlanMACFrameConfig('FrameType', 'QoS Data');
% From DS flag
qosDataCfg.FromDS = 1;
% To DS flag
qosDataCfg.ToDS = 0;
% Acknowledgment Policy
qosDataCfg.AckPolicy = 'Normal Ack';
% Receiver address
qosDataCfg.Address1 = 'FF1122AABBCC';
% Transmitter address
qosDataCfg.Address2 = 'EEDD11223300';

phyConfig = wlanHTConfig('MCS',MCS);

% payload = repmat('11', 1, 400);
payload = randi([0 1],10*8,1);

% Generate bits for a QoS Data frame
preBits = wlanMACFrame(payload, qosDataCfg, phyConfig, 'OutputFormat', 'bits');
qosDataFrameBits = [preBits; ...
                    randi([0 1],(PSDUlength-length(preBits)/8)*8,1)];

% Generate IQ 
formatConf.Modulation = 'OFDM';
formatConf.ChannelBandwidth = 'CBW20';
formatConf.NumTransmitAntennas = 1;
formatConf.MCS = MCS;
formatConf.PSDULength = PSDUlength;
% qosDataFrameBits = randi([0 1],PSDUlength*8,1);
dataIQ = wlanWaveformGenerator(qosDataFrameBits,formatConf);

id1 = real(dataIQ);
qd1 = imag(dataIQ);
scalefactor = max(abs([max(id1) min(id1) max(qd1) min(qd1)]));

dataIQ = dataIQ/scalefactor;

% dataIQ = dataIQ/max(abs(dataIQ));
dataIQ = dataIQ * scale;