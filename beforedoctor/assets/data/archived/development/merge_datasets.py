#!/usr/bin/env python3
"""
Dataset Merger Script
Merges CSV and JSON pediatric symptom datasets into a comprehensive JSON format.
"""

import json
import csv
import re
from typing import Dict, List, Any

def load_json_dataset(file_path: str) -> Dict[str, Any]:
    """Load the existing JSON dataset."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading JSON dataset: {e}")
        return {}

def load_csv_dataset(file_path: str) -> List[Dict[str, str]]:
    """Load the CSV dataset and convert to list of dictionaries."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            return list(reader)
    except Exception as e:
        print(f"Error loading CSV dataset: {e}")
        return []

def convert_csv_to_json_format(csv_data: List[Dict[str, str]]) -> Dict[str, Any]:
    """Convert CSV data to JSON format matching the existing structure."""
    json_data = {}
    
    # Common pediatric symptoms to replace generic placeholders
    real_symptoms = [
        "fever", "cough", "vomiting", "diarrhea", "rash", "ear_pain", 
        "headache", "sore_throat", "breathing_difficulty", "abdominal_pain",
        "constipation", "fatigue", "dehydration", "allergic_reaction",
        "asthma", "pneumonia", "bronchitis", "strep_throat", "flu",
        "chickenpox", "measles", "mumps", "roseola", "hand_foot_mouth",
        "impetigo", "ringworm", "scabies", "lice", "eczema", "dermatitis",
        "conjunctivitis", "pink_eye", "stye", "ear_infection", "sinusitis",
        "tonsillitis", "laryngitis", "croup", "whooping_cough", "bronchiolitis",
        "gastroenteritis", "food_poisoning", "appendicitis", "hernia",
        "urinary_tract_infection", "kidney_infection", "bladder_infection",
        "seizure", "migraine", "tension_headache", "cluster_headache",
        "motion_sickness", "car_sickness", "seasickness", "altitude_sickness",
        "heat_exhaustion", "heat_stroke", "hypothermia", "frostbite",
        "sunburn", "poison_ivy", "bee_sting", "spider_bite", "snake_bite",
        "animal_bite", "human_bite", "scrape", "cut", "burn", "bruise",
        "sprain", "strain", "fracture", "dislocation", "concussion",
        "nosebleed", "toothache", "dental_abscess", "gum_disease",
        "thrush", "cold_sore", "canker_sore", "gingivostomatitis",
        "teething", "colic", "reflux", "spitting_up", "gas_pain",
        "hiccups", "burping", "belching", "nausea", "dizziness",
        "fainting", "syncope", "palpitations", "chest_pain", "back_pain",
        "neck_pain", "shoulder_pain", "elbow_pain", "wrist_pain",
        "hip_pain", "knee_pain", "ankle_pain", "foot_pain", "toe_pain",
        "joint_pain", "muscle_pain", "bone_pain", "nerve_pain",
        "itching", "burning", "tingling", "numbness", "weakness",
        "paralysis", "tremor", "twitching", "spasm", "cramp",
        "swelling", "edema", "inflammation", "infection", "abscess",
        "boil", "pimple", "acne", "blackhead", "whitehead",
        "mole", "wart", "birthmark", "freckle", "age_spot"
    ]
    
    for i, row in enumerate(csv_data):
        # Use real symptom name if available, otherwise use generic
        symptom_name = real_symptoms[i] if i < len(real_symptoms) else f"symptom_{i+1}"
        
        # Create age groups for comprehensive coverage
        age_groups = ["infant", "toddler", "preschool", "school_age", "adolescent"]
        
        for age_group in age_groups:
            key = f"{symptom_name}_{age_group}"
            
            # Parse follow-up questions
            follow_up_raw = row.get('Follow-Up Questions', '')
            follow_up_questions = [q.strip() for q in follow_up_raw.split(';') if q.strip()]
            
            # Parse diagnoses
            diagnoses_raw = row.get('Likely Diagnosis', '')
            diagnoses = [d.strip() for d in diagnoses_raw.split(';') if d.strip()]
            
            # Parse treatment questions
            treatment_questions_raw = row.get('Treatment Questions', '')
            treatment_questions = [q.strip() for q in treatment_questions_raw.split(';') if q.strip()]
            
            # Create comprehensive treatment structure
            treatment = {
                "otc": [
                    f"{symptom_name}-relief medication (OTC)",
                    "Acetaminophen for pain/fever",
                    "Ibuprofen for inflammation"
                ],
                "prescription": [
                    f"Prescription treatment for {symptom_name}",
                    "Antibiotics if bacterial infection",
                    "Steroids for severe inflammation"
                ],
                "home_remedies": [
                    f"Home care for {symptom_name} (hydration, rest)",
                    "Cool compresses",
                    "Warm compresses",
                    "Humidifier",
                    "Salt water gargle",
                    "Honey (for children >1 year)"
                ],
                "precautions": [
                    f"Monitor severity of {symptom_name}, seek help if worsens",
                    "Watch for signs of dehydration",
                    "Monitor temperature",
                    "Check for red flags"
                ]
            }
            
            # Create rich prompt template
            prompt_template = f"""Analyze the condition of a {age_group} child experiencing {symptom_name}. 

Step 1: Ask clarifying questions:
- What is the child's age and gender?
- When did the {symptom_name} start?
- How severe is the {symptom_name}?
- Are there any other symptoms present?
- Has the child experienced this before?
- Any recent exposures (food, medication, travel)?

Step 2: Consider differential diagnoses:
- Most common causes for {symptom_name} in {age_group} children
- Age-specific considerations
- Red flags to watch for

Step 3: Recommend appropriate treatment:
- Age-appropriate medications
- Home care measures
- When to seek medical attention

Provide a comprehensive assessment with clear next steps for the caregiver."""

            json_data[key] = {
                "symptom": symptom_name,
                "age_group": age_group,
                "prompt_template": prompt_template,
                "follow_up_questions": follow_up_questions,
                "diagnosis_list": diagnoses,
                "treatment": treatment,
                "urgency_level": row.get('Urgency Level', 'medium'),
                "suggested_treatment": row.get('Suggested Treatment', ''),
                "treatment_questions": treatment_questions,
                "red_flags": [
                    f"Severe {symptom_name}",
                    f"Persistent {symptom_name}",
                    f"{symptom_name} with high fever",
                    f"{symptom_name} with breathing difficulty",
                    f"{symptom_name} with signs of dehydration"
                ]
            }
    
    return json_data

def merge_datasets(json_data: Dict[str, Any], csv_converted: Dict[str, Any]) -> Dict[str, Any]:
    """Merge the two datasets, prioritizing richer content."""
    merged = {}
    
    # Add all JSON data (higher quality)
    for key, value in json_data.items():
        merged[key] = value
    
    # Add CSV-converted data, avoiding duplicates
    for key, value in csv_converted.items():
        if key not in merged:
            merged[key] = value
        else:
            # If duplicate, merge the best parts
            existing = merged[key]
            new_data = value
            
            # Merge follow-up questions
            existing_questions = set(existing.get('follow_up_questions', []))
            new_questions = set(new_data.get('follow_up_questions', []))
            merged[key]['follow_up_questions'] = list(existing_questions.union(new_questions))
            
            # Merge diagnoses
            existing_diagnoses = set(existing.get('diagnosis_list', []))
            new_diagnoses = set(new_data.get('diagnosis_list', []))
            merged[key]['diagnosis_list'] = list(existing_diagnoses.union(new_diagnoses))
            
            # Merge treatment options
            existing_treatment = existing.get('treatment', {})
            new_treatment = new_data.get('treatment', {})
            
            for category in ['otc', 'prescription', 'home_remedies', 'precautions']:
                existing_items = set(existing_treatment.get(category, []))
                new_items = set(new_treatment.get(category, []))
                merged[key]['treatment'][category] = list(existing_items.union(new_items))
    
    return merged

def main():
    """Main function to merge datasets."""
    print("🔄 Starting dataset merge...")
    
    # Load existing JSON dataset
    json_file = "archived/smaller_versions/pediatric_prompt_dataset_1000.json"
    json_data = load_json_dataset(json_file)
    print(f"✅ Loaded JSON dataset: {len(json_data)} records")
    
    # Load and convert CSV dataset
    csv_file = "Pediatric_Prompt_Dataset__Flat_Format_.csv"
    csv_data = load_csv_dataset(csv_file)
    print(f"✅ Loaded CSV dataset: {len(csv_data)} records")
    
    # Convert CSV to JSON format
    csv_converted = convert_csv_to_json_format(csv_data)
    print(f"✅ Converted CSV to JSON format: {len(csv_converted)} records")
    
    # Merge datasets
    merged_data = merge_datasets(json_data, csv_converted)
    print(f"✅ Merged datasets: {len(merged_data)} total records")
    
    # Save merged dataset
    output_file = "pediatric_symptom_dataset_merged.json"
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(merged_data, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Saved merged dataset to: {output_file}")
    print(f"📊 Final dataset contains {len(merged_data)} comprehensive symptom records")
    
    # Print some statistics
    symptoms = set()
    age_groups = set()
    for key, value in merged_data.items():
        symptoms.add(value.get('symptom', ''))
        age_groups.add(value.get('age_group', ''))
    
    print(f"🏥 Unique symptoms: {len(symptoms)}")
    print(f"👶 Age groups: {', '.join(sorted(age_groups))}")

if __name__ == "__main__":
    main() 