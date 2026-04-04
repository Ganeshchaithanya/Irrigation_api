import traceback
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

if __name__ == '__main__':
    try:
        import test_all_db_models
        test_all_db_models.test_all_models()
    except Exception as e:
        with open('run_error.txt', 'w', encoding='utf-8') as f:
            traceback.print_exc(file=f)
        print("Run failed. Error saved to run_error.txt")
