"""Utilities to pull selected files from a remote host via compression."""

from __future__ import annotations

import argparse
import os
import posixpath
import shlex
import shutil
import subprocess
import tempfile
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


def _read_file_list(file_list_path: str) -> list[str]:
	with open(file_list_path, encoding="utf-8") as handle:
		return [line.strip() for line in handle if line.strip() and not line.lstrip().startswith("#")]


def _run(cmd: list[str], *, capture_output: bool = False) -> subprocess.CompletedProcess:
	printable = " ".join(shlex.quote(part) for part in cmd)
	print(f"Running: {printable}")
	return subprocess.run(cmd, check=True, capture_output=capture_output)


def _ssh_cmd(hostname: str, username: str, key: str, remote_command: str) -> list[str]:
	return [
		"ssh",
		"-i",
		key,
		f"{username}@{hostname}",
		remote_command,
	]


def _scp_pull_cmd(hostname: str, username: str, key: str, remote_path: str, local_path: str) -> list[str]:
	return [
		"scp",
		"-i",
		key,
		f"{username}@{hostname}:{remote_path}",
		local_path,
	]


@dataclass
class TransferLayout:
	hostname: str
	username: str
	key_filename: str
	archive_name: str
	remote_archive_dir: str
	remote_archive_path: str
	local_output_dir: Path
	local_archive_path: Path
	payload_dir: Path
	keep_local_archive: bool


def compress_pull_extract(
	*,
	hostname: str,
	username: str,
	key_filename: str,
	file_list_path: str,
	local_output_dir: str,
	archive_basename: str | None = None,
	keep_local_archive: bool = False,
	remote_archive_dir: str | None = None,
) -> Path:
	file_names = _read_file_list(file_list_path)
	if not file_names:
		raise ValueError("No files found in manifest; nothing to transfer.")

	layout = _build_layout(
		hostname=hostname,
		username=username,
		key_filename=key_filename,
		local_output_dir=local_output_dir,
		archive_basename=archive_basename,
		keep_local_archive=keep_local_archive,
		remote_archive_dir=remote_archive_dir,
	)

	try:
		_create_remote_archive(layout, file_names)
		_fetch_archive(layout)
		_extract_flat(layout, file_names)
	finally:
		_cleanup(layout)

	return layout.local_output_dir


def _build_layout(
	*,
	hostname: str,
	username: str,
	key_filename: str,
	local_output_dir: str,
	archive_basename: str | None,
	keep_local_archive: bool,
	remote_archive_dir: str | None,
) -> TransferLayout:
	archive_name = archive_basename or f"pull_{uuid.uuid4().hex}.tar.gz"
	remote_dir = (remote_archive_dir or posixpath.join("/home", username, ".remote_transfer_archives")).rstrip("/")
	local_dir = Path(local_output_dir).expanduser().resolve()
	local_dir.mkdir(parents=True, exist_ok=True)
	payload_dir = local_dir
	return TransferLayout(
		hostname=hostname,
		username=username,
		key_filename=os.path.expanduser(key_filename),
		archive_name=archive_name,
		remote_archive_dir=remote_dir,
		remote_archive_path=f"{remote_dir}/{archive_name}",
		local_output_dir=local_dir,
		local_archive_path=local_dir / archive_name,
		payload_dir=payload_dir,
		keep_local_archive=keep_local_archive,
	)


def _create_remote_archive(layout: TransferLayout, file_names: list[str]) -> None:
	print("Creating remote archive...")
	remote_cmd = (
		f"set -euo pipefail; mkdir -p {shlex.quote(layout.remote_archive_dir)} && "
		f"tar -czf {shlex.quote(layout.remote_archive_path)} -T -"
	)
	ssh_cmd = _ssh_cmd(layout.hostname, layout.username, layout.key_filename, remote_cmd)
	with subprocess.Popen(ssh_cmd, stdin=subprocess.PIPE, text=True) as proc:
		assert proc.stdin is not None
		for path in file_names:
			proc.stdin.write(f"{path}\n")
		proc.stdin.close()
		returncode = proc.wait()
	if returncode != 0:
		raise subprocess.CalledProcessError(returncode, ssh_cmd)


def _fetch_archive(layout: TransferLayout) -> None:
	print("Downloading archive...")
	_run(
		_scp_pull_cmd(
			layout.hostname,
			layout.username,
			layout.key_filename,
			layout.remote_archive_path,
			str(layout.local_archive_path),
		)
	)


def _extract_flat(layout: TransferLayout, remote_paths: list[str]) -> None:
	print("Extracting locally (flattened)...")
	temp_dir = Path(tempfile.mkdtemp(prefix="transfer_extract_", dir=layout.local_output_dir))
	try:
		_run(["tar", "-xzf", str(layout.local_archive_path), "-C", str(temp_dir)])
		for original in remote_paths:
			source = temp_dir / original.lstrip("/")
			if not source.exists():
				print(f"Warning: expected file {original} missing in archive")
				continue
			dest = _next_destination(layout.payload_dir, _flattened_filename(original))
			dest.parent.mkdir(parents=True, exist_ok=True)
			shutil.move(str(source), dest)
	finally:
		shutil.rmtree(temp_dir, ignore_errors=True)


def _flattened_filename(remote_path: str) -> str:
	"""Turn /a/b/file.txt into a___b___file.txt so the full path stays visible."""
	cleaned = remote_path.strip().lstrip("/")
	if not cleaned:
		return "unnamed"
	return cleaned.replace("/", "___")


def _next_destination(target_dir: Path, filename: str) -> Path:
	base = Path(filename).name or "unnamed"
	dest = target_dir / base
	if not dest.exists():
		return dest
	stem = dest.stem
	suffix = dest.suffix
	idx = 1
	while True:
		candidate = target_dir / f"{stem}_{idx}{suffix}"
		if not candidate.exists():
			return candidate
		idx += 1


def _cleanup(layout: TransferLayout) -> None:
	print("Cleaning remote archive...")
	cleanup_cmd = f"rm -f {shlex.quote(layout.remote_archive_path)}"
	_run(_ssh_cmd(layout.hostname, layout.username, layout.key_filename, cleanup_cmd))
	if not layout.keep_local_archive and layout.local_archive_path.exists():
		print("Removing local archive...")
		layout.local_archive_path.unlink()


def build_parser() -> argparse.ArgumentParser:
	parser = argparse.ArgumentParser(
		description="Compress remote files listed in a YAML input, download them, and extract locally.",
	)
	parser.add_argument(
		"--input-yaml",
		required=True,
		help="Path to the YAML file describing the transfer (hostname, username, key, file_list, etc.)",
	)
	parser.add_argument(
		"--local-output",
		dest="local_output_dir",
		default="./downloaded_remote_files",
		help="Directory where the downloaded files will be extracted.",
	)
	return parser


def _parse_bool(value: str | bool | None) -> bool:
	if isinstance(value, bool):
		return value
	if value is None:
		return False
	return str(value).strip().lower() in {"1", "true", "yes", "on"}


def _load_transfer_config(input_yaml: str) -> dict[str, str | bool | None]:
	yaml_path = Path(input_yaml)
	if not yaml_path.exists():
		raise FileNotFoundError(f"YAML file not found: {input_yaml}")

	config: dict[str, str] = {}
	for raw_line in yaml_path.read_text(encoding="utf-8").splitlines():
		line = raw_line.split("#", 1)[0].strip()
		if not line:
			continue
		if ":" not in line:
			continue
		key, value = line.split(":", 1)
		key = key.strip()
		value = value.strip()
		if value and value[0] in {"'", '"'} and value[-1] == value[0]:
			value = value[1:-1]
		config[key] = value

	required_keys = ["hostname", "username", "key_filename", "file_list"]
	missing = [k for k in required_keys if not config.get(k)]
	if missing:
		raise ValueError(f"Missing required YAML keys: {', '.join(missing)}")

	file_list_value = config["file_list"]
	file_list_path = Path(os.path.expanduser(file_list_value))
	if not file_list_path.is_absolute():
		file_list_path = (yaml_path.parent / file_list_path).resolve()
	if not file_list_path.exists():
		raise FileNotFoundError(f"File list not found: {file_list_path}")

	archive_basename = config.get("archive_basename") or None
	keep_archive = _parse_bool(config.get("keep_archive"))
	remote_archive_dir = config.get("remote_archive_dir") or None
	transferred_dir_value = config.get("transferred_files_dir") or config.get("shared_transfer_dir") or None
	transferred_dir_path: str | None = None
	if transferred_dir_value:
		candidate = Path(os.path.expanduser(transferred_dir_value))
		if not candidate.is_absolute():
			candidate = (yaml_path.parent / candidate).resolve()
		transferred_dir_path = str(candidate)

	return {
		"hostname": config["hostname"],
		"username": config["username"],
		"key_filename": os.path.expanduser(config["key_filename"]),
		"file_list_path": str(file_list_path),
		"archive_basename": archive_basename,
		"keep_local_archive": keep_archive,
		"remote_archive_dir": remote_archive_dir,
		"transferred_files_dir": transferred_dir_path,
	}


def compress_pull_extract_from_yaml(input_yaml: str, local_output_dir: str) -> Path:
	"""Load connection settings from YAML and execute the transfer."""

	config = _load_transfer_config(input_yaml)
	preferred_output = config.pop("transferred_files_dir", None)
	config["local_output_dir"] = preferred_output or local_output_dir
	return compress_pull_extract(**config)  # type: ignore[arg-type]


def main(argv: Iterable[str] | None = None) -> None:
	parser = build_parser()
	args = parser.parse_args(argv)
	compress_pull_extract_from_yaml(args.input_yaml, args.local_output_dir)


if __name__ == "__main__":
	main()

