# 📊 Data Directory

## Overview
This directory contains all datasets used in the GlobalRetail Inc. sales analysis project.

## Data Structure

### Raw Data (`raw/`)
- **globalretail_transactions.csv**: Original sales transaction data (536,350 records)
- **Data Fields**:
  - TransactionNo: Unique transaction identifier
  - Date: Transaction date
  - ProductNo: Product identifier
  - ProductName: Product description
  - Price: Unit price
  - Quantity: Quantity sold (negative for returns)
  - CustomerNo: Customer identifier
  - Country: Transaction country

### Processed Data (`processed/`)
- **sales_transactions_clean.csv**: Cleaned and validated transaction data

## Data Quality Notes
- Original dataset: 536,350 transactions
- Date range: December 2018 - December 2019
- 8 core data fields analyzed
- Return transactions identified by negative quantities

## Data Privacy & Ethics
- All customer data has been anonymized
- No personally identifiable information (PII) included
- Data used for educational and analytical purposes only
- Complies with data protection best practices

## Usage Instructions
1. Raw data files are located in the `raw/` subdirectory
2. Processed and cleaned data available in `processed/` subdirectory
3. Refer to PostgreSQL schema files for data structure details
4. Use these datasets with the provided SQL queries for analysis reproduction
