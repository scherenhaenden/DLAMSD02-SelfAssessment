#!/usr/bin/env python3
"""
measure_documentation_and_complexity.py
AssessYourself - Code Quality & Cognitive Load Metric Tool (DLAMSD02)

Analyzes Swift source files to measure:
1. Documentation Coverage (Lines of comments vs. executable code, type & function docstrings)
2. Cognitive Load Indicators (Max nesting depth, long functions, cyclomatic complexity proxies)
"""

import os
import re
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import List, Dict, Tuple

# Thresholds
MIN_DOC_RATIO_TARGET = 15.0       # At least 15% comments/docstrings
MIN_DECL_DOC_TARGET = 60.0        # At least 60% types/methods documented
MAX_RECOMMENDED_NESTING = 3       # Max logical nesting depth in methods
MAX_RECOMMENDED_FUNC_LINES = 40   # Max lines per function body

@dataclass
class FunctionMetric:
    name: str
    start_line: int
    line_count: int
    max_nesting: int
    is_documented: bool

@dataclass
class FileMetric:
    path: str
    total_lines: int = 0
    code_lines: int = 0
    comment_lines: int = 0
    blank_lines: int = 0
    total_declarations: int = 0
    documented_declarations: int = 0
    functions: List[FunctionMetric] = field(default_factory=list)

    @property
    def doc_ratio(self) -> float:
        total = self.code_lines + self.comment_lines
        return (self.comment_lines / total * 100.0) if total > 0 else 0.0

    @property
    def decl_doc_ratio(self) -> float:
        return (self.documented_declarations / self.total_declarations * 100.0) if self.total_declarations > 0 else 100.0

    @property
    def max_nesting(self) -> int:
        if not self.functions:
            return 0
        return max(f.max_nesting for f in self.functions)

    @property
    def high_cognitive_load_funcs(self) -> List[FunctionMetric]:
        return [f for f in self.functions if f.line_count > MAX_RECOMMENDED_FUNC_LINES or f.max_nesting > MAX_RECOMMENDED_NESTING]


DECLARATION_REGEX = re.compile(
    r'^\s*(public\s+|private\s+|fileprivate\s+|internal\s+|open\s+|override\s+|final\s+|mutating\s+)*'
    r'(struct|class|enum|protocol|actor|func|init)\b'
)

FUNC_REGEX = re.compile(
    r'^\s*(?:(?:public|private|fileprivate|internal|open|override|final|mutating|static|@\w+(?:\([^)]*\))?)\s+)*'
    r'(func\s+([A-Za-z0-9_]+)|init\b)'
)

def analyze_file(filepath: Path) -> FileMetric:
    rel_path = str(filepath)
    metric = FileMetric(path=rel_path)

    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    metric.total_lines = len(lines)
    in_block_comment = False
    pending_doc_comment = False

    brace_depth = 0
    current_func: FunctionMetric = None
    func_brace_start = 0

    for idx, raw_line in enumerate(lines, start=1):
        line = raw_line.strip()

        # Blank line
        if not line:
            metric.blank_lines += 1
            if not in_block_comment:
                pending_doc_comment = False
            continue

        # Block comment handling
        if in_block_comment:
            metric.comment_lines += 1
            if "*/" in line:
                in_block_comment = False
                pending_doc_comment = True
            continue

        if line.startswith("/*"):
            metric.comment_lines += 1
            if "*/" not in line:
                in_block_comment = True
            else:
                pending_doc_comment = True
            continue

        # Single-line comment handling
        if line.startswith("//"):
            metric.comment_lines += 1
            if line.startswith("///"):
                pending_doc_comment = True
            continue

        # Otherwise it's code
        metric.code_lines += 1

        # Check for declarations
        decl_match = DECLARATION_REGEX.search(line)
        if decl_match:
            metric.total_declarations += 1
            if pending_doc_comment:
                metric.documented_declarations += 1

        # Check for function start
        func_match = FUNC_REGEX.search(line)
        if func_match and current_func is None:
            name = func_match.group(2) if func_match.group(2) else "init"
            current_func = FunctionMetric(
                name=name,
                start_line=idx,
                line_count=0,
                max_nesting=0,
                is_documented=pending_doc_comment
            )
            func_brace_start = brace_depth

        # Track braces and nesting depth
        open_braces = line.count("{")
        close_braces = line.count("}")
        brace_depth += (open_braces - close_braces)

        if current_func:
            current_func.line_count += 1
            local_nesting = max(0, brace_depth - func_brace_start)
            if local_nesting > current_func.max_nesting:
                current_func.max_nesting = local_nesting

            # Function ended when brace depth returns to or below start
            if brace_depth <= func_brace_start and (close_braces > 0 or open_braces > 0):
                metric.functions.append(current_func)
                current_func = None

        # Reset doc flag if code line didn't declare anything
        if not decl_match:
            pending_doc_comment = False

    if current_func:
        metric.functions.append(current_func)

    return metric


def run_analysis(root_dir: Path) -> List[FileMetric]:
    metrics = []
    src_dir = root_dir / "src"
    if not src_dir.exists():
        src_dir = root_dir

    for p in sorted(src_dir.rglob("*.swift")):
        # Skip generated mocks or xcodeproj configs if any
        if ".build" in p.parts or "DerivedData" in p.parts:
            continue
        metrics.append(analyze_file(p))
    return metrics


def print_report(metrics: List[FileMetric], root_dir: Path):
    print("=" * 90)
    print(" AssessYourself: Documentation Coverage & Cognitive Load Audit (DLAMSD02)")
    print("=" * 90)

    total_lines = sum(m.total_lines for m in metrics)
    total_code = sum(m.code_lines for m in metrics)
    total_comments = sum(m.comment_lines for m in metrics)
    total_decls = sum(m.total_declarations for m in metrics)
    total_doc_decls = sum(m.documented_declarations for m in metrics)

    overall_doc_ratio = (total_comments / (total_code + total_comments) * 100.0) if (total_code + total_comments) > 0 else 0
    overall_decl_doc = (total_doc_decls / total_decls * 100.0) if total_decls > 0 else 0

    print(f"\n[Overall Statistics]")
    print(f"  • Files Analyzed:              {len(metrics)}")
    print(f"  • Total Lines of Code (LOC):   {total_lines:,}")
    print(f"  • Executable Code Lines:       {total_code:,}")
    print(f"  • Documentation Lines:         {total_comments:,} ({overall_doc_ratio:.1f}% overall doc density)")
    print(f"  • Total Declarations:          {total_decls}")
    print(f"  • Documented Declarations:     {total_doc_decls} ({overall_decl_doc:.1f}% API doc coverage)")

    print("\n" + "-" * 90)
    print(f"{'File':<42} | {'Code':>5} | {'Doc':>5} | {'Doc %':>6} | {'Decl Doc':>8} | {'Max Nest':>8}")
    print("-" * 90)

    needs_docs = []
    high_complexity = []

    for m in metrics:
        rel = os.path.relpath(m.path, root_dir)
        if len(rel) > 42:
            rel = "..." + rel[-39:]
        
        status_flag = ""
        if m.doc_ratio < MIN_DOC_RATIO_TARGET:
            status_flag = "⚠️ low doc"
            needs_docs.append(m)
        if m.max_nesting > MAX_RECOMMENDED_NESTING or len(m.high_cognitive_load_funcs) > 0:
            high_complexity.append(m)

        print(f"{rel:<42} | {m.code_lines:>5} | {m.comment_lines:>5} | {m.doc_ratio:>5.1f}% | {m.decl_doc_ratio:>7.1f}% | {m.max_nesting:>8}")

    print("-" * 90)

    print("\n[Identified Gaps - Pending Refinement]")
    print(f"1. Files below {MIN_DOC_RATIO_TARGET}% documentation density: {len(needs_docs)} / {len(metrics)}")
    for m in needs_docs[:8]:
        rel = os.path.relpath(m.path, root_dir)
        print(f"   - {rel} ({m.doc_ratio:.1f}% docs, {m.documented_declarations}/{m.total_declarations} decls)")
    if len(needs_docs) > 8:
        print(f"   ... and {len(needs_docs) - 8} more files.")

    print(f"\n2. Cognitive Load: Files with functions > {MAX_RECOMMENDED_FUNC_LINES} lines or nesting > {MAX_RECOMMENDED_NESTING}: {len(high_complexity)}")
    for m in high_complexity[:6]:
        rel = os.path.relpath(m.path, root_dir)
        print(f"   - {rel} (Max nesting: {m.max_nesting}, Long/Deep functions: {len(m.high_cognitive_load_funcs)})")
        for f in m.high_cognitive_load_funcs[:2]:
            print(f"     * {f.name}() at L{f.start_line}: {f.line_count} lines, depth {f.max_nesting}")

    print("\n" + "=" * 90)
    print(" [Standard Definition & Minimal Rules]")
    print("  • Minimal Type/API Doc: Every public/internal type & method must have 1-3 lines of '///'")
    print("  • In-Line Intent: Non-obvious algorithms must state *why* (rationale), not just *what*")
    print("  • Cognitive Load Limit: Max nesting <= 3, Max function length <= 40 lines")
    print("=" * 90)


def main():
    root_dir = Path(__file__).resolve().parent.parent
    if len(sys.argv) > 1:
        root_dir = Path(sys.argv[1]).resolve()

    metrics = run_analysis(root_dir)
    print_report(metrics, root_dir)

if __name__ == "__main__":
    main()
