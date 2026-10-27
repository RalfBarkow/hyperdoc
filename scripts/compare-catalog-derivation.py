#!/usr/bin/env python3
"""Show that hyperdoc-catalog is unchanged between two HyperDoc revisions, apart from HyperDoc's own source.

  compare-catalog-derivation.py FLAKE-REF-A FLAKE-REF-B SYSTEM EVIDENCE.json

Evaluates (does not build) packages.SYSTEM.hyperdoc-catalog at both flake references. HyperDoc's source store path
changes with any repository change, and the output path follows from it; both are replaced by placeholders. Every
other field of the two derivations, including every input derivation and every other source, must be equal.
"""
import json, subprocess, sys, time


def derivation(ref, system):
    out = subprocess.run(["nix", "derivation", "show", "--offline", f"{ref}#packages.{system}.hyperdoc-catalog"],
                         capture_output=True, check=True, text=True).stdout
    (path, drv), = json.loads(out).items()
    return path, drv


def normalised(drv, source):
    text = json.dumps(drv, sort_keys=True).replace(source, "<HYPERDOC-SOURCE>")
    for output in drv["outputs"].values():
        if "path" in output:
            text = text.replace(output["path"], "<OUT>")
    text = text.replace(drv["env"]["out"], "<OUT>")
    result = json.loads(text)
    result["inputSrcs"] = sorted(result["inputSrcs"])  # Nix lists them by store hash, which the placeholder hides
    return result


def main(a, b, system, evidence_path):
    started = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    path_a, drv_a = derivation(a, system)
    path_b, drv_b = derivation(b, system)
    only_a = sorted(set(drv_a["inputSrcs"]) - set(drv_b["inputSrcs"]))
    only_b = sorted(set(drv_b["inputSrcs"]) - set(drv_a["inputSrcs"]))
    same = (len(only_a) == len(only_b) <= 1 and drv_a["inputDrvs"] == drv_b["inputDrvs"]
            and normalised(drv_a, only_a[0] if only_a else "\0") == normalised(drv_b, only_b[0] if only_b else "\0"))
    evidence = {"kind": "hyperdoc-catalog-derivation-comparison", "evaluatedAtUTC": started, "system": system,
                "a": {"ref": a, "drv": path_a, "hyperdocSource": only_a}, "b": {"ref": b, "drv": path_b, "hyperdocSource": only_b},
                "inputDrvsEqual": drv_a["inputDrvs"] == drv_b["inputDrvs"],
                "equalExceptHyperDocSourceAndOutput": same, "built": False}
    with open(evidence_path, "w") as out:
        json.dump(evidence, out, indent=1)
    print(json.dumps(evidence, indent=1))
    return 0 if same else 1


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
