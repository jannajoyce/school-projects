from collections import defaultdict
import glob

label_files = glob.glob("valid/labels/*.txt")

images_per_class = defaultdict(set)

for label in label_files:
    image_name = label.split("/")[-1].replace(".txt", "")
    with open(label, "r") as f:
        for line in f:
            class_id = int(line.split()[0])
            images_per_class[class_id].add(image_name)

# Print results
for class_id in sorted(images_per_class):
    print(f"Class {class_id}: {len(images_per_class[class_id])} images")
