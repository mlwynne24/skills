import re
from pathlib import Path

import docx
import pypdf

SUPPORTED_SUFFIXES: frozenset[str] = frozenset({
    ".docx", ".pdf", ".txt", ".md", ".vtt", ".srt",
})

_BOM = "﻿"
_TRIPLE_BLANK = re.compile(r"\n{3,}")


class UnsupportedExtensionError(ValueError):
    def __init__(self, paths: list[Path]) -> None:
        self.paths = paths
        names = ", ".join(p.name for p in paths)
        super().__init__(
            f"Unsupported file extensions in INPUTS_DIR: {names}. "
            f"Supported: {sorted(SUPPORTED_SUFFIXES)}"
        )


class PasswordProtectedPDFError(ValueError):
    def __init__(self, path: Path) -> None:
        self.path = path
        super().__init__(
            f"PDF is password-protected: {path}. "
            "Remove the password (e.g. via Acrobat or qpdf) and re-run."
        )


def read_transcript(path: Path) -> str:
    """Dispatch on suffix, return normalized text."""
    suffix = path.suffix.lower()
    if suffix == ".docx":
        text = _read_docx(path)
    elif suffix == ".pdf":
        text = _read_pdf(path)
    elif suffix in {".txt", ".md", ".vtt", ".srt"}:
        text = path.read_text(encoding="utf-8", errors="replace")
    else:
        raise UnsupportedExtensionError([path])
    return _normalize(text)


def preflight_inputs(paths: list[Path]) -> None:
    """Raise UnsupportedExtensionError if any path has an unsupported suffix."""
    bad = [p for p in paths if p.suffix.lower() not in SUPPORTED_SUFFIXES]
    if bad:
        raise UnsupportedExtensionError(bad)


def _read_docx(path: Path) -> str:
    doc = docx.Document(str(path))
    return "\n".join(p.text for p in doc.paragraphs)


def _read_pdf(path: Path) -> str:
    reader = pypdf.PdfReader(str(path))
    if reader.is_encrypted:
        try:
            ok = reader.decrypt("")
        except Exception:
            ok = 0
        if not ok:
            raise PasswordProtectedPDFError(path)
    return "\n".join(page.extract_text() or "" for page in reader.pages)


def _normalize(text: str) -> str:
    if text.startswith(_BOM):
        text = text[1:]
    return _TRIPLE_BLANK.sub("\n\n", text)
