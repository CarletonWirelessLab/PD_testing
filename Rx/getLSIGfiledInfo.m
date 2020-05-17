function [calcDuration, rate] = getLSIGfiledInfo(LSIGBITS, configObj, pf)

pduLength = double(bi2de(LSIGBITS(6:17)'));


rateTable =[{'BPSK 1/2 6 Mb/s'}, ...	
            {'BPSK 3/4 9 Mb/s'}, ...	
            {'QPSK 1/2 12 Mb/s'}, ...	
            {'QPSK 3/4 18 Mb/s'}, ...	
            {'16-QAM 1/2 24 Mb/s'}, ...	
            {'16-QAM 3/4 36 Mb/s'}, ...	
            {'64-QAM 2/3 48 Mb/s'}, ...	
            {'64-QAM 3/4 54 Mb/s'}];

MCSTable = struct('bitSeq', {[1 1 0 1], [1 1 1 1], [0 1 0 1], [0 1 1 1], [1 0 0 1], [1 0 1 1], [0 0 0 1], [0 0 1 1]...
    }, 'MCS', {6, 9, 12, 18, 24, 36, 48, 54});

ii = 1;
while(ii <= 8)
    if( isequal(MCSTable(ii).bitSeq', LSIGBITS(1:4)) )
        rate =MCSTable(ii).MCS;
        break;
    end
    ii = ii + 1;
end

if (ii > 8)
    warning('Packet MCS does not match the table.');
end

if isempty(configObj)
    calcDuration = 20 + pduLength * 8 /rate;
else
    if(configObj.ChannelBandwidth == 'CBW20')
        BW = 20;
    elseif(configObj.ChannelBandwidth == 'CBW40')
        BW = 40;
    elseif(configObj.ChannelBandwidth == 'CBW80')
        BW = 80;
    elseif(configObj.ChannelBandwidth == 'CBW160')
        BW = 160;
    else
        error('BW must be either 20, 40, 80 or 160.');
    end

    fieldIndices = wlanFieldIndices(configObj);
    fn = fieldnames(fieldIndices);
    calcDuration = fieldIndices.(fn{end})(2)/BW;
    %calcDuration = fieldIndices.(end)(2)/BW;
end
if pf
    disp('Signal Filed information:')
    disp(['Data length= ' num2str(pduLength) ' bytes'])
    disp(['Data Rate is ' char(rateTable(ii))])
    disp(['Calculated Duration = ' num2str(calcDuration) ' uSec'])
end


