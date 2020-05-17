function [beaconIQ1] = getWiFiBeaconIQ(scale, ssid)
% for -60dBm, scale should be 2
% for -80dBm, scale should be 0.1

%% Generate Beacon
formatConf = wlanNonHTConfig;
beaconCfg = wlanMACFrameConfig('FrameType', 'Beacon');

% Create a management frame-body configuration object
frameBodyCfg = wlanMACManagementConfig;
% Beacon Interval
frameBodyCfg.BeaconInterval = 100;
% Timestamp
frameBodyCfg.Timestamp = 554411;
% SSID
frameBodyCfg.SSID = ssid;
% Add DS Parameter IE (element ID - 3) with channel number 11 (0x0b)
frameBodyCfg = frameBodyCfg.addIE(3, '0b');
% Privacy — Privacy required for all data frames
frameBodyCfg.Privacy = 0;

frameBodyCfg.ESSCapability = 1;
frameBodyCfg.RadioMeasurement = 1;
frameBodyCfg.BasicRates = {'6 Mbps' '9 Mbps' '12 Mbps' '18 Mbps' '24 Mbps' '36 Mbps' '48 Mbps' '54 Mbps'};

%%%%%%%%%%%%%%%%%%%%%%%%55
% 1 Update management frame-body configuration
beaconCfg.ManagementConfig = frameBodyCfg;
% Generate bits for a Beacon frame
beaconFrameBits1 = wlanMACFrame(beaconCfg, 'OutputFormat', 'bits');
addbits = [beaconFrameBits1];
% Generate IQ 
formatConf.PSDULength = round(length(addbits)/8);
beaconIQ1 = wlanWaveformGenerator(beaconFrameBits1,formatConf);

id1 = real(beaconIQ1);
qd1 = imag(beaconIQ1);
scalefactor = max(abs([max(id1) min(id1) max(qd1) min(qd1)]));

beaconIQ1 = beaconIQ1/scalefactor;
% % beaconIQ1 = beaconIQ1/max(abs(beaconIQ1));
beaconIQ1 = beaconIQ1 * scale;
