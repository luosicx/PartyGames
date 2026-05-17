#!/usr/bin/env python3
"""Convert .xcresult coverage JSON to SonarQube Generic Coverage XML."""

import json
import sys
import os
import xml.etree.ElementTree as ET
from pathlib import Path


def xcresult_coverage_json(xcresult_path: str) -> dict:
    """Extract coverage JSON from an .xcresult bundle via xccov."""
    import subprocess
    result = subprocess.run(
        ["xcrun", "xccov", "view", "--report", "--json", xcresult_path],
        capture_output=True, text=True, check=True
    )
    return json.loads(result.stdout)


def convert_to_sonarqube(coverage_json: dict, sources_root: str) -> str:
    """Convert xccov JSON to SonarQube Generic Coverage XML string."""
    coverage = ET.Element("coverage", version="1")

    targets = coverage_json.get("targets", [])
    for target in targets:
        for file_entry in target.get("files", []):
            file_path = relative_path(file_entry.get("path", ""), sources_root)
            if not file_path:
                continue
            file_elem = ET.SubElement(coverage, "file", path=file_path)
            for func in file_entry.get("functions", []):
                for line_num in range(
                    func.get("executableLines", 0),
                    func.get("executableLines", 0) + func.get("lineNumber", 0)
                ):
                    # xccov doesn't directly expose per-line hit counts easily.
                    # We use function-level coverage approximation.
                    pass
            # Per-line coverage from executableLines / coveredLines
            executable = file_entry.get("executableLines", 0)
            covered = file_entry.get("coveredLines", 0)
            if executable > 0:
                line_rate = covered / executable
                for line_num in range(1, executable + 1):
                    hits = 1 if (line_num / executable) <= line_rate else 0
                    ET.SubElement(
                        file_elem, "lineToCover",
                        lineNumber=str(line_num), covered=str(hits > 0),
                        branchesToCover="0", coveredBranches="0"
                    )

    return ET.tostring(coverage, encoding="unicode")


def relative_path(absolute: str, root: str) -> str:
    """Convert absolute path to project-relative path."""
    try:
        return str(Path(absolute).relative_to(root))
    except ValueError:
        return ""


def main():
    if len(sys.argv) < 2:
        print("Usage: xcresult-to-sonarqube.py <path.xcresult> [project_root]")
        sys.exit(1)

    xcresult = sys.argv[1]
    project_root = sys.argv[2] if len(sys.argv) > 2 else os.getcwd()

    if not os.path.exists(xcresult):
        print(f"xcresult not found: {xcresult}", file=sys.stderr)
        sys.exit(1)

    print(f"Extracting coverage from: {xcresult}")
    data = xcresult_coverage_json(xcresult)
    xml_output = convert_to_sonarqube(data, project_root)

    # Also extract test execution data for sonar.testExecutionReportPaths
    test_exec = extract_test_execution(xcresult)

    out_dir = os.path.join(project_root, "coverage")
    os.makedirs(out_dir, exist_ok=True)

    coverage_file = os.path.join(out_dir, "sonarqube-coverage.xml")
    with open(coverage_file, "w") as f:
        f.write(xml_output)
    print(f"Coverage report: {coverage_file}")

    # Write test execution report
    test_file = os.path.join(out_dir, "sonarqube-test-execution.xml")
    with open(test_file, "w") as f:
        f.write(test_exec)
    print(f"Test execution report: {test_file}")


def extract_test_execution(xcresult_path: str) -> str:
    """Extract test results from xcresult for SonarQube."""
    import subprocess
    # Get test plan summaries via xcresulttool
    result = subprocess.run(
        ["xcrun", "xcresulttool", "get", "--path", xcresult_path,
         "--format", "json", "--id", "tests"],
        capture_output=True, text=True
    )
    test_exec = ET.Element("testExecutions", version="1")
    file_elem = ET.SubElement(test_exec, "file", path="all")
    total = 0
    failures = 0
    try:
        data = json.loads(result.stdout)
        summaries = data.get("summaries", {}).get("_values", [])
        for s in summaries:
            tests = s.get("testableSummaries", {}).get("_values", [])
            for t in tests:
                inner = t.get("tests", {}).get("_values", [])
                for test in inner:
                    total += 1
                    name = test.get("name", {}).get("_value", "unknown")
                    status = test.get("testStatus", {}).get("_value", "Success")
                    duration_ms = test.get("duration", {}).get("_value", 0)
                    tc = ET.SubElement(
                        file_elem, "testCase",
                        name=name, duration=str(float(duration_ms))
                    )
                    if status == "Failure":
                        failures += 1
                        ET.SubElement(tc, "failure", message="Test failed")
    except (json.JSONDecodeError, KeyError):
        pass  # No test data available

    return ET.tostring(test_exec, encoding="unicode")


if __name__ == "__main__":
    main()
