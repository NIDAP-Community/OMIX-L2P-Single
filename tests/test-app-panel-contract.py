#!/usr/bin/env python3
"""Audit the L2P Single Code Ocean adapter against the reviewed OMIX schema."""

from __future__ import annotations

import copy
import hashlib
import json
import pathlib
import re


ROOT = pathlib.Path(__file__).resolve().parents[1]
CANONICAL_COMMIT = "5caab82a6dc89c20a30f4cf3826618620b1daf0f"
SCIENTIFIC_SHA256 = "f24c57751dcbda394cdf222bdf46892b6f463f98fb678d07234e921fa0c02054"
SCHEMA_SHA256 = "ff40848d376cdf9b5bb406a478a689b7398387752e8f0e2efbfb1595f4f2a1e0"


def control(
    name,
    r_type,
    panel_type="text",
    value_type="string",
    default=None,
    choices=None,
    panel_default=None,
):
    return {
        "name": name,
        "r_type": r_type,
        "panel_type": panel_type,
        "value_type": value_type,
        "default": default,
        "panel_default": default if panel_default is None else panel_default,
        "choices": choices or [],
    }


# Canonical public/advanced order from interface version 1. Mouse and B-A are
# reviewed deployment presets for the attached demonstration DEG table.
CONTRACT = [
    control("deg_table", "character", "file"),
    control("custom_pathways", "character", "file"),
    control("comparison", "character", panel_default="B-A"),
    control("comparisons", "character"),
    control("species", "character", "list", default="Mouse", choices=["Human", "Mouse", "Macaque", "Rat", "Zebrafish", "Rabbit", "Drosophila"]),
    control("collections_to_include", "character", default="GO,REACTOME,KEGG"),
    control("gene_names_column", "character"),
    control("t_statistic_column", "character"),
    control("significance_column", "character"),
    control("fold_change_column", "character"),
    control("t_statistic_suffix", "character", default="_tstat"),
    control("significance_suffix", "character", default="_pval"),
    control("fold_change_suffix", "character", default="_FC"),
    control("select_by_rank", "character", value_type="boolean", default="FALSE"),
    control("select_top_percentage_of_genes", "character", value_type="boolean", default="TRUE"),
    control("select_top_genes", "integer", value_type="number", default=500),
    control("significance_threshold", "double", value_type="number", default=0.05),
    control("fold_change_threshold", "double", value_type="number", default=1.2),
    control("minimum_number_of_deg_genes", "integer", value_type="number", default=50),
    control("minimum_pathway_hit_count", "integer", value_type="number", default=5),
    control("p_value_threshold_for_output", "double", value_type="number", default=0.05),
    control("use_built_in_gene_universe", "character", value_type="boolean", default="FALSE"),
    control("use_fdr_p_values", "character", value_type="boolean", default="FALSE"),
    control("custom_pathway_name_column", "character", default="gene_set_name"),
    control("custom_pathway_gene_column", "character", default="gene_symbol"),
    control("number_of_pathways_to_plot", "integer", value_type="number", default=20),
    control("pathway_axis_label_max_length", "integer", value_type="number", default=50),
    control("pathway_axis_label_font_size", "integer", value_type="number", default=15),
    control("x_axis_title_font_size", "integer", value_type="number", default=20),
    control("y_axis_title_font_size", "integer", value_type="number", default=20),
    control("x_axis_tick_font_size", "integer", value_type="number", default=15),
    control("plot_top_pathways_up", "character", value_type="boolean", default="TRUE"),
    control("pathways_to_use_up", "character"),
    control("plot_top_pathways_down", "character", value_type="boolean", default="TRUE"),
    control("pathways_to_use_down", "character"),
    control("sort_bubble_plot_by", "character", "list", default="percent gene hits per pathway", choices=["percent gene hits per pathway", "Fisher's Exact pval", "fdr corrected pval", "enrichment score", "number of hits"]),
    control("plot_bubble_size", "character", "list", default="number of hits", choices=["number of hits", "percent gene hits per pathway", "enrichment score", "Fisher's Exact pval", "fdr corrected pval"]),
    control("plot_bubble_color", "character", "list", default="Fisher's Exact pval", choices=["Fisher's Exact pval", "fdr corrected pval", "percent gene hits per pathway", "number of hits", "enrichment score"]),
    control("bubble_colors", "character", "list", default="blues", choices=["blues", "reds", "blue to red"]),
    control("color_for_bar", "character", "list", default="GreentoBlue", choices=["Blue", "Green", "Orange", "Grey", "Red", "Purple", "GreentoBlue", "OrangetoRed", "YellowOrangeRed"]),
    control("export_plot_width", "double", value_type="number", default=12),
    control("export_plot_height", "double", value_type="number", default=12),
]


def reject_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise AssertionError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def comparable(value):
    if value is None or value == "":
        return None
    if isinstance(value, (int, float)):
        return float(value)
    text = str(value).strip()
    if re.fullmatch(r"[-+]?(?:\d+(?:\.\d*)?|\.\d+)", text):
        return float(text)
    return text


def parse_r_options(text):
    pattern = re.compile(
        r'make_option\(\s*"--(?P<name>[A-Za-z0-9_]+)"\s*,\s*'
        r'type\s*=\s*"(?P<type>[A-Za-z]+)"\s*,\s*'
        r'default\s*=\s*(?P<default>NULL|[-+]?\d+(?:\.\d+)?|"[^"]*")',
        re.DOTALL,
    )
    values = []
    for match in pattern.finditer(text):
        raw = match.group("default")
        if raw == "NULL":
            default = None
        elif raw.startswith('"'):
            default = raw[1:-1]
        else:
            default = float(raw)
        values.append({"name": match.group("name"), "type": match.group("type"), "default": default})
    return values


def audit(panel, main_text, source_text):
    findings = []
    expected_names = [item["name"] for item in CONTRACT]
    parameters = panel.get("parameters", [])
    panel_names = [item.get("param_name") for item in parameters]

    if panel.get("named_parameters") is not True:
        findings.append("named_parameters must be true")
    if any(name is None for name in panel_names):
        findings.append("every App Panel control must define param_name")
    if len(panel_names) != len(set(panel_names)):
        findings.append("duplicate App Panel param_name values")
    missing = [name for name in expected_names if name not in panel_names]
    extra = [name for name in panel_names if name not in expected_names]
    if missing:
        findings.append("missing App Panel controls: " + ", ".join(missing))
    if extra:
        findings.append("extra App Panel controls: " + ", ".join(map(str, extra)))
    if panel_names != expected_names:
        findings.append("App Panel control order differs from canonical schema")

    panel_by_name = {item.get("param_name"): item for item in parameters}
    for expected in CONTRACT:
        observed = panel_by_name.get(expected["name"])
        if observed is None:
            continue
        if observed.get("type") != expected["panel_type"]:
            findings.append(f"{expected['name']}: App Panel type mismatch")
        if observed.get("value_type") != expected["value_type"]:
            findings.append(f"{expected['name']}: App Panel value_type mismatch")
        if comparable(observed.get("default_value")) != comparable(expected["panel_default"]):
            findings.append(f"{expected['name']}: App Panel default mismatch")
        if observed.get("extra_data", []) != expected["choices"]:
            findings.append(f"{expected['name']}: App Panel choices mismatch")

    options = parse_r_options(main_text)
    option_names = [item["name"] for item in options]
    if option_names != expected_names:
        findings.append("adapter CLI controls are missing, extra, or out of canonical order")
    option_by_name = {item["name"]: item for item in options}
    for expected in CONTRACT:
        observed = option_by_name.get(expected["name"])
        if observed is None:
            continue
        if observed["type"] != expected["r_type"]:
            findings.append(f"{expected['name']}: adapter CLI type mismatch")
        if comparable(observed["default"]) != comparable(expected["default"]):
            findings.append(f"{expected['name']}: adapter CLI default mismatch")

    if "--deg_file" in main_text or '"param_name": "deg_file"' in json.dumps(panel):
        findings.append("deprecated deg_file control remains exposed")
    if 'source("functions/L2P_Analysis.R")' not in main_text:
        findings.append("adapter does not source the canonical scientific export")
    if 'source("adapter_io.R")' not in main_text:
        findings.append("adapter does not source adapter-owned input translation")
    if "resolve_l2p_comparisons(" not in main_text:
        findings.append("adapter does not use canonical blank-comparison resolution")
    if 'opt[["comparison"]]' not in main_text or 'opt[["comparisons"]]' not in main_text:
        findings.append("adapter comparison controls are vulnerable to partial matching")
    if "Batched Comparisons uses automatic comparison-prefixed columns" not in main_text:
        findings.append("batched exact-column overrides are not rejected")
    if CANONICAL_COMMIT not in source_text:
        findings.append("canonical source record is not pinned to the reviewed contract commit")
    if SCIENTIFIC_SHA256 not in source_text:
        findings.append("scientific export SHA-256 is absent from the source record")
    if SCHEMA_SHA256 not in source_text:
        findings.append("canonical schema SHA-256 is absent from the source record")
    if "Runtime digest | Pending" not in source_text:
        findings.append("runtime digest is not recorded honestly as pending")
    if "Named-parameter platform run | Pending" not in source_text:
        findings.append("Code Ocean validation is not recorded honestly as pending")
    if "mouse demonstration" not in source_text.lower():
        findings.append("Mouse demo default exception is not documented")
    if "`comparison` to `B-A`" not in source_text:
        findings.append("B-A mouse-demo comparison preset is not documented")
    if "codeocean/omix-r-pathway:r4.4.3-bioconductor3.20-v2" not in source_text:
        findings.append("OMIX Pathways v2 runtime tag is not recorded")

    scientific_path = ROOT / "code" / "functions" / "L2P_Analysis.R"
    digest = hashlib.sha256(scientific_path.read_bytes()).hexdigest()
    if digest != SCIENTIFIC_SHA256:
        findings.append("managed scientific export hash differs from canonical")
    function_files = sorted(path.name for path in (ROOT / "code" / "functions").glob("*.R"))
    if function_files != ["L2P_Analysis.R"]:
        findings.append("code/functions contains files outside the canonical R export")

    return findings


panel = json.loads(
    (ROOT / ".codeocean" / "app-panel.json").read_text(),
    object_pairs_hook=reject_duplicate_keys,
)
main_text = (ROOT / "code" / "main.R").read_text()
source_text = (ROOT / "OMIX_MODULE_SOURCE.md").read_text()

baseline = audit(panel, main_text, source_text)
assert baseline == [], "\n".join(baseline)

# Mutation checks prove that the audit fails for the regressions it is meant
# to guard rather than merely parsing the current files successfully.
missing_control = copy.deepcopy(panel)
missing_control["parameters"] = missing_control["parameters"][:-1]
assert any("missing App Panel controls" in item for item in audit(missing_control, main_text, source_text))

wrong_default = copy.deepcopy(panel)
wrong_default["parameters"][5]["default_value"] = "H"
assert any("collections_to_include: App Panel default mismatch" in item for item in audit(wrong_default, main_text, source_text))

wrong_choices = copy.deepcopy(panel)
wrong_choices["parameters"][4]["extra_data"] = list(reversed(wrong_choices["parameters"][4]["extra_data"]))
assert any("species: App Panel choices mismatch" in item for item in audit(wrong_choices, main_text, source_text))

wrong_cli = main_text.replace('"--comparison"', '"--comparison_old"', 1)
assert any("adapter CLI controls" in item for item in audit(panel, wrong_cli, source_text))

print("L2P Single adapter contract and mutation checks passed")
