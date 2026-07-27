#!/usr/bin/env python3

import argparse
import json
import logging
import sys
from pathlib import Path
from urllib.parse import urlparse, urljoin
from urllib.request import url2pathname

try:
    import jsonschema
    from jsonschema import Draft4Validator, Draft6Validator, Draft7Validator
    from jsonschema.validators import Draft201909Validator, Draft202012Validator
    import jsonschema.exceptions
except ImportError:
    sys.exit("ERROR: jsonschema not installed. Run: pip install jsonschema")

try:
    from referencing import Registry, Resource
    from referencing import exceptions as ref_exc
    import referencing.jsonschema as rjs

    _REFERENCING_AVAILABLE = True
except ImportError:
    _REFERENCING_AVAILABLE = False

DRAFT_MAP = {
    "4": Draft4Validator,
    "6": Draft6Validator,
    "7": Draft7Validator,
    "2019": Draft201909Validator,
    "2020": Draft202012Validator,
}
# Maps draft key → referencing specification constant (used in retrieve callback)
_DRAFT_SPEC_MAP = None  # populated lazily if referencing is available


def _get_draft_spec_map():
    global _DRAFT_SPEC_MAP
    if _DRAFT_SPEC_MAP is None and _REFERENCING_AVAILABLE:
        _DRAFT_SPEC_MAP = {
            "4": rjs.DRAFT4,
            "6": rjs.DRAFT6,
            "7": rjs.DRAFT7,
            "2019": rjs.DRAFT201909,
            "2020": rjs.DRAFT202012,
        }
    return _DRAFT_SPEC_MAP


# $schema URI fragments → draft key
SCHEMA_URI_HINTS = {
    "draft-04": "4",
    "draft-06": "6",
    "draft-07": "7",
    "draft/2019-09": "2019",
    "draft/2020-12": "2020",
}

STD_IM_PATH = Path(__file__).parent.parent.parent.parent.parent
STD_SCHEMA_PATH = STD_IM_PATH / "Model" / "im-standard-schema"
TOP_SCHEMAS = {"IM": STD_SCHEMA_PATH / "InformationModel" / "InformationModel-schema.json"
               }

assert STD_IM_PATH.is_dir(),f"Directory does not exist: {STD_IM_PATH}"
assert STD_SCHEMA_PATH.is_dir(),f"Directory does not exist: {STD_SCHEMA_PATH}"
for key,filepath in TOP_SCHEMAS.items():
    assert filepath.is_file(),f"File does not exist for schema {key}: {filepath}"

def load_json(path: Path, label: str="") -> object:
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        sys.exit(f"ERROR: Cannot read {label} '{path}': {e}")
    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        sys.exit(f"ERROR: {label} '{path}' is not valid JSON: {e}")


def check_schema(schema,
                 draft: str,
                 quiet: bool) -> object:
    """
    select a validator according to draft or the $schma in schema if no draft given
    checks validity of schema-file
    :param schema: json-schema-file
    :param draft: number of the draft to be used
    :param quiet: don't print any warnings
    :return: validator_cls: validator to be used to validate the json file
            draft_label: info about the chosen draft
    """
    # ── Select validator ──────────────────────────────────────────────────────
    validator_cls, draft_label = _pick_validator_class(schema=schema,
                                                       forced_draft=draft)

    # ── Validate schema itself (meta-validation) ──────────────────────────────
    try:
        validator_cls.check_schema(schema)
    except jsonschema.exceptions.SchemaError as e:
        if not quiet:
            print(f"WARNING: The schema itself has an issue: {e.message}\n")
            return None, draft_label
    return validator_cls, draft_label


def _detect_draft(schema: dict) -> str | None:
    uri = schema.get("$schema", "")
    for fragment, draft in SCHEMA_URI_HINTS.items():
        if fragment in uri:
            return draft
    return None


def _pick_validator_class(schema: dict, forced_draft: str | None):
    draft = forced_draft or _detect_draft(schema)
    if draft:
        cls = DRAFT_MAP.get(draft)
        if cls is None:
            sys.exit(f"ERROR: Unknown draft '{draft}'. Valid: {', '.join(DRAFT_MAP)}")
        return cls, draft
    # Fall back to the jsonschema default (currently Draft-202012)
    return Draft202012Validator, "2020"


def format_error(err: jsonschema.exceptions.ValidationError, index: int) -> str:
    path = " → ".join(str(p) for p in err.absolute_path) or "(root)"
    schema_path = " → ".join(str(p) for p in err.absolute_schema_path)
    lines = [
        f"  [{index}] Path      : {path}",
        f"       Schema path: {schema_path}",
        f"       Message    : {err.message}",
    ]
    if err.context:
        lines.append(f"       Sub-errors : {len(err.context)}")
    return "\n".join(lines)


def _make_local_registry(schema_dir: Path, draft: str):
    """
    Return a Registry with a retrieve callback that resolves relative $ref
    values against schema_dir.

    Resolution order for a ref URI passed to retrieve():
      1. Absolute file:// URI       → use path directly
      2. Relative path (incl. ../)  → resolve via urljoin against schema_dir's
                                      file:// URI, then normalise with resolve()
                                      This correctly handles ../sibling/x.json.

    Note: retrieve() receives only the file part of a $ref — the JSON Pointer
    fragment (#/foo/bar) is stripped by referencing before calling retrieve().
    """
    if not _REFERENCING_AVAILABLE:
        return None

    spec = _get_draft_spec_map().get(draft, rjs.DRAFT202012)
    # Base URI must end with "/" so urljoin treats it as a directory, not a file.
    base_uri = schema_dir.resolve().as_uri() + "/"

    def retrieve(uri: str) -> Resource:
        parsed = urlparse(uri)
        if parsed.scheme == "file":
            # Already absolute file URI — use directly.
            candidate = Path(url2pathname(parsed.path)).resolve()
        else:
            # Relative ref, possibly with ".." segments.
            # urljoin resolves ".." correctly against the base directory URI.
            absolute_uri = urljoin(base_uri, uri)
            candidate = Path(url2pathname(urlparse(absolute_uri).path)).resolve()

        if not candidate.exists():
            raise ref_exc.NoSuchResource(ref=uri)

        try:
            content = json.loads(candidate.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as e:
            raise ref_exc.NoSuchResource(ref=uri) from e

        return Resource.from_contents(content, default_specification=spec)

    return Registry(retrieve=retrieve)


def dovalidate(data, schema, draft: str=None, quiet: bool=True,
               schema_dir: Path=STD_SCHEMA_PATH):

    validator_cls, draft_label = check_schema(schema=schema,
                                              draft=draft,
                                              quiet=quiet)

    registry = _make_local_registry(schema_dir=schema_dir, draft=draft_label)

    # ── Build validator ───────────────────────────────────────────────────────
    validator_kwargs = {}
    if registry is not None:
        validator_kwargs["registry"] = registry
    # ── Validate data ─────────────────────────────────────────────────────────
    validator = validator_cls(schema=schema, **validator_kwargs)
    try:
        errors = [e for e in validator.iter_errors(data)]
    except Exception as exp:
        logging.warning("********Validator-Error in schema:\n"+json.dumps(schema)+"\n******")
        errors=[]
    errors=sorted(errors,key=lambda e: list(e.absolute_path))
    return errors,draft_label


def main(args=None):
    parser = argparse.ArgumentParser(
        description="""
validate_json.py — Validate a JSON file against a JSON Schema file.

Usage:
    python validate_json.py <json_file> <schema_file> [options]

Options:
    -v, --verbose       Show all validation errors (default: stop at first)
    -q, --quiet         Exit code only, no output
    --draft {4,6,7,2019,2020}
                        Force a specific JSON Schema draft validator.
                        Auto-detected from $schema if omitted.
                        default 2020
    -h, --help          Show this help message
    
""",
        add_help=True,
    )
    parser.add_argument("json_file", type=Path, help="Path to the JSON data file")
    parser.add_argument("schema_file", type=Path,
                        help="Path to the JSON Schema file. Abbreviation: IM for InformationModel, DM for DataModel, MM for MetaModel")

    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Collect and show ALL validation errors (default: stop at first)",
    )
    parser.add_argument(
        "-q", "--quiet",
        action="store_true",
        help="Suppress all output; communicate result via exit code only",
    )
    parser.add_argument(
        "-d", "--draft",
        choices=DRAFT_MAP.keys(),
        metavar="{" + ",".join(DRAFT_MAP) + "}",
        help="Force a specific JSON Schema draft (auto-detected from $schema if omitted, defaulted to 2020 if none found)",
    )
    args = parser.parse_args(args)

    jsoninputfile=args.json_file.resolve()
    if Path(args.schema_file).is_file():
        schemafile = args.schema_file.resolve()
    elif str(args.schema_file) in TOP_SCHEMAS:
        schemafile = TOP_SCHEMAS[str(args.schema_file)]
    else:
        if not args.quiet:
            print(f"ERROR: schema file not found: {args.schema_file}")
        sys.exit(2)

    # ── Load files ────────────────────────────────────────────────────────────
    data = load_json(jsoninputfile, "JSON data file")
    schema = load_json(schemafile, "JSON schema file")
    errors,draft_label=dovalidate(data=data,schema=schema,
                         draft=args.draft,
                         quiet=args.quiet,
                         schema_dir= schemafile.parent.parent)

    if not args.quiet:
        print(f"Validator  : JSON Schema Draft {draft_label}")
        print(f"Data file  : {args.json_file}")
        print(f"Schema file: {schemafile}")
        print()

    if args.verbose:
        if not errors:
            if not args.quiet:
                print("✓ VALID — no errors found.")
            sys.exit(0)
        if not args.quiet:
            print(f"✗ INVALID — {len(errors)} error(s) found:\n")
            for i, err in enumerate(errors, 1):
                print(format_error(err, i))
                print()
        sys.exit(1)
    else:
        if errors:
            if not args.quiet:
                print("✗ INVALID — first error:\n")
                print(format_error(errors[0], 1))
                print()
                print("Tip: use -v / --verbose to see all errors.")
            sys.exit(1)
        else:
            if not args.quiet:
                print("✓ VALID — no errors found.")
        sys.exit(0)
    return


if __name__ == "__main__":
    main()
