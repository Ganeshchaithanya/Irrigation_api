import asyncio
import json
import uuid
import sys
import os

# Set console output to handle UTF-8 if possible (Windows fix)
if sys.platform == "win32":
    import subprocess
    # Use 'chcp 65001' to set the console to UTF-8
    try:
        subprocess.run(["chcp", "65001"], shell=True)
    except:
        pass

# Add project root to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.ai_service import AIService

def safe_print(text):
    """Prints text in a way that handles encoding issues on Windows terminals."""
    try:
        print(text)
    except UnicodeEncodeError:
        print(text.encode('ascii', errors='replace').decode('ascii'))

async def simulate_scenario(ai, scenario):
    """Run a single test scenario through the AI Engine."""
    name = scenario['name']
    sensor_data = scenario['sensor_data']
    state = scenario.get('state', "IDLE")
    prev_data = scenario.get('previous_data', {})
    
    # Inject previous data context for sudden drop detection
    if 'moisture' in prev_data:
        sensor_data['previous_moisture'] = prev_data['moisture']
    
    safe_print(f"\n" + "-"*60)
    safe_print(f"SCENARIO: {name}")
    safe_print(f"Description: {scenario['description']}")
    safe_print(f"State: {state} | Sensor: {sensor_data}")
    safe_print("-"*60)
    
    zone_id = uuid.uuid4()
    
    try:
        # We pass a list containing the single reading for this scenario
        report = await ai.generate_full_report([sensor_data], {}, zone_id, current_state=state)
        
        # 1. Anomaly Layer Report
        safe_print(f"\nAI ENGINE AUDIT [Status: {report['status']}]")
        
        if report['anomalies']:
            safe_print("\nLAYER 1: ANOMALY MONITOR")
            for a in report['anomalies']:
                safe_print(f"  [CRITICAL] Type: {a.get('type', 'UNKNOWN')}")
                safe_print(f"  -> AI Diagnosis: {a['ai_diagnosis']}")
                safe_print(f"  -> Suggested Action: {a['suggested_action']}")
        else:
            safe_print("\nLAYER 1: NO ANOMALIES DETECTED")

        # 2. Prediction Layer (Partial display for focus)
        pred = report['predictions']
        safe_print(f"\nLAYER 2: PREDICTIVE STRATEGY")
        if 'recommendation_text' in pred:
            safe_print(f"  -> Advice: \"{pred['recommendation_text']}\"")
        else:
            safe_print(f"  -> Status: {pred.get('status', 'NONE')}")

    except Exception as e:
        print(f"ERROR during scenario {name}: {e}")

async def main():
    # 1. Initialize AI Engine with default crop (e.g., Corn)
    safe_print("STARTING PRECISION AI ENGINE AUDIT (FAO-56 BASED)...")
    ai_corn = AIService(crop_type="corn")
    ai_succulent = AIService(crop_type="succulent")
    
    # 2. Load Test Material
    try:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        scenarios_path = os.path.join(base_dir, "test_scenarios.json")
        with open(scenarios_path, "r") as f:
            scenarios = json.load(f)
    except Exception as e:
        safe_print(f"ERROR: Failed to load test scenarios: {e}")
        return

    # 3. RUN AUDIT LOOP
    # We'll run a few key scenarios with different crops to see the delta
    for scenario in scenarios[:3]: # First 3: Healthy, Leak, Burst
        safe_print(f"\n[CROP: CORN]")
        await simulate_scenario(ai_corn, scenario)
        
        safe_print(f"\n[CROP: SUCCULENT]")
        await simulate_scenario(ai_succulent, scenario)

    safe_print("\n" + "="*60)
    safe_print("  All scenarios complete.")
    safe_print("  AI Engine Precision Audit finished.")
    safe_print("="*60)

if __name__ == "__main__":
    asyncio.run(main())
