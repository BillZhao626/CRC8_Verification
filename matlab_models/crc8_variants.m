function crc = crc8_ccitt(data)
    % CRC-8/CCITT 标准
    crc = crc8_golden(data, uint8(0x07), uint8(0x00), false, false, uint8(0x00));
end

function crc = crc8_maxim(data)
    % CRC-8/MAXIM 标准
    crc = crc8_golden(data, uint8(0x31), uint8(0x00), true, true, uint8(0x00));
end

function crc = crc8_autosar(data)
    % CRC-8/AUTOSAR 标准
    crc = crc8_golden(data, uint8(0x2F), uint8(0xFF), false, false, uint8(0xFF));
end