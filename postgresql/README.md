# 🗄️ PostgreSQL Database Analysis

## Overview
Contains all PostgreSQL database schemas, queries, and ETL processes used for comprehensive data analysis of GlobalRetail Inc.'s sales transactions.

## Database Structure

### Schema Definition (`schema/`)
- **create_tables.sql**: Complete database schema definition
- **indexes.sql**: Performance optimization indexes
- **constraints.sql**: Data integrity constraints
- **views.sql**: Business intelligence views

### ETL Processes (`etl_scripts/`)
- **01_data_import.sql**: Raw data ingestion procedures
- **02_data_cleaning.sql**: Data quality and cleansing operations
- **03_data_transformation.sql**: Business logic transformations
- **04_aggregations.sql**: Pre-calculated metrics and KPIs

### Analytical Queries (`queries/`)

#### Business Intelligence (`queries/business_analysis/`)
- `revenue_analysis.sql`: Revenue and profitability calculations
- `customer_segmentation.sql`: RFM analysis and customer grouping
- `product_performance.sql`: Product metrics and rankings
- `geographic_insights.sql`: Country and regional analysis
- `temporal_patterns.sql`: Time-series and seasonal analysis

#### Advanced Analytics (`queries/advanced/`)
- `cohort_analysis.sql`: Customer lifetime value analysis
- `anomaly_detection.sql`: Unusual transaction pattern identification
- `trend_analysis.sql`: Growth trends and forecasting
- `correlation_analysis.sql`: Product and customer relationship analysis

#### Data Quality (`queries/data_quality/`)
- `data_profiling.sql`: Comprehensive data exploration
- `validation_checks.sql`: Data integrity verification
- `duplicate_detection.sql`: Duplicate record identification

## Key PostgreSQL Features Utilized

### Window Functions
- ROW_NUMBER(), RANK(), DENSE_RANK() for customer and product rankings
- LAG(), LEAD() for time-series analysis
- Running totals and cumulative calculations

### Advanced Aggregations
- CUBE and ROLLUP for multi-dimensional analysis
- Percentile calculations for customer segmentation
- Complex GROUP BY operations with multiple dimensions

### Common Table Expressions (CTEs)
- Recursive CTEs for hierarchical data analysis
- Multiple CTEs for complex analytical workflows
- Performance-optimized query structures

### Custom Functions
- Business logic encapsulation
- Reusable analytical components
- Data validation functions

## Performance Considerations
- Strategic indexing on frequently queried columns
- Query optimization for large dataset analysis
- Partitioning strategies for time-based data
- Connection pooling for dashboard connectivity

## Database Statistics
- **Total Records Processed**: 536,350 transactions
- **Query Execution Time**: Optimized for sub-second responses
- **Storage Optimization**: Efficient data types and compression
- **Concurrent Users**: Designed for multi-user analytics access

## Getting Started
1. Install PostgreSQL 12+ and PgAdmin 4
2. Execute schema creation scripts from `schema/` folder
3. Run ETL processes in order from `etl_scripts/`
4. Use analytical queries from `queries/` for business insights
5. Connect Power BI to PostgreSQL for real-time dashboards
