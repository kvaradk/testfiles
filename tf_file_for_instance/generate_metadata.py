import json

# Read terraform.tfvars.json
with open("config.json", "r") as f:
    flat_data = json.load(f)

# Reconstruct the nested block_volume_attributes structure
block_volumes = []
volume_index = 1

while f"block_volume_{volume_index}-volume_size_in_gbs" in flat_data:
    bv = {
        "volume_size_in_gbs": int(flat_data[f"block_volume_{volume_index}-volume_size_in_gbs"]),
        "block_volume_name": flat_data[f"block_volume_{volume_index}-block_volume_name"],
        "block_volume_attachment_type": flat_data[f"block_volume_{volume_index}-block_volume_attachment_type"],
        "block_volume_partition_map": []
    }

    partition_index = 1
    while f"block_volume_{volume_index}-block_volume_partition_{partition_index}-block_volume_partition_size" in flat_data:
        partition = {
            "block_volume_partition_size": int(flat_data[f"block_volume_{volume_index}-block_volume_partition_{partition_index}-block_volume_partition_size"]),
            "block_volume_filesystem_type": flat_data[f"block_volume_{volume_index}-block_volume_partition_{partition_index}-block_volume_filesystem_type"],
            "block_volume_mount_point": flat_data[f"block_volume_{volume_index}-block_volume_partition_{partition_index}-block_volume_mount_point"]
        }
        bv["block_volume_partition_map"].append(partition)
        partition_index += 1

    block_volumes.append(bv)
    volume_index += 1

# Output JSON file for Terraform to read
output = {"block_volume_attributes": block_volumes}

with open("metadata.json", "w") as f:
    json.dump(output, f, indent=2)

print("Generated metadata.json successfully!")
