"""Analysis viewer — Flask server skeleton.

Run: python viewer/app.py
Customize: viz-frontend agent builds domain-specific views here.
"""
from __future__ import annotations
from pathlib import Path

from flask import Flask, send_from_directory, jsonify

app = Flask(__name__, static_folder="static")
PROJECT_ROOT = Path(__file__).parent.parent


@app.route("/")
def index():
    return send_from_directory(app.static_folder, "index.html")


@app.route("/api/experiments")
def list_experiments():
    """List all experiments with basic metadata."""
    exp_dir = PROJECT_ROOT / "exp"
    if not exp_dir.is_dir():
        return jsonify([])

    experiments = []
    for d in sorted(exp_dir.iterdir()):
        if d.is_dir() and d.name.startswith("exp"):
            experiments.append({
                "id": d.name,
                "has_readme": (d / "README.md").exists(),
                "has_results": (d / "results" / "runs.log").exists(),
            })
    return jsonify(experiments)


if __name__ == "__main__":
    app.run(debug=True, port=5001)
