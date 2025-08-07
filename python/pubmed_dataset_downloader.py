#!/usr/bin/env python3
"""
PubMed Dataset Downloader for BeforeDoctor
Downloads and processes pediatric symptom treatment datasets from PubMed
"""

import requests
import json
import time
import os
from datetime import datetime
from typing import List, Dict, Any
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('pubmed_download.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class PubMedDatasetDownloader:
    """Downloads and processes PubMed pediatric symptom treatment datasets"""
    
    def __init__(self):
        self.base_url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
        self.search_url = f"{self.base_url}/esearch.fcgi"
        self.summary_url = f"{self.base_url}/esummary.fcgi"
        self.fetch_url = f"{self.base_url}/efetch.fcgi"
        
        # Search queries for pediatric symptom treatment datasets
        self.search_queries = [
            "pediatric symptom treatment dataset",
            "child symptom management clinical trial",
            "pediatric fever treatment study",
            "child cough treatment dataset",
            "pediatric pain management clinical",
            "child vomiting treatment study",
            "pediatric rash treatment dataset",
            "child diarrhea treatment clinical",
            "pediatric respiratory symptoms study",
            "child allergy treatment dataset",
            "pediatric medication safety study",
            "child immunization reaction dataset",
            "pediatric emergency symptoms study",
            "child growth monitoring dataset",
            "pediatric developmental screening",
            "pediatric fever management",
            "child cough management",
            "pediatric pain assessment",
            "child dehydration treatment",
            "pediatric rash diagnosis"
        ]
        
        # Symptom keywords for classification
        self.symptom_keywords = {
            'fever': ['fever', 'pyrexia', 'temperature', 'hyperthermia'],
            'cough': ['cough', 'coughing', 'respiratory', 'bronchitis'],
            'vomiting': ['vomit', 'vomiting', 'emesis', 'nausea'],
            'diarrhea': ['diarrhea', 'diarrhoea', 'loose stools', 'gastroenteritis'],
            'pain': ['pain', 'ache', 'discomfort', 'soreness'],
            'rash': ['rash', 'eruption', 'dermatitis', 'eczema'],
            'fatigue': ['fatigue', 'tiredness', 'lethargy', 'exhaustion'],
            'headache': ['headache', 'head pain', 'migraine'],
            'wheezing': ['wheezing', 'wheeze', 'asthma'],
            'sore throat': ['sore throat', 'pharyngitis', 'tonsillitis'],
            'runny nose': ['runny nose', 'rhinorrhea', 'nasal discharge'],
            'ear pain': ['ear pain', 'otalgia', 'otitis'],
            'abdominal pain': ['abdominal pain', 'stomach ache', 'colic'],
            'dehydration': ['dehydration', 'fluid loss', 'electrolyte imbalance']
        }
        
        # Treatment keywords for classification
        self.treatment_keywords = {
            'antibiotics': ['antibiotic', 'antibiotics', 'penicillin', 'amoxicillin', 'ceftriaxone'],
            'antipyretics': ['antipyretic', 'acetaminophen', 'paracetamol', 'ibuprofen', 'aspirin'],
            'antihistamines': ['antihistamine', 'benadryl', 'diphenhydramine', 'cetirizine'],
            'bronchodilators': ['bronchodilator', 'albuterol', 'salbutamol', 'ipratropium'],
            'corticosteroids': ['corticosteroid', 'prednisone', 'dexamethasone', 'hydrocortisone'],
            'oral rehydration': ['oral rehydration', 'ors', 'electrolyte', 'pedialyte'],
            'vaccination': ['vaccine', 'vaccination', 'immunization', 'immunisation'],
            'surgery': ['surgery', 'surgical', 'operation', 'procedure'],
            'physical therapy': ['physical therapy', 'physiotherapy', 'rehabilitation'],
            'dietary changes': ['diet', 'nutrition', 'feeding', 'dietary']
        }
        
        self.studies = []
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'BeforeDoctor/1.0 (https://github.com/beforedoctor)'
        })

    def search_pubmed(self, query: str, max_results: int = 20) -> List[str]:
        """Search PubMed for studies matching the query"""
        try:
            params = {
                'db': 'pubmed',
                'term': query,
                'retmax': max_results,
                'retmode': 'json',
                'sort': 'relevance'
            }
            
            logger.info(f"Searching PubMed for: {query}")
            response = self.session.get(self.search_url, params=params)
            response.raise_for_status()
            
            data = response.json()
            id_list = data.get('esearchresult', {}).get('idlist', [])
            
            logger.info(f"Found {len(id_list)} studies for query: {query}")
            return id_list
            
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 429:
                logger.warning(f"Rate limited for query '{query}'. Waiting 60 seconds...")
                time.sleep(60)
                return []
            else:
                logger.error(f"HTTP error searching PubMed for '{query}': {e}")
                return []
        except Exception as e:
            logger.error(f"Error searching PubMed for '{query}': {e}")
            return []

    def fetch_study_details(self, pmid: str) -> Dict[str, Any]:
        """Fetch detailed information for a specific study"""
        try:
            params = {
                'db': 'pubmed',
                'id': pmid,
                'retmode': 'json'
            }
            
            response = self.session.get(self.summary_url, params=params)
            response.raise_for_status()
            
            data = response.json()
            result = data.get('result', {}).get(pmid, {})
            
            if not result:
                return {}
            
            study = {
                'pmid': pmid,
                'title': result.get('title', ''),
                'abstract': result.get('abstract', ''),
                'authors': [author.get('name', '') for author in result.get('authors', [])],
                'journal': result.get('fulljournalname', ''),
                'pubdate': result.get('pubdate', ''),
                'keywords': result.get('keywords', []),
                'mesh_terms': result.get('meshterms', []),
                'study_type': self.extract_study_type(result.get('title', ''), result.get('abstract', '')),
                'symptom_focus': self.extract_symptom_focus(result.get('title', ''), result.get('abstract', '')),
                'treatment_mentioned': self.extract_treatment_mention(result.get('title', ''), result.get('abstract', '')),
                'age_group': self.extract_age_group(result.get('title', ''), result.get('abstract', '')),
                'sample_size': self.extract_sample_size(result.get('abstract', '')),
                'relevance_score': self.calculate_relevance_score(result.get('title', ''), result.get('abstract', '')),
                'download_date': datetime.now().isoformat()
            }
            
            return study
            
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 429:
                logger.warning(f"Rate limited for PMID {pmid}. Waiting 60 seconds...")
                time.sleep(60)
                return {}
            else:
                logger.error(f"HTTP error fetching study details for PMID {pmid}: {e}")
                return {}
        except Exception as e:
            logger.error(f"Error fetching study details for PMID {pmid}: {e}")
            return {}

    def extract_study_type(self, title: str, abstract: str) -> str:
        """Extract study type from title and abstract"""
        text = f"{title.lower()} {abstract.lower()}"
        
        if 'randomized' in text or 'rct' in text:
            return 'RCT'
        elif 'systematic review' in text or 'meta-analysis' in text:
            return 'Review'
        elif 'case study' in text or 'case report' in text:
            return 'Case Study'
        elif 'cohort study' in text:
            return 'Cohort'
        elif 'cross-sectional' in text:
            return 'Cross-sectional'
        elif 'observational' in text:
            return 'Observational'
        elif 'clinical trial' in text:
            return 'Clinical Trial'
        
        return 'Other'

    def extract_symptom_focus(self, title: str, abstract: str) -> List[str]:
        """Extract symptom focus from title and abstract"""
        text = f"{title.lower()} {abstract.lower()}"
        symptoms = []
        
        for symptom, keywords in self.symptom_keywords.items():
            for keyword in keywords:
                if keyword in text:
                    symptoms.append(symptom)
                    break
        
        return list(set(symptoms))

    def extract_treatment_mention(self, title: str, abstract: str) -> List[str]:
        """Extract treatment mentions from title and abstract"""
        text = f"{title.lower()} {abstract.lower()}"
        treatments = []
        
        for treatment, keywords in self.treatment_keywords.items():
            for keyword in keywords:
                if keyword in text:
                    treatments.append(treatment)
                    break
        
        return list(set(treatments))

    def extract_age_group(self, title: str, abstract: str) -> str:
        """Extract age group from title and abstract"""
        text = f"{title.lower()} {abstract.lower()}"
        
        if 'neonatal' in text or 'newborn' in text:
            return 'Neonatal (0-28 days)'
        elif 'infant' in text or 'baby' in text:
            return 'Infant (1-12 months)'
        elif 'toddler' in text:
            return 'Toddler (1-3 years)'
        elif 'preschool' in text:
            return 'Preschool (3-5 years)'
        elif 'school age' in text or 'school-age' in text:
            return 'School age (6-12 years)'
        elif 'adolescent' in text or 'teen' in text:
            return 'Adolescent (13-18 years)'
        elif 'pediatric' in text or 'children' in text:
            return 'Pediatric (0-18 years)'
        
        return 'Not specified'

    def extract_sample_size(self, abstract: str) -> int:
        """Extract sample size from abstract"""
        import re
        
        try:
            pattern = r'(\d+)\s*(?:patients?|children|subjects?|participants?)'
            match = re.search(pattern, abstract, re.IGNORECASE)
            if match:
                return int(match.group(1))
        except Exception as e:
            logger.warning(f"Failed to extract sample size: {e}")
        
        return 0

    def calculate_relevance_score(self, title: str, abstract: str) -> float:
        """Calculate relevance score for pediatric symptom treatment"""
        score = 0.0
        text = f"{title.lower()} {abstract.lower()}"
        
        # Pediatric focus
        if 'pediatric' in text or 'child' in text or 'infant' in text:
            score += 0.3
        
        # Symptom focus
        if self.extract_symptom_focus(title, abstract):
            score += 0.2
        
        # Treatment focus
        if self.extract_treatment_mention(title, abstract):
            score += 0.2
        
        # Recent publication (last 10 years)
        current_year = datetime.now().year
        import re
        year_match = re.search(r'(\d{4})', text)
        if year_match:
            try:
                year = int(year_match.group(1))
                if current_year - year <= 10:
                    score += 0.1
            except ValueError:
                pass
        
        # Study quality indicators
        if 'randomized' in text or 'systematic review' in text:
            score += 0.1
        if 'clinical trial' in text:
            score += 0.1
        
        return min(score, 1.0)

    def download_all_studies(self) -> List[Dict[str, Any]]:
        """Download all studies from PubMed"""
        all_studies = []
        
        for query in self.search_queries:
            logger.info(f"Processing query: {query}")
            
            # Search for studies
            pmid_list = self.search_pubmed(query)
            
            # Fetch details for each study
            for pmid in pmid_list:
                study = self.fetch_study_details(pmid)
                if study:
                    all_studies.append(study)
                
                # Rate limiting to respect PubMed API guidelines (3 requests per second)
                time.sleep(0.4)
            
            # Rate limiting between queries
            time.sleep(2)
        
        # Remove duplicates based on PMID
        unique_studies = {}
        for study in all_studies:
            unique_studies[study['pmid']] = study
        
        self.studies = list(unique_studies.values())
        logger.info(f"Downloaded {len(self.studies)} unique studies")
        
        return self.studies

    def save_to_json(self, filename: str = None) -> str:
        """Save studies to JSON file"""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"pubmed_pediatric_studies_{timestamp}.json"
        
        data = {
            'metadata': {
                'total_studies': len(self.studies),
                'download_date': datetime.now().isoformat(),
                'search_queries': self.search_queries,
                'version': '1.0'
            },
            'studies': self.studies,
            'statistics': self.generate_statistics()
        }
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        
        logger.info(f"Saved {len(self.studies)} studies to {filename}")
        return filename

    def generate_statistics(self) -> Dict[str, Any]:
        """Generate statistics from downloaded studies"""
        stats = {
            'total_studies': len(self.studies),
            'study_types': {},
            'age_groups': {},
            'symptoms_covered': {},
            'treatments_mentioned': {},
            'publication_years': {},
            'sample_sizes': []
        }
        
        for study in self.studies:
            # Study types
            study_type = study.get('study_type', 'Unknown')
            stats['study_types'][study_type] = stats['study_types'].get(study_type, 0) + 1
            
            # Age groups
            age_group = study.get('age_group', 'Not specified')
            stats['age_groups'][age_group] = stats['age_groups'].get(age_group, 0) + 1
            
            # Symptoms
            for symptom in study.get('symptom_focus', []):
                stats['symptoms_covered'][symptom] = stats['symptoms_covered'].get(symptom, 0) + 1
            
            # Treatments
            for treatment in study.get('treatment_mentioned', []):
                stats['treatments_mentioned'][treatment] = stats['treatments_mentioned'].get(treatment, 0) + 1
            
            # Publication years
            pubdate = study.get('pubdate', '')
            if pubdate:
                import re
                year_match = re.search(r'(\d{4})', pubdate)
                if year_match:
                    year = year_match.group(1)
                    stats['publication_years'][year] = stats['publication_years'].get(year, 0) + 1
            
            # Sample sizes
            sample_size = study.get('sample_size', 0)
            if sample_size > 0:
                stats['sample_sizes'].append(sample_size)
        
        return stats

    def export_for_flutter(self, output_dir: str = "assets/data") -> str:
        """Export data in format suitable for Flutter app"""
        os.makedirs(output_dir, exist_ok=True)
        
        # Create Flutter-compatible JSON
        flutter_data = {
            'studies': self.studies,
            'statistics': self.generate_statistics(),
            'last_updated': datetime.now().isoformat(),
            'version': '1.0'
        }
        
        output_file = os.path.join(output_dir, "pubmed_pediatric_studies.json")
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(flutter_data, f, indent=2, ensure_ascii=False)
        
        logger.info(f"Exported Flutter-compatible data to {output_file}")
        return output_file

def main():
    """Main function to download PubMed datasets"""
    logger.info("Starting PubMed dataset download for BeforeDoctor")
    
    downloader = PubMedDatasetDownloader()
    
    try:
        # Download all studies
        studies = downloader.download_all_studies()
        
        # Save to JSON
        json_file = downloader.save_to_json()
        
        # Export for Flutter
        flutter_file = downloader.export_for_flutter()
        
        # Print statistics
        stats = downloader.generate_statistics()
        logger.info(f"Download completed successfully!")
        logger.info(f"Total studies: {stats['total_studies']}")
        logger.info(f"Study types: {stats['study_types']}")
        logger.info(f"Age groups: {stats['age_groups']}")
        logger.info(f"Top symptoms: {dict(sorted(stats['symptoms_covered'].items(), key=lambda x: x[1], reverse=True)[:5])}")
        logger.info(f"Top treatments: {dict(sorted(stats['treatments_mentioned'].items(), key=lambda x: x[1], reverse=True)[:5])}")
        
    except Exception as e:
        logger.error(f"Error during download: {e}")
        raise

if __name__ == "__main__":
    main() 