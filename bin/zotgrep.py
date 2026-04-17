#!/bin/sh 
'''exec' uv run --no-project --with tqdm python "$0" "$@" # ''' 

""" 
zotgrep: 
    Search Zotero PDFs with ripgrep using a multiprocessing-built text cache. 
    Multiprocessing is used to efficiently utilize all CPU cores while converting PDFs to text. 
"""

import argparse
import subprocess
import sys
from pathlib import Path
import multiprocessing as mp
import os

# ----------------------------
# Default paths
# ----------------------------
DEFAULT_ZOTERO_DIR = Path("/mnt/d/val/note/zotero/storage")
DEFAULT_CACHE_DIR = Path.home() / ".my-paper-cache"
DEFAULT_PDFTOTEXT = "pdftotext"
DEFAULT_PDFTOTEXT_OPTS = ["-layout"]
DEFAULT_RIPGREP = "rg"
DEFAULT_RIPGREP_ARGS = ["--color=always", "--heading", "--line-number"]

# ----------------------------
# Path mapping
# ----------------------------
def txt_path_for(pdf_path: Path, zotero_dir: Path, cache_dir: Path):
    """Mirror directory structure in the cache."""
    rel = pdf_path.relative_to(zotero_dir)
    return (cache_dir / rel).with_suffix(".txt")

# ----------------------------
# PDF discovery
# ----------------------------
def find_pdfs(zotero_dir: Path):
    return list(zotero_dir.rglob("*.pdf"))

# ----------------------------
# Conversion
# ----------------------------
def needs_update(pdf: Path, txt: Path):
    if not txt.exists():
        return True
    return pdf.stat().st_mtime > txt.stat().st_mtime

def convert_one(args):
    pdf, txt, pdftotext_path, pdftotext_opts = args
    txt.parent.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run(
            [str(pdftotext_path), *pdftotext_opts, str(pdf), str(txt)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False

def build_cache(pdfs, zotero_dir: Path, cache_dir: Path, jobs: int, pdftotext_path, pdftotext_opts):
    tasks = [
        (pdf, txt_path_for(pdf, zotero_dir, cache_dir), pdftotext_path, pdftotext_opts)
        for pdf in pdfs if needs_update(pdf, txt_path_for(pdf, zotero_dir, cache_dir))
    ]

    if not tasks:
        print("Cache is up to date.", file=sys.stderr)
        return

    print(f"Building cache for {len(tasks)} PDFs using {jobs} workers...")
    with mp.Pool(processes=jobs) as pool:
        list(pool.imap_unordered(convert_one, tasks), total=len(tasks))

# ----------------------------
# Ripgrep search
# ----------------------------
def run_ripgrep(cache_dir: Path, rg_args, rg_path):
    cmd = [rg_path, *DEFAULT_RIPGREP_ARGS, *rg_args]
    result = subprocess.run(cmd, cwd=str(cache_dir), stdout=sys.stdout, stderr=sys.stderr, text=True)
    return result.returncode

# ----------------------------
# Main CLI
# ----------------------------
def main():
    parser = argparse.ArgumentParser(
        description="Search Zotero PDFs using ripgrep with a multiprocessing-built text cache."
    )

    parser.add_argument("--zotero-dir", type=Path, default=DEFAULT_ZOTERO_DIR,
                        help="Path to Zotero storage directory")
    parser.add_argument("--cache-dir", type=Path, default=DEFAULT_CACHE_DIR,
                        help="Path to text cache directory")
    parser.add_argument("--jobs", "-j", type=int, default=mp.cpu_count(),
                        help="Number of parallel workers (default: CPU cores)")
    parser.add_argument("--rebuild", action="store_true", help="Force rebuild entire cache")
    parser.add_argument("--skip-cache", action="store_true", help="Skip cache rebuilding (assumes cache is up-to-date)")
    parser.add_argument("--pdftotext", type=str, default=DEFAULT_PDFTOTEXT,
                        help="Path to pdftotext executable")
    parser.add_argument("--pdftotext-opts", type=str, nargs="*", default=DEFAULT_PDFTOTEXT_OPTS,
                        help="Options passed to pdftotext")
    parser.add_argument("--ripgrep", type=str, default=DEFAULT_RIPGREP,
                        help="Path to ripgrep executable")
    parser.add_argument("rg_args", nargs=argparse.REMAINDER, help="Arguments passed to ripgrep")

    args = parser.parse_args()

    if args.rebuild and args.cache_dir.exists():
        print("Clearing cache...", file=sys.stderr)
        for f in args.cache_dir.rglob("*"):
            if f.is_file():
                f.unlink()

    if not args.skip_cache:
        pdfs = find_pdfs(args.zotero_dir)
        if not pdfs:
            print("No PDFs found.", file=sys.stderr)
            return 1
        build_cache(pdfs, args.zotero_dir, args.cache_dir, args.jobs,
                    args.pdftotext, args.pdftotext_opts)

    return run_ripgrep(args.cache_dir, args.rg_args, args.ripgrep)

if __name__ == "__main__":
    sys.exit(main())
