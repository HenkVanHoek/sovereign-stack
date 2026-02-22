import os
import pynetbox
from dotenv import load_dotenv


def main():
    load_dotenv()
    nb = pynetbox.api(os.getenv("NETBOX_URL").strip().rstrip('/'),
                      token=os.getenv("NETBOX_API_TOKEN").strip())

    file_path = "nmap_flat.txt"
    print(f"--- Starting Unique Device Rename ---")

    # We houden bij welke namen we al hebben gebruikt in deze run
    used_names = []

    with open(file_path, "r", encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or ';' not in line: continue

            hostname, ip, mac = line.split(';')
            short_mac = mac.replace(':', '').replace('-', '').replace('.', '').upper()[
                -4:]
            temp_name = f"New-Device-{short_mac}"

            # Schoon de naam op
            raw_name = hostname.replace('.fritz.box', '').strip()

            # Als de naam 'Unknown' is of we hebben hem al eens gebruikt, voeg suffix toe
            if raw_name == "Unknown" or raw_name in used_names:
                new_name = f"{raw_name}-{short_mac}"
            else:
                new_name = raw_name

            used_names.append(new_name)

            device = nb.dcim.devices.get(name=temp_name)
            if device:
                update_data = {}
                if device.name != new_name:
                    update_data["name"] = new_name

                if not device.primary_ip4:
                    ip_addr = nb.ipam.ip_addresses.get(address=f"{ip}/24")
                    if ip_addr:
                        update_data["primary_ip4"] = ip_addr.id

                if update_data:
                    try:
                        print(f"UPDATING {temp_name} -> {new_name}")
                        device.update(update_data)
                    except Exception as e:
                        print(f"FAILED to update {temp_name}: {e}")
            else:
                # Het kan zijn dat het apparaat al hernoemd is in een vorige (geparticipte) run
                # We checken of de nieuwe naam al bestaat
                check_exists = nb.dcim.devices.get(name=new_name)
                if check_exists:
                    print(f"ALREADY UPDATED: {new_name}")
                else:
                    print(f"NOT FOUND: {temp_name}")

    print(f"\n--- Finished ---")


if __name__ == "__main__":
    main()
