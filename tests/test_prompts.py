import pytest
from pathlib import Path
from prompts import load_prompt


def test_load_prompt_finds_version(tmp_path):
    """Loads specific prompt version."""
    comp_dir = tmp_path / "summarize"
    comp_dir.mkdir()
    (comp_dir / "_v00.md").write_text("Summarize the following: {input}")
    (comp_dir / "_v01.md").write_text("Provide a concise summary: {input}")

    result = load_prompt("summarize", version=1, prompts_dir=str(tmp_path))
    assert "concise summary" in result


def test_load_prompt_latest_version(tmp_path):
    """Without version, loads the latest."""
    comp_dir = tmp_path / "summarize"
    comp_dir.mkdir()
    (comp_dir / "_v00.md").write_text("V0")
    (comp_dir / "_v01.md").write_text("V1")
    (comp_dir / "_v02.md").write_text("V2")

    result = load_prompt("summarize", prompts_dir=str(tmp_path))
    assert result == "V2"


def test_load_prompt_missing_component(tmp_path):
    """Raises FileNotFoundError for missing component."""
    with pytest.raises(FileNotFoundError):
        load_prompt("nonexistent", prompts_dir=str(tmp_path))


def test_load_prompt_missing_version(tmp_path):
    """Raises FileNotFoundError for missing version."""
    comp_dir = tmp_path / "summarize"
    comp_dir.mkdir()
    (comp_dir / "_v00.md").write_text("V0")

    with pytest.raises(FileNotFoundError):
        load_prompt("summarize", version=99, prompts_dir=str(tmp_path))
