# golden_crc8.py - CRC-8/CCITT 黄金模型（与 MATLAB 交叉验证）
import crcmod
from typing import List


def create_crc8_func():
    """
    Create CRC-8 function with configuration:
    - Polynomial: 0x107 (CRC-8/CCITT, 包含前导1位)
    - Initial value: 0x00
    - Input reflection: False
    - Output reflection: False
    - Final XOR: 0x00
    
    注意：crcmod要求多项式包含前导1位
    - 数学表示: x^8 + x^2 + x + 1
    - MATLAB格式: 0x07
    - crcmod格式: 0x107 (最高位1代表x^8)
    """
    return crcmod.mkCrcFun(0x107, initCrc=0x00, rev=False, xorOut=0x00)


def calculate_crc8(data: bytes) -> int:
    """
    Calculate CRC-8 for byte sequence.
    Args:
        data: Byte sequence (bytes or list of integers)
    Returns:
        CRC-8 value (0-255)
    """
    if isinstance(data, list):
        data = bytes(data)
    crc_func = create_crc8_func()
    return crc_func(data) & 0xFF


def calculate_crc8_incremental(data: bytes) -> int:
    """
    Calculate CRC-8 incrementally (byte-by-byte) to match RTL behavior.
    Args:
        data: Byte sequence
    Returns:
        CRC-8 value (0-255)
    """
    crc_func = create_crc8_func()
    crc = 0x00
    for byte in data:
        crc = crc_func(bytes([byte]), crc) & 0xFF
    return crc


def validate_known_vectors():
    """
    Validate against known CRC-8 test vectors.
    Returns:
        True if all tests pass
    """
    test_cases = [
        (b'\x00', 0x00, "Single zero byte"),
        (b'\x01', 0x07, "Single 0x01 byte"),
        (b'\xFF', 0xF3, "Single all-ones byte"),
        (b'\x01\x02\x03\x04\x05', 0xBC, "Sequence [1,2,3,4,5]"),
    ]
    print("Validating golden CRC-8 model...")
    all_pass = True
    for data, expected, desc in test_cases:
        crc = calculate_crc8(data)
        status = "[PASS]" if crc == expected else "[FAIL]"
        exp_str = f"0x{expected:02X}" if expected is not None else "N/A"
        print(f"{status} {desc}: data={data.hex()}, CRC=0x{crc:02X}, expected={exp_str}")
        if crc != expected:
            all_pass = False
    return all_pass


if __name__ == "__main__":
    print("CRC-8 Golden Model Validation")
    print("=" * 50)
    if validate_known_vectors():
        print("\n[SUCCESS] All test vectors passed")
    else:
        print("\n[ERROR] Some test vectors failed")
        exit(1)