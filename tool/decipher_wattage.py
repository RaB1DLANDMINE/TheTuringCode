import sys

def extract_value(jumble, index):
    # Search for a float pattern starting from index
    raw = jumble[index:index+12]
    dot = raw.find('.')
    if dot != -1:
        # Determine decimals based on index (index 40 is current with 3 decimals)
        decimals = 3 if index == 40 else 2
        return raw[:dot + decimals + 1]
    return raw

def decipher_all(jumble):
    if len(jumble) != 64:
        print("Error: Jumble must be exactly 64 characters long.")
        return None

    return {
        "Adjusted Wattage": extract_value(jumble, 20),
        "Adjusted Voltage": extract_value(jumble, 30),
        "Adjusted Current": extract_value(jumble, 40),
        "Raw Single-Cell Wattage": extract_value(jumble, 50)
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python decipher_wattage.py <64_char_jumble>")
        sys.exit(1)

    jumble_input = sys.argv[1]
    results = decipher_all(jumble_input)
    if results:
        print("-" * 30)
        print("DIAGNOSTIC RESULTS")
        print("-" * 30)
        for key, val in results.items():
            unit = "W" if "Wattage" in key else ("V" if "Voltage" in key else "A")
            print(f"{key:25}: {val}{unit}")
        print("-" * 30)

        # Add interpretation help
        try:
            adj_w = float(results["Adjusted Wattage"])
            raw_w = float(results["Raw Single-Cell Wattage"])
            if adj_w > raw_w * 1.5:
                print("Note: Dual-cell battery boost (2x) was applied to Adjusted Wattage.")
        except:
            pass
