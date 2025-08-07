#!/usr/bin/env python3
import pandas as pd
import json

def check_nih_data():
    try:
        # Load the real metadata file
        df = pd.read_csv('nih_chest_xray_training/data/Data_Entry_2017.csv')
        
        print(f"📊 NIH Dataset Analysis:")
        print(f"Total records: {len(df):,}")
        print(f"Columns: {list(df.columns)}")
        
        # Check if Patient_Age column exists
        if 'Patient_Age' in df.columns:
            pediatric_df = df[df['Patient_Age'] < 18]
            print(f"Pediatric cases (age < 18): {len(pediatric_df):,}")
            print(f"\n👶 Pediatric Age Distribution:")
            print(pediatric_df['Patient_Age'].value_counts().sort_index())
        else:
            print("Patient_Age column not found. Available columns:")
            for col in df.columns:
                print(f"  - {col}")
        
        # Check respiratory conditions
        if 'Finding Labels' in df.columns:
            respiratory_conditions = ['Pneumonia', 'Effusion', 'Atelectasis', 'Consolidation']
            respiratory_cases = df[df['Finding Labels'].str.contains('|'.join(respiratory_conditions), na=False)]
            print(f"\n🫁 Respiratory Cases: {len(respiratory_cases):,}")
            
            # Sample some findings
            print(f"\n📋 Sample Findings:")
            print(df['Finding Labels'].value_counts().head(10))
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_nih_data() 