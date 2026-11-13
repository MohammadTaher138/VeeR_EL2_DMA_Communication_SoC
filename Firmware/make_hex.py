import sys

def main():
    if len(sys.argv) < 3:
        print("Usage: make_hex.py <input.bin> <output.hex>")
        sys.exit(1)
    bin_file = sys.argv[1]
    hex_file = sys.argv[2]
    with open(bin_file, "rb") as f:
        data = f.read()

    # Pad to multiple of 8 bytes
    if len(data) % 8 != 0:
        data += b"\x00" * (8 - (len(data) % 8))

    with open(hex_file, "w") as f:
        for i in range(0, len(data), 8):
            chunk = data[i:i+8]
            w0 = int.from_bytes(chunk[0:4], 'little')
            w1 = int.from_bytes(chunk[4:8], 'little')
            val64 = (w1 << 32) | w0
            f.write(f"{val64:016x}\n")

if __name__ == '__main__':
    main()
