import sys

def extract_value(jumble, index):
    raw = jumble[index:index+10]
    dot = raw.find('.')
    if dot != -1:
        # Determine decimals based on common patterns
        # index 40 is current (3 decimals), others are 2
        decimals = 3 if index == 40 else 2
        return raw[:dot + decimals + 1]
    return raw

def decipher_all(jumble):
    if len(jumble) != 64:
        print("Error: Jumble must be exactly 64 characters long.")
        return None

    return {
        "Wattage": extract_value(jumble, 20),
        "Voltage": extract_value(jumble, 30),
        "Current": extract_value(jumble, 40),
        "Boosted Wattage (Dual-Cell)": extract_value(jumble, 50)
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python decipher_wattage.py <64_char_jumble>")
        sys.exit(1)

    jumble_input = sys.argv[1]
    results = decipher_all(jumble_input)
    if results:
        for key, val in results.items():
            unit = "W" if "Wattage" in key else ("V" if key == "Voltage" else "A")
            print(f"{key}: {val}{unit}")
