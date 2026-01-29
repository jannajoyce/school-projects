from ultralytics import YOLO
import os

trained_model = YOLO(r'C:\Users\DWIGHT LANCE JUMAOAS\Downloads\snakes_philippines\runs\train\snakes_yolo112\snakes_yolo112\weights\best.ptt')

print("\nEvaluating model on test dataset...")
results = trained_model.val(data=DATA_YAML, split='test')

print("\nTest Results Summary:")
print(results)
