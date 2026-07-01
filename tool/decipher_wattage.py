import sys

def extract_value(jumble, index):
    raw = jumble[index:index+12]
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
        "Wattage (Total)": extract_value(jumble, 20),
        "Voltage (Total)": extract_value(jumble, 30),
        "Current": extract_value(jumble, 40),
        "Voltage (Single Cell)": extract_value(jumble, 50)
    }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python decipher_wattage.py <64_char_jumble>")
        sys.exit(1)

    jumble_input = sys.argv[1]
    results = decipher_all(jumble_input)
    if results:
        print("-" * 40)
        print("DIAGNOSTIC REPORT")
        print("-" * 40)
        for key, val in results.items():
            unit = "W" if "Wattage" in key else ("V" if "Voltage" in key else "A")
            print(f"{key:25}: {val}{unit}")
        print("-" * 40)

        try:
            v_total = float(results["Voltage (Total)"])
            v_single = float(results["Voltage (Single Cell)"])
            if v_total > v_single * 1.5:
                print("Status: Dual-Cell battery detected. Total voltage is the sum of both cells.")
            else:
                print("Status: Single-Cell battery detected.")
        except:
            pass
        print("-" * 40)
