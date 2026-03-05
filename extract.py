from __future__ import annotations

import argparse
import re
from pathlib import Path


def _parse_pages(pages: str | None, total_pages: int) -> list[int]:
    if not pages:
        return list(range(total_pages))

    selected: set[int] = set()
    for part in pages.split(","):
        part = part.strip()
        if not part:
            continue

        if "-" in part:
            start_s, end_s = part.split("-", 1)
            start = int(start_s) if start_s.strip() else 1
            end = int(end_s) if end_s.strip() else total_pages
            if start < 1 or end < 1 or start > total_pages or end > total_pages:
                raise ValueError(f"Page range out of bounds: {part!r}")
            if start > end:
                raise ValueError(f"Invalid page range: {part!r}")
            selected.update(range(start - 1, end))
        else:
            page = int(part)
            if page < 1 or page > total_pages:
                raise ValueError(f"Page out of bounds: {part!r}")
            selected.add(page - 1)

    return sorted(selected)


def _pick_default_pdf(root: Path) -> Path | None:
    pdfs = [p for p in root.glob("*.pdf") if p.is_file()]
    if not pdfs:
        return None

    def score(path: Path) -> tuple[int, int, str]:
        name = path.name.casefold()
        is_figures = "figure" in name or "figures" in name
        is_assignment = "assign" in name or "assignment" in name
        bucket = 0 if (is_assignment and not is_figures) else (1 if is_assignment else 2)
        return (bucket, len(path.name), path.name)

    return min(pdfs, key=score)


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract text from a PDF (prints per-page).")
    parser.add_argument(
        "pdf",
        nargs="?",
        help="Path to a PDF. If omitted, picks an assignment-looking PDF in the current folder.",
    )
    parser.add_argument(
        "--pages",
        help="Pages to extract, 1-based (e.g. '1,3-5,10-'). Default: all pages.",
    )
    parser.add_argument(
        "--max-chars",
        type=int,
        default=2000,
        help="Max characters to print per page (0 = unlimited). Default: 2000.",
    )

    args = parser.parse_args()

    pdf_path = Path(args.pdf) if args.pdf else _pick_default_pdf(Path.cwd())
    if not pdf_path:
        print("No PDF found in the current directory. Pass a PDF path explicitly.")
        return 2
    pdf_path = pdf_path.expanduser().resolve()

    if not pdf_path.exists():
        print(f"PDF not found: {pdf_path}")
        return 2

    try:
        from PyPDF2 import PdfReader  # type: ignore[import-not-found]

        reader = PdfReader(str(pdf_path))
    except ModuleNotFoundError:
        try:
            from pypdf import PdfReader  # type: ignore[import-not-found]

            reader = PdfReader(str(pdf_path))
        except ModuleNotFoundError:
            print("Missing dependency. Install one of: PyPDF2, pypdf")
            return 2

    total_pages = len(reader.pages)
    try:
        page_indexes = _parse_pages(args.pages, total_pages)
    except ValueError as exc:
        print(f"Invalid --pages value: {exc}")
        return 2

    for page_index in page_indexes:
        page_number = page_index + 1
        page = reader.pages[page_index]
        text = page.extract_text() or ""
        text = re.sub(r"\r\n|\r", "\n", text)

        print(f"--- page {page_number} / {total_pages} ---")
        if args.max_chars and args.max_chars > 0:
            print(text[: args.max_chars])
        else:
            print(text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
