"""Chunk-aware runner that leverages keyword_filter search utilities."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Iterable

from keyword_filter import (
    PK_KEYWORDS,
    export_results_to_file,
    save_relevant_filenames,
    search_file_for_keywords,
)


def load_file_list(file_list_path: Path) -> list[Path]:
    lines: list[Path] = []
    with file_list_path.open("r", encoding="utf-8") as handle:
        for raw in handle:
            candidate = raw.strip()
            if not candidate:
                continue
            lines.append(Path(candidate))
    return lines


def run_keyword_search(file_list: Path, output_dir: Path, case_sensitive: bool) -> dict[str, dict[str, list[str]]]:
    output_dir.mkdir(parents=True, exist_ok=True)
    results: dict[str, dict[str, list[str]]] = {}
    missing_files: list[str] = []
    candidates = load_file_list(file_list)

    for candidate in candidates:
        if not candidate.is_file():
            missing_files.append(str(candidate))
            continue
        found = search_file_for_keywords(candidate, PK_KEYWORDS, case_sensitive)
        if any(found[category] for category in found):
            results[str(candidate)] = found

    json_path = output_dir / "results.json"
    json_path.write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8")

    summary_path = output_dir / "keyword_summary.txt"
    export_results_to_file(results, str(summary_path)) if results else summary_path.write_text(
        "No files contained the target keywords.\n", encoding="utf-8"
    )

    filenames_path = output_dir / "filtered_files.txt"
    if results:
        save_relevant_filenames(results, str(filenames_path))
    else:
        filenames_path.write_text("", encoding="utf-8")

    if missing_files:
        (output_dir / "missing_files.txt").write_text("\n".join(missing_files) + "\n", encoding="utf-8")

    stats_path = output_dir / "stats.txt"
    processed_count = len(candidates) - len(missing_files)
    stats_path.write_text(
        "Total listed files: {total}\nProcessed: {processed}\nMatches: {matches}\nMissing: {missing}\n".format(
            total=len(candidates),
            processed=processed_count,
            matches=len(results),
            missing=len(missing_files),
        ),
        encoding="utf-8",
    )

    return results


def parse_args(argv: Iterable[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run keyword filtering for a subset of files.")
    parser.add_argument("--file-list", required=True, help="Path to the chunk file containing absolute paths.")
    parser.add_argument("--output-dir", required=True, help="Directory to write results into.")
    parser.add_argument(
        "--case-sensitive",
        default="false",
        help="Whether to treat keyword matching as case sensitive (true/false).",
    )
    return parser.parse_args(argv)


def main(argv: Iterable[str] | None = None) -> None:
    args = parse_args(argv)
    case_sensitive = str(args.case_sensitive).strip().lower() in {"1", "true", "yes", "on"}
    file_list = Path(args.file_list).expanduser().resolve()
    output_dir = Path(args.output_dir).expanduser().resolve()
    run_keyword_search(file_list, output_dir, case_sensitive)


if __name__ == "__main__":
    main()
