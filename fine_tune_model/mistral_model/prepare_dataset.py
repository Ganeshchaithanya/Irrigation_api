import json
import os

def prepare_dataset():
    data_dir = os.path.dirname(os.path.abspath(__file__))
    files = ["kharif.json", "rabi.json", "zaid.json"]
    output_file = os.path.join(data_dir, "train_data.jsonl")
    
    samples = []
    
    for filename in files:
        filepath = os.path.join(data_dir, filename)
        if not os.path.exists(filepath):
            print(f"Skipping {filename} (not found)")
            continue
            
        with open(filepath, "r") as f:
            season_data = json.load(f)
            season_name = season_data.get("season", "Unknown")
            
            for crop in season_data.get("crops", []):
                crop_name = crop["name"]
                for stage in crop.get("growth_stages", []):
                    stage_name = stage["stage"]
                    min_m = stage["soil_moisture_min"]
                    max_m = stage["soil_moisture_max"]
                    freq = stage["irrigation_frequency"]
                    ops = ", ".join(stage.get("critical_operations", [])) or "None"
                    
                    # Create multiple samples per stage (start, middle, end)
                    days = [stage["days_start"], (stage["days_start"] + stage["days_end"]) // 2, stage["days_end"]]
                    # Use set to avoid duplicates for 1-day stages
                    for d in set(days):
                        instruction = "Identify the crop growth stage and irrigation requirements."
                        input_text = f"Season: {season_name}, Crop: {crop_name}, Day: {d}"
                        output_text = (f"Stage: {stage_name}. "
                                     f"Moisture Requirement: {min_m}%-{max_m}%. "
                                     f"Irrigation Frequency: {freq}. "
                                     f"Critical Operations: {ops}.")
                        
                        samples.append({
                            "instruction": instruction,
                            "input": input_text,
                            "output": output_text
                        })

    with open(output_file, "w") as f:
        for s in samples:
            f.write(json.dumps(s) + "\n")
            
    print(f"Successfully generated {len(samples)} samples in {output_file}")

if __name__ == "__main__":
    prepare_dataset()
