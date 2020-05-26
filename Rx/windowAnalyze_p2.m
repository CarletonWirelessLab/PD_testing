clc; 
close all; clear all;
% fileName = 'ReceiveEricsson.bin';
fileName = 'Receivenoise.bin';

% Set the first 3 Octets of the UUT MAC Address
% Ericsson AP = '00:0D:67', also BelAir
% TP-Link AP  = 'D4:6E:0E', 
% ASUS AP     = '40:16:7E'
% D-Link      = '40:9B:CD'
% Google WiFi = '30:FD:38'
% USB_Edimax  = '80:1F:02'
% USB_DLink   = '90:94:E4'
UUT_MAC = '00:0D:67'; 

sampRate = 20e6; % USRP sampling rate
bandWidth = 20; % channel bandwidth in MHz
duration = Inf; % Process duration In seconds (Inf -> to end of file)
f = 0.015; % noise threshold fine tuning
% Find packetstart and end epochs
[cData, locs, threshold] = detectPacketLocations(fileName, sampRate, duration, f); % Kareem's code



TxMacExist = 0;
silenc = [];
silence_known = []; 
silence_unknown = [];
packet_unknown = []; 
empty_test = [];
empty_test_count = 1;
count = 1;
unknown_count = 1;
beginFlag = 0;
foundBeconIn = 0;
beacon_count = 0;
longestFrame = 0;
longestSilence = 0;
index_fail = [];
index_noise = [];
index_collision = [];
count_test = 0;
passCount = 0;
testingLengths = [];
testingLengthsUnknow = [];
preambleDetected = 0;

global gaurd_us;
gaurd_us = 8; 
totalPreamble = 20 + gaurd_us;
silenceAfterData = 16; % uSec SIFS 
preambleMeasureErr = 2;
frameMeasureErr = 2;
pf = 1; % display or not

for ii = 2:length(locs)
    packet =  1 * cData(locs(ii, 1):locs(ii, 2));
    if (locs(ii, 2)-locs(ii, 1))/20 < 20 - 2
        fprintf('Noise skipped \n');
        continue;
    end
    disp(['Frame #' char(string(ii)) ':'])
%     if ii == 304
%         keyboard;
%     end
    if (locs(ii, 2)-locs(ii, 1)) > longestFrame(1)
        longestFrame(1) = (locs(ii, 2)-locs(ii, 1));
        longestFrame(2) = ii;
    end
    if (locs(ii, 1)-locs(ii-1, 2)) > longestSilence(1)
        longestSilence(1) = (locs(ii, 1)-locs(ii-1, 2));
        longestSilence(2) = ii;
    end
    try 
        payloadU = 0;
        configObj = [];
        [configObj, payloadU, MACAggregation, LSIGBITS] = packetDecode_p2(decimate(packet,sampRate/bandWidth/1e6), ...
            bandWidth, sampRate / (sampRate/bandWidth/1e6), 1e-6);
        if isempty(configObj) & beginFlag
            preambleDetected = 1;
        end
    catch
        if (locs(ii, 2)-locs(ii, 1))/20 > 30
            index_collision = [index_collision,ii];
            if pf, fprintf('packet decode error, collision\n'); end% maybe collision
            if pf, fprintf('packet duration: %f (uSec)\n',(locs(ii, 2)-locs(ii, 1))/20); end
%             keyboard;
        elseif (locs(ii, 2)-locs(ii, 1))/20 < 20 -2
            index_noise =[index_noise,ii];
            if pf, fprintf('packet decode error, noise\n'); end
            if pf, fprintf('packet duration: %f (uSec)\n',(locs(ii, 2)-locs(ii, 1))/20); end
        else
            if pf, fprintf('packet duration: %f (uSec)\n',(locs(ii, 2)-locs(ii, 1))/20); end
        end
        if pf, disp('==============================================='); end
        continue;
    end

    % plotAround(fileName, ii, 2, f)
    [calcDuration, rate] = getLSIGfiledInfo(LSIGBITS, configObj, pf);
    measDuration = (locs(ii, 2)-locs(ii, 1))/sampRate*1e6;
    if pf, disp(['Measured Duration   = ' num2str(measDuration) ' uSec' ]); end
    if abs(measDuration - calcDuration) > frameMeasureErr
        if pf, disp ('##### Duration missmatch, May be a collision or truncated frame ####'); end
    end
    
    % If preamble and already found a beacon, get frame length from SIG filed
    if abs(measDuration - totalPreamble) < preambleMeasureErr & ...
           ~payloadU & beginFlag
        testingLengths(count) = calcDuration - 20 ...
            + silenceAfterData - frameMeasureErr; % subtract the preamble
    end
        
    if(MACAggregation)
        %disp('- Aggregation is on')
        payLoad = payloadU(33:end); % Skip the first 32 bits
    else
        %disp('- Aggregation is off')
        payLoad =  payloadU;
    end
    
    dataLength = 0;
    if length(payLoad) > 1
        [type, subtype] = FindWiFiFrameType(payLoad);    
        if pf, disp(['type is ' type ' subtype is ' subtype '.']); end
        TxMacExist = 0;
        try
            if pf, disp(['Rx Add = ' getMAC(payLoad(32 + (1:48))) ',    Tx Add = ' getMAC(payLoad(80 + (1:48))) '.']), end 
            TxMacExist = 1;
        catch
            % Decodable frame but not Tx MAC, most probably Preamble, could be RTS/CTS
            if pf, disp(['Rx Add = ' getMAC(payLoad(32 + (1:48)))]); end
            TxMacExist = 0;
        end 

        if TxMacExist % MAC exist means, this is not a preamble
            tempmac = getMAC(payLoad(80 + (1:48)));
            if tempmac == '00:12:34:56:78:9B' % this is USRP beacon
                beacon_count = beacon_count + 1;
                silence (count) = locs(ii,2) + (16+20)*20; % 16 SIFS + 20 Preamble + 5 gaurd = end of preamble
                beginFlag = 1;
            elseif  beginFlag & preambleDetected ...
                    & tempmac(1:8) == UUT_MAC 
                silence_known (count) = (locs(ii,1) - silence (count))/20;  % uSec 
                count_test = count_test+1;
                
                if length(testingLengths) < count 
                    % one of the preambles could not be identified
                    silence_known(count) = [];
                    count = count - 1;
                    keyboard;
                end
                if silence_known(count) < testingLengths(count)
                    fprintf("VIOLATION\n");
                    index_fail = [index_fail,ii];
                else
                    passCount = passCount +1;
                end
                beginFlag = 0;
                preambleDetected = 0;
                count = count + 1;
                
            % Has a MAC address (not preamble) and not from UUT, 
            % possibly Jaming signal again (no UUT transmission happened in this test)   
            elseif  tempmac == 'EE:DD:11:22:33:00' & beginFlag & preambleDetected
                empty_test(empty_test_count) = ii;
                empty_test_count = empty_test_count + 1;
                beginFlag = 0;
                preambleDetected = 0;
                %keyboard;
            elseif beginFlag & preambleDetected
                silence_unknown (unknown_count) = (locs(ii,1) - silence (count))/20;  % uSec 
                testingLengthsUnknow(unknown_count) = testingLengths(count);
                packet_unknown (unknown_count) = ii;
                unknown_count = unknown_count + 1;
                beginFlag = 0;
                preambleDetected = 0;
%                 keyboard;
            end
        end
    end
    if pf, disp('==============================================='), end
%     keyboard
end
if length(silence_known) < length(testingLengths)
    testingLengths(end) = [];
end
% plotAround(fileName, ii, 2, f)
 disp('===============================================')
passed_known = sum(silence_known > testingLengths);
passed_unknown = sum(silence_unknown > testingLengthsUnknow);
%passed = passed_known + passed_unknown;
disp(['No. of beacons = ' num2str(beacon_count)])
disp(['No. of tests = ' num2str(count_test)])
disp(['No. of tests passed = ' num2str(passed_known)])
disp(['%   of tests passed = ' num2str(100*passed_known/count_test) ' %' ])
disp(['No. of tests followed by known packets = ' num2str(sum(silence_known>0)) ', passed ' num2str(passed_known)])
disp(['No. of tests followed by unknown packets = ' num2str(sum(silence_unknown>0)) ', passed ' num2str(passed_unknown)])
disp(['Longest frame = ' num2str(longestFrame(1)/20) ' uSec'])
disp(['Longest Silence = ' num2str(longestSilence(1)/20) ' uSec'])
if empty_test_count > 1
    warning('Empty Test Exists, %i',empty_test_count-1)
end
if unknown_count > 1
    warning('Unknown Packets source exists, %i',unknown_count-1)
end
% keyboard
%%
results_filename = ['P2_Ericsson_new+' num2str(gaurd_us) '.m'];
fid = fopen(results_filename, 'A');
% for n = 1:length(passed_known)
%     fprintf(fid,'%f\n',passed_known(n));
% end
fprintf(fid,'%i,%i\n',passed_known,count_test);
fclose(fid);
%clear all
