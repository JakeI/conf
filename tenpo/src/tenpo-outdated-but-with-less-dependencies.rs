#!/usr/bin/env rust-script
// cargo-deps: chrono="0.4"

use chrono::NaiveDateTime;
use std::{
    env,
    fs::{self, File},
    io::{BufRead, BufReader},
    path::PathBuf,
};

#[derive(Debug)]
struct Entry {
    time: NaiveDateTime,
    project: String,
    description: String,
    stars: usize,
    is_day_start: bool,
}

//
// ---------------- Parsing utilities ----------------
//

fn parse_line(line: &str) -> Option<Entry> {
    let mut parts = line.split_whitespace();
    let date = parts.next()?;
    let hm = parts.next()?;
    let timestamp_str = format!("{} {}", date, hm);

    let time = NaiveDateTime::parse_from_str(&timestamp_str, "%Y-%m-%d %H:%M").ok()?;

    let rest: String = parts.collect::<Vec<_>>().join(" ");

    // Hello (or empty rest) → day start
    if rest.is_empty() || rest == "hello" {
        return Some(Entry {
            time,
            project: "".into(),
            description: "".into(),
            stars: 0,
            is_day_start: true,
        });
    }

    // Split into project:description
    let (project_raw, description) = match rest.split_once(':') {
        Some((p, d)) => (p.trim().to_string(), d.trim().to_string()),
        None => {
            eprintln!(
                "Warning: missing colon, treating as new day start: {}",
                line
            );
            return Some(Entry {
                time,
                project: "".into(),
                description: "".into(),
                stars: 0,
                is_day_start: true,
            });
        }
    };

    if project_raw.contains(char::is_whitespace) {
        eprintln!("Warning: project contains whitespace → '{}'", project_raw);
    }

    let stars = description.matches('*').count();

    Some(Entry {
        time,
        project: project_raw,
        description,
        stars,
        is_day_start: false,
    })
}

//
// ---------------- File aggregation ----------------
//

fn collect_input_files(user_arg: Option<String>) -> Vec<PathBuf> {
    if let Some(path) = user_arg {
        return vec![PathBuf::from(path)];
    }

    #[cfg(target_os = "windows")]
    let default_dir = PathBuf::from("D:/val/time");

    #[cfg(not(target_os = "windows"))]
    let default_dir = PathBuf::from("/mnt/d/val/time");

    let mut files: Vec<_> = fs::read_dir(&default_dir)
        .expect("Cannot read default time directory")
        .filter_map(|e| e.ok())
        .filter(|e| e.file_type().map(|ft| ft.is_file()).unwrap_or(false))
        .map(|e| e.path())
        .collect();

    files.sort();
    files
}

fn load_entries_from_files(paths: &[PathBuf]) -> Vec<Entry> {
    let mut entries = Vec::new();

    for p in paths {
        let file = File::open(p).expect("Cannot open input file");
        let reader = BufReader::new(file);

        for line in reader.lines().flatten() {
            if let Some(e) = parse_line(&line) {
                entries.push(e);
            }
        }
    }

    // Sort and validate order
    entries.sort_by_key(|e| e.time);

    for i in 1..entries.len() {
        if entries[i].time < entries[i - 1].time {
            eprintln!(
                "Error: timestamps must not decrease:\n {} < {}",
                entries[i].time,
                entries[i - 1].time
            );
            std::process::exit(1);
        }
    }

    // Hard requirement: file must begin with a hello/daystart
    if !entries.first().map(|e| e.is_day_start).unwrap_or(false) {
        eprintln!("Error: first entry must be a 'hello' (day start)");
        std::process::exit(1);
    }

    entries
}

//
// ---------------- Report generator ----------------
//

fn report(entries: &[Entry]) {
    println!("start,end,duration_hours,project,stars,description");

    let mut last_end_time: Option<NaiveDateTime> = None;

    for e in entries {
        if e.is_day_start {
            last_end_time = Some(e.time);
            continue;
        }

        let start = match last_end_time {
            Some(t) => t,
            None => {
                // Should never happen now that first entry must be hello
                continue;
            }
        };

        let duration = e.time - start;
        let minutes = duration.num_minutes();
        let hours = minutes as f64 / 60.0;

        println!(
            "{},{},{:.4},{},{},\"{}\"",
            start.format("%Y-%m-%d %H:%M"),
            e.time.format("%Y-%m-%d %H:%M"),
            hours,
            e.project,
            e.stars,
            e.description.replace('"', "\"\"")
        );

        last_end_time = Some(e.time);
    }
}

//
// ---------------- Main dispatcher ----------------
//

fn main() {
    let mut args = env::args().skip(1);

    let subcommand = args.next().unwrap_or_else(|| "report".to_string());
    let path_arg = args.next();

    match subcommand.as_str() {
        "report" => {
            let files = collect_input_files(path_arg);
            let entries = load_entries_from_files(&files);
            report(&entries);
        }
        other => {
            eprintln!("Unknown subcommand '{}'", other);
        }
    }
}
