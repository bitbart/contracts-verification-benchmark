#!/usr/bin/env python3
"""
CSV Merger Tool for Property Verification Results

This script merges CSV files containing property verification results.
Usage: python merge_tools_results.py --bank

The script looks for CSV files in ../contracts/{folder_name}/
Expected files: ground-truth.csv, certora.csv, solcmc-z3.csv, solcmc-eld.csv, gpt-5.csv
"""

import argparse
import os
import pandas as pd
import glob
from pathlib import Path
import sys


def normalize_truth_value(value):
    """
    Convert various truth value representations to 0 or 1.
    
    Args:
        value: The value to normalize
        
    Returns:
        int: 0 or 1, or None if value is NaN/empty
    """
    if pd.isna(value) or value == '' or value is None:
        return None
    
    # Convert to string and strip whitespace
    str_value = str(value).strip().upper()
    
    # Truth value mapping
    truth_mapping = {
        'P': 1,
        'P!': 1,
        'N': 0,
        'N!': 0,
        'UNK': 0,
        'ERR': 0,
        'TRUE': 1,
        'FALSE': 0,
        '1': 1,
        '0': 0,
        '1.0': 1,
        '0.0': 0
    }
    
    return truth_mapping.get(str_value, None)


def load_and_process_csv(file_path):
    """
    Load a CSV file and extract the first three columns with proper naming.
    
    Args:
        file_path (str): Path to the CSV file
        
    Returns:
        tuple: (DataFrame, filename) or (None, filename) if error
    """
    filename = os.path.basename(file_path).replace('.csv', '')
    
    try:
        # Load the CSV file
        df = pd.read_csv(file_path)
        
        if len(df.columns) < 3:
            print(f"✗ Error: {filename}.csv has fewer than 3 columns")
            return None, filename
        
        # Take only the first three columns
        df_processed = df.iloc[:, :3].copy()
        
        # Rename columns to standard names
        df_processed.columns = ['property', 'version', 'truth_value']
        
        # Normalize truth values
        df_processed['truth_value'] = df_processed['truth_value'].apply(normalize_truth_value)
        
        # Remove rows where property or version is NaN
        df_processed = df_processed.dropna(subset=['property', 'version'])
        
        # Convert property and version to strings to ensure consistent types
        df_processed['property'] = df_processed['property'].astype(str)
        df_processed['version'] = df_processed['version'].astype(str)
        
        print(f"✓ Loaded {filename}.csv: {len(df_processed)} rows")
        
        return df_processed, filename
        
    except Exception as e:
        print(f"✗ Error loading {filename}.csv: {e}")
        return None, filename


def merge_verification_results(csv_files, output_path):
    """
    Merge verification result CSV files into a union format.
    
    Args:
        csv_files (list): List of CSV file paths
        output_path (str): Path for the merged output file
        
    Returns:
        bool: True if successful, False otherwise
    """
    if not csv_files:
        print("No CSV files found to merge.")
        return False
    
    print(f"\nProcessing {len(csv_files)} CSV files:")
    
    # Dictionary to store dataframes by filename
    dataframes = {}
    
    # Load all CSV files
    for file_path in csv_files:
        df, filename = load_and_process_csv(file_path)
        if df is not None:
            dataframes[filename] = df
    
    if not dataframes:
        print("No valid CSV files could be loaded.")
        return False
    
    print(f"\nSuccessfully loaded {len(dataframes)} files: {list(dataframes.keys())}")
    
    # Create the union of all property-version pairs
    all_pairs = set()
    for df in dataframes.values():
        pairs = set(zip(df['property'], df['version']))
        all_pairs.update(pairs)
    
    print(f"Total unique property-version pairs: {len(all_pairs)}")
    
    # Create base dataframe with all property-version pairs
    properties, versions = zip(*sorted(all_pairs))
    result_df = pd.DataFrame({
        'property': properties,
        'version': versions
    })
    
    # Add columns for each CSV file
    expected_files = ['ground-truth', 'certora', 'solcmc-z3', 'solcmc-eld', 'gpt-5']
    
    for file_key in expected_files:
        column_name = 'ground' if file_key == 'ground-truth' else file_key
        
        if file_key in dataframes:
            df = dataframes[file_key]
            # Create a mapping from (property, version) to truth_value
            value_map = dict(zip(zip(df['property'], df['version']), df['truth_value']))
            
            # Map values to result dataframe
            result_df[column_name] = result_df.apply(
                lambda row: value_map.get((row['property'], row['version']), None), 
                axis=1
            )
            
            non_null_count = result_df[column_name].notna().sum()
            print(f"  {column_name}: {non_null_count} values mapped")
        else:
            # Add empty column if file not found
            result_df[column_name] = None
            print(f"  {column_name}: file not found, added empty column")
    
    # Sort by property, then version
    result_df = result_df.sort_values(['property', 'version']).reset_index(drop=True)
    
    try:
        # Convert float columns to integers, keeping NaN as empty
        for col in result_df.columns[2:]:  # Skip property and version columns
            result_df[col] = result_df[col].astype('Int64')
			
        # Save merged file
        result_df.to_csv(output_path, index=False)
        print(f"\n✓ Merged file saved as: {output_path}")
        
        # Display summary statistics
        print(f"\nMerged dataset summary:")
        print(f"  Total rows: {len(result_df)}")
        print(f"  Total columns: {len(result_df.columns)}")
        print(f"  Unique properties: {result_df['property'].nunique()}")
        
        # Show coverage for each tool
        print(f"\nCoverage by tool:")
        for col in result_df.columns[2:]:  # Skip property and version columns
            coverage = result_df[col].notna().sum()
            percentage = (coverage / len(result_df)) * 100
            print(f"  {col}: {coverage}/{len(result_df)} ({percentage:.1f}%)")
        
        # Show first few rows as preview
        print(f"\nPreview of merged data:")
        print(result_df.head(10).to_string(index=False))
        
        return True
        
    except Exception as e:
        print(f"✗ Error saving merged file: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Merge property verification CSV files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Expected CSV files in the folder:
  - ground-truth.csv
  - certora.csv  
  - solcmc-z3.csv
  - solcmc-eld.csv
  - gpt-5.csv

Examples:
  python merge_tools_results.py --bank
  python merge_tools_results.py --contracts
        """
    )
    
    parser.add_argument(
        '--folder', '--bank', 
        dest='folder_name',
        required=True,
        help='Name of the folder containing CSV files'
    )
    
    parser.add_argument(
        '--output', '-o',
        default=None,
        help='Output filename (default: merged_{folder_name}.csv)'
    )
    
    parser.add_argument(
        '--base-path',
        default='../contracts',
        help='Base path where folders are located (default: ../contracts)'
    )
    
    args = parser.parse_args()
    
    # Construct folder path
    folder_path = os.path.join(args.base_path, args.folder_name)
    folder_path = os.path.abspath(folder_path)
    
    print(f"Property Verification CSV Merger")
    print(f"=" * 50)
    print(f"Looking for CSV files in: {folder_path}")
    
    # Check if folder exists
    if not os.path.exists(folder_path):
        print(f"✗ Error: Folder '{folder_path}' does not exist.")
        sys.exit(1)
    
    if not os.path.isdir(folder_path):
        print(f"✗ Error: '{folder_path}' is not a directory.")
        sys.exit(1)
    
    # Get specific CSV files
    expected_files = ['ground-truth.csv', 'certora.csv', 'solcmc-z3.csv', 'solcmc-eld.csv', 'gpt-5.csv']
    csv_files = []
    
    for filename in expected_files:
        file_path = os.path.join(folder_path, filename)
        if os.path.exists(file_path):
            csv_files.append(file_path)
        else:
            print(f"⚠ Warning: {filename} not found in {folder_path}")
    
    if not csv_files:
        print(f"✗ No expected CSV files found in {folder_path}")
        print(f"Expected files: {', '.join(expected_files)}")
        sys.exit(1)
    
    # Determine output filename
    if args.output:
        output_path = args.output
    else:
        output_path = f"merged_{args.folder_name}.csv"
    
    output_path = os.path.abspath(output_path)
    
    # Merge files
    success = merge_verification_results(csv_files, output_path)
    
    if success:
        print(f"\n🎉 Successfully merged verification results!")
        print(f"Output saved to: {output_path}")
        sys.exit(0)
    else:
        print(f"\n❌ Failed to merge CSV files.")
        sys.exit(1)


if __name__ == "__main__":
    main()
