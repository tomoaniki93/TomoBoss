#!/usr/bin/env python3
"""
TomoBoss - Release ZIP builder

Place this file in:
    TomoBoss/Tools/Build_Release.py

Run from anywhere:
    python Tools/Build_Release.py

Default output:
    TomoBoss/Release/TomoBoss-<version>.zip

The archive contains a top-level "TomoBoss/" folder ready to extract into
World of Warcraft/_retail_/Interface/AddOns/.

Only Python's standard library is required.
"""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import os
import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path, PurePosixPath


ADDON_NAME = "TomoBoss"

# Entire folders that must never be shipped to players.
EXCLUDED_DIR_NAMES = {
    "Docs",
    "Tools",
    "Release",
    "Releases",
    "dist",
    "build",
    ".git",
    ".github",
    ".idea",
    ".vscode",
    "__pycache__",
}

# Exact root-level files that are useful for development but not needed by WoW.
EXCLUDED_ROOT_FILES = {
    "README.md",
    "PROVENANCE.md",
    "VALIDATION.txt",
    "INSTALL-INPLACE.txt",
}

# Development / migration / test artifacts.
# These patterns are matched against the file name only.
EXCLUDED_FILE_PATTERNS = (
    "BETA*-TEST.txt",
    "BETA*-HOTFIX.txt",
    "HOTFIX-*.txt",
    "MIGRATION-*.txt",
    "CHANGELOG*.md",
    "*.patch",
    "*.diff",
    "*.py",
    "*.pyc",
    "*.pyo",
    "*.ps1",
    "*.cmd",
    "*.bat",
    ".DS_Store",
    "Thumbs.db",
)

# Keep legal files if present.
LEGAL_FILE_NAMES = {
    "LICENSE",
    "LICENSE.txt",
    "LICENSE.md",
    "COPYING",
    "COPYING.txt",
    "NOTICE",
    "NOTICE.txt",
    "NOTICE.md",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a clean TomoBoss player release ZIP."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=None,
        help="Addon source root. Default: parent of the Tools folder.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Output directory. Default: <root>/Release",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate and print the package contents without creating the ZIP.",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print every included file.",
    )
    parser.add_argument(
        "--no-sha256-file",
        action="store_true",
        help="Do not create the .sha256 sidecar file.",
    )
    return parser.parse_args()


def addon_root_from_script() -> Path:
    return Path(__file__).resolve().parent.parent


def read_version(toc_path: Path) -> str:
    text = toc_path.read_text(encoding="utf-8-sig")
    match = re.search(r"(?mi)^##\s*Version\s*:\s*(.+?)\s*$", text)
    if not match:
        raise RuntimeError(f"Unable to find '## Version:' in {toc_path}")
    version = match.group(1).strip()
    if not version:
        raise RuntimeError("The addon version is empty.")
    return version


def safe_filename(value: str) -> str:
    # Windows-safe and release-friendly.
    value = re.sub(r'[<>:"/\\|?*\x00-\x1F]', "-", value)
    value = re.sub(r"\s+", "-", value.strip())
    return value or "unknown"


def is_excluded(relative_path: Path) -> tuple[bool, str]:
    parts = relative_path.parts

    # Any occurrence of an excluded directory removes the entire subtree.
    for part in parts[:-1]:
        if part in EXCLUDED_DIR_NAMES:
            return True, f"directory:{part}"

    name = relative_path.name

    # Legal files are explicitly allowed, even when using a .md extension.
    if name in LEGAL_FILE_NAMES:
        return False, ""

    # Root-only development files.
    if len(parts) == 1 and name in EXCLUDED_ROOT_FILES:
        return True, f"root-file:{name}"

    for pattern in EXCLUDED_FILE_PATTERNS:
        if fnmatch.fnmatch(name, pattern):
            return True, f"pattern:{pattern}"

    # Common editor/temp files.
    if name.startswith(".") and name not in {".toc"}:
        return True, "hidden-file"
    if name.endswith(("~", ".bak", ".tmp", ".swp", ".swo")):
        return True, "temporary-file"

    return False, ""


def collect_files(root: Path) -> tuple[list[Path], list[tuple[Path, str]]]:
    included: list[Path] = []
    excluded: list[tuple[Path, str]] = []

    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(root)
        skip, reason = is_excluded(rel)
        if skip:
            excluded.append((rel, reason))
        else:
            included.append(rel)

    return included, excluded


def normalize_ref(ref: str) -> Path:
    return Path(ref.replace("\\", "/"))


def toc_dependencies(toc_path: Path) -> list[Path]:
    deps: list[Path] = []
    for raw in toc_path.read_text(encoding="utf-8-sig").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        deps.append(normalize_ref(line))
    return deps


def xml_dependencies(xml_path: Path) -> list[Path]:
    deps: list[Path] = []
    try:
        tree = ET.parse(xml_path)
    except ET.ParseError as exc:
        raise RuntimeError(f"Invalid XML: {xml_path}: {exc}") from exc

    base = xml_path.parent
    for elem in tree.iter():
        file_attr = elem.attrib.get("file")
        if not file_attr:
            continue
        dep = normalize_ref(file_attr)
        # XML file references are relative to the XML's directory.
        deps.append((base / dep).resolve())
    return deps


def validate_runtime_dependencies(root: Path, included: list[Path]) -> None:
    included_abs = {(root / p).resolve() for p in included}
    toc = root / f"{ADDON_NAME}.toc"

    missing: list[str] = []
    excluded_refs: list[str] = []

    # First-level TOC dependencies.
    pending_xml: list[Path] = []
    visited_xml: set[Path] = set()

    for dep in toc_dependencies(toc):
        dep_abs = (root / dep).resolve()
        if not dep_abs.exists():
            missing.append(str(dep))
            continue
        if dep_abs not in included_abs:
            excluded_refs.append(str(dep))
            continue
        if dep_abs.suffix.lower() == ".xml":
            pending_xml.append(dep_abs)

    # Recursively validate XML Include/Script file dependencies.
    while pending_xml:
        xml_path = pending_xml.pop()
        if xml_path in visited_xml:
            continue
        visited_xml.add(xml_path)

        for dep_abs in xml_dependencies(xml_path):
            try:
                dep_rel = dep_abs.relative_to(root.resolve())
            except ValueError:
                missing.append(f"{xml_path.relative_to(root)} -> OUTSIDE ROOT: {dep_abs}")
                continue

            if not dep_abs.exists():
                missing.append(f"{xml_path.relative_to(root)} -> {dep_rel}")
                continue
            if dep_abs not in included_abs:
                excluded_refs.append(f"{xml_path.relative_to(root)} -> {dep_rel}")
                continue
            if dep_abs.suffix.lower() == ".xml":
                pending_xml.append(dep_abs)

    if missing or excluded_refs:
        lines = ["Runtime dependency validation FAILED."]
        if missing:
            lines.append("\nMissing referenced files:")
            lines.extend(f"  - {item}" for item in sorted(set(missing)))
        if excluded_refs:
            lines.append("\nRuntime files would be excluded from the release:")
            lines.extend(f"  - {item}" for item in sorted(set(excluded_refs)))
        raise RuntimeError("\n".join(lines))


def archive_name(version: str) -> str:
    return f"{ADDON_NAME}-{safe_filename(version)}.zip"


def format_size(size: int) -> str:
    units = ("B", "KiB", "MiB", "GiB")
    value = float(size)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.1f} {unit}" if unit != "B" else f"{int(value)} B"
        value /= 1024
    return f"{size} B"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_zip(root: Path, files: list[Path], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)

    tmp_path = output_path.with_suffix(output_path.suffix + ".tmp")
    if tmp_path.exists():
        tmp_path.unlink()

    try:
        with zipfile.ZipFile(
            tmp_path,
            mode="w",
            compression=zipfile.ZIP_DEFLATED,
            compresslevel=9,
        ) as archive:
            for rel in files:
                source = root / rel
                # Player ZIP must always have exactly one TomoBoss/ root folder.
                arcname = PurePosixPath(ADDON_NAME) / PurePosixPath(rel.as_posix())
                archive.write(source, arcname.as_posix())

        # Atomic-ish replacement: a failed build does not destroy the previous ZIP.
        os.replace(tmp_path, output_path)
    finally:
        if tmp_path.exists():
            tmp_path.unlink()


def validate_archive(output_path: Path, expected_files: list[Path]) -> None:
    expected = {
        (PurePosixPath(ADDON_NAME) / PurePosixPath(p.as_posix())).as_posix()
        for p in expected_files
    }

    with zipfile.ZipFile(output_path, "r") as archive:
        actual = {name for name in archive.namelist() if not name.endswith("/")}

    missing = expected - actual
    extra = actual - expected
    forbidden = [
        name
        for name in actual
        if any(part in EXCLUDED_DIR_NAMES for part in PurePosixPath(name).parts)
        or PurePosixPath(name).name in EXCLUDED_ROOT_FILES
    ]

    if missing or extra or forbidden:
        message = ["Release ZIP validation FAILED."]
        if missing:
            message.append("Missing: " + ", ".join(sorted(missing)))
        if extra:
            message.append("Unexpected: " + ", ".join(sorted(extra)))
        if forbidden:
            message.append("Forbidden: " + ", ".join(sorted(forbidden)))
        raise RuntimeError("\n".join(message))


def main() -> int:
    args = parse_args()

    root = (args.root or addon_root_from_script()).resolve()
    toc_path = root / f"{ADDON_NAME}.toc"

    if not toc_path.is_file():
        print(f"ERROR: {toc_path} not found.", file=sys.stderr)
        print(
            "Build_Release.py must live in TomoBoss/Tools/, "
            "or use --root <TomoBoss folder>.",
            file=sys.stderr,
        )
        return 2

    version = read_version(toc_path)
    output_dir = (args.output_dir or (root / "Release")).resolve()
    output_path = output_dir / archive_name(version)

    included, excluded = collect_files(root)

    # The TOC itself is mandatory.
    if Path(f"{ADDON_NAME}.toc") not in included:
        print("ERROR: TomoBoss.toc would not be included.", file=sys.stderr)
        return 2

    try:
        validate_runtime_dependencies(root, included)
    except RuntimeError as exc:
        print(f"ERROR:\n{exc}", file=sys.stderr)
        return 3

    source_size = sum((root / rel).stat().st_size for rel in included)

    print("=" * 68)
    print("TomoBoss Release Builder")
    print("=" * 68)
    print(f"Root       : {root}")
    print(f"Version    : {version}")
    print(f"Output     : {output_path}")
    print(f"Included   : {len(included)} files ({format_size(source_size)})")
    print(f"Excluded   : {len(excluded)} files")
    print("Validation : TOC/XML runtime dependencies OK")
    print("ZIP layout : TomoBoss/<runtime files>")
    print()

    if args.list:
        print("Included files:")
        for rel in included:
            print(f"  + {rel.as_posix()}")
        print()

    if args.dry_run:
        print("DRY RUN: no ZIP created.")
        return 0

    try:
        build_zip(root, included, output_path)
        validate_archive(output_path, included)
    except Exception as exc:
        print(f"ERROR while building release: {exc}", file=sys.stderr)
        return 4

    digest = sha256_file(output_path)
    zip_size = output_path.stat().st_size

    if not args.no_sha256_file:
        sha_path = output_path.with_suffix(output_path.suffix + ".sha256")
        sha_path.write_text(
            f"{digest}  {output_path.name}\n",
            encoding="ascii",
        )
    else:
        sha_path = None

    print("Release created successfully.")
    print(f"ZIP        : {output_path}")
    print(f"ZIP size   : {format_size(zip_size)}")
    print(f"SHA256     : {digest}")
    if sha_path:
        print(f"SHA file   : {sha_path}")
    print()
    print("Excluded from player ZIP:")
    print("  Docs/, Tools/, Release/, Git/editor folders")
    print("  README.md, PROVENANCE.md, VALIDATION.txt, INSTALL-INPLACE.txt")
    print("  BETA*-TEST, HOTFIX, MIGRATION, CHANGELOG markdown, patches/scripts")
    print()
    print("Legal files (LICENSE/COPYING/NOTICE) are kept when present.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
