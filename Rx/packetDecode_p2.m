function [configObj, payloadBits, MACAggregation, LSIGBITS] = packetDecode_p2(IQPacketData, BW, sampRate, nVar)
% Decodes wifi packets and outputs PHY payload bits
% Currently supports Non-HT and MF HT format
% Extensions: VHT format and GF format
% CBW is 20, 40, 80, and 160

% To do list
% 1) Add handle for MCS 33-76 for HT
% 2) Add handle for the aggregation bit for HT and VHT
% 3) Add handle for wrong packet length 

% Add argument defaults
if(BW == 20)
    CBW = 'CBW20';
elseif(BW == 40)
    CBW = 'CBW40';
elseif(BW == 80)
    CBW = 'CBW80';
elseif(BW == 160)
    CBW = 'CBW160';
else
    error('BW must be either 20, 40, 80 or 160.');
end
% Define and initial HT obj
configObj = wlanHTConfig;
configObj.ChannelBandwidth = CBW;
pfOffset = comm.PhaseFrequencyOffset('SampleRate',sampRate,'FrequencyOffsetSource','Input port');

% Find indices
fieldIndices = wlanFieldIndices(configObj);

% LSTF processing
% 1) Extract LSTF
rxLSTF = IQPacketData(fieldIndices.LSTF(1):fieldIndices.LSTF(2));
% 2) Perform Coarse frequency offset
foffset = wlanCoarseCFOEstimate(rxLSTF, configObj.ChannelBandwidth);
IQPacketDataOffsetCorrection = pfOffset(IQPacketData,-foffset);


% LLTF processing
% 1) Extract LLTF
rxLLTF = IQPacketDataOffsetCorrection(fieldIndices.LLTF(1):fieldIndices.LLTF(2));
% 2) Perform fine frequency offset
foffset = wlanFineCFOEstimate(rxLLTF, configObj.ChannelBandwidth);
IQPacketDataOffsetCorrection = pfOffset(IQPacketDataOffsetCorrection,-foffset);
% 3) Perform channel estimate
rxLLTF = IQPacketDataOffsetCorrection(fieldIndices.LLTF(1):fieldIndices.LLTF(2));
demodSig = wlanLLTFDemodulate(rxLLTF, configObj);
chEST = wlanLLTFChannelEstimate(demodSig, configObj.ChannelBandwidth);

global gaurd_us;
% LSIG processing
rxLSIG = IQPacketDataOffsetCorrection(fieldIndices.LSIG(1):fieldIndices.LSIG(2));
LSIGBITS = wlanLSIGRecover(rxLSIG, chEST, 0.1, configObj.ChannelBandwidth);

% Test if it is a valid preamble only
if(isequal(LSIGBITS(19:24), zeros(6, 1)) && mod(sum(LSIGBITS(1:17)),2) == LSIGBITS(18))
    measDuration = (length(IQPacketData))/sampRate*1e6;
    calcDuration = 20 + double(bi2de(LSIGBITS(6:17)')) * 8/6;
    if length(IQPacketData) <= (fieldIndices.LSIG(2) + (gaurd_us*20) + 2) && ...
        abs(measDuration - calcDuration) > 10 
        fprintf("This is the short packet preamble\n");
        payloadBits = 0;
        MACAggregation = 0;
        configObj = [];
        return;
    end
else
    error("This is noise\n");
end

% Detect Format
rxSig = IQPacketDataOffsetCorrection(double(fieldIndices.LLTF(2)) + (1:12e-6*sampRate));
format = wlanFormatDetect(rxSig, chEST, 0.01, configObj.ChannelBandwidth);


if(strcmp(format, 'HT-GF'))
    error('HT-GF packets are not supported')
elseif(strcmp(format, 'Non-HT'))
    % Change configuration object to Non-HT
    disp('Frame format is Legacy (802.11a/b/g).')
    configObj = wlanNonHTConfig;
    
    
    % Check if valid format is received
    if(isequal(LSIGBITS(19:24), zeros(6, 1)) && mod(sum(LSIGBITS(1:17)),2) == LSIGBITS(18))
        disp('LSIG check passed.')
    else
        disp('LSIG check failed.')
    end
    
    
    MCSTable = struct('bitSeq', {[1 1 0 1], [1 1 1 1], [0 1 0 1], [0 1 1 1], [1 0 0 1], [1 0 1 1], [0 0 0 1], [0 0 1 1]...
        }, 'MCS', {0, 1, 2, 3, 4, 5, 6, 7});
    
    ii = 1;
    while(ii <= 8)
        if( isequal(MCSTable(ii).bitSeq', LSIGBITS(1:4)) )
            configObj.MCS =MCSTable(ii).MCS;
            break;
        end
        ii = ii + 1;
    end
    
    if (ii > 8)
        error('Packet MCS does not match the table.');
    end
    configObj.PSDULength = double(bi2de(LSIGBITS(6:17)'));
    fieldIndices = wlanFieldIndices(configObj);
    
    % payload recovery
    % May handle later
%     if(fieldIndices.NonHTData(2) > length(IQPacketDataOffsetCorrection))
%         IQPacketDataOffsetCorrection = [IQPacketDataOffsetCorrection; ...
%             zeros(fieldIndices.NonHTData(2)-length(IQPacketDataOffsetCorrection),1)];
%     end
%     IQPacketDataOffsetCorrection = decimate(IQPacketDataOffsetCorrection,BW/20); % downsample to 20M
    rxData = IQPacketDataOffsetCorrection(fieldIndices.NonHTData(1):fieldIndices.NonHTData(2));
    rxLLTF = IQPacketDataOffsetCorrection(fieldIndices.LLTF(1):fieldIndices.LLTF(2));
    demodSig = wlanLLTFDemodulate(rxLLTF, configObj);
    chEST = wlanLLTFChannelEstimate(demodSig, configObj.ChannelBandwidth);
    payloadBits = wlanNonHTDataRecover(rxData, chEST, nVar, configObj);
    MACAggregation = 0;
elseif(strcmp(format,'HT-MF'))
    disp('Frame format is HT-MF (802.11n).')
    
    % Check if valid format is received (6 tail bits in LSIG = 0 & xor all bits should be = parity bit)
    if(isequal(LSIGBITS(19:24), zeros(6, 1)) && mod(sum(LSIGBITS(1:17)),2) == LSIGBITS(18))
        disp('LSIG check passed.')
    else
        disp('LSIG check failed.')
    end
    
    rxHTSIG = IQPacketDataOffsetCorrection(fieldIndices.HTSIG(1):fieldIndices.HTSIG(2));
    [HTSIGBits, failCRC] = wlanHTSIGRecover(rxHTSIG, chEST, nVar, configObj.ChannelBandwidth);
    
    if(~failCRC && isequal(HTSIGBits(43:48), zeros(6, 1)))
        disp('HTSIG CRC check passed');
    else
        disp('HTSIG CRC check failed');
    end
    
    % MCS bits (0:6)
    configObj.MCS = double(bi2de(HTSIGBits(1:7)'));
    NSS = floor(configObj.MCS/8) + 1;
    
    % CBW bit (7)
    if(HTSIGBits(8) == 0)
        configObj.ChannelBandwidth = 'CBW20';
    else
        configObj.ChannelBandwidth = 'CBW40';
    end
    
    % HT length (8:23)
    configObj.PSDULength = double(bi2de(HTSIGBits(9:24)'));
    % Smoothing (24) 
    configObj.RecommendSmoothing = logical(HTSIGBits(25)); 
    % Not Sounding Bit (25)
    
    
     MACAggregation = HTSIGBits(28);
%    mappingTable = [2 0; 3 4; 4 0] % Table 6.1, Next Generation WLAN book, STBC specifies col index while NSS specifies row index. 
     STBCField = double(bi2de(HTSIGBits(29:30)'));
     configObj.NumSpaceTimeStreams = double(NSS + STBCField);
     
     if(HTSIGBits(31))
         configObj.ChannelCoding = 'LDPC';
     else
         configObj.ChannelCoding = 'BCC';
     end
     
     if(HTSIGBits(32))
         configObj.GuardInterval = 'Short';
     else
         configObj.GuardInterval = 'Long';
     end
     configObj.NumExtensionStreams = double(bi2de(HTSIGBits(33:34)'));
     configObj.NumTransmitAntennas = configObj.NumExtensionStreams + configObj.NumSpaceTimeStreams;
     fieldIndices = wlanFieldIndices(configObj);
     
     % Re-estimate Channel Coefficients
     rxHTLTF = IQPacketDataOffsetCorrection(fieldIndices.HTLTF(1):fieldIndices.HTLTF(2));
     demodSig = wlanHTLTFDemodulate(rxHTLTF, configObj);
     chEST = wlanHTLTFChannelEstimate(demodSig, configObj);
     
     % Payload recovery
     try
        rxData = IQPacketDataOffsetCorrection(fieldIndices.HTData(1):fieldIndices.HTData(2));
     catch
        warning('End of Packet is not Accurate')
        rxData = [IQPacketDataOffsetCorrection(fieldIndices.HTData(1):end); zeros(fieldIndices.HTData(2) - length(IQPacketData), 1)];
     end
     payloadBits = wlanHTDataRecover(rxData, chEST, nVar, configObj);
elseif(strcmp(format, 'VHT'))
    % Do VHT decoding 802.11ac
     disp('Frame format is VHT (802.11ac).')
     configObj = wlanVHTConfig('ChannelBandwidth', 'CBW20');
     fieldIndices = wlanFieldIndices(configObj);
    
    % Check if valid format is received
    if(isequal(LSIGBITS(19:24), zeros(6, 1)) && mod(sum(LSIGBITS(1:17)),2) == LSIGBITS(18))
        disp('LSIG check passed.')
    else
        disp('LSIG check failed.')
    end
    
%   Extract VHT-SIG A Field
    rxVHTSIGA = IQPacketDataOffsetCorrection(fieldIndices.VHTSIGA(1):fieldIndices.VHTSIGA(2));
    [VHTSIGABits, failCRC] = wlanVHTSIGARecover(rxVHTSIGA,chEST,0.01,configObj.ChannelBandwidth);
    
    % Check CRC
    if(~failCRC && isequal(VHTSIGABits(43:48), zeros(6, 1)) && VHTSIGABits(3) && VHTSIGABits(34) && VHTSIGABits(24))
        disp('VHTSIGA CRC check passed');
    else
        disp('VHTSIGA CRC check failed');
    end
    
    % Decide on BW
    if(isequal(VHTSIGABits(1:2),[0 0]'))
        configObj.ChannelBandwidth = 'CBW20';
    elseif(isequal(VHTSIGABits(1:2),[1 0]'))
        configObj.ChannelBandwidth = 'CBW40';
    elseif(isequal(VHTSIGABits(1:2),[0 1]'))
        configObj.ChannelBandwidth = 'CBW80';
    else
        configObj.ChannelBandwidth = 'CBW160';
    end
    
    STBCField = logical(VHTSIGABits(4));
    % Check if STBC
     if(STBCField)
         error('STBC mode on!');
     else
         configObj.STBC = false;
     end
     % Get group ID and Partial ID
     configObj.GroupID = sum(2.^(0:5)'.* double(VHTSIGABits(5:10)));
     configObj.PartialAID = sum(2.^(0:8)' .* double(VHTSIGABits(14:22)));
     
     % Get Space Time Streams
     NSTS = sum(2.^(0:2)' .* double(VHTSIGABits(11:13))) + 1;
     if(NSTS ~= 1)
         error('MIMO is on!');
     end
     configObj.NumSpaceTimeStreams = NSTS;
     NLTF = 1;          % Extend in the future
     configObj.NumTransmitAntennas = 1;
     
     if(~VHTSIGABits(23))
         %error('TXOP_PS is allowed!');
     end
     
     % Short GI check
     GIambg = 0;
     if(VHTSIGABits(25))
         configObj.GuardInterval = 'Short';
         Tsym = 3.6;
         if(VHTSIGABits(26))
             GIambg = 1;
         end
     else
         configObj.GuardInterval = 'Long';
         Tsym = 4;
     end
     extraSym = 0;
     if(VHTSIGABits(27))
         configObj.ChannelCoding = 'LDPC';
         if(VHTSIGABits(28))
             extraSym = 1;
         end
     else
         configObj.ChannelCoding = 'BCC';
     end
     
     configObj.MCS = sum(2.^(0:3)' .* double(VHTSIGABits(29:32)));
     %LSIG = double(bi2de(LSIGBITS(6:17)'));
     %RxTime = ceil((LSIG + 3)/3) * 4 + 20;
     %NSym = floor((RxTime - 36 - 4 * NLTF)/Tsym) - extraSym - STBCField - GIambg;
     fieldIndices = wlanFieldIndices(configObj);
     
     
     % Re-estimate Channel Coefficients
     rxVHTLTF = IQPacketDataOffsetCorrection(fieldIndices.VHTLTF(1):fieldIndices.VHTLTF(2));
     demodSig = wlanVHTLTFDemodulate(rxVHTLTF, configObj);
     chEST = wlanVHTLTFChannelEstimate(demodSig, configObj);
     
     rxVHTSIGB = IQPacketDataOffsetCorrection(fieldIndices.VHTSIGB(1):fieldIndices.VHTSIGB(2));
     VHTSIGBBits = wlanVHTSIGBRecover(rxVHTSIGB, chEST, 0.01, configObj.ChannelBandwidth);
     
     % Find VHTSIGB
     if(configObj.ChannelBandwidth == 'CBW20')
         if(~isequal(VHTSIGBBits(18:26), [1 1 1 0 0 0 0 0 0]'))
             error('VHTSIGB: invalid format');
         end
         configObj.APEPLength = sum(double(VHTSIGBBits(1:17)) .* 2.^(0:16)') * 4;
     else
         error('Channel BW > 20, will add support later');
     end
     % Extract data
     fieldIndices = wlanFieldIndices(configObj);
     try
        rxData = IQPacketDataOffsetCorrection(fieldIndices.VHTData(1):fieldIndices.VHTData(2));
     catch
        warning('End of Packet is not Accurate')
        rxData = [IQPacketDataOffsetCorrection(fieldIndices.VHTData(1):end); zeros(fieldIndices.VHTData(2) - length(IQPacketData), 1)];
     end
     %rxData = rxData/rms(abs(rxData)) * 0.001356828944908;
     payloadBits = wlanVHTDataRecover(rxData, chEST, nVar, configObj);
     MACAggregation = 1;
end


