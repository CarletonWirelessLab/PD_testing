function [type, subtype] = FindWiFiFrameType(payLoad)

temp = payLoad(1:16)';
subTypeSeq = temp(8:-1:5);
if(isequal(temp(1:2),  zeros(1, 2)))
    if(isequal(temp(3:4), zeros(1,2)))
        type = 'management';
        
        if(isequal(subTypeSeq, [0 0 0 0]))
            subtype = 'Association Request';
        elseif(isequal(subTypeSeq, [0 0 0 1]))
            subtype = 'Association Response';
        elseif(isequal(subTypeSeq, [0 0 1 0]))
            subtype = 'Reassociation Request';
        elseif(isequal(subTypeSeq, [0 0 1 1]))
            subtype = 'Reassociation Response';
        elseif(isequal(subTypeSeq, [0 1 0 0]))
            subtype = 'Probe Request';
        elseif(isequal(subTypeSeq, [0 1 0 1]))
            subtype = 'Probe Response';
        elseif(isequal(subTypeSeq, [0 1 1 0]))
            subtype = 'Reserved';
        elseif(isequal(subTypeSeq, [0 1 1 1]))
            subtype = 'Reserved';
        elseif(isequal(subTypeSeq, [1 0 0 0]))
            subtype = 'Beacon';
        elseif(isequal(subTypeSeq, [1 0 0 1]))
            subtype = 'ATIM';
        elseif(isequal(subTypeSeq, [1 0 1 0]))
            subtype = 'Deassociation';
        elseif(isequal(subTypeSeq, [1 0 1 1]))
            subtype = 'Authentication';
        elseif(isequal(subTypeSeq, [1 1 0 0]))
            subtype = 'Deauthentication';
        elseif(isequal(subTypeSeq, [1 1 0 1]))
            subtype = 'Action';
        elseif(isequal(subTypeSeq, [1 1 1 0]))
            subtype = 'Action no ACK';
        elseif(isequal(subTypeSeq, [1 1 1 1]))
            subtype = 'Reserved';
        end
        
    elseif(isequal(temp(3:4), [1 0]))
        type = 'control';
        
        if(isequal(subTypeSeq, [0 0 0 0]))
            subtype = 'Reserved';
        elseif(isequal(subTypeSeq, [0 0 0 1]))
            subtype = 'Reserved';
        elseif(isequal(subTypeSeq, [0 0 1 0]))
            subtype = 'Reserved';
        elseif(isequal(subTypeSeq, [0 0 1 1]))
            subtype = 'Reserved';
        elseif(isequal(subTypeSeq, [0 1 0 0]))
            subtype = 'Beamforming';
        elseif(isequal(subTypeSeq, [0 1 0 1]))
            subtype = 'VHT NDP announcement';
        elseif(isequal(subTypeSeq, [0 1 1 0]))
            subtype = 'Reserved';
        elseif(isequal(subTypeSeq, [0 1 1 1]))
            subtype = 'Control Wrapper';
        elseif(isequal(subTypeSeq, [1 0 0 0]))
            subtype = 'BAR';
        elseif(isequal(subTypeSeq, [1 0 0 1]))
            subtype = 'BA';
        elseif(isequal(subTypeSeq, [1 0 1 0]))
            subtype = 'PS-Poll';
        elseif(isequal(subTypeSeq, [1 0 1 1]))
            subtype = 'RTS';
        elseif(isequal(subTypeSeq, [1 1 0 0]))
            subtype = 'CTS';
        elseif(isequal(subTypeSeq, [1 1 0 1]))
            subtype = 'ACK';
        elseif(isequal(subTypeSeq, [1 1 1 0]))
            subtype = 'CF-END';
        elseif(isequal(subTypeSeq, [1 1 1 1]))
            subtype = 'CF-END + CF-ACK';
        end
    elseif(isequal(temp(3:4), [0 1]))
        type = 'data';
        
        if(isequal(subTypeSeq, [0 0 0 0]))
            subtype = 'Data';
        elseif(isequal(subTypeSeq, [0 0 0 1]))
            subtype = 'Data + CF-ACK';
        elseif(isequal(subTypeSeq, [0 0 1 0]))
            subtype = 'Data + CF-Poll';
        elseif(isequal(subTypeSeq, [0 0 1 1]))
            subtype = 'Data + CF-ACK + CF-Poll';
        elseif(isequal(subTypeSeq, [0 1 0 0]))
            subtype = 'Null data';
        elseif(isequal(subTypeSeq, [0 1 0 1]))
            subtype = 'CF-ACK';
        elseif(isequal(subTypeSeq, [0 1 1 0]))
            subtype = 'CF-Poll';
        elseif(isequal(subTypeSeq, [0 1 1 1]))
            subtype = 'CF-ACK + CF-Poll';
        elseif(isequal(subTypeSeq, [1 0 0 0]))
            subtype = 'QOS data';
        elseif(isequal(subTypeSeq, [1 0 0 1]))
            subtype = 'QOS data + CF-ACK';
        elseif(isequal(subTypeSeq, [1 0 1 0]))
            subtype = 'QOS data + CF-Poll';
        elseif(isequal(subTypeSeq, [1 0 1 1]))
            subtype = 'QOS data + CF-ACK + CF-Poll';
        elseif(isequal(subTypeSeq, [1 1 0 0]))
            subtype = 'QOS Null';
        elseif(isequal(subTypeSeq, [1 1 0 1]))
            subtype = 'Reserved';
        elseif(isequal(subTypeSeq, [1 1 1 0]))
            subtype = 'QOS CF-Poll';
        elseif(isequal(subTypeSeq, [1 1 1 1]))
            subtype = 'QOS CF-ACK + CF-Poll';
        end
    else
        type = 'unidentified';
        subtype = 'unidentified';
    end
else
    type = 'unidentified';
    subtype = 'unidentified';
end