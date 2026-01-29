
from ultralytics import YOLO
import os

DATA_YAML = r'C:\Users\DWIGHT LANCE JUMAOAS\Downloads\snakes_philippines\dataset\data.yaml'

# ==============================
# STEP 5: Load Pretrained YOLOv11 Model
# ==============================
model = YOLO('yolo11n.pt')  # lightweight YOLOv11 nano version

# ==============================
# STEP 6: Train the Model
# ==============================
model.train(
    data=DATA_YAML,
    epochs=500,
    imgsz=640,
    batch=16,
    name='snakes_yolo11',
    project=r'C:\Users\DWIGHT LANCE JUMAOAS\Downloads\snakes_philippines\runs',  # save results to Drive
    workers=2,
)
