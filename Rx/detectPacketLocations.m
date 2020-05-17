function [cData, locs, threshold] = detectPacketLocations(fileName, sampRate, duration, f)
% locs = detectPacketLocations(fileName, sampRate, duartion)
% Reads wifi data from the file fileName, and returns the start and end location of
% each packet.


% Edit: Add check if fileName is not string and duration is not a number
fid = fopen(fileName , 'r');
rawData = fread(fid, 2 * sampRate * duration, 'float32');
fclose(fid);
%rawData = rawData1(30000001:end);
iData = rawData(1:2:end);
qData = rawData(2:2:end);

idl = length(iData);
qdl = length(qData);

if     idl > qdl
        iData = iData(1:qdl);
elseif qdl > idl
        qData = qData(1:idl);
end

cData = iData + 1j * qData;

envData = abs(cData).^2;

threshold = f * (mean(envData) + sqrt(var(envData)));
%threshold = f * mean(envData);
windowSize = 4e-6 * sampRate; % May change later
packetIndices = find(envData > threshold);
tempVector = diff(packetIndices);
packetEndIndices = packetIndices([tempVector > windowSize; true]);
packetStartIndices = packetIndices([true; tempVector> windowSize]);

%first_packet = i_data(packet_indices(1):packetEndIndices(1)) + 1j * q_data(packet_indices(1):packetEndIndices(1));
%t_first_packet = t(packet_indices(1):packetEndIndices(1));
locs = [packetStartIndices packetEndIndices];

figure(20)
t = (0:(length(cData)-1))/sampRate;
indicator = zeros(size(t));
indicator(locs(:)) = 0.4 * max(abs(cData(:)));
plot(t, abs(cData), 'b-',  t, sqrt(threshold) * ones(size(cData)), 'g--', t, indicator, 'r-');
legend('IQ', 'Thrshold')