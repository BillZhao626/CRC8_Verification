function crc = crc8_golden(data, poly, initVal, refIn, refOut, xorOut)
    % CRC-8 黄金模型函数
    % 输入:
    %   data    - uint8向量，输入数据
    %   poly    - uint8，多项式 (如 0x07)
    %   initVal - uint8，初始值 (如 0x00)
    %   refIn   - bool，输入是否反转 (true/false)
    %   refOut  - bool，输出是否反转 (true/false)
    %   xorOut  - uint8，最终异或值
    % 输出:
    %   crc     - uint8，CRC-8校验值

    % 参数验证
    validateattributes(data, {'numeric'}, {'vector', 'integer', '>=', 0, '<=', 255});
    validateattributes(poly, {'numeric'}, {'scalar', 'integer', '>=', 0, '<=', 255});
    validateattributes(initVal, {'numeric'}, {'scalar', 'integer', '>=', 0, '<=', 255});
    validateattributes(xorOut, {'numeric'}, {'scalar', 'integer', '>=', 0, '<=', 255});
    
    crc = initVal;
    
    for i = 1:length(data)
        byte = data(i);
        if refIn
            byte = bitrev(byte);
        end
        
        crc = bitxor(crc, byte);
        
        for j = 1:8
            if bitand(crc, 0x80)
                crc = bitxor(bitshift(crc, 1), poly);
            else
                crc = bitshift(crc, 1);
            end
        end
    end
    
    if refOut
        crc = bitrev(crc);
    end
    
    crc = bitxor(crc, xorOut);
end

function reversed = bitrev(byte)
    % 位反转函数
    reversed = 0;
    for i = 0:7
        if bitand(byte, bitshift(1, i))
            reversed = bitor(reversed, bitshift(1, 7-i));
        end
    end
end