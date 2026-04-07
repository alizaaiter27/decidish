#!/usr/bin/env python3
"""Render SUPERVISOR_PROJECT_REPORT.md to DeciDish_Supervisor_Report.pdf.

Requires: pip install fpdf2
Fonts: place DejaVuSans.ttf and DejaVuSans-Bold.ttf in ./_pdf_fonts/
  (download from https://cdn.jsdelivr.net/npm/dejavu-fonts-ttf@2.37.3/ttf/)
"""

from __future__ import annotations

import re
import urllib.request
from pathlib import Path

from fpdf import FPDF

_FONT_BASE = "https://cdn.jsdelivr.net/npm/dejavu-fonts-ttf@2.37.3/ttf/"
_FONT_FILES = ("DejaVuSans.ttf", "DejaVuSans-Bold.ttf")


def body_w(pdf: FPDF) -> float:
    return pdf.w - pdf.l_margin - pdf.r_margin


def strip_md(s: str) -> str:
    s = re.sub(r"\*\*(.+?)\*\*", r"\1", s)
    s = re.sub(r"`([^`]+)`", r"\1", s)
    return s


class ReportPDF(FPDF):
    def __init__(self, font_dir: Path) -> None:
        super().__init__(format="A4")
        self.set_auto_page_break(auto=True, margin=18)
        self.add_font("DejaVu", "", str(font_dir / "DejaVuSans.ttf"))
        self.add_font("DejaVu", "B", str(font_dir / "DejaVuSans-Bold.ttf"))


def flush_paragraph(pdf: ReportPDF, buf: list[str]) -> None:
    if not buf:
        return
    text = strip_md(" ".join(buf).strip())
    if not text:
        buf.clear()
        return
    pdf.set_font("DejaVu", size=12)
    pdf.set_x(pdf.l_margin)
    pdf.multi_cell(body_w(pdf), 6, text)
    pdf.ln(2)
    buf.clear()


def render_table(pdf: ReportPDF, rows: list[list[str]]) -> None:
    if not rows:
        return
    pdf.set_font("DejaVu", size=12)
    for row in rows:
        line = "  |  ".join(strip_md(c) for c in row)
        pdf.set_x(pdf.l_margin)
        pdf.multi_cell(body_w(pdf), 6, line)
    pdf.ln(3)


def ensure_fonts(font_dir: Path) -> None:
    font_dir.mkdir(parents=True, exist_ok=True)
    for name in _FONT_FILES:
        path = font_dir / name
        if path.exists():
            continue
        url = _FONT_BASE + name
        print(f"Downloading {name} …")
        urllib.request.urlretrieve(url, path)


def main() -> None:
    root = Path(__file__).resolve().parent
    md_path = root / "SUPERVISOR_PROJECT_REPORT.md"
    out_path = root / "DeciDish_Supervisor_Report.pdf"
    font_dir = root / "_pdf_fonts"

    ensure_fonts(font_dir)

    raw_lines = md_path.read_text(encoding="utf-8").splitlines()
    pdf = ReportPDF(font_dir)
    pdf.add_page()
    pdf.set_margins(18, 18, 18)

    buf: list[str] = []
    table_rows: list[list[str]] = []
    in_table = False

    def end_table() -> None:
        nonlocal in_table, table_rows
        if in_table and table_rows:
            render_table(pdf, table_rows)
        table_rows = []
        in_table = False

    i = 0
    while i < len(raw_lines):
        line = raw_lines[i]
        s = line.strip()

        if not s:
            if in_table:
                end_table()
            flush_paragraph(pdf, buf)
            pdf.ln(1)
            i += 1
            continue

        # Markdown table
        if s.startswith("|") and s.endswith("|"):
            flush_paragraph(pdf, buf)
            in_table = True
            inner = s[1:-1]
            cells = [c.strip() for c in inner.split("|")]
            # separator row --- 
            if all(re.match(r"^[\s\-:]+$", c) for c in cells if c):
                i += 1
                continue
            table_rows.append(cells)
            i += 1
            continue

        if in_table:
            end_table()

        if s == "---" or s == "***":
            flush_paragraph(pdf, buf)
            pdf.set_draw_color(190, 190, 190)
            y = pdf.get_y()
            pdf.line(18, y, pdf.w - 18, y)
            pdf.ln(5)
            i += 1
            continue

        if s.startswith("### "):
            flush_paragraph(pdf, buf)
            pdf.set_font("DejaVu", "B", size=12)
            pdf.set_x(pdf.l_margin)
            pdf.multi_cell(body_w(pdf), 7, strip_md(s[4:]))
            pdf.ln(2)
            i += 1
            continue

        if s.startswith("## "):
            flush_paragraph(pdf, buf)
            pdf.set_font("DejaVu", "B", size=14)
            pdf.set_x(pdf.l_margin)
            pdf.multi_cell(body_w(pdf), 8, strip_md(s[3:]))
            pdf.ln(3)
            i += 1
            continue

        if s.startswith("# "):
            flush_paragraph(pdf, buf)
            pdf.set_font("DejaVu", "B", size=18)
            pdf.set_x(pdf.l_margin)
            pdf.multi_cell(body_w(pdf), 10, strip_md(s[2:]))
            pdf.ln(4)
            i += 1
            continue

        if s.startswith("- ") or (s.startswith("* ") and not s.startswith("**")):
            flush_paragraph(pdf, buf)
            pdf.set_font("DejaVu", size=12)
            pdf.set_x(pdf.l_margin + 4)
            pdf.multi_cell(body_w(pdf) - 4, 6, "\u2022 " + strip_md(s[2:]))
            pdf.set_x(pdf.l_margin)
            i += 1
            continue

        if re.match(r"^\d+\.\s", s):
            flush_paragraph(pdf, buf)
            pdf.set_font("DejaVu", size=12)
            pdf.set_x(pdf.l_margin + 4)
            pdf.multi_cell(body_w(pdf) - 4, 6, strip_md(s))
            pdf.set_x(pdf.l_margin)
            i += 1
            continue

        buf.append(s)
        i += 1

    if in_table:
        end_table()
    flush_paragraph(pdf, buf)

    pdf.output(str(out_path))
    print(f"Wrote {out_path} ({out_path.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
