function plotAround(fileName, id, around, f)

sampRate = 20e6;

fid = fopen(fileName , 'r');
rawData = fread(fid, 2 * sampRate * inf, 'float32');
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
windowSize = 4e-6 * sampRate; % May change later
packetIndices = find(envData > threshold);
tempVector = diff(packetIndices);
packetEndIndices = packetIndices([tempVector > windowSize; true]);
packetStartIndices = packetIndices([true; tempVector> windowSize]);

locs = [packetStartIndices packetEndIndices];
partLocs = locs(max(1,id-around):min(length(locs),id+around),:);
partcData = cData(partLocs(1,1):partLocs(end,2));

envData = abs(partcData).^2;
windowSize = 4e-6 * sampRate; % May change later
packetIndices = find(envData > threshold);
tempVector = diff(packetIndices);
packetEndIndices = packetIndices([tempVector > windowSize; true]);
packetStartIndices = packetIndices([true; tempVector> windowSize]);

locs = [packetStartIndices packetEndIndices];

figure(100)
t = (0:(length(partcData)-1))/sampRate;
indicator = zeros(size(t));
colorIndicator = indicator;
indicator(locs(:)) = 0.4 * max(abs(partcData(:)));
middleLocation = ceil(length(locs)/2);
colorIndicator(locs(middleLocation,:)) = 0.4 * max(abs(partcData(:)));
plot(t, abs(partcData), 'b-',  t, sqrt(threshold) * ones(size(partcData)), 'g--', t, indicator, 'r-', t, colorIndicator, 'g');
legend('IQ', 'Thrshold')


