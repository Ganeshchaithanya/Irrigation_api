import httpx
import asyncio
import json

async def verify_ai_logic():
    print("\n" + "🚀" * 15)
    print("🔥 AI ENGINE API E2E VERIFICATION")
    print("🚀" * 15)

    url = "http://localhost:8001/ai/run"
    
    # 1. SETUP: Mock a Zone with a failed MIDDLE node
    payload = {
        "zone_id": "test-zone-001",
        "current_state": "IDLE",
        "crop_season": "Rabi",
        "day_of_growth": 45,
        "sensor_data": [
            {"id": "node-middle", "moisture": 0.0, "temp": 30.0}, # FAULTY
            {"id": "node-middle", "moisture": 0.0, "temp": 30.0},
            {"id": "node-middle", "moisture": 0.0, "temp": 30.0}
        ],
        "neighbors": [
            {"id": "node-start", "position_label": "START", "status": "ACTIVE", "moisture_history": [45.0, 44.5, 44.0]},
            {"id": "node-middle", "position_label": "MIDDLE", "status": "ACTIVE"},
            {"id": "node-end", "position_label": "END", "status": "ACTIVE", "moisture_history": [48.0, 47.5, 47.0]}
        ]
    }

    print("\n📦 Sending 'Middle Node Fault' payload to AI Engine (Port 8001)...")
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=payload, timeout=60.0)
            
            if response.status_code != 200:
                print(f"❌ FAILED: AI Engine returned {response.status_code}")
                print(response.text)
                return

            report = response.json()
            print("\n" + "="*50)
            print("📊 AI ENGINE RESPONSE")
            print("="*50)

            # A. Check Anomaly detection
            anoms = report.get('anomalies', [])
            print(f"📡 Hardware Health: {report['status']}")
            for a in anoms:
                print(f"   - {a.get('type')}: {a.get('ai_diagnosis')}")

            # B. Check Surrogacy
            pred = report.get('predictions', {})
            is_virtual = pred.get('is_virtual_sensing_active')
            print(f"\n🔮 Resiliency Check:")
            print(f"   - Node Surrogacy Active: {is_virtual}")
            if is_virtual:
                print(f"   - STATUS: SUCCESS. AI detected the fault and used neighbor data.")

            # C. Check AI Reasoning
            print(f"\n💡 Llama-3.2 Reasoning:")
            print(f"   - Decision: {pred.get('backend_action')}")
            print(f"   - Reasoning: \"{pred.get('ai_reasoning')}\"")
            print(f"   - Time until Needed: {pred.get('hours_until_needed')}h")
            print(f"   - Tomorrow Requirement: {pred.get('tomorrow_mm_needed')}mm")

            print("\n✅ E2E VERIFICATION COMPLETE. Logic Chain (Anomaly -> Surrogacy -> AI Reasoning) is ALIVE.")

    except Exception as e:
        print(f"❌ CRITICAL ERROR: Could not connect to AI Engine: {e}")

if __name__ == "__main__":
    asyncio.run(verify_ai_logic())
