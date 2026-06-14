#!/usr/bin/env python3

import subprocess
import polars as pl
from datetime import datetime
from io import StringIO
import sys

actual_stdout = sys.stdout
with open('/mnt/d/val/time/report.md', 'w') as f:
    sys.stdout = f

    def frame_to_markdown(df: pl.DataFrame) -> str:
        with pl.Config(
                tbl_formatting             = "ASCII_MARKDOWN",
                tbl_hide_column_data_types = True,
                tbl_hide_dataframe_shape   = True,
                tbl_rows                   = -1
            ):
            return str(df)

    try:
        result = subprocess.run(
            ["utt", "report", "--from", "2025-01-01", "--csv-section", "per-task"],
            capture_output=True,
            text=True,
            check=True
        )
        dfr = pl.read_csv(StringIO(result.stdout))
    except subprocess.CalledProcessError as e:
        print(f"Error: {e.stderr}")
        exit(1)

    def add_year_strs(df):
        return df.with_columns([
            pl.format(
                "{}",
                pl.col("Date").dt.year() % 100
            ).alias("year"),
            pl.format(
                "{}Q{}",
                pl.col("Date").dt.year() % 100,
                pl.col("Date").dt.quarter().cast(pl.Utf8).str.zfill(2),
            ).alias("year_quarter"),
            pl.format(
                "{}M{}",
                pl.col("Date").dt.year() % 100,
                pl.col("Date").dt.month().cast(pl.Utf8).str.zfill(2),
            ).alias("year_month"),
            pl.format(
                "{}W{}",
                pl.col("Date").dt.year() % 100,
                pl.col("Date").dt.week().cast(pl.Utf8).str.zfill(2),
            ).alias("year_week"),
        ])
    df = add_year_strs(dfr.sql('''
            SELECT 
                DATE(Date) AS Date, 
                Projects, 
                Duration, 
                Type,
            FROM self
        '''))

    dayly = add_year_strs(df.sql('''
            SELECT 
                Date,
                ROUND(SUM(Duration), 1) AS Hours,
                ROUND(SUM(Duration) - 7.9, 1) AS Diff
            FROM self
            WHERE
                Type = 'WORK'
            GROUP BY Date
            ORDER BY Date DESC
        '''))
    print('# Work Time\n')
    d = dayly.sql('SELECT Date, Hours, Diff FROM self')
    print(f'## Daily worktime\n\n{frame_to_markdown(d)}\n\n')
    def print_work_time_table(dayly, group, title):
        d = dayly.sql(f'''
                SELECT 
                    {group}, 
                    ROUND(SUM(Hours), 1), 
                    ROUND(SUM(Diff), 1) 
                FROM self 
                GROUP BY {group}
            ''')
        print(f'## {title} worktime\n\n{frame_to_markdown(d)}\n\n')
    print_work_time_table(dayly, "year", "Yearly")
    print_work_time_table(dayly, "year_quarter", "Quaterly")
    print_work_time_table(dayly, "year_month", "Monthly")
    print_work_time_table(dayly, "year_week", "Weekly")

    print("# By Project\n")
    def print_by_project(df, group, title): 
        print(f"## {title}\n")
        for idx in df[group].unique().sort():
            d = df.sql(f'''
                        SELECT 
                            Projects AS Project, 
                            ROUND(SUM(Duration), 1) AS Hours, 
                        FROM self
                        WHERE 
                            Type = 'WORK' AND 
                            Projects IS NOT NULL AND 
                            {group} = '{idx}'
                        GROUP BY Projects
                ''')
            print(f"### {idx}\n\n{frame_to_markdown(d)}\n\n")

    print_by_project(df, "year", "Yearly")
    print_by_project(df, "year_quarter", "Quaterly")
    print_by_project(df, "year_month", "Monthly")
    print_by_project(df, "year_week", "Weekly")

    print(f"# All data\n\n{frame_to_markdown(dfr)}\n\n")

try:
    result = subprocess.run(["pandoc", 
        "-f", "markdown", 
        "-t", "html", 
        "--toc", 
        "--standalone", "--embed-resources",
        "-o", "/mnt/d/val/time/report.html",
        "--metadata", "title=Time Sheet Jochen Illerhaus",
        "--metadata", f"date={datetime.now().strftime('%Y-%m-%d')}",
        "--template", "GitHub.html5",
        "--", "/mnt/d/val/time/report.md"
    ])
    # subprocess.run(["explorer.exe", "D:\\val\\time\\report.html"])
except subprocess.CalledProcessError as e:
    print(f"Error: {e.stderr}")
    exit(1)
