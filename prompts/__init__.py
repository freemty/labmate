"""Versioned prompt template loader.

Convention: prompts/{component}/_v{NN}.md
"""
from __future__ import annotations
import re
from pathlib import Path

_PROMPTS_DIR = Path(__file__).parent


def load_prompt(
    name: str,
    version: int | None = None,
    prompts_dir: str | None = None,
) -> str:
    """Load a prompt template by component name and optional version.

    Args:
        name: Component name (directory under prompts/)
        version: Specific version number. If None, loads latest.
        prompts_dir: Override prompts directory (for testing).

    Returns:
        Prompt template content as string.

    Raises:
        FileNotFoundError: If component or version doesn't exist.
    """
    base = Path(prompts_dir) if prompts_dir else _PROMPTS_DIR
    comp_dir = base / name

    if not comp_dir.is_dir():
        raise FileNotFoundError(f"Prompt component '{name}' not found at {comp_dir}")

    version_files = sorted(
        [f for f in comp_dir.iterdir() if re.match(r"_v\d+\.md$", f.name)],
        key=lambda f: int(re.search(r"_v(\d+)", f.name).group(1)),
    )

    if not version_files:
        raise FileNotFoundError(f"No version files found in {comp_dir}")

    if version is not None:
        target = comp_dir / f"_v{version:02d}.md"
        if not target.exists():
            raise FileNotFoundError(f"Version {version} not found: {target}")
        return target.read_text()

    return version_files[-1].read_text()
