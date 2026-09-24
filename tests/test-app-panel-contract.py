#!/usr/bin/env python3
"""Static contract checks for the L2P Single Code Ocean adapter."""

import json
import pathlib
import re


ROOT = pathlib.Path(__file__).resolve().parents[1]


def reject_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        assert key not in result, f"Duplicate JSON key: {key}"
        result[key] = value
    return result


PANEL = json.loads(
    (ROOT / ".codeocean" / "app-panel.json").read_text(),
    object_pairs_hook=reject_duplicate_keys,
)
MAIN = (ROOT / "code" / "main.R").read_text()


def parameters_by_name():
    parameters = PANEL.get("parameters", [])
    names = [parameter.get("param_name") for parameter in parameters]
    assert all(names), "Every panel parameter must define param_name"
    assert len(names) == len(set(names)), "Panel param_name values must be unique"
    return {parameter["param_name"]: parameter for parameter in parameters}


parameters = parameters_by_name()
cli_flags = set(re.findall(r'make_option\(\s*"--([a-z0-9_]+)"', MAIN))
cli_flags.update(re.findall(r'^\s*"--([a-z0-9_]+)",?\s*$', MAIN, re.MULTILINE))
assert set(parameters) == cli_flags, (
    f"Panel/CLI controls differ: panel-only={sorted(set(parameters) - cli_flags)}; "
    f"CLI-only={sorted(cli_flags - set(parameters))}"
)

# Mouse is the one intentional scientific-default override: the attached demo
# is mouse. Input-mode selection is deployment-only and has no canonical peer.
expected_defaults = {
    "species": "Mouse",
    "collections_to_include": "GO,REACTOME,KEGG",
    "select_by_rank": "FALSE",
    "select_top_percentage_of_genes": "TRUE",
    "select_top_genes": "500",
    "significance_threshold": "0.05",
    "fold_change_threshold": "1.2",
    "minimum_number_of_deg_genes": "50",
    "minimum_pathway_hit_count": "5",
    "p_value_threshold_for_output": "0.05",
    "number_of_pathways_to_plot": "20",
    "pathway_axis_label_max_length": "50",
    "pathway_axis_label_font_size": "15",
    "x_axis_title_font_size": "20",
    "y_axis_title_font_size": "20",
    "x_axis_tick_font_size": "15",
    "export_plot_width": "12",
    "export_plot_height": "12",
}
for name, expected in expected_defaults.items():
    observed = str(parameters[name].get("default_value"))
    assert observed == expected, f"{name}: expected default {expected}, found {observed}"

category_names = {category["id"]: category["name"] for category in PANEL["categories"]}
assert category_names["basic"] == "Main Settings"
for category_id, category_name in category_names.items():
    if category_id != "basic":
        assert category_name.startswith("Advanced:"), (
            f"Non-primary category {category_id} must be explicitly labeled Advanced"
        )
assert parameters["gene_names_column"]["category"] == "columns"

print("L2P Single app-panel contract checks passed")
