import os
import time
import numpy as np
import tensorflow as tf

# -------------------------------------------------
# Utility: Compute model size in MB
# -------------------------------------------------
def model_size_mb(path):
    size_bytes = os.path.getsize(path)
    return size_bytes / (1024 * 1024)

# -------------------------------------------------
# FP32 TFLite model path
# -------------------------------------------------
fp32_path = r"C:\Users\DWIGHT LANCE JUMAOAS\Downloads\snakes_philippines\runs\train\snakes_yolo112\snakes_yolo112\weights\best_saved_model\best_float32.tflite"

# -------------------------------------------------
# Model size evaluation
# -------------------------------------------------
fp32_size = model_size_mb(fp32_path)
print(f"FP32 TFLite model size : {fp32_size:.2f} MB")

# -------------------------------------------------
# Load FP32 TFLite interpreter
# -------------------------------------------------
interpreter = tf.lite.Interpreter(model_path=fp32_path)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# -------------------------------------------------
# Prepare dummy input (based on model input shape)
# -------------------------------------------------
input_shape = input_details[0]['shape']
input_dtype = input_details[0]['dtype']

input_data = np.random.rand(*input_shape).astype(input_dtype)

# -------------------------------------------------
# Warm-up runs (to stabilize performance)
# -------------------------------------------------
warmup_runs = 10
for _ in range(warmup_runs):
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()

# -------------------------------------------------
# Inference time measurement
# -------------------------------------------------
runs = 100
start_time = time.time()

for _ in range(runs):
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()

end_time = time.time()

avg_inference_time_ms = ((end_time - start_time) / runs) * 1000
print(f"Average FP32 inference time : {avg_inference_time_ms:.2f} ms")
