#!/usr/bin/env python3
"""
SonarCloud MCP Server — Drives code optimization directly from analysis results.

Tools:
  - sonarcloud_list_issues      List open issues (filter by severity, type, file)
  - sonarcloud_get_issue        Get full details for a single issue
  - sonarcloud_get_quality_gate Quality gate status (Pass/Fail + conditions)
  - sonarcloud_get_metrics      Project metrics (bugs, smells, coverage, debt)
  - sonarcloud_list_projects    List projects in the organization

Usage:
  SONARCLOUD_TOKEN=squ_xxx SONARCLOUD_ORG=myorg python3 sonarcloud-mcp.py
"""

import os
import json
import urllib.request
import urllib.error
import urllib.parse
import base64
from typing import Any

from mcp.server.fastmcp import FastMCP

SONARCLOUD_API = "https://sonarcloud.io/api"

mcp = FastMCP(
    name="SonarCloud",
    instructions="""
SonarCloud code analysis MCP server.
Before calling any tool, ensure SONARCLOUD_ORG is set to the correct organization key.
Default project is luosicx_PartyGames — override with the `projectKey` parameter.
""",
)


def _api(path: str, params: dict[str, Any] | None = None) -> dict:
    """Call SonarCloud API with token auth."""
    token = os.environ.get("SONARCLOUD_TOKEN", "")
    if not token:
        raise RuntimeError("SONARCLOUD_TOKEN env var not set")

    auth = base64.b64encode(f"{token}:".encode()).decode()
    url = f"{SONARCLOUD_API}/{path.lstrip('/')}"
    if params:
        qs = urllib.parse.urlencode({k: v for k, v in params.items() if v is not None})
        url = f"{url}?{qs}"

    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Basic {auth}")
    req.add_header("Accept", "application/json")

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode()[:500]
        raise RuntimeError(f"SonarCloud API error {e.code}: {body}") from e


# ─────────────────────────────────────────────────────────────
# Tools
# ─────────────────────────────────────────────────────────────

@mcp.tool()
def sonarcloud_list_issues(
    projectKey: str = "luosicx_PartyGames",
    severities: str | None = None,
    types: str | None = None,
    statuses: str = "OPEN",
    pageSize: int = 50,
) -> str:
    """
    List SonarCloud issues for a project.

    Args:
        projectKey: SonarCloud project key (default: luosicx_PartyGames)
        severities: Comma-separated, e.g. "MAJOR,CRITICAL,BLOCKER"
        types: Comma-separated, e.g. "BUG,VULNERABILITY,CODE_SMELL"
        statuses: Issue statuses (default: OPEN)
        pageSize: Results per page (max 500)

    Returns:
        JSON string with issues: key, rule, severity, type, message, component, line, debt
    """
    params: dict[str, Any] = {
        "projectKeys": projectKey,
        "statuses": statuses,
        "ps": min(pageSize, 500),
    }
    if severities:
        params["severities"] = severities
    if types:
        params["types"] = types

    data = _api("issues/search", params)
    issues = []
    for i in data.get("issues", []):
        issues.append({
            "key": i["key"],
            "rule": i["rule"],
            "severity": i.get("severity", "?"),
            "type": i.get("type", "?"),
            "message": i.get("message", ""),
            "component": i["component"].split(":")[-1],
            "line": i.get("line", "?"),
            "debt": i.get("debt", "?"),
            "effort": i.get("effort", "?"),
        })

    org = os.environ.get("SONARCLOUD_ORG", "")
    return json.dumps({
        "total": data.get("total", 0),
        "paging": data.get("paging", {}),
        "dashboard_url": f"https://sonarcloud.io/project/issues?id={projectKey}&organization={org}",
        "issues": issues,
    }, indent=2, ensure_ascii=False)


@mcp.tool()
def sonarcloud_get_issue(
    issueKey: str,
) -> str:
    """
    Get full details for a single SonarCloud issue, including rule description.

    Args:
        issueKey: The issue key, e.g. "AZ42SFf3Cu9-4Mh-VXSJ"

    Returns:
        JSON string with issue details + rule description + remediation guidance
    """
    # Get issue detail
    data = _api("issues/search", {"issues": issueKey, "ps": 1})
    issues = data.get("issues", [])
    if not issues:
        return json.dumps({"error": f"Issue {issueKey} not found"}, indent=2)

    issue = issues[0]

    # Get rule details
    rule_key = issue["rule"]
    rule_data = _api("rules/show", {"key": rule_key})

    return json.dumps({
        "key": issue["key"],
        "rule": issue["rule"],
        "rule_name": rule_data.get("rule", {}).get("name", ""),
        "severity": issue.get("severity", "?"),
        "type": issue.get("type", "?"),
        "message": issue.get("message", ""),
        "component": issue["component"].split(":")[-1],
        "line": issue.get("line", "?"),
        "textRange": issue.get("textRange", {}),
        "debt": issue.get("debt", "?"),
        "effort": issue.get("effort", "?"),
        "rule_description": rule_data.get("rule", {}).get("htmlDesc", "")[:2000],
        "rule_severity": rule_data.get("rule", {}).get("severity", ""),
    }, indent=2, ensure_ascii=False)


@mcp.tool()
def sonarcloud_get_quality_gate(
    projectKey: str = "luosicx_PartyGames",
) -> str:
    """
    Get quality gate status for a project (Pass/Fail + per-condition details).

    Args:
        projectKey: SonarCloud project key

    Returns:
        JSON string with gate status, conditions, and metrics
    """
    data = _api("qualitygates/project_status", {"projectKey": projectKey})
    status = data.get("projectStatus", {})

    conditions = []
    for c in status.get("conditions", []):
        conditions.append({
            "metric": c.get("metricKey", "?"),
            "op": c.get("comparator", "?"),
            "actual": c.get("actualValue", "?"),
            "error_threshold": c.get("errorThreshold", "?"),
            "status": c.get("status", "?"),
        })

    org = os.environ.get("SONARCLOUD_ORG", "")
    return json.dumps({
        "status": status.get("status", "UNKNOWN"),
        "ignoredConditions": status.get("ignoredConditions", False),
        "conditions": conditions,
        "dashboard_url": f"https://sonarcloud.io/dashboard?id={projectKey}&organization={org}",
    }, indent=2, ensure_ascii=False)


@mcp.tool()
def sonarcloud_get_metrics(
    projectKey: str = "luosicx_PartyGames",
    metricKeys: str | None = None,
) -> str:
    """
    Get project metrics: bugs, vulnerabilities, code smells, coverage, duplications, debt.

    Args:
        projectKey: SonarCloud project key
        metricKeys: Comma-separated metric keys (default: all key metrics).
                    Common keys: bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density,
                    sqale_debt_ratio,ncloc,complexity,cognitive_complexity,reliability_rating,
                    security_rating,sqale_rating

    Returns:
        JSON string with metric name → value pairs
    """
    if metricKeys is None:
        metricKeys = (
            "bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density,"
            "sqale_debt_ratio,ncloc,complexity,cognitive_complexity,"
            "reliability_rating,security_rating,sqale_rating,"
            "new_bugs,new_vulnerabilities,new_code_smells"
        )

    data = _api("measures/component", {
        "component": projectKey,
        "metricKeys": metricKeys,
    })

    measures = []
    for m in data.get("component", {}).get("measures", []):
        measures.append({
            "metric": m["metric"],
            "value": m.get("value", "?"),
            "bestValue": m.get("bestValue", False),
        })

    org = os.environ.get("SONARCLOUD_ORG", "")
    return json.dumps({
        "project": projectKey,
        "dashboard_url": f"https://sonarcloud.io/dashboard?id={projectKey}&organization={org}",
        "measures": measures,
    }, indent=2, ensure_ascii=False)


@mcp.tool()
def sonarcloud_list_projects(
    search: str | None = None,
) -> str:
    """
    List projects in the configured SonarCloud organization.

    Args:
        search: Optional search term to filter projects by name/key

    Returns:
        JSON string with projects: key, name, visibility, lastAnalysisDate
    """
    org = os.environ.get("SONARCLOUD_ORG", "")
    if not org:
        return json.dumps({"error": "SONARCLOUD_ORG not set"}, indent=2)

    params: dict[str, Any] = {"organization": org}
    if search:
        params["search"] = search

    data = _api("projects/search", params)

    projects = []
    for p in data.get("components", []):
        projects.append({
            "key": p["key"],
            "name": p["name"],
            "visibility": p.get("visibility", "?"),
            "lastAnalysisDate": p.get("lastAnalysisDate", "?"),
        })

    return json.dumps({
        "total": data.get("paging", {}).get("total", 0),
        "organization": org,
        "projects": projects,
    }, indent=2, ensure_ascii=False)


# ─────────────────────────────────────────────────────────────
# Entry Point
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    # Validate config at startup
    token = os.environ.get("SONARCLOUD_TOKEN", "")
    org = os.environ.get("SONARCLOUD_ORG", "")
    if not token:
        print("[sonarcloud-mcp] WARNING: SONARCLOUD_TOKEN not set — all calls will fail", flush=True)
    if not org:
        print("[sonarcloud-mcp] WARNING: SONARCLOUD_ORG not set — project listing unavailable", flush=True)

    mcp.run(transport="stdio")
