"""
DuckDB Python Integration Example
This script demonstrates how to connect to DuckDB from Python/Jupyter
"""

import duckdb


def connect_to_duckdb():
    """Connect to DuckDB HTTP server"""
    try:
        # Connect to DuckDB HTTP server
        conn = duckdb.connect("http://localhost:8081")
        print("✅ Successfully connected to DuckDB")
        return conn
    except Exception as e:
        print(f"❌ Failed to connect to DuckDB: {e}")
        return None


def test_connection(conn):
    """Test the DuckDB connection"""
    try:
        # Test basic query
        result = conn.execute("SELECT health_check()").fetchone()
        print(f"Health check: {result[0]}")

        # Test Unity Catalog connection
        result = conn.execute("SELECT * FROM unity_catalog_test").fetchone()
        print(f"Unity Catalog: {result[0]}")

        return True
    except Exception as e:
        print(f"❌ Connection test failed: {e}")
        return False


def query_hubspot_data(conn):
    """Query HubSpot communications data"""
    try:
        # Query raw JSON data from Azure Storage
        query = """
        SELECT 
            id,
            properties['hs_engagement_type'] as engagement_type,
            properties['hs_createdate'] as created_date,
            properties['hs_body_preview'] as body_preview,
            properties['hubspot_owner_id'] as owner_id
        FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/140000.json')
        LIMIT 10
        """

        df = conn.execute(query).df()
        print("📊 HubSpot Communications Data:")
        print(df.head())
        return df

    except Exception as e:
        print(f"❌ Failed to query HubSpot data: {e}")
        return None


def analyze_communications(conn):
    """Analyze communications by type"""
    try:
        query = """
        SELECT 
            properties['hs_engagement_type'] as engagement_type,
            COUNT(*) as count,
            MIN(properties['hs_createdate']) as earliest_date,
            MAX(properties['hs_createdate']) as latest_date
        FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/*.json')
        WHERE properties['hs_engagement_type'] IS NOT NULL
        GROUP BY properties['hs_engagement_type']
        ORDER BY count DESC
        """

        df = conn.execute(query).df()
        print("📈 Communications Analysis:")
        print(df)
        return df

    except Exception as e:
        print(f"❌ Failed to analyze communications: {e}")
        return None


def create_views(conn):
    """Create useful views for analysis"""
    try:
        # Create a view for communications
        view_query = """
        CREATE OR REPLACE VIEW hubspot_communications_view AS
        SELECT 
            id,
            properties['hs_engagement_type'] as engagement_type,
            properties['hs_createdate'] as created_date,
            properties['hs_lastmodifieddate'] as modified_date,
            properties['hs_body_preview'] as body_preview,
            properties['hubspot_owner_id'] as owner_id,
            properties['hs_meeting_start_time'] as meeting_start,
            properties['hs_meeting_end_time'] as meeting_end,
            properties['hs_meeting_outcome'] as meeting_outcome,
            archived,
            _filename
        FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/*/*.json')
        """

        conn.execute(view_query)
        print("✅ Created hubspot_communications_view")

        # Test the view
        df = conn.execute(
            "SELECT engagement_type, COUNT(*) as count FROM hubspot_communications_view GROUP BY engagement_type"
        ).df()
        print("📊 View test results:")
        print(df)

    except Exception as e:
        print(f"❌ Failed to create views: {e}")


def export_data(conn, format="parquet"):
    """Export query results"""
    try:
        query = """
        SELECT 
            id,
            properties['hs_engagement_type'] as engagement_type,
            properties['hs_createdate'] as created_date,
            properties['hs_body_preview'] as body_preview
        FROM read_json_auto('https://strprimrosedatalake.blob.core.windows.net/raw/hubspot/communications/20250531/*.json')
        WHERE properties['hs_engagement_type'] IS NOT NULL
        """

        if format == "parquet":
            conn.execute(
                f"COPY ({query}) TO 'communications_export.parquet' (FORMAT PARQUET)"
            )
        elif format == "csv":
            conn.execute(
                f"COPY ({query}) TO 'communications_export.csv' (FORMAT CSV, HEADER)"
            )

        print(f"✅ Exported data to communications_export.{format}")

    except Exception as e:
        print(f"❌ Failed to export data: {e}")


def main():
    """Main function to demonstrate DuckDB usage"""
    print("🦆 DuckDB Python Integration Demo")
    print("=" * 40)

    # Connect to DuckDB
    conn = connect_to_duckdb()
    if not conn:
        return

    # Test connection
    if not test_connection(conn):
        return

    print("\n" + "=" * 40)

    # Query HubSpot data
    df = query_hubspot_data(conn)

    print("\n" + "=" * 40)

    # Analyze communications
    analysis_df = analyze_communications(conn)

    print("\n" + "=" * 40)

    # Create views
    create_views(conn)

    print("\n" + "=" * 40)

    # Export data
    export_data(conn, "parquet")

    # Close connection
    conn.close()
    print("\n✅ Demo completed successfully!")


if __name__ == "__main__":
    main()
