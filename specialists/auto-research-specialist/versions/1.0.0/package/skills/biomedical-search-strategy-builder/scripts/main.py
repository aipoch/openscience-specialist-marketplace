#!/usr/bin/env python3
"""
PubMed Search Specialist
Builds complex Boolean query strings for precise PubMed/MEDLINE retrieval.
"""

import argparse
import datetime
import json
import re
import sys
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict
from enum import Enum

try:
    import urllib.request
    import urllib.parse
    _HAS_URLLIB = True
except ImportError:
    _HAS_URLLIB = False

# Compute current year dynamically so date filters are never stale
_CURRENT_YEAR = datetime.datetime.now().year


class FieldTag(Enum):
    """PubMed field tags for search queries."""
    MESH_TERMS = "[MeSH Terms]"
    MESH_MAJOR = "[MeSH Major Topic]"
    TITLE = "[Title]"
    ABSTRACT = "[Abstract]"
    TITLE_ABSTRACT = "[Title/Abstract]"
    AUTHOR = "[Author]"
    JOURNAL = "[Journal]"
    PUB_DATE = "[Publication Date]"
    LANGUAGE = "[Language]"
    PUB_TYPE = "[Publication Type]"
    AFFILIATION = "[Affiliation]"


class FilterType(Enum):
    """Common PubMed filter categories — date filters use dynamic current year."""
    HUMANS = 'humans[MeSH Terms]'
    ANIMALS = 'animals[MeSH Terms]'
    ENGLISH = 'english[Language]'
    ADULT = 'adult[MeSH Terms]'
    AGED = 'aged[MeSH Terms]'
    CHILD = 'child[MeSH Terms]'
    LAST_5_YEARS = f'{_CURRENT_YEAR - 5}:{_CURRENT_YEAR}[Publication Date]'
    LAST_10_YEARS = f'{_CURRENT_YEAR - 10}:{_CURRENT_YEAR}[Publication Date]'
    RCT = 'randomized controlled trial[Publication Type]'
    META_ANALYSIS = 'meta-analysis[Publication Type]'
    SYSTEMATIC_REVIEW = 'systematic review[Publication Type]'
    REVIEW = 'review[Publication Type]'
    CLINICAL_TRIAL = 'clinical trial[Publication Type]'


@dataclass
class SearchConcept:
    """Represents a search concept with MeSH and text word components."""
    name: str
    mesh_terms: List[str]
    text_words: List[str]
    use_explode: bool = True
    subheadings: Optional[List[str]] = None
    was_fallback: bool = False  # True if MeSH mapping failed

    def to_query(self) -> str:
        parts = []
        for mesh in self.mesh_terms:
            if self.was_fallback:
                # Fallback: search as Title/Abstract not as MeSH term
                parts.append(f'"{mesh}"{FieldTag.TITLE_ABSTRACT.value}')
            else:
                if self.subheadings:
                    for sub in self.subheadings:
                        parts.append(f'"{mesh}/{sub}"{FieldTag.MESH_TERMS.value}')
                else:
                    explode_mod = "" if self.use_explode else ":noexp"
                    parts.append(f'"{mesh}"{FieldTag.MESH_TERMS.value}{explode_mod}')
        for tw in self.text_words:
            parts.append(f'"{tw}"{FieldTag.TITLE_ABSTRACT.value}')
        return f"({(' OR '.join(parts))})"


@dataclass
class SearchStrategy:
    """Complete search strategy with concepts and filters."""
    concepts: List[SearchConcept]
    filters: List[str]
    description: str = ""
    fallback_warnings: List[str] = None  # type: ignore

    def to_query(self) -> str:
        concept_queries = [c.to_query() for c in self.concepts]
        all_parts = concept_queries + self.filters
        return f"({' AND '.join(all_parts)})"

    def to_line_by_line(self) -> str:
        lines = []
        for i, concept in enumerate(self.concepts, 1):
            lines.append(f"# {i}. {concept.name}")
            if concept.was_fallback:
                lines.append(f"# ⚠️  '{concept.mesh_terms[0]}' is a free-text literal (MeSH mapping not found in local dictionary)")
            lines.append(concept.to_query())

        if self.filters:
            lines.append(f"# {len(self.concepts) + 1}. Filters")
            lines.append(f"({' AND '.join(self.filters)})")

        lines.append("\n# Final Query")
        lines.append(self.to_query())

        if self.fallback_warnings:
            lines.append("\n# ⚠️  MeSH Fallback Warnings")
            lines.append("# The following concepts were not found in the local MeSH dictionary")
            lines.append("# and are used as free-text literals. Verify at https://meshb.nlm.nih.gov/")
            for w in self.fallback_warnings:
                lines.append(f"#   - {w}")
            lines.append("# Note: Free-text literals may miss records indexed only under the MeSH heading.")

        return '\n'.join(lines)


class MeSHMapper:
    """Maps common medical concepts to MeSH terms."""

    # Expanded common term mappings (≈80+ entries for broad coverage)
    COMMON_MESH = {
        # ── Populations / Diseases ──────────────────────────────────────────
        "diabetes": ["Diabetes Mellitus", "Diabetes Mellitus, Type 2", "Diabetes Mellitus, Type 1"],
        "diabetes mellitus": ["Diabetes Mellitus", "Diabetes Mellitus, Type 2", "Diabetes Mellitus, Type 1"],
        "type 2 diabetes": ["Diabetes Mellitus, Type 2"],
        "type 1 diabetes": ["Diabetes Mellitus, Type 1"],
        "hypertension": ["Hypertension"],
        "high blood pressure": ["Hypertension"],
        "obesity": ["Obesity"],
        "overweight": ["Overweight"],
        "stroke": ["Stroke", "Brain Ischemia"],
        "ischemic stroke": ["Brain Ischemia"],
        "hemorrhagic stroke": ["Intracranial Hemorrhages"],
        "myocardial infarction": ["Myocardial Infarction"],
        "heart attack": ["Myocardial Infarction"],
        "heart failure": ["Heart Failure"],
        "atrial fibrillation": ["Atrial Fibrillation"],
        "coronary artery disease": ["Coronary Artery Disease"],
        "cancer": ["Neoplasms"],
        "tumor": ["Neoplasms"],
        "tumour": ["Neoplasms"],
        "lung cancer": ["Lung Neoplasms"],
        "breast cancer": ["Breast Neoplasms"],
        "colorectal cancer": ["Colorectal Neoplasms"],
        "prostate cancer": ["Prostatic Neoplasms"],
        "liver cancer": ["Liver Neoplasms"],
        "hepatocellular carcinoma": ["Carcinoma, Hepatocellular"],
        "glioblastoma": ["Glioblastoma"],
        "glioma": ["Glioma"],
        "leukemia": ["Leukemia"],
        "lymphoma": ["Lymphoma"],
        "nsclc": ["Carcinoma, Non-Small-Cell Lung"],
        "non-small cell lung cancer": ["Carcinoma, Non-Small-Cell Lung"],
        "ovarian cancer": ["Ovarian Neoplasms"],
        "gastric cancer": ["Stomach Neoplasms"],
        "pancreatic cancer": ["Pancreatic Neoplasms"],
        "depression": ["Depression"],
        "major depressive disorder": ["Depressive Disorder, Major"],
        "anxiety": ["Anxiety Disorders"],
        "schizophrenia": ["Schizophrenia"],
        "dementia": ["Dementia"],
        "alzheimer": ["Alzheimer Disease"],
        "alzheimer's disease": ["Alzheimer Disease"],
        "parkinson": ["Parkinson Disease"],
        "parkinson's disease": ["Parkinson Disease"],
        "multiple sclerosis": ["Multiple Sclerosis"],
        "epilepsy": ["Epilepsy"],
        "asthma": ["Asthma"],
        "copd": ["Pulmonary Disease, Chronic Obstructive"],
        "sepsis": ["Sepsis"],
        "pneumonia": ["Pneumonia"],
        "covid-19": ["COVID-19"],
        "sars-cov-2": ["COVID-19", "SARS-CoV-2"],
        "hiv": ["HIV Infections"],
        "aids": ["Acquired Immunodeficiency Syndrome"],
        "rheumatoid arthritis": ["Arthritis, Rheumatoid"],
        "lupus": ["Lupus Erythematosus, Systemic"],
        "inflammatory bowel disease": ["Inflammatory Bowel Diseases"],
        "crohn's disease": ["Crohn Disease"],
        "ulcerative colitis": ["Colitis, Ulcerative"],
        "chronic kidney disease": ["Renal Insufficiency, Chronic"],
        "kidney failure": ["Kidney Failure, Chronic"],
        "liver cirrhosis": ["Liver Cirrhosis"],
        "nonalcoholic fatty liver": ["Non-alcoholic Fatty Liver Disease"],
        "acute respiratory distress": ["Respiratory Distress Syndrome"],

        # ── Interventions / Drugs ────────────────────────────────────────────
        "aspirin": ["Aspirin"],
        "acetylsalicylic acid": ["Aspirin"],
        "metformin": ["Metformin"],
        "insulin": ["Insulin"],
        "statins": ["Hydroxymethylglutaryl-CoA Reductase Inhibitors"],
        "statin": ["Hydroxymethylglutaryl-CoA Reductase Inhibitors"],
        "placebo": ["Placebos"],
        "surgery": ["Surgical Procedures, Operative"],
        "exercise": ["Exercise"],
        "physical activity": ["Exercise"],
        "diet": ["Diet Therapy"],
        "chemotherapy": ["Drug Therapy"],
        "immunotherapy": ["Immunotherapy"],
        "pembrolizumab": ["Pembrolizumab"],
        "nivolumab": ["Nivolumab"],
        "bevacizumab": ["Bevacizumab"],
        "trastuzumab": ["Trastuzumab"],
        "temozolomide": ["Temozolomide"],
        "radiation": ["Radiotherapy"],
        "radiotherapy": ["Radiotherapy"],
        "checkpoint inhibitor": ["Immune Checkpoint Inhibitors"],
        "pd-1": ["Programmed Cell Death 1 Receptor"],
        "pd-l1": ["B7-H1 Antigen"],
        "ctla-4": ["CTLA-4 Antigen"],
        "car-t": ["Receptors, Chimeric Antigen"],
        "antidepressant": ["Antidepressive Agents"],
        "ssri": ["Selective Serotonin Reuptake Inhibitors"],
        "anticoagulant": ["Anticoagulants"],
        "warfarin": ["Warfarin"],
        "beta blocker": ["Adrenergic beta-Antagonists"],
        "ace inhibitor": ["Angiotensin-Converting Enzyme Inhibitors"],
        "antibiotic": ["Anti-Bacterial Agents"],

        # ── Outcomes / Endpoints ─────────────────────────────────────────────
        "mortality": ["Mortality"],
        "overall survival": ["Survival Rate"],
        "progression-free survival": ["Disease-Free Survival"],
        "recurrence": ["Neoplasm Recurrence, Local"],
        "quality of life": ["Quality of Life"],
        "adverse effects": ["Drug-Related Side Effects and Adverse Reactions"],
        "side effects": ["Drug-Related Side Effects and Adverse Reactions"],
        "efficacy": ["Treatment Outcome"],
        "treatment outcome": ["Treatment Outcome"],
        "safety": ["Safety"],
        "hospitalization": ["Hospitalization"],
        "readmission": ["Patient Readmission"],

        # ── Study Design / Methods ───────────────────────────────────────────
        "randomized controlled trial": ["Randomized Controlled Trials as Topic"],
        "meta-analysis": ["Meta-Analysis as Topic"],
        "systematic review": ["Systematic Reviews as Topic"],
        "cohort study": ["Cohort Studies"],
        "case-control": ["Case-Control Studies"],
        "cross-sectional": ["Cross-Sectional Studies"],
        "biomarker": ["Biomarkers"],
        "gene expression": ["Gene Expression"],
        "genome-wide association": ["Genome-Wide Association Study"],
        "gwas": ["Genome-Wide Association Study"],
        "rna sequencing": ["Sequence Analysis, RNA"],
        "single-cell": ["Single-Cell Analysis"],
        "machine learning": ["Machine Learning"],
        "deep learning": ["Deep Learning"],
    }

    # Synonym suggestions for free-text expansion
    SYNONYM_MAP = {
        "diabetes": ["diabetic", "diabetics", "hyperglycemia", "glycemic"],
        "hypertension": ["high blood pressure", "elevated blood pressure", "blood pressure"],
        "stroke": ["cerebrovascular accident", "cva", "brain attack", "cerebral infarction"],
        "myocardial infarction": ["heart attack", "mi", "cardiac infarction", "acute coronary"],
        "aspirin": ["acetylsalicylic acid", "asa"],
        "cancer": ["tumor", "tumour", "malignancy", "malignant", "neoplasm"],
        "glioblastoma": ["gbm", "glioblastoma multiforme", "grade iv glioma", "high-grade glioma"],
        "temozolomide": ["tmz", "temodar", "temodal"],
        "immunotherapy": ["checkpoint inhibitor", "pd-1", "pd-l1", "ctla-4", "immune checkpoint"],
        "quality of life": ["qol", "hrqol", "health-related quality of life", "patient-reported outcomes"],
        "children": ["child", "pediatric", "paediatric", "infant", "adolescent"],
        "elderly": ["aged", "older adults", "geriatric", "seniors", "elderly patients"],
        "alzheimer": ["alzheimer's disease", "ad", "amyloid", "cognitive decline"],
        "covid-19": ["sars-cov-2", "coronavirus", "covid", "2019-ncov"],
        "mortality": ["death", "fatal", "fatality", "all-cause mortality"],
        "survival": ["overall survival", "os", "disease-free survival", "progression-free"],
        "biomarker": ["marker", "predictor", "indicator", "prognostic factor"],
        "machine learning": ["ml", "deep learning", "artificial intelligence", "neural network"],
    }

    # Track fallback concepts for summary reporting
    _fallback_log: List[str] = []

    @classmethod
    def reset_fallback_log(cls):
        cls._fallback_log = []

    @classmethod
    def suggest_mesh(cls, concept: str) -> Tuple[List[str], bool]:
        """
        Suggest MeSH terms for a concept.
        Returns (terms, was_fallback) where was_fallback=True means no MeSH match found.
        """
        concept_lower = concept.lower().strip()
        results = []

        # Exact key match
        if concept_lower in cls.COMMON_MESH:
            results.extend(cls.COMMON_MESH[concept_lower])
        else:
            # Partial match
            for key, terms in cls.COMMON_MESH.items():
                if key in concept_lower or concept_lower in key:
                    results.extend(terms)

        if results:
            return list(set(results)), False

        # Fallback: try NCBI MeSH lookup API
        api_result = cls._ncbi_mesh_lookup(concept_lower)
        if api_result:
            return api_result, False

        # Final fallback: concept as literal
        cls._fallback_log.append(concept)
        return [concept], True

    @classmethod
    def _ncbi_mesh_lookup(cls, concept: str) -> Optional[List[str]]:
        """Try NCBI MeSH API lookup. Returns list of MeSH terms or None if unavailable."""
        if not _HAS_URLLIB:
            return None
        try:
            encoded = urllib.parse.quote(concept)
            url = f"https://id.nlm.nih.gov/mesh/lookup/descriptor?label={encoded}&match=startswith&limit=3"
            req = urllib.request.Request(url, headers={"Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=5) as resp:
                data = json.loads(resp.read().decode())
            terms = [item.get("label", "") for item in data if item.get("label")]
            return terms if terms else None
        except Exception:
            return None

    @classmethod
    def suggest_synonyms(cls, concept: str) -> List[str]:
        """Suggest text word synonyms for a concept."""
        concept_lower = concept.lower().strip()
        for key, syns in cls.SYNONYM_MAP.items():
            if key in concept_lower or concept_lower in key:
                return syns
        return []

    @classmethod
    def get_fallback_summary(cls) -> List[str]:
        return list(cls._fallback_log)


class QueryBuilder:
    """Builds PubMed Boolean queries."""

    CLINICAL_QUERIES = {
        "therapy": """(
            randomized controlled trial[Publication Type] OR
            (randomized[Title/Abstract] AND controlled[Title/Abstract] AND trial[Title/Abstract]) OR
            (clinical[Title/Abstract] AND trial[Title/Abstract])
        )""",

        "diagnosis": """(
            sensitivity and specificity[MeSH Terms] OR
            sensitivity[Title/Abstract] OR
            specificity[Title/Abstract] OR
            "diagnostic accuracy"[Title/Abstract] OR
            "likelihood ratio"[Title/Abstract] OR
            "roc curve"[Title/Abstract]
        )""",

        "prognosis": """(
            incidence[MeSH Terms] OR
            mortality[MeSH Terms] OR
            "follow-up studies"[MeSH Terms] OR
            prognos*[Title/Abstract] OR
            predict*[Title/Abstract] OR
            course[Title/Abstract]
        )""",

        "etiology": """(
            risk[MeSH Terms] OR
            "risk factors"[MeSH Terms] OR
            (risk[Title/Abstract] AND factor*[Title/Abstract]) OR
            caus*[Title/Abstract] OR
            associat*[Title/Abstract]
        )""",

        "clinical_prediction": """(
            "predictive value of tests"[MeSH Terms] OR
            "clinical prediction rule"[Title/Abstract] OR
            (predict*[Title/Abstract] AND model[Title/Abstract]) OR
            "decision rule"[Title/Abstract] OR
            "risk score"[Title/Abstract]
        )"""
    }

    @classmethod
    def build_pico_query(
        cls,
        population: Optional[str] = None,
        intervention: Optional[str] = None,
        comparison: Optional[str] = None,
        outcome: Optional[str] = None,
        study_type: Optional[str] = None,
        show_mapping: bool = False
    ) -> SearchStrategy:
        """Build query from PICO components."""
        MeSHMapper.reset_fallback_log()
        concepts = []
        mapping_table = []

        def add_concept(label: str, term: str):
            mesh_terms, was_fallback = MeSHMapper.suggest_mesh(term)
            synonyms = MeSHMapper.suggest_synonyms(term)
            if show_mapping:
                mapping_table.append((label, term, mesh_terms, synonyms, was_fallback))
            # For fallback terms, use as text words; for known terms add the literal as text word too
            text_words = synonyms + ([term] if was_fallback else [term])
            concepts.append(SearchConcept(
                name=label,
                mesh_terms=mesh_terms,
                text_words=list(set(text_words)),
                use_explode=True,
                was_fallback=was_fallback
            ))

        if population:
            add_concept("Population", population)
        if intervention:
            add_concept("Intervention", intervention)
        if comparison:
            add_concept("Comparison", comparison)
        if outcome:
            add_concept("Outcome", outcome)

        if show_mapping and mapping_table:
            print("\n# MeSH Mapping Table (Step 2b check-in)")
            print(f"{'Concept':<15} {'Input':<25} {'MeSH Term(s)':<40} {'Synonyms':<30} {'Fallback?'}")
            print("-" * 120)
            for label, term, mesh_terms, syns, fallback in mapping_table:
                fallback_str = "⚠️ YES" if fallback else "No"
                mesh_str = "; ".join(mesh_terms[:2])
                syn_str = ", ".join(syns[:3])
                print(f"{label:<15} {term:<25} {mesh_str:<40} {syn_str:<30} {fallback_str}")
            print()
            resp = input("Does this mapping look correct? (y = proceed, n = abort): ").strip().lower()
            if resp != 'y':
                print("Aborting query construction. Please refine your PICO terms.")
                raise SystemExit(0)

        filters = []
        if study_type and study_type.lower() in cls.CLINICAL_QUERIES:
            filters.append(cls.CLINICAL_QUERIES[study_type.lower()])

        fallback_warnings = MeSHMapper.get_fallback_summary()

        return SearchStrategy(
            concepts=concepts,
            filters=filters,
            description="PICO-based search strategy",
            fallback_warnings=fallback_warnings if fallback_warnings else None
        )

    @classmethod
    def validate_query(cls, query: str) -> Tuple[bool, List[str]]:
        """Validate query syntax including parentheses, quotes, and square brackets."""
        errors = []

        # Check balanced parentheses
        if query.count('(') != query.count(')'):
            open_count = query.count('(')
            close_count = query.count(')')
            errors.append(f"Unbalanced parentheses: {open_count} opening '(' vs {close_count} closing ')'")

        # Check balanced square brackets — critical for PubMed field tags
        if query.count('[') != query.count(']'):
            open_count = query.count('[')
            close_count = query.count(']')
            errors.append(
                f"Unbalanced square brackets: {open_count} opening '[' vs {close_count} closing ']'. "
                f"A field tag such as '[MeSH Terms' without a closing ']' will cause a PubMed syntax error."
            )

        # Check for unclosed quotes
        if query.count('"') % 2 != 0:
            errors.append("Unclosed quotation marks (odd number of '\"' characters)")

        # Check for valid field tags (only complete tags will be found by this regex)
        valid_tags = [tag.value for tag in FieldTag]
        found_tags = re.findall(r'\[[A-Za-z/: ]+\]', query)
        for tag in found_tags:
            if tag not in valid_tags:
                errors.append(f"Unusual or unrecognized field tag: {tag} — verify against PubMed field tag list")

        return len(errors) == 0, errors


def main():
    parser = argparse.ArgumentParser(
        description="PubMed Search Specialist — Build complete Boolean queries for systematic literature searches"
    )

    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    # PICO command
    pico_parser = subparsers.add_parser('pico', help='Build query from PICO framework')
    pico_parser.add_argument('-p', '--population', help='Population/Problem')
    pico_parser.add_argument('-i', '--intervention', help='Intervention')
    pico_parser.add_argument('-c', '--comparison', help='Comparison')
    pico_parser.add_argument('-o', '--outcome', help='Outcome')
    pico_parser.add_argument('-s', '--study-type',
                             choices=['therapy', 'diagnosis', 'prognosis', 'etiology', 'clinical_prediction'],
                             help='Clinical query category')
    pico_parser.add_argument('--format', choices=['query', 'lines', 'json'], default='lines',
                             help='Output format')
    pico_parser.add_argument('--show-mapping', action='store_true',
                             help='Show MeSH mapping table and ask for confirmation before building query (Step 2b)')

    # MeSH suggestion command
    mesh_parser = subparsers.add_parser('mesh', help='Look up MeSH terms for a concept')
    mesh_parser.add_argument('concept', help='Concept to map to MeSH')

    # Validate command
    validate_parser = subparsers.add_parser('validate', help='Validate PubMed query syntax')
    validate_parser.add_argument('query', help='Query string to validate')

    args = parser.parse_args()

    if args.command == 'pico':
        strategy = QueryBuilder.build_pico_query(
            population=args.population,
            intervention=args.intervention,
            comparison=args.comparison,
            outcome=args.outcome,
            study_type=args.study_type,
            show_mapping=args.show_mapping
        )

        if args.format == 'json':
            print(json.dumps(asdict(strategy), indent=2, default=str))
        elif args.format == 'query':
            print(strategy.to_query())
        else:  # lines
            print(strategy.to_line_by_line())

        # Emit fallback warnings to stderr as a summary block
        fallbacks = MeSHMapper.get_fallback_summary()
        if fallbacks:
            print("\n⚠️  MeSH Fallback Summary:", file=sys.stderr)
            for concept in fallbacks:
                print(f"  - '{concept}' not found in local MeSH dictionary (~{len(MeSHMapper.COMMON_MESH)} terms).", file=sys.stderr)
                print(f"    Used as free-text literal. Verify the correct MeSH heading at:", file=sys.stderr)
                print(f"    https://meshb.nlm.nih.gov/search?searchInField=termCompleteSuggest&term={urllib.parse.quote(concept) if _HAS_URLLIB else concept}", file=sys.stderr)

    elif args.command == 'mesh':
        concept = args.concept
        mesh_terms, was_fallback = MeSHMapper.suggest_mesh(concept)
        synonyms = MeSHMapper.suggest_synonyms(concept)

        print(f"Concept: {concept}")

        if was_fallback:
            print(f"\n⚠️  '{concept}' was NOT found in local MeSH dictionary.")
            print(f"   Local dictionary covers ~{len(MeSHMapper.COMMON_MESH)} common medical concepts.")
            print(f"   If this concept has an official MeSH heading, it will be missed by your search.")
            print(f"\n   Recommended actions:")
            print(f"   1. Look up the correct MeSH heading at: https://meshb.nlm.nih.gov/")
            print(f"   2. Use the confirmed MeSH heading as a controlled vocabulary term.")
            print(f"   3. Add free-text synonyms (abbreviations, trade names, variant spellings).")
            print(f"\n   For systematic reviews: this fallback may cause significant recall loss.")
            print(f"   This concept will be searched as free-text '{concept}' in [Title/Abstract].")
        else:
            print(f"\nSuggested MeSH Terms (controlled vocabulary):")
            for term in mesh_terms:
                print(f"  - {term}")

        print(f"\nSuggested Free-Text Synonyms:")
        if synonyms:
            for syn in synonyms:
                print(f"  - {syn}")
        else:
            print(f"  - No synonyms in local dictionary for '{concept}'")
            print(f"    Consider: trade names, abbreviations, common misspellings, variant spellings")

    elif args.command == 'validate':
        valid, errors = QueryBuilder.validate_query(args.query)
        if valid:
            print("✓ Query syntax is valid (parentheses, square brackets, and quotes are balanced)")
            print("  Note: Validation checks syntax balance only — it does not verify MeSH term existence.")
            print("  Always test your final query in PubMed before use in a systematic review.")
        else:
            print("✗ Query has syntax errors:")
            for error in errors:
                print(f"  - {error}")
            print("\n  Fix all errors before submitting to PubMed.")

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
