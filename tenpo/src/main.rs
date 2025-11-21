#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! chrono = "0.4"
//! polars = { version = "0.52", features = ["lazy", "temporal", "csv"] }
//! polars-sql = "0.52"
//! ```

use chrono::{Datelike, Local, NaiveDate, NaiveDateTime, Weekday};
use polars::prelude::*;
use polars_sql::SQLContext;
use std::{
    env,
    ffi::OsStr,
    fs::{self, File, OpenOptions},
    io::{BufRead, BufReader, BufWriter, Write},
    path::{Path, PathBuf},
    process::{Command, ExitCode},
};

#[cfg(target_os = "windows")]
const DEFAULT_DIR: &str = "D:/val/time";
#[cfg(not(target_os = "windows"))]
const DEFAULT_DIR: &str = "/mnt/d/val/time";

#[cfg(target_os = "windows")]
const LOG_PATH: &str = "D:/val/time/utt.uttlog";
#[cfg(not(target_os = "windows"))]
const LOG_PATH: &str = "/mnt/d/val/time/utt.uttlog";

#[derive(Debug)]
struct Entry {
    time: NaiveDateTime,
    project: String,
    description: String,
    stars: usize,
    is_day_start: bool,
}

#[derive(Debug)]
struct Row {
    start: NaiveDateTime,
    end: NaiveDateTime,
    minutes: i64,
    project: String,
    stars: i64,
    description: String,
    date: NaiveDate,
}

fn usage() -> &'static str {
    "Usage:
  tenpo.rs report [<path>] [--sql <query>] [--out <file>] [--format <csv|parquet|ipc|feather>]
  tenpo.rs edit
  tenpo.rs add project: description
  tenpo.rs help
Notes:
  Scans only .utt/.uttlog files in /mnt/d/val/time; 'utt.utt'/'utt.uttlog' are placed last.
  Lines must be:
  blank (ignored), or
  YYYY-MM-DD HH:MM [hello]               => start-of-day marker, or
  YYYY-MM-DD HH:MM project: description  => normal entry
  Any other format is an error.
  Output columns: start, end, minutes, hours, project, stars, description, date, year, month, day, dow, week.
Example SQL
  Just worktime between dates:
    tenpo report --sql \"SELECT * FROM t WHERE stars = 0 AND date >= '2025-01-01' AND date < '2025-12-15'\"
  Hours per project between dates
    tenpo.rs report --sql \"SELECT project, ROUND(SUM(hours),2) AS hours FROM t WHERE stars = 0 AND date >= '2025-01-01' AND date < '2025-12-15' GROUP BY project ORDER BY hours DESC\"
  Total Hours of worktimebetween dates
    ./tenpo.rs report --sql \"SELECT ROUND(SUM(hours),2) AS hours FROM t WHERE stars = 0 AND date >= '2025-01-01' AND date < '2025-12-15'\"
"
}

// ---------- Parsing ----------

fn parse_line_strict(line: &str) -> Result<Option<Entry>, String> {
    let line = line.trim();
    if line.is_empty() {
        return Ok(None);
    }
    let mut parts = line.split_whitespace();
    let date = parts.next().ok_or("missing date")?;
    let hm = parts.next().ok_or("missing time")?;
    let ts = format!("{date} {hm}");
    let time = NaiveDateTime::parse_from_str(&ts, "%Y-%m-%d %H:%M")
        .map_err(|_| format!("invalid timestamp '{}'", ts))?;
    let rest = parts.collect::<Vec<_>>().join(" ");
    if rest.is_empty() || rest.eq_ignore_ascii_case("hello") {
        return Ok(Some(Entry {
            time,
            project: String::new(),
            description: String::new(),
            stars: 0,
            is_day_start: true,
        }));
    }
    let (project, description) = rest
        .split_once(':')
        .map(|(p, d)| (p.trim().to_string(), d.trim().to_string()))
        .ok_or("entry must be 'project: description'")?;
    if project.is_empty() {
        return Err("project is empty".into());
    }
    let stars = description.matches('*').count();
    Ok(Some(Entry {
        time,
        project,
        description,
        stars,
        is_day_start: false,
    }))
}

// ---------- Files ----------

fn is_utt_like(p: &Path) -> bool {
    matches!(
        p.extension().and_then(OsStr::to_str).map(|s| s.to_ascii_lowercase()),
        Some(ref e) if e == "utt" || e == "uttlog"
    )
}
fn is_special_last(p: &Path) -> bool {
    matches!(
        p.file_name().and_then(OsStr::to_str),
        Some("utt.utt" | "utt.uttlog")
    )
}

fn collect_input_files(user_path: Option<PathBuf>) -> Vec<PathBuf> {
    let path = user_path.unwrap_or_else(|| PathBuf::from(DEFAULT_DIR));
    if path.is_file() {
        return vec![path];
    }
    let mut files: Vec<_> = fs::read_dir(&path)
        .unwrap_or_else(|e| panic!("Cannot read {}: {e}", path.display()))
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().map(|ft| ft.is_file()).unwrap_or(false))
        .map(|e| e.path())
        .filter(|p| is_utt_like(p))
        .collect();
    files.sort();
    let mut normal = Vec::new();
    let mut special = Vec::new();
    for p in files {
        if is_special_last(&p) {
            special.push(p);
        } else {
            normal.push(p);
        }
    }
    normal.extend(special);
    normal
}

fn load_entries_from_files(paths: &[PathBuf]) -> Vec<Entry> {
    let mut entries = Vec::new();
    for p in paths {
        let file = File::open(p).unwrap_or_else(|e| panic!("Cannot open {}: {e}", p.display()));
        let reader = BufReader::new(file);
        for (i, line) in reader.lines().enumerate() {
            let ln = i + 1;
            let line = line.unwrap_or_else(|e| {
                eprintln!("Error reading {}:{}: {}", p.display(), ln, e);
                std::process::exit(1);
            });
            match parse_line_strict(&line) {
                Ok(Some(e)) => entries.push(e),
                Ok(None) => {}
                Err(msg) => {
                    eprintln!("Error in {}:{}: {}", p.display(), ln, msg);
                    std::process::exit(1);
                }
            }
        }
    }
    entries.sort_by_key(|e| e.time);
    for i in 1..entries.len() {
        if entries[i].time < entries[i - 1].time {
            eprintln!(
                "Error: timestamps must be non-decreasing:\n {} < {}",
                entries[i].time,
                entries[i - 1].time
            );
            std::process::exit(1);
        }
    }
    entries
}

// ---------- To intervals + DataFrame ----------

fn build_rows(entries: &[Entry]) -> Vec<Row> {
    let mut rows = Vec::new();
    let mut last_end: Option<NaiveDateTime> = None;
    let mut last_date: Option<NaiveDate> = None;
    for e in entries {
        if e.is_day_start {
            last_end = Some(e.time);
            last_date = Some(e.time.date());
            continue;
        }
        if last_end.is_none() {
            last_end = Some(e.time);
            last_date = Some(e.time.date());
            continue;
        }
        let start = last_end.unwrap();
        let end = e.time;
        let date = last_date.unwrap_or_else(|| start.date());
        rows.push(Row {
            start,
            end,
            minutes: (end - start).num_minutes(),
            project: e.project.clone(),
            stars: e.stars as i64,
            description: e.description.clone(),
            date,
        });
        last_end = Some(end);
    }
    rows
}

fn rows_to_dataframe(rows: &[Row]) -> PolarsResult<DataFrame> {
    let mut df = df![
        "start" => rows.iter().map(|r| r.start.format("%Y-%m-%d %H:%M").to_string()).collect::<Vec<_>>(),
        "end" => rows.iter().map(|r| r.end.format("%Y-%m-%d %H:%M").to_string()).collect::<Vec<_>>(),
        "minutes" => rows.iter().map(|r| r.minutes).collect::<Vec<_>>(),
        "project" => rows.iter().map(|r| r.project.clone()).collect::<Vec<_>>(),
        "stars" => rows.iter().map(|r| r.stars).collect::<Vec<_>>(),
        "description" => rows.iter().map(|r| r.description.clone()).collect::<Vec<_>>(),
        "date" => rows.iter().map(|r| r.date.format("%Y-%m-%d").to_string()).collect::<Vec<_>>()
    ]?;
    // Derived columns after building df
    let hours: Vec<f64> = rows.iter().map(|r| r.minutes as f64 / 60.0).collect();
    let years: Vec<i32> = rows.iter().map(|r| r.date.year()).collect();
    let months: Vec<u32> = rows.iter().map(|r| r.date.month()).collect();
    let days: Vec<u32> = rows.iter().map(|r| r.date.day()).collect();
    let dows: Vec<u32> = rows
        .iter()
        .map(|r| match r.date.weekday() {
            Weekday::Mon => 1,
            Weekday::Tue => 2,
            Weekday::Wed => 3,
            Weekday::Thu => 4,
            Weekday::Fri => 5,
            Weekday::Sat => 6,
            Weekday::Sun => 7,
        })
        .collect();
    let weeks: Vec<u32> = rows
        .iter()
        .map(|r| r.date.iso_week().week() as u32)
        .collect();

    df.with_column(Series::new("hours".into(), hours))?;
    df.with_column(Series::new("year".into(), years))?;
    df.with_column(Series::new("month".into(), months))?;
    df.with_column(Series::new("day".into(), days))?;
    df.with_column(Series::new("dow".into(), dows))?;
    df.with_column(Series::new("week".into(), weeks))?;

    Ok(df)
}

// ---------- SQL and output ----------

fn maybe_apply_sql(df: DataFrame, sql: Option<String>) -> PolarsResult<DataFrame> {
    if let Some(query) = sql {
        let mut ctx = SQLContext::new();
        ctx.register("t", df.lazy());
        ctx.execute(&query)
            .map_err(|e| PolarsError::ComputeError(format!("SQL error: {e}").into()))?
            .collect()
    } else {
        Ok(df)
    }
}

enum OutFmt {
    Csv,
    Parquet,
    Ipc,
}

fn infer_format_from_path(path: &Path) -> Option<OutFmt> {
    match path
        .extension()
        .and_then(OsStr::to_str)
        .map(|s| s.to_ascii_lowercase())
    {
        Some(ref e) if e == "csv" => Some(OutFmt::Csv),
        Some(ref e) if e == "parquet" || e == "parq" => Some(OutFmt::Parquet),
        Some(ref e) if e == "ipc" || e == "feather" => Some(OutFmt::Ipc),
        _ => None,
    }
}
fn parse_format_flag(s: &str) -> Option<OutFmt> {
    match s.to_ascii_lowercase().as_str() {
        "csv" => Some(OutFmt::Csv),
        "parquet" => Some(OutFmt::Parquet),
        "ipc" | "feather" => Some(OutFmt::Ipc),
        _ => None,
    }
}

fn write_df(df: &DataFrame, out_path: &Path, fmt: OutFmt) -> Result<(), String> {
    match fmt {
        OutFmt::Csv => {
            let f = File::create(out_path)
                .map_err(|e| format!("create {}: {e}", out_path.display()))?;
            let mut w = CsvWriter::new(BufWriter::new(f)).include_header(true);
            let mut tmp = df.clone();
            w.finish(&mut tmp).map_err(|e| format!("write CSV: {e}"))?;
        }
        OutFmt::Parquet => {
            eprintln!("Parquet file writing removed to keep binary size small no output is written")
            // let f = File::create(out_path)
            //     .map_err(|e| format!("create {}: {e}", out_path.display()))?;
            // let w = ParquetWriter::new(BufWriter::new(f));
            // let mut tmp = df.clone();
            // w.finish(&mut tmp).map_err(|e| format!("write Parquet: {e}"))?;
        }
        OutFmt::Ipc => {
            eprintln!("Ipc file writing removed to keep binary size small not output is written")
            // let f = File::create(out_path)
            //     .map_err(|e| format!("create {}: {e}", out_path.display()))?;
            // let mut w = IpcWriter::new(BufWriter::new(f));
            // let mut tmp = df.clone();
            // w.finish(&mut tmp).map_err(|e| format!("write IPC: {e}"))?;
        }
    }
    Ok(())
}

fn print_df_as_csv(df: &DataFrame) -> Result<(), String> {
    let mut buf = Vec::new();
    let mut w = CsvWriter::new(&mut buf).include_header(true);
    let mut tmp = df.clone();
    w.finish(&mut tmp)
        .map_err(|e| format!("write CSV to stdout: {e}"))?;
    let mut stdout = std::io::stdout().lock();
    stdout
        .write_all(&buf)
        .and_then(|_| stdout.flush())
        .map_err(|e| format!("stdout write: {e}"))
}

// ---------- Subcommands ----------

fn cmd_report(args: &[String]) -> ExitCode {
    // flags: [<path>] [--sql ...] [--out ...] [--format ...]
    let mut path_arg: Option<PathBuf> = None;
    let mut sql_query: Option<String> = None;
    let mut out_path: Option<PathBuf> = None;
    let mut out_fmt_flag: Option<OutFmt> = None;
    let mut i = 0;
    while i < args.len() {
        match args[i].as_str() {
            "--sql" | "-q" => {
                i += 1;
                if i >= args.len() {
                    eprintln!("--sql requires a query");
                    return ExitCode::from(2);
                }
                sql_query = Some(args[i].clone());
            }
            "--out" | "-o" => {
                i += 1;
                if i >= args.len() {
                    eprintln!("--out requires a file");
                    return ExitCode::from(2);
                }
                out_path = Some(PathBuf::from(&args[i]));
            }
            "--format" | "-f" => {
                i += 1;
                if i >= args.len() {
                    eprintln!("--format requires csv|parquet|ipc|feather");
                    return ExitCode::from(2);
                }
                out_fmt_flag = parse_format_flag(&args[i]);
                if out_fmt_flag.is_none() {
                    eprintln!("Unknown --format '{}'", args[i]);
                    return ExitCode::from(2);
                }
            }
            s if s.starts_with('-') => {
                eprintln!("Unknown option '{}'\n\n{}", s, usage());
                return ExitCode::from(2);
            }
            s => {
                if path_arg.is_none() {
                    path_arg = Some(PathBuf::from(s));
                } else {
                    eprintln!("Unexpected extra positional arg '{}'\n\n{}", s, usage());
                    return ExitCode::from(2);
                }
            }
        }
        i += 1;
    }

    let files = collect_input_files(path_arg);
    if files.is_empty() {
        eprintln!("No .utt/.uttlog files found.");
        return ExitCode::from(1);
    }

    let rows = build_rows(&load_entries_from_files(&files));
    let mut df = match rows_to_dataframe(&rows) {
        Ok(df) => df,
        Err(e) => {
            eprintln!("DataFrame error: {e}");
            return ExitCode::from(1);
        }
    };
    df = match maybe_apply_sql(df, sql_query) {
        Ok(df) => df,
        Err(e) => {
            eprintln!("{e}");
            return ExitCode::from(1);
        }
    };

    if let Some(p) = out_path {
        let fmt = out_fmt_flag.or_else(|| infer_format_from_path(&p));
        let Some(fmt) = fmt else {
            eprintln!(
                "Cannot infer output format from '{}'. Use --format csv|parquet|ipc|feather, or a known extension like .csv/.parquet/.ipc/.feather",
                p.display()
            );
            return std::process::ExitCode::from(2);
        };
        if let Err(e) = write_df(&df, &p, fmt) {
            eprintln!("Output error: {e}");
            return std::process::ExitCode::from(1);
        }
    } else {
        if let Err(e) = print_df_as_csv(&df) {
            eprintln!("Output error: {e}");
            return std::process::ExitCode::from(1);
        }
    }

    ExitCode::SUCCESS
}

fn cmd_edit() -> ExitCode {
    let editor = env::var("EDITOR").unwrap_or_else(|_| {
        if cfg!(target_os = "windows") {
            "notepad".into()
        } else {
            "vi".into()
        }
    });
    let mut parts = editor.split_whitespace().map(|s| s.to_string());
    let prog = match parts.next() {
        Some(p) => p,
        None => {
            eprintln!("EDITOR is empty");
            return ExitCode::from(2);
        }
    };
    let mut args: Vec<String> = parts.collect();
    let is_vimlike = prog.ends_with("vim")
        || prog.ends_with("vim.exe")
        || prog.ends_with("nvim")
        || prog.ends_with("nvim.exe");
    if is_vimlike {
        args.push("+".into());
    }
    args.push(LOG_PATH.into());
    let status = Command::new(&prog).args(&args).status();
    match status {
        Ok(s) if s.success() => ExitCode::SUCCESS,
        Ok(s) => {
            eprintln!("Editor exited with status {}", s);
            ExitCode::from(1)
        }
        Err(e) => {
            eprintln!("Failed to run editor '{}': {}", prog, e);
            ExitCode::from(1)
        }
    }
}

fn cmd_appends(rest: &[String]) -> ExitCode {
    let line = if rest.is_empty() {
        // allow a bare timestamp line (day start)
        Local::now().format("%Y-%m-%d %H:%M").to_string()
    } else {
        format!(
            "{} {}",
            Local::now().format("%Y-%m-%d %H:%M"),
            rest.join(" ")
        )
    };
    let mut f = match OpenOptions::new().create(true).append(true).open(LOG_PATH) {
        Ok(f) => f,
        Err(e) => {
            eprintln!("Cannot open {}: {}", LOG_PATH, e);
            return ExitCode::from(1);
        }
    };
    if let Err(e) = writeln!(f, "{}", line) {
        eprintln!("Write error: {}", e);
        return ExitCode::from(1);
    }
    ExitCode::SUCCESS
}

// ---------- Main ----------
fn main() -> std::process::ExitCode {
    let mut args: Vec<String> = std::env::args().skip(1).collect();
    match args.get(0).map(|s| s.as_str()) {
        Some("edit") | Some("e") => {
            // no need to keep/remove args for edit
            cmd_edit()
        }
        Some("add") | Some("a") => {
            args.remove(0); // safe: we know there's at least one elem
            cmd_appends(&args)
        }
        Some("report") | Some("r") => {
            args.remove(0); // safe here too
            cmd_report(&args)
        }
        _ => {
            // Some("help") | Some("--help") | Some("-h") not needed anything is usage
            print!("{}", usage());
            std::process::ExitCode::SUCCESS
        }
    }
}
