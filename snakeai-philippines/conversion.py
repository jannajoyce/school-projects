from ultralytics import YOLO
import os

trained_model = YOLO(r'C:\Users\DWIGHT LANCE JUMAOAS\Downloads\snakes_philippines\runs\train\snakes_yolo112\snakes_yolo112\weights\best.ptt')

trained_model.export(format='tflite')  # Export model to TensorFlow Lite for mobile deployment

print("\nExport complete! Files generated in:")

