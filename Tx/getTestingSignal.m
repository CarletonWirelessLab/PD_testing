clear all, close all;

% sampling rate in samples per second
sampling_rate = 20e6;
% modulation rate in bit per second
modulation_rate = 6e6; 
% length of payload in Bytes
maxPSDUlength = 2^12-1;


% duration in seconds for a signal
Jam_duration = 25e-3;
silence16_duration = 16e-6;
STF_duration = 8e-6;
LTF_duration = 8e-6;
SIGF_duration = 4e-6;
preamble_duration = STF_duration + LTF_duration + SIGF_duration;
backoff_duration = 10e-3; % Must have 16e-6 sec + extra

extraPreamble_duration = 8e-6;

% Number of samples for a signal
Jam_samples = sampling_rate*Jam_duration;
silence16_samples = sampling_rate*silence16_duration;
silence8_samples = round(silence16_samples/2);
STF_samples = sampling_rate*STF_duration;
LTF_samples = sampling_rate*LTF_duration;
SIGF_samples = sampling_rate*SIGF_duration;
preamble_samples = round(sampling_rate*preamble_duration);
extraPreamble_samples = round(sampling_rate*extraPreamble_duration);
backoff_samples = round(sampling_rate*backoff_duration);

% IQ components of sampled data for a signal
%Jam_data = ones(Jam_samples,1)+1i*ones(Jam_samples,1);
silence16DataIQ = complex(zeros(silence16_samples,1));
% STF_data = ;
% LTF_data = ;
% SIGF_data = ;
% preamble_data = ;
scale = 0.1; 
%% Get Jam Signal
JamScale = 1.2; %1.2

beaconIQ1 = getWiFiBeaconIQ(JamScale, 'Carleton-Ericsson');
beaconIQ2 = getWiFiBeaconIQ(scale, 'Carleton-Ericsson_');
avrPowerBeacon = mean(abs(beaconIQ1).^2);

jamDataIQ = getWiFiSignalIQ(2941, JamScale, 0); % 2941 to adjust 12mSec
avrPowerDataBefore = mean(abs(jamDataIQ).^2);
jamDataIQ = jamDataIQ * sqrt(avrPowerBeacon/avrPowerDataBefore);
avrPowerData = mean(abs(jamDataIQ).^2);

JamDataIQ = [jamDataIQ;...
             complex(zeros(silence8_samples,1));...
             jamDataIQ;...
             complex(zeros(silence8_samples,1));...
             jamDataIQ;...
%              complex(zeros(silence8_samples,1));...
%              jamDataIQ;...
%              complex(zeros(silence8_samples,1));...
%              jamDataIQ;...
             complex(zeros(silence8_samples,1));...
             beaconIQ1;...
             ];

%% Get the preamble Signal

beaconIQ2 = getWiFiBeaconIQ(scale, 'Carleton-Ericsson_');
avrPowerBeacon2 = mean(abs(beaconIQ2).^2);

RandomLengths = 0;
MCS = 0;
allSignalIQ = [];
randomPayloadUsed = [];
n = 1;
for n = 1:10
    if RandomLengths
        PSDUlength = randi([220 maxPSDUlength]);  % minimum length 220 octates (Guido's Recommendation)
    else
        PSDUlength = maxPSDUlength;
    end
    dataIQ = getWiFiSignalIQ(PSDUlength, scale, MCS);
    % avrPowerPreamb1 = mean(abs(dataIQ).^2)
    dataIQ = dataIQ * sqrt(avrPowerBeacon/avrPowerDataBefore); % scale based on Power
    % avrPowerPreamb2 = mean(abs(dataIQ).^2)

    preambleDataIQ = dataIQ(1:preamble_samples);
    extraPreamble_IQ =  dataIQ(preamble_samples +(1:extraPreamble_samples));
%     l = length(guard_IQ);
%     guard_IQ = [guard_IQ(l/2+1:end); guard_IQ(1:l/2)];

    backoffDataIQ = complex(zeros(backoff_samples,1));
    payload_samples = round(sampling_rate * PSDUlength * 8/modulation_rate);
    silencex = complex(zeros(payload_samples - extraPreamble_samples,1));
    randomPayloadUsed(n) = payload_samples/sampling_rate*1e6;
%     oneTest_signalIQ = [silence16DataIQ; JamDataIQ; silence16DataIQ; beaconIQ2; silence16DataIQ; preambleDataIQ; guard_IQ; silencex; backoffDataIQ];
    oneTest_signalIQ = [silence16DataIQ; JamDataIQ; silence16DataIQ; preambleDataIQ; extraPreamble_IQ; silencex; backoffDataIQ;];
    allSignalIQ = [allSignalIQ; oneTest_signalIQ];
end
% disp(num2str(gaurd_duration))

%%

figure(100)
t = (0:(length(oneTest_signalIQ)-1))/sampling_rate;
plot(t, abs(oneTest_signalIQ))

figure(101)
t = (0:(length(allSignalIQ)-1))/sampling_rate;
plot(t, abs(allSignalIQ))
%% Save to file
rawdata = zeros(2*length(allSignalIQ),1);
rawdata(1:2:end) = real(allSignalIQ);
rawdata(2:2:end) = imag(allSignalIQ);

fid = fopen('testingSignal.bin', 'w');
fwrite(fid, rawdata, 'float32');
fclose(fid);