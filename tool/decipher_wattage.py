import sys

def extract_fixed_format(jumble, index, length):
    # We know the fixed format from the Dart side:
    # Wattage: toStringAsFixed(2) -> e.g. "15.50" or "5.00"
    # Voltage: toStringAsFixed(2) -> e.g. "4.20"
    # Current: toStringAsFixed(3) -> e.g. "1.500"

    # Actually, the length is not fixed because the integer part can vary.
    # But we can look for the dot and then take X digits after it.

    val = ""
    dot_index = -1
    for i in range(index, len(jumble)):
        char = jumble[i]
        if char == '.':
            dot_index = i
            val += char
        elif char.isdigit():
            val += char
            if dot_index != -1:
                # We have seen the dot. Check how many decimals we have.
                decimals = i - dot_index
                # We expect 2 decimals for W/V and 3 for I.
                # However, since we don't know which one it is here,
                # let's look at the context or just take a reasonable amount.
                # If we are extracting Wattage/Voltage, we want 2.
                # If Current, 3.
                pass
        else:
            break

    return val

def decipher_all(jumble):
    if len(jumble) != 64:
        print("Error: Jumble must be exactly 64 characters long.")
        return None

    # Refined extraction based on known formats
    # Wattage (index 20): has '.' and 2 decimals
    wattage_raw = jumble[20:30] # Take a slice
    w_dot = wattage_raw.find('.')
    wattage = wattage_raw[:w_dot + 3] if w_dot != -1 else wattage_raw

    # Voltage (index 30): has '.' and 2 decimals
    voltage_raw = jumble[30:40]
    v_dot = voltage_raw.find('.')
    voltage = voltage_raw[:v_dot + 3] if v_dot != -1 else voltage_raw

    # Current (index 40): has '.' and 3 decimals
    current_raw = jumble[40:55]
    i_dot = current_raw.find('.')
    current = current_raw[:i_dot + 4] if i_dot != -1 else current_raw

    return {
        "Wattage": wattage,
        "Voltage": voltage,
        "Current": current
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python decipher_wattage.py <64_char_jumble>")
        sys.exit(1)

    jumble_input = sys.argv[1]
    results = decipher_all(jumble_input)
    if results:
        for key, val in results.items():
            unit = "W" if key == "Wattage" else ("V" if key == "Voltage" else "A")
            print(f"{key}: {val}{unit}")
