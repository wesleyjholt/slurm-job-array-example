from pathlib import Path
from typing import List, Dict
import re

# Define keywords related to pharmacokinetic compartment modeling
PK_KEYWORDS = {
    'compartment': ['compartment', 'compartmental', 'multi-compartment', 'one-compartment', 'two-compartment', 'three-compartment'],
    'pharmacokinetics': ['pharmacokinetic', 'pharmacokinetics', 'PK', 'PKPD', 'PK/PD'],
    'parameters': ['clearance', 'volume of distribution', 'Vd', 'CL', 'elimination', 'absorption', 'ka', 'ke'],
    'modeling': ['NONMEM', 'population PK', 'PopPK', 'Monolix', 'ADAPT', 'Phoenix', 'WinNonlin'],
    'kinetics': ['first-order', 'zero-order', 'Michaelis-Menten', 'bioavailability', 'AUC', 'Cmax', 'Tmax'],
    'distribution': ['central compartment', 'peripheral compartment', 'distribution phase', 'elimination phase']
}

def search_file_for_keywords(file_path: Path, keywords: Dict[str, List[str]], case_sensitive: bool = False) -> Dict[str, List[str]]:
    """
    Search a text file for specified keywords.

    Args:
        file_path: Path to the text file
        keywords: Dictionary of keyword categories and their terms
        case_sensitive: Whether to perform case-sensitive search

    Returns:
        Dictionary with categories as keys and list of found keywords as values
    """
    found_keywords = {category: [] for category in keywords.keys()}

    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

            if not case_sensitive:
                content_lower = content.lower()

            for category, terms in keywords.items():
                for term in terms:
                    search_term = term if case_sensitive else term.lower()
                    search_content = content if case_sensitive else content_lower

                    # Use word boundary regex for more accurate matching
                    pattern = r'\b' + re.escape(search_term) + r'\b'
                    if re.search(pattern, search_content, re.IGNORECASE if not case_sensitive else 0):
                        found_keywords[category].append(term)

        return found_keywords

    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return found_keywords

def search_directory(root_dir: str, keywords: Dict[str, List[str]],
                    file_extensions: List[str] = ['.txt', '.text'],
                    case_sensitive: bool = False) -> Dict[str, Dict[str, List[str]]]:
    """
    Recursively search through directory for keywords in text files.

    Args:
        root_dir: Root directory to search
        keywords: Dictionary of keyword categories and their terms
        file_extensions: List of file extensions to search
        case_sensitive: Whether to perform case-sensitive search

    Returns:
        Dictionary mapping file paths to found keywords
    """
    results = {}
    root_path = Path(root_dir)

    if not root_path.exists():
        print(f"Error: Directory '{root_dir}' does not exist")
        return results

    # Walk through all subdirectories
    for file_path in root_path.rglob('*'):
        if file_path.is_file() and file_path.suffix.lower() in file_extensions:
            found = search_file_for_keywords(file_path, keywords, case_sensitive)

            # Only include files that have at least one keyword match
            if any(found[category] for category in found):
                results[str(file_path)] = found

    return results

def print_results(results: Dict[str, Dict[str, List[str]]], show_categories: bool = True):
    """
    Print search results in a readable format.

    Args:
        results: Dictionary of file paths and their keyword matches
        show_categories: Whether to show keyword categories
    """
    if not results:
        print("No files found with matching keywords.")
        return

    print(f"\n{'='*80}")
    print(f"Found {len(results)} file(s) with pharmacokinetic compartment modeling keywords")
    print(f"{'='*80}\n")

    for file_path, found_keywords in sorted(results.items()):
        print(f"\n=� File: {file_path}")
        print("-" * 80)

        total_matches = sum(len(terms) for terms in found_keywords.values())
        print(f"Total keyword matches: {total_matches}")

        if show_categories:
            for category, terms in found_keywords.items():
                if terms:
                    print(f"  [{category}]: {', '.join(sorted(set(terms)))}")

        print("-" * 80)

def export_results_to_file(results: Dict[str, Dict[str, List[str]]], output_file: str):
    """
    Export search results to a text file.

    Args:
        results: Dictionary of file paths and their keyword matches
        output_file: Path to output file
    """
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("Pharmacokinetic Compartment Modeling Keyword Search Results\n")
        f.write("=" * 80 + "\n\n")

        for file_path, found_keywords in sorted(results.items()):
            f.write(f"File: {file_path}\n")
            f.write("-" * 80 + "\n")

            for category, terms in found_keywords.items():
                if terms:
                    f.write(f"  [{category}]: {', '.join(sorted(set(terms)))}\n")
            f.write("\n")

    print(f"\nResults exported to: {output_file}")

def save_relevant_filenames(results: Dict[str, Dict[str, List[str]]], output_file: str):
    """
    Save just the names of files that contain relevant keywords.

    Args:
        results: Dictionary of file paths and their keyword matches
        output_file: Path to output file for filenames
    """
    with open(output_file, 'w', encoding='utf-8') as f:
        for file_path in sorted(results.keys()):
            f.write(f"{file_path}\n")

    print(f"Relevant filenames saved to: {output_file}")

# Main execution
if __name__ == "__main__":
    # Configure your search parameters here
    ROOT_DIRECTORY = "/Users/kaisarthik/remote/txt"  # Change this to your target directory
    CASE_SENSITIVE = False
    FILE_EXTENSIONS = ['.txt', '.text', '.md']  # Add more extensions if needed
    EXPORT_RESULTS = True
    OUTPUT_FILE = "pk_compartment_search_results.txt"
    FILENAMES_ONLY_FILE = "relevant_files.txt"

    print("Starting pharmacokinetic compartment modeling keyword search...")
    print(f"Root directory: {ROOT_DIRECTORY}")
    print(f"File extensions: {', '.join(FILE_EXTENSIONS)}")
    print(f"Case sensitive: {CASE_SENSITIVE}\n")

    # Perform the search
    results = search_directory(
        root_dir=ROOT_DIRECTORY,
        keywords=PK_KEYWORDS,
        file_extensions=FILE_EXTENSIONS,
        case_sensitive=CASE_SENSITIVE
    )

    # Display results
    print_results(results, show_categories=True)

    # Export results if requested
    if EXPORT_RESULTS and results:
        export_results_to_file(results, OUTPUT_FILE)
        save_relevant_filenames(results, FILENAMES_ONLY_FILE)
