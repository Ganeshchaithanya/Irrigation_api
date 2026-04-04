import asyncio
import sys
import os

# Add project root to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from application.ai.specialists.vector_db import VectorDB

async def test():
    try:
        print("Initializing VectorDB...")
        db = VectorDB()
        print("Success.")
        
        print("Testing add_farm_memory...")
        db.add_farm_memory("Test memory from simulation.", {"zone_id": "test_zone", "type": "test"})
        print("Success.")
        
        print("Testing retrieval...")
        res = db.retrieve_expert_knowledge("test_zone", type="experience")
        print(f"Retrieved: {res}")
        
    except Exception as e:
        print(f"FAILED: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test())
