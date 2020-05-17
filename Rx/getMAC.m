function MACAdd = getMAC(bitSeq)
% Get the MAC address for a 48 bit WiFi sequence
bitSeq = double(bitSeq(:)');
str = '0123456789ABCDEF';
MACAdd = [];
for ii = 1:6
    start_index_first_num = (ii - 1) * 8 + 1;
    end_index_first_num = start_index_first_num + 3;
    start_index_second_num = start_index_first_num + 4;
    end_index_second_num = ii * 8;
    
    num1 = sum(2.^(0:3) .* bitSeq(start_index_first_num:end_index_first_num));
    num2 = sum(2.^(0:3) .* bitSeq(start_index_second_num:end_index_second_num));
    
    MACAdd = [MACAdd str(num2 + 1)];
    MACAdd = [MACAdd str(num1 + 1) ':'];
end
MACAdd(end) = [];
    