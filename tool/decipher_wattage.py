import sys

def decipher_wattage(jumble):
    if len(jumble) != 64:
        print("Error: Jumble must be exactly 64 characters long.")
        return None

    # Wattage starts at the 21st character (index 20)
    # The jumble is generated from numbers 0-9.
    # The wattage is formatted as toStringAsFixed(2), so it looks like "XX.XX"
    # However, since the jumble base is only numbers '0123456789',
    # the dot '.' will be preserved in the jumble because of how _generateJumble works.

    # We need to find where the wattage value ends.
    # It starts at index 20. We can look for the pattern of numbers and a dot.

    potential_wattage = ""
    for i in range(20, len(jumble)):
        char = jumble[i]
        if char.isdigit() or char == '.':
            potential_wattage += char
        else:
            break

        # We know wattage is formatted as fixed 2 decimals,
        # so it's likely something like "15.50" (5 chars) or "5.50" (4 chars)
        # We can stop if we have 2 digits after the dot.
        if '.' in potential_wattage:
            parts = potential_wattage.split('.')
            if len(parts) > 1 and len(parts[1]) == 2:
                break

    return potential_wattage

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python decipher_wattage.py <64_char_jumble>")
        sys.exit(1)

    jumble_input = sys.argv[1]
    result = decipher_wattage(jumble_input)
    if result:
        print(f"Extracted Wattage: {result}W")
