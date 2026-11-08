#!/usr/bin/env python3
"""
House-style checker for academic manuscripts.

Checks prose files (.tex, .md, .qmd, .txt, .Rmd) against the project house style:

  1. Em dashes            : the character em dash, and the LaTeX "---" ligature
  2. "utilise"            : all inflections, including the -ize spellings
  3. American spellings   : a curated list, plus a general -ize/-yze sweep
  4. AI cliches           : stock filler phrases
  5. Minor nits           : double spaces, "very unique", straight quotes in LaTeX
  6. Paragraph length     : manuscript paragraphs must have 3 to 8 sentences

Markdown fenced code blocks, inline code spans, LaTeX verbatim/lstlisting
environments and LaTeX comments are skipped, so code samples are not flagged.

Suppression
-----------
Where a line must legitimately name a banned word or quote a source verbatim,
exempt it with a marker in a comment:

    ... text ...                 <!-- style-check: ignore -->
    <!-- style-check: ignore-next -->
    <!-- style-check: off -->    ... exempt region ...    <!-- style-check: on -->

Usage
-----
    python check_style.py paper/paper.tex paper/paper.md README.md
    python check_style.py --all .                 # walk a directory tree
    python check_style.py --quiet paper/paper.tex # exit code only

Exit codes
----------
    0  no issues found
    1  one or more issues found
    2  bad invocation (no readable input files)
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

PROSE_SUFFIXES = {".tex", ".md", ".qmd", ".txt", ".rmd"}

SKIP_DIR_NAMES = {
    ".git", ".github", "node_modules", "renv", "__pycache__",
    "data", "outputs", "journal_template", ".quarto", "_site",
    ".venv", "venv", "env",
}


# --------------------------------------------------------------------------
# Rules
# --------------------------------------------------------------------------

@dataclass(frozen=True)
class Rule:
    name: str
    pattern: re.Pattern
    message: str
    suffixes: frozenset | None = None   # None means "all prose files"
    severity: str = "error"


# 1. Em dashes -------------------------------------------------------------

EM_DASH_RULES = [
    Rule(
        name="em-dash",
        pattern=re.compile(r"\u2014"),
        message="Em dash. Use a colon, comma or parentheses instead.",
    ),
    Rule(
        name="em-dash-latex",
        pattern=re.compile(r"(?<!-)---(?!-)"),
        message="LaTeX em dash ('---'). Use a colon, comma or parentheses instead.",
        suffixes=frozenset({".tex"}),
    ),
]


# 2. "utilise" -------------------------------------------------------------

UTILISE_RULE = Rule(
    name="utilise",
    pattern=re.compile(r"\butilis|\butiliz", re.IGNORECASE),
    message="'utilise'/'utilize' and its forms are banned. Use 'use'.",
)


# 3. American spellings ----------------------------------------------------

# Curated pairs: American form -> British form.
AMERICAN_SPELLINGS = {
    "analyze": "analyse", "analyzed": "analysed", "analyzes": "analyses",
    "analyzing": "analysing", "analyzer": "analyser",
    "behavior": "behaviour", "behaviors": "behaviours",
    "behavioral": "behavioural", "behaviorally": "behaviourally",
    "center": "centre", "centers": "centres", "centered": "centred",
    "centering": "centring",
    "color": "colour", "colors": "colours", "colored": "coloured",
    "coloring": "colouring", "colorful": "colourful",
    "defense": "defence", "defenses": "defences",
    "enrollment": "enrolment", "enrollments": "enrolments",
    "favor": "favour", "favors": "favours", "favorable": "favourable",
    "favored": "favoured",
    "fulfill": "fulfil", "fulfills": "fulfils",
    "labor": "labour", "labors": "labours",
    "license": "licence (noun); 'license' is the verb in British English",
    "meter": "metre (unit); 'meter' is a measuring device",
    "meters": "metres (unit)",
    "modeled": "modelled", "modeling": "modelling", "modeler": "modeller",
    "neighbor": "neighbour", "neighbors": "neighbours",
    "neighboring": "neighbouring", "neighborhood": "neighbourhood",
    "offense": "offence",
    "practise": "practice (noun); 'practise' is the verb",
    "signaled": "signalled", "signaling": "signalling",
    "skillful": "skilful",
    "traveled": "travelled", "traveling": "travelling", "traveler": "traveller",
    "vapor": "vapour", "vapors": "vapours",
}

# Words ending -ize/-ization/-yze that are legitimate and must not be flagged
# by the general sweep below.
IZE_ALLOWLIST = {
    "size", "sizes", "sized", "sizing", "resize", "resized", "resizes",
    "resizing", "oversize", "oversized", "undersized", "downsize",
    "downsized", "downsizing", "upsize", "midsize", "capsize", "capsized",
    "prize", "prizes", "prized", "prizing", "seize", "seizes", "seized",
    "seizing", "seizure", "seizures", "maize", "baize", "assize",
    "gaze", "gazes", "gazed", "gazing", "maze", "mazes", "haze", "hazes",
    "hazed", "blaze", "blazes", "blazed", "graze", "grazes", "grazed",
    "grazing", "amaze", "amazed", "amazes", "amazing", "ooze", "oozes",
    "bronze", "bronzes", "freeze", "freezes", "breeze", "breezes",
    "squeeze", "squeezes", "squeezed", "squeezing", "sneeze", "sneezes",
    "wheeze", "wheezes", "snooze", "booze", "doze", "dozes", "dozed",
    "dozen", "dozens", "froze", "frozen", "seize", "noize",
}

IZE_SWEEP = re.compile(r"\b[A-Za-z]{3,}(?:iz(?:e|es|ed|ing|ation|ations|er|ers)|yz(?:e|es|ed|ing|er|ers))\b")


# 4. AI cliches ------------------------------------------------------------

AI_CLICHES = [
    r"what this buys you",
    r"delve into",
    r"delving into",
    r"it'?s worth noting that",
    r"it is worth noting that",
    r"in today'?s (?:rapidly )?(?:evolving|changing) (?:landscape|world)",
    r"in the (?:ever[- ])?evolving (?:landscape|world|field)",
    r"navigate the complexit(?:y|ies)",
    r"a testament to",
    r"plays? a (?:crucial|pivotal|vital|key) role in",
    r"at the heart of (?:this|the) (?:matter|issue)",
    r"unlock(?:ing)? the (?:potential|power)",
    r"harness(?:ing)? the power of",
    r"paradigm shift",
    r"game[- ]chang(?:er|ing)",
    r"deep dive",
    r"let'?s (?:dive|unpack)",
    r"when it comes to",
    r"the key takeaway (?:here )?is",
    r"shed(?:s|ding)? light on",
    r"tapestry of",
    r"cannot be overstated",
    r"stands? as a",
    r"in conclusion, (?:we|this paper)",
    r"moreover, it is important to",
    r"furthermore, it should be noted",
    r"robust(?:ly)? underscore",
    r"underscor(?:e|es|ing) the importance",
    r"realm of",
    r"myriad of",
    r"seamless(?:ly)? integrat",
    r"leverag(?:e|es|ing) (?:the|our|this)",
]

CLICHE_RULES = [
    Rule(
        name="ai-cliche",
        pattern=re.compile(phrase, re.IGNORECASE),
        message="AI cliche or stock filler phrase. Rewrite plainly.",
    )
    for phrase in AI_CLICHES
]


# 5. Minor nits ------------------------------------------------------------

NIT_RULES = [
    Rule(
        name="double-space",
        pattern=re.compile(r"(?<=\S)  +(?=\S)"),
        message="Double space inside a sentence.",
        severity="warning",
    ),
    Rule(
        name="very-unique",
        pattern=re.compile(r"\b(?:very|quite|somewhat|rather)\s+unique\b", re.IGNORECASE),
        message="'unique' is absolute and takes no modifier.",
        severity="warning",
    ),
    Rule(
        name="straight-quotes-latex",
        pattern=re.compile(r'"'),
        message="Straight double quote in LaTeX. Use ``...'' instead.",
        suffixes=frozenset({".tex"}),
        severity="warning",
    ),
]


# Whether "data" takes a singular or plural verb is a house convention, not a
# correctness question: journals genuinely differ. The project follows its
# landmark paper, so this rule is opt-in via --data-plural.
DATA_PLURAL_RULE = Rule(
    name="data-is",
    pattern=re.compile(r"\bdata\s+(?:is|was)\b", re.IGNORECASE),
    message="'data is/was'. This project follows the plural 'data are/were'.",
    severity="warning",
)


# --------------------------------------------------------------------------
# Masking of code regions
# --------------------------------------------------------------------------

MASK_CHAR = "\x00"


def blank(text: str) -> str:
    """Filler of the same length as `text`.

    A non-space, non-word character is used so that masked regions keep the
    column offsets aligned without themselves looking like double spaces or
    word boundaries to the rules.
    """
    return MASK_CHAR * len(text)


def mask_code_regions(lines: list[str], suffix: str) -> list[str]:
    """Replace code content with filler so offsets stay aligned but
    nothing inside code is matched by the rules."""
    masked: list[str] = []
    in_md_fence = False
    in_tex_verbatim = False

    tex_verb_start = re.compile(r"\\begin\{(verbatim|lstlisting|minted|Verbatim|semiverbatim)\}")
    tex_verb_end = re.compile(r"\\end\{(verbatim|lstlisting|minted|Verbatim|semiverbatim)\}")

    for raw in lines:
        line = raw.rstrip("\n")

        if suffix in {".md", ".qmd", ".rmd"}:
            if re.match(r"^\s*(```|~~~)", line):
                in_md_fence = not in_md_fence
                masked.append(blank(line))
                continue
            if in_md_fence:
                masked.append(blank(line))
                continue
            # Inline code spans.
            line = re.sub(r"`[^`]*`", lambda m: blank(m.group(0)), line)
            # Bare URLs and markdown link targets.
            line = re.sub(r"\]\([^)]*\)", lambda m: blank(m.group(0)), line)
            line = re.sub(r"https?://\S+", lambda m: blank(m.group(0)), line)

        if suffix == ".tex":
            if tex_verb_start.search(line):
                in_tex_verbatim = True
                masked.append(blank(line))
                continue
            if tex_verb_end.search(line):
                in_tex_verbatim = False
                masked.append(blank(line))
                continue
            if in_tex_verbatim:
                masked.append(blank(line))
                continue
            # LaTeX comments (an escaped \% is not a comment).
            cmt = re.search(r"(?<!\\)%", line)
            if cmt:
                line = line[: cmt.start()] + blank(line[cmt.start():])
            # \verb|...| and \url{...} and \texttt{...} and LaTeX environments/control words
            line = re.sub(r"\\verb(.)(.*?)\1", lambda m: blank(m.group(0)), line)
            line = re.sub(r"\\(?:url|href|path|cite[a-zA-Z]*|ref|label|includegraphics|input|bibliography|begin|end)\s*\{[^}]*\}",
                          lambda m: blank(m.group(0)), line)
            line = re.sub(r"\\[A-Za-z]+", lambda m: blank(m.group(0)), line)

        masked.append(line)

    return masked


# --------------------------------------------------------------------------
# Checking
# --------------------------------------------------------------------------

@dataclass
class Issue:
    path: Path
    line_no: int
    col: int
    rule: str
    severity: str
    snippet: str
    message: str


def build_rules(suffix: str, data_plural: str = "off") -> list[Rule]:
    rules: list[Rule] = []
    rules.extend(EM_DASH_RULES)
    rules.append(UTILISE_RULE)
    rules.extend(CLICHE_RULES)
    rules.extend(NIT_RULES)

    if data_plural in {"warn", "error"}:
        rules.append(
            Rule(
                name=DATA_PLURAL_RULE.name,
                pattern=DATA_PLURAL_RULE.pattern,
                message=DATA_PLURAL_RULE.message,
                severity="warning" if data_plural == "warn" else "error",
            )
        )

    for american, british in AMERICAN_SPELLINGS.items():
        rules.append(
            Rule(
                name="us-spelling",
                pattern=re.compile(rf"\b{american}\b", re.IGNORECASE),
                message=f"American spelling '{american}'. Use '{british}'.",
            )
        )

    return [r for r in rules if r.suffixes is None or suffix in r.suffixes]


def suppressed_lines(lines: list[str]) -> set[int]:
    """Line numbers (1-based) exempted by an inline suppression marker.

    A document sometimes has to name a banned word in order to ban it, or
    quote a source verbatim. Three markers are recognised, in a Markdown
    comment, a LaTeX comment or any other comment syntax:

        style-check: ignore        exempts the line it appears on
        style-check: ignore-next   exempts the following line
        style-check: off / on      exempts everything between them
    """
    ignore_here = re.compile(r"style-check:\s*ignore\b(?!-next)", re.IGNORECASE)
    ignore_next = re.compile(r"style-check:\s*ignore-next\b", re.IGNORECASE)
    block_off = re.compile(r"style-check:\s*off\b", re.IGNORECASE)
    block_on = re.compile(r"style-check:\s*on\b", re.IGNORECASE)

    skipped: set[int] = set()
    in_block = False

    for i, line in enumerate(lines, start=1):
        if block_off.search(line):
            in_block = True
            skipped.add(i)
            continue
        if block_on.search(line):
            in_block = False
            skipped.add(i)
            continue
        if in_block:
            skipped.add(i)
            continue
        if ignore_here.search(line):
            skipped.add(i)
        if ignore_next.search(line):
            skipped.add(i)
            skipped.add(i + 1)

    return skipped


# --------------------------------------------------------------------------
# Paragraph sentence-count checking
# --------------------------------------------------------------------------

NON_MANUSCRIPT_NAMES = {
    "readme.md", "progress.md", "provenance.md", "skill.md",
    "workflow.md", "cover_letter.md", "novelty_statement.md",
}

NON_MANUSCRIPT_DIRS = {"reviews", "literature", "eda", "references"}

ABBREV_RE = re.compile(
    r"\b(?:e\.g|i\.e|et al|vs|cf|viz|al|ca|approx|resp|eq|eqs|fig|figs|sec|secs|"
    r"ch|no|nos|vol|vols|pp|p|dr|prof|mr|mrs|ms|st|jr|sr|inc|ltd|co)\.",
    re.IGNORECASE,
)

EQ_END_PERIOD_RE = re.compile(
    r"\.\s*(?:\\(?:label|tag)\{[^}]*\}\s*)*(?:\$\$|\\end\{[^}]+\})?\s*$"
)


def _strip_nested_command(text: str, cmd: str) -> str:
    """Remove \\cmd{...} handling nested braces."""
    pattern = re.compile(rf"\\{cmd}\s*\{{")
    while True:
        m = pattern.search(text)
        if not m:
            break
        start = m.start()
        idx = m.end()
        depth = 1
        while idx < len(text) and depth > 0:
            if text[idx] == "{" and (idx == 0 or text[idx - 1] != "\\"):
                depth += 1
            elif text[idx] == "}" and (idx == 0 or text[idx - 1] != "\\"):
                depth -= 1
            idx += 1
        text = text[:start] + text[idx:]
    return text


def count_sentences(paragraph: str) -> int:
    """Count sentences in a prose paragraph (LaTeX or Markdown)."""
    text = paragraph.strip()
    if not text:
        return 0
    for cmd in ("footnote", "footnotetext"):
        text = _strip_nested_command(text, cmd)
    text = re.sub(
        r"\$\$[^$]+\$\$",
        lambda m: " . " if EQ_END_PERIOD_RE.search(m.group(0)) else " ",
        text,
    )
    text = re.sub(r"\$[^$]+\$", " MATH ", text)
    text = re.sub(r"https?://[^\s)]+", "URL", text)
    text = ABBREV_RE.sub("ABBR", text)
    text = re.sub(r"\b[A-Z]\.(?=\s+[A-Z])", "INIT", text)
    text = re.sub(r"(?<=\d)\.(?=\d)", "DEC", text)
    text = re.sub(r"\.{2,}", " ", text)
    ends = re.findall(r"[.!?][\"\x27\)\]\}\*]*(?:\s+|$)", text)
    return len(ends)


def _merge_prose_blocks(raw_blocks: list[tuple[int, int, str, str]]) -> list[tuple[int, int, str]]:
    """Merge prose blocks bridged by display equations and skip list lead-ins."""
    merged: list[tuple[int, int, str]] = []
    idx = 0
    while idx < len(raw_blocks):
        start_ln, end_ln, kind, txt = raw_blocks[idx]
        if kind != "prose":
            idx += 1
            continue
        while idx + 1 < len(raw_blocks) and raw_blocks[idx + 1][2] == "eq":
            eq_dots: list[str] = []
            j = idx + 1
            while j < len(raw_blocks) and raw_blocks[j][2] == "eq":
                if raw_blocks[j][3]:
                    eq_dots.append(raw_blocks[j][3])
                end_ln = raw_blocks[j][1]
                j += 1
            if eq_dots:
                txt = txt + " " + " ".join(eq_dots)
            if j < len(raw_blocks) and raw_blocks[j][2] == "prose":
                txt = txt + " " + raw_blocks[j][3]
                end_ln = raw_blocks[j][1]
                idx = j
            else:
                idx = j - 1
                break
        if txt.rstrip().endswith(":") and idx + 1 < len(raw_blocks) and raw_blocks[idx + 1][2] == "list":
            idx += 1
            continue
        if count_sentences(txt) == 0:
            idx += 1
            continue
        merged.append((start_ln, end_ln, txt))
        idx += 1
    return merged


def extract_tex_paragraphs(lines: list[str]) -> list[tuple[int, int, str]]:
    """Extract (start_line, end_line, text) for prose paragraphs in a .tex file."""
    has_begin_doc = any("\\begin{document}" in l for l in lines)
    in_doc = not has_begin_doc
    in_declarations = False
    skip_envs = {
        "figure", "figure*", "table", "table*", "tabular", "tabularx", "longtable",
        "threeparttable", "tablenotes", "itemize", "enumerate", "description",
        "thebibliography", "verbatim", "lstlisting", "minted", "tikzpicture",
        "titlepage", "author",
    }
    eq_envs = {
        "equation", "equation*", "align", "align*", "gather", "gather*",
        "multline", "multline*", "eqnarray", "eqnarray*",
    }
    in_skip = 0
    in_eq = 0
    raw_blocks: list[tuple[int, int, str, str]] = []
    curr_lines: list[str] = []
    curr_start = 1
    curr_end = 1

    def flush_prose() -> None:
        nonlocal curr_lines
        if curr_lines:
            raw_blocks.append((curr_start, curr_end, "prose", " ".join(curr_lines)))
            curr_lines = []

    for i, raw in enumerate(lines, 1):
        line = re.sub(r"(?<!\\)%.*", "", raw).strip()
        if "\\begin{document}" in line:
            in_doc = True
            continue
        if "\\end{document}" in line:
            flush_prose()
            break
        if not in_doc:
            continue
        if re.match(
            r"^\\section\*?\{.*(?:Declarations|Statements|Acknowledgements|Acknowledgments|"
            r"Author Contributions|Data Availability|Code Availability)",
            line,
            re.IGNORECASE,
        ):
            flush_prose()
            in_declarations = True
            continue
        if re.match(r"^\\(?:section|appendix)\b", line):
            in_declarations = False
        if in_declarations:
            continue

        entered_skip = False
        for env in skip_envs:
            if re.search(rf"\\begin\{{{re.escape(env)}\}}", line):
                flush_prose()
                kind = "list" if env in {"itemize", "enumerate", "description"} else "other"
                raw_blocks.append((i, i, kind, ""))
                in_skip += 1
                entered_skip = True
            if re.search(rf"\\end\{{{re.escape(env)}\}}", line):
                in_skip = max(0, in_skip - 1)
        if in_skip > 0 or entered_skip or any(re.search(rf"\\end\{{{re.escape(env)}\}}", line) for env in skip_envs):
            continue

        for env in eq_envs:
            if re.search(rf"\\begin\{{{re.escape(env)}\}}", line):
                flush_prose()
                in_eq += 1
        if in_eq > 0:
            raw_blocks.append((i, i, "eq", "." if EQ_END_PERIOD_RE.search(line) else ""))
            for env in eq_envs:
                if re.search(rf"\\end\{{{re.escape(env)}\}}", line):
                    in_eq = max(0, in_eq - 1)
            continue

        if not line:
            flush_prose()
            continue

        if (
            re.match(
                r"^\\(?:maketitle|section|subsection|subsubsection|paragraph|subparagraph|"
                r"FloatBarrier|clearpage|newpage|pagebreak|appendix|bibliographystyle|"
                r"bibliography|vspace|hspace)\b",
                line,
            )
            or re.match(r"^\\(?:begin|end)\{abstract\}", line)
            or re.match(r"^(?:\\noindent\s*)?\\textbf\{Keywords:?\}", line)
        ):
            flush_prose()
            raw_blocks.append((i, i, "other", ""))
            continue
        if re.match(r"^\\label\{[^}]*\}$", line):
            continue

        if not curr_lines:
            curr_start = i
        curr_end = i
        curr_lines.append(line)

    flush_prose()
    return _merge_prose_blocks(raw_blocks)


def extract_md_paragraphs(lines: list[str]) -> list[tuple[int, int, str]]:
    """Extract (start_line, end_line, text) for prose paragraphs in Markdown/Quarto."""
    in_fence = False
    in_yaml = False
    in_math = False
    in_declarations = False
    raw_blocks: list[tuple[int, int, str, str]] = []
    curr_lines: list[str] = []
    curr_start = 1
    curr_end = 1

    def flush_prose() -> None:
        nonlocal curr_lines
        if curr_lines:
            raw_blocks.append((curr_start, curr_end, "prose", " ".join(curr_lines)))
            curr_lines = []

    for i, raw in enumerate(lines, 1):
        s = raw.strip()
        if i == 1 and s == "---":
            in_yaml = True
            continue
        if in_yaml:
            if s in {"---", "..."}:
                in_yaml = False
            continue
        if re.match(r"^(```|~~~)", s):
            flush_prose()
            in_fence = not in_fence
            raw_blocks.append((i, i, "other", ""))
            continue
        if in_fence:
            continue

        if s.startswith("$$") and (s == "$$" or not s.endswith("$$")):
            flush_prose()
            in_math = not in_math
            raw_blocks.append((i, i, "eq", "." if EQ_END_PERIOD_RE.search(s) else ""))
            continue
        if in_math:
            if EQ_END_PERIOD_RE.search(s):
                raw_blocks.append((i, i, "eq", "."))
            if s.endswith("$$"):
                in_math = False
            continue
        if s.startswith("$$") and s.endswith("$$") and len(s) >= 4:
            flush_prose()
            raw_blocks.append((i, i, "eq", "." if EQ_END_PERIOD_RE.search(s) else ""))
            continue

        if s.startswith("#"):
            flush_prose()
            if re.search(
                r"(?:Declarations|Statements|Acknowledgements|Acknowledgments|"
                r"Author Contributions|Data Availability|Code Availability|References|Bibliography)",
                s,
                re.IGNORECASE,
            ):
                in_declarations = True
            elif re.match(r"^#+\s+(?:\d+\.?|Appendix)\b", s, re.IGNORECASE):
                in_declarations = False
            raw_blocks.append((i, i, "other", ""))
            continue
        if in_declarations:
            continue

        if not s:
            flush_prose()
            continue

        if re.match(r"^(?:[-*+]|\d+[.)])\s+", s):
            flush_prose()
            raw_blocks.append((i, i, "list", ""))
            continue

        if (
            s.startswith(("|", "![", "<!--", ">", ": "))
            or re.match(r"^(?:---|___|\*\*\*)\s*$", s)
            or re.match(r"^\*(?:Table|Figure)\s+\d+", s, re.IGNORECASE)
            or re.match(
                r"^\*\*(?:Keywords|Author Contributions|Data Availability|Code Availability|"
                r"Funding|Conflict of Interest|Ethics|Acknowledgements|Note|Source)[:.]?\*\*",
                s,
                re.IGNORECASE,
            )
        ):
            flush_prose()
            raw_blocks.append((i, i, "other", ""))
            continue

        if not curr_lines:
            curr_start = i
        curr_end = i
        curr_lines.append(s)

    flush_prose()
    return _merge_prose_blocks(raw_blocks)


def should_check_paragraphs(path: Path) -> bool:
    """Return True if `path` is a manuscript file subject to the paragraph-length rule."""
    if path.name.lower() in NON_MANUSCRIPT_NAMES:
        return False
    if any(part.lower() in NON_MANUSCRIPT_DIRS for part in path.parts):
        return False
    return True


def check_paragraphs(
    path: Path,
    lines: list[str],
    skipped: set[int],
    min_sentences: int = 3,
    max_sentences: int = 8,
) -> list[Issue]:
    if (min_sentences <= 0 and max_sentences <= 0) or not should_check_paragraphs(path):
        return []
    suffix = path.suffix.lower()
    if suffix == ".tex":
        paras = extract_tex_paragraphs(lines)
    else:
        paras = extract_md_paragraphs(lines)

    issues: list[Issue] = []
    for start_ln, end_ln, text in paras:
        if any(ln in skipped for ln in range(start_ln, end_ln + 1)):
            continue
        n_sents = count_sentences(text)
        if min_sentences > 0 and n_sents < min_sentences:
            issues.append(
                Issue(
                    path=path,
                    line_no=start_ln,
                    col=1,
                    rule="short-paragraph",
                    severity="error",
                    snippet=text.strip()[:110],
                    message=f"Paragraph has {n_sents} sentence(s); minimum is {min_sentences}.",
                )
            )
        elif max_sentences > 0 and n_sents > max_sentences:
            issues.append(
                Issue(
                    path=path,
                    line_no=start_ln,
                    col=1,
                    rule="long-paragraph",
                    severity="error",
                    snippet=text.strip()[:110],
                    message=f"Paragraph has {n_sents} sentences; maximum is {max_sentences}.",
                )
            )
    return issues


def check_file(
    path: Path,
    data_plural: str = "off",
    min_sentences: int = 3,
    max_sentences: int = 8,
) -> list[Issue]:
    suffix = path.suffix.lower()
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError) as exc:
        print(f"skipped {path}: {exc}", file=sys.stderr)
        return []

    lines = text.splitlines()
    masked = mask_code_regions(lines, suffix)
    rules = build_rules(suffix, data_plural)
    skipped = suppressed_lines(lines)
    issues: list[Issue] = []

    for i, (original, line) in enumerate(zip(lines, masked), start=1):
        if i in skipped:
            continue
        for rule in rules:
            for m in rule.pattern.finditer(line):
                issues.append(
                    Issue(
                        path=path,
                        line_no=i,
                        col=m.start() + 1,
                        rule=rule.name,
                        severity=rule.severity,
                        snippet=original.strip()[:110],
                        message=rule.message,
                    )
                )

        # General -ize/-yze sweep, minus the allowlist and words already caught.
        for m in IZE_SWEEP.finditer(line):
            word = m.group(0)
            if word.lower() in IZE_ALLOWLIST:
                continue
            if word.lower().startswith(("utilis", "utiliz")):
                continue  # already reported by the utilise rule
            if word.lower() in AMERICAN_SPELLINGS:
                continue  # already reported by the curated-list rule
            british = re.sub(r"yz", "ys", re.sub(r"iz", "is", word))
            issues.append(
                Issue(
                    path=path,
                    line_no=i,
                    col=m.start() + 1,
                    rule="us-spelling-ize",
                    severity="error",
                    snippet=original.strip()[:110],
                    message=f"'-ize/-yze' spelling '{word}'. Use '{british}'.",
                )
            )

    issues.extend(check_paragraphs(path, lines, skipped, min_sentences, max_sentences))
    return issues


def gather_files(targets: list[str], walk: bool) -> list[Path]:
    found: list[Path] = []
    for t in targets:
        p = Path(t)
        if p.is_dir():
            if not walk:
                print(f"{p} is a directory. Pass --all to walk it.", file=sys.stderr)
                continue
            for child in sorted(p.rglob("*")):
                if any(part in SKIP_DIR_NAMES for part in child.parts):
                    continue
                if child.is_file() and child.suffix.lower() in PROSE_SUFFIXES:
                    found.append(child)
        elif p.is_file():
            found.append(p)
        else:
            print(f"not found: {p}", file=sys.stderr)
    return found


def main() -> int:
    ap = argparse.ArgumentParser(description="House-style checker for academic manuscripts.")
    ap.add_argument("targets", nargs="+", help="files or directories to check")
    ap.add_argument("--all", action="store_true", help="walk directories for prose files")
    ap.add_argument("--quiet", action="store_true", help="suppress output, use the exit code only")
    ap.add_argument("--warnings-as-errors", action="store_true",
                    help="treat warnings as failures too")
    ap.add_argument("--data-plural", choices=["off", "warn", "error"], default="off",
                    help="flag 'data is/was'. Journals differ, so follow the landmark "
                         "paper chosen in Phase 5 (default: off)")
    ap.add_argument("--min-sentences", type=int, default=3,
                    help="minimum number of sentences per manuscript paragraph (default: 3; 0 to disable)")
    ap.add_argument("--max-sentences", type=int, default=8,
                    help="maximum number of sentences per manuscript paragraph (default: 8; 0 to disable)")
    args = ap.parse_args()

    files = gather_files(args.targets, args.all)
    if not files:
        print("No readable prose files to check.", file=sys.stderr)
        return 2

    all_issues: list[Issue] = []
    for f in files:
        all_issues.extend(check_file(f, args.data_plural, args.min_sentences, args.max_sentences))

    errors = [i for i in all_issues if i.severity == "error"]
    warnings = [i for i in all_issues if i.severity == "warning"]

    if not args.quiet:
        if not all_issues:
            print(f"Clean. Checked {len(files)} file(s), no house-style issues found.")
        else:
            current: Path | None = None
            for issue in sorted(all_issues, key=lambda x: (str(x.path), x.line_no, x.col)):
                if issue.path != current:
                    current = issue.path
                    print(f"\n{issue.path}")
                tag = "ERROR  " if issue.severity == "error" else "warning"
                print(f"  {tag} {issue.line_no}:{issue.col}  [{issue.rule}] {issue.message}")
                print(f"           {issue.snippet}")

            print(
                f"\nChecked {len(files)} file(s): "
                f"{len(errors)} error(s), {len(warnings)} warning(s)."
            )

    if errors:
        return 1
    if warnings and args.warnings_as_errors:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
