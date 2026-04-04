import json
import os
import sys

# 1. PATH SETUP
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Repath removed by unification refactor

from application.ai.specialists.vector_db import VectorDB

def ingest_all_guides():
    db = VectorDB()
    guide_dir = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 
        "data", 
        "guides"
    )
    
    seasons = ["kharif", "rabi", "zaid"]
    
    for season_name in seasons:
        file_path = os.path.join(guide_dir, f"{season_name}_cropguide.json")
        if not os.path.exists(file_path):
            print(f"[INGESTOR] Skipping {season_name} - File not found.")
            continue
            
        print(f"[INGESTOR] Processing {season_name.capitalize()} Guide...")
        with open(file_path, "r") as f:
            data = json.load(f)
            
        season = data.get("season", season_name.capitalize())
        crops = data.get("crops", [])
        
        for crop in crops:
            crop_name = crop.get("crop_name")
            guide = crop.get("complete_farming_guide", {})
            
            documents = []
            metadatas = []
            ids = []
            
            # Chunking Strategy: Break by "Step"
            for step_key, step_data in guide.items():
                title = step_data.get("title", step_key)
                # handle list of steps or list of dicts (pests/diseases)
                if "steps" in step_data:
                    step_text = "\n".join([f"- {s}" for s in step_data["steps"]])
                elif "schedule" in step_data:
                    sched = step_data["schedule"]
                    step_text = "\n".join([f"- {s.get('timing')}: {s.get('fertilizers')}" for s in sched])
                elif "pests" in step_data:
                    pests = step_data["pests"]
                    step_text = "\n".join([f"- {p.get('pest')}: {p.get('symptoms')} | Control: {p.get('control')}" for p in pests])
                elif "diseases" in step_data:
                    diseases = step_data["diseases"]
                    step_text = "\n".join([f"- {d.get('disease')}: {d.get('symptoms')} | Control: {d.get('control')}" for d in diseases])
                else:
                    step_text = str(step_data)

                # Construct Document
                doc_content = f"CROP: {crop_name} ({season})\nSTAGE: {title}\nINSTRUCTIONS:\n{step_text}"
                
                doc_id = f"EXPERT_{season}_{crop_name}_{step_key}".replace(" ", "_")
                
                documents.append(doc_content)
                metadatas.append({
                    "season": season,
                    "crop": crop_name,
                    "stage": title,
                    "type": "expert_guide"
                })
                ids.append(doc_id)
            
            # Batch Ingest for this crop
            if documents:
                db.expert_collection.add(
                    documents=documents,
                    metadatas=metadatas,
                    ids=ids
                )
                print(f"   [+] Ingested {len(documents)} steps for {crop_name}")

    print("\n✅ INGESTION COMPLETE. Your Scientific Guides are now part of the RAG system.")

if __name__ == "__main__":
    ingest_all_guides()
