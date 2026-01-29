import pandas as pd

# ------------------------------------------------------------------
# Load YOLO training results CSV
# Update the path if needed
# ------------------------------------------------------------------
csv_path = r"C:\Users\DWIGHT LANCE JUMAOAS\Downloads\snakes_philippines\runs\train\snakes_yolo112\snakes_yolo112\results.csv"
df = pd.read_csv(csv_path)

# ------------------------------------------------------------------
# Create summary table of losses
# ------------------------------------------------------------------
summary = pd.DataFrame(
    {
        "Min Train": [
            df["train/box_loss"].min(),
            df["train/cls_loss"].min(),
            df["train/dfl_loss"].min()
        ],
        "Min Val": [
            df["val/box_loss"].min(),
            df["val/cls_loss"].min(),
            df["val/dfl_loss"].min()
        ],
        "Avg Train": [
            df["train/box_loss"].mean(),
            df["train/cls_loss"].mean(),
            df["train/dfl_loss"].mean()
        ],
        "Avg Val": [
            df["val/box_loss"].mean(),
            df["val/cls_loss"].mean(),
            df["val/dfl_loss"].mean()
        ]
    },
    index=["Box Loss", "Class Loss", "DFL Loss"]
)

# ------------------------------------------------------------------
# Display summary
# ------------------------------------------------------------------
print("\nLoss Summary Table:")
print(summary)

# ------------------------------------------------------------------
# Optional: Save summary to CSV (for thesis / appendix)
# ------------------------------------------------------------------
summary.to_csv("loss_summary.csv")
print("\nLoss summary saved as loss_summary.csv")
