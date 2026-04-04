import pandas as pd
import numpy as np

class DataPipeline:
    def __init__(self):
        pass

    def clean_data(self, df):
        """Preprocessing (cleaning, normalization) for sensor streams."""
        return df

    def _compute_similarity(self, device_a_id, device_b_id, sensor_history):
        """
        Simple similarity check between two devices based on moisture trends.
        In a real system, we'd use a longer history from the DB.
        """
        # Extract moisture streams for both devices
        stream_a = [r['moisture'] for r in sensor_history if str(r.get('id')) == str(device_a_id)]
        stream_b = [r['moisture'] for r in sensor_history if str(r.get('id')) == str(device_b_id)]
        
        if len(stream_a) < 3 or len(stream_b) < 3:
            return 1.0  # Default to high similarity if not enough data yet
            
        # Basic correlation-like check
        diffs = [abs(a - b) for a, b in zip(stream_a[-10:], stream_b[-10:])]
        avg_diff = sum(diffs) / len(diffs)
        
        # 0.0 (identical) to 1.0 (very different). Return 1.0 - normalized diff.
        score = max(0.0, 1.0 - (avg_diff / 50.0))
        return score

    def identify_surrogate(self, failed_device_id, neighbors, sensor_history):
        """
        PICKS A SURROGATE: Logic to pick a healthy neighbor based on similarity.
        """
        MIN_SIMILARITY = 0.75
        
        potential_surrogates = [n for n in neighbors if str(n.get('id')) != str(failed_device_id) and n.get('status') == 'ACTIVE']
        
        if not potential_surrogates:
            return None, 0.0
        
        best_surrogate = None
        best_score = -1.0
        
        for n in potential_surrogates:
            score = self._compute_similarity(failed_device_id, n['id'], sensor_history)
            if score > best_score:
                best_score = score
                best_surrogate = n
                
        if best_surrogate and best_score >= MIN_SIMILARITY:
            return best_surrogate, best_score
            
        return None, 0.0

    def apply_surrogacy(self, raw_data, anomalies, neighbors):
        """
        CORE VIRTUAL SENSING: Mirroring readings with similarity validation.
        """
        processed_data = []
        for reading in raw_data:
            device_id = str(reading.get('id'))
            
            # Check if this device has a critical anomaly (failing)
            is_failing = any(a['device_id'] == device_id and a['severity'] == 'critical' for a in anomalies)
            
            if is_failing:
                surrogate, confidence = self.identify_surrogate(device_id, neighbors, raw_data)
                if surrogate:
                    # Mirror the surrogate's data
                    surrogate_reading = next((r for r in raw_data if str(r.get('id')) == str(surrogate['id'])), None)
                    
                    if surrogate_reading:
                        virtual_reading = reading.copy()
                        virtual_reading['moisture'] = surrogate_reading['moisture']
                        virtual_reading['temp'] = surrogate_reading['temp']
                        virtual_reading['is_virtual'] = True
                        virtual_reading['surrogate_id'] = surrogate['id']
                        virtual_reading['surrogate_confidence'] = confidence
                        processed_data.append(virtual_reading)
                        continue
            
            processed_data.append(reading)
        
        return processed_data

    def handle_missing_values(self, df):
        """Imputation logic for missing sensor data."""
        return df.interpolate(method='linear').ffill().bfill()

    def virtual_sensing_interpolation(self, failed_node_id, neighbors_data, weather_data):
        """
        VIRTUAL SENSING: Resilience for faulty nodes.
        If a node fails, interpolate from neighbors' past irrigation timing/patterns.
        Implementation: virtual_irrigation = avg_neighbor_past + weather_adjust.
        """
        avg_neighbor_moisture = np.mean([n['moisture'] for n in neighbors_data])
        weather_adjust = weather_data.get('predicted_evapotranspiration', 0.0)
        
        # Kalman filter or regression model can be plugged in here
        virtual_reading = avg_neighbor_moisture + (weather_adjust * 0.1)
        return virtual_reading
