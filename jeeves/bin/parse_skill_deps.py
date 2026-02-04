#!/usr/bin/env python3
"""
Parse SKILL.md files to extract dependencies.

This script parses SKILL.md files and outputs their dependencies as JSON.
Skills are typically located in directories like:
- ~/.claude/skills/<name>/SKILL.md
- ~/.config/opencode/skills/<name>/SKILL.md
"""

import argparse
import json
import logging
import re
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional


def setup_logging(verbose: bool) -> None:
    """Configure logging based on verbosity level."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )


def discover_skill_files(skill_path: Path) -> List[Path]:
    """
    Discover SKILL.md files from a path.
    
    Args:
        skill_path: Path to a single SKILL.md file or directory containing skills
        
    Returns:
        List of Path objects pointing to SKILL.md files
        
    Raises:
        FileNotFoundError: If the path does not exist
        PermissionError: If the path is not readable
    """
    logger = logging.getLogger(__name__)
    
    if not skill_path.exists():
        raise FileNotFoundError(f"Path not found: {skill_path}")
    
    if not skill_path.is_dir():
        if skill_path.is_file() and skill_path.name == 'SKILL.md':
            logger.debug(f"Found single skill file: {skill_path}")
            return [skill_path]
        else:
            raise ValueError(f"Path is not a SKILL.md file or directory: {skill_path}")
    
    skill_files = []
    
    try:
        for skill_file in skill_path.rglob('SKILL.md'):
            if skill_file.is_file():
                skill_files.append(skill_file)
                logger.debug(f"Found skill file: {skill_file}")
    except PermissionError as e:
        raise PermissionError(f"Permission denied accessing {skill_path}: {e}")
    
    logger.info(f"Discovered {len(skill_files)} skill file(s)")
    return skill_files


def parse_skill_file(skill_path: Path) -> Dict[str, Any]:
    """
    Parse a single SKILL.md file to extract dependencies and metadata.
    
    Args:
        skill_path: Path to the SKILL.md file
        
    Returns:
        Dictionary containing skill metadata and dependencies
    """
    logger = logging.getLogger(__name__)
    logger.debug(f"Parsing skill file: {skill_path}")
    
    try:
        content = skill_path.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        content = skill_path.read_text(encoding='latin-1')
    except Exception as e:
        raise IOError(f"Failed to read {skill_path}: {e}")
    
    frontmatter = extract_frontmatter(content)

    dependencies = parse_dependencies_section(content)

    if not dependencies:
        dependencies = parse_installation_section(content)

    if not dependencies:
        dependencies = parse_inline_commands(content)

    return {
        'path': str(skill_path),
        'name': skill_path.parent.name,
        'frontmatter': frontmatter,
        'dependencies': dependencies
    }


def parse_all_skills(skill_files: List[Path]) -> Dict[str, Any]:
    """
    Parse multiple SKILL.md files and aggregate results.
    
    Args:
        skill_files: List of Path objects pointing to SKILL.md files
        
    Returns:
        Dictionary containing all skills and their dependencies
    """
    logger = logging.getLogger(__name__)
    logger.info(f"Parsing {len(skill_files)} skill file(s)")
    
    results = {
        'skills': [],
        'total_count': len(skill_files),
        'errors': []
    }
    
    for skill_file in skill_files:
        try:
            skill_data = parse_skill_file(skill_file)
            results['skills'].append(skill_data)
        except Exception as e:
            logger.error(f"Failed to parse {skill_file}: {e}")
            results['errors'].append({
                'path': str(skill_file),
                'error': str(e)
            })
    
    results['parsed_count'] = len(results['skills'])
    return results


def output_results(results: Dict[str, Any], output_path: Optional[Path] = None) -> None:
    """
    Output results as JSON to file or stdout.
    
    Args:
        results: Dictionary containing skill data
        output_path: Optional path to output file (stdout if None)
    """
    logger = logging.getLogger(__name__)
    json_output = json.dumps(results, indent=2)
    
    if output_path:
        try:
            output_path.write_text(json_output)
            logger.info(f"Results written to: {output_path}")
        except PermissionError:
            raise PermissionError(f"Permission denied writing to: {output_path}")
        except Exception as e:
            raise IOError(f"Failed to write output file: {e}")
    else:
        print(json_output)


def format_output(skills_data: list, output_path: Optional[str] = None) -> str:
    """
    Format skill dependencies into a comprehensive JSON structure.
    
    Args:
        skills_data: List of skill dicts with name, path, and dependencies
        output_path: Optional path to write JSON file
        
    Returns:
        JSON string formatted with the required schema
    """
    formatted_skills = []
    all_apt = set()
    all_pip = set()
    all_npm = set()
    skills_with_deps = 0
    
    for skill in skills_data:
        name = skill.get('name', '')
        path = skill.get('path', '')
        dependencies = skill.get('dependencies', [])
        
        apt_packages = []
        pip_packages = []
        npm_packages = []
        
        for dep in dependencies:
            manager = dep.get('manager', 'unknown')
            package_name = dep.get('package_name', '')
            
            if not package_name:
                continue
                
            if manager == 'apt':
                apt_packages.append(package_name)
                all_apt.add(package_name)
            elif manager == 'pip':
                pip_packages.append(package_name)
                all_pip.add(package_name)
            elif manager == 'npm':
                npm_packages.append(package_name)
                all_npm.add(package_name)
        
        if apt_packages or pip_packages or npm_packages:
            skills_with_deps += 1
        
        formatted_skills.append({
            'name': name,
            'path': path,
            'dependencies': {
                'apt': apt_packages,
                'pip': pip_packages,
                'npm': npm_packages
            }
        })
    
    summary = {
        'total_skills': len(skills_data),
        'skills_with_deps': skills_with_deps,
        'apt_packages': len(all_apt),
        'pip_packages': len(all_pip),
        'npm_packages': len(all_npm),
        'all_apt': sorted(list(all_apt)),
        'all_pip': sorted(list(all_pip)),
        'all_npm': sorted(list(all_npm))
    }
    
    output = {
        'skills': formatted_skills,
        'summary': summary
    }
    
    json_output = json.dumps(output, indent=2, sort_keys=True)
    
    if output_path:
        Path(output_path).write_text(json_output)
    
    return json_output


def extract_frontmatter(content: str) -> Optional[dict]:
    """
    Extract YAML frontmatter from SKILL.md content.
    
    Extracts YAML content between '---' markers at the start of the file,
    parses it, and returns a dictionary with at least these fields:
    - name: skill name (required)
    - description: skill description (optional)
    - license: license info (optional)
    
    Args:
        content: The markdown file content as a string.
        
    Returns:
        A dictionary containing frontmatter fields, or None if no valid
        frontmatter is found or if YAML is malformed.
    """
    if not content:
        return None
    
    # Pattern to match frontmatter: --- at start, content, then ---
    # Uses re.DOTALL to make . match newlines
    # Allows optional whitespace before first ---
    pattern = r'^\s*---\s*\n(.*?)\n\s*---\s*\n'
    match = re.search(pattern, content, re.DOTALL)
    
    if not match:
        return None
    
    yaml_content = match.group(1)
    
    # Try PyYAML first
    try:
        import yaml
        frontmatter = yaml.safe_load(yaml_content)
        
        if not isinstance(frontmatter, dict):
            return None
            
        # Ensure required 'name' field exists
        if 'name' not in frontmatter:
            return None
            
        return frontmatter
        
    except ImportError:
        # PyYAML not available, use fallback
        return _parse_yaml_simple(yaml_content)
    except Exception:
        # Malformed YAML or other parsing error
        return None


def _parse_yaml_simple(yaml_content: str) -> Optional[dict]:
    """
    Simple YAML parser fallback when PyYAML is not available.
    Only handles basic key: value pairs, not nested structures.
    """
    result = {}
    
    for line in yaml_content.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
            
        # Match key: value patterns
        match = re.match(r'^([^:]+):\s*(.*)$', line)
        if match:
            key = match.group(1).strip()
            value = match.group(2).strip()
            
            # Remove quotes if present
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            elif value.startswith("'") and value.endswith("'"):
                value = value[1:-1]
            
            # Try to parse as list
            if value.startswith('[') and value.endswith(']'):
                list_content = value[1:-1]
                value = [item.strip().strip('"\'') for item in list_content.split(',') if item.strip()]
            
            result[key] = value
    
    if 'name' not in result:
        return None
        
    return result


def parse_dependencies_section(content: str) -> list:
    """
    Parse the Dependencies section from SKILL.md content.
    
    Args:
        content: The markdown content to parse
        
    Returns:
        List of dictionaries with package info
    """
    results = []
    
    section_match = re.search(
        r'^(?:##|###)\s+Dependencies\s*\n(.*?)(?=\n(?:##|###)\s|\Z)',
        content,
        re.MULTILINE | re.DOTALL
    )
    
    if not section_match:
        return results
    
    section_content = section_match.group(1)
    
    bullet_pattern = re.compile(
        r'^\s*-\s+\*\*([^*]+)\*\*:\s*`([^`]+)`(?:\s*\(([^)]+)\))?',
        re.MULTILINE
    )
    
    for match in bullet_pattern.finditer(section_content):
        package_name = match.group(1).strip()
        command = match.group(2).strip()
        description = match.group(3).strip() if match.group(3) else ""
        
        manager = detect_manager(command)
        
        if manager == "npm" and len(command.split()) > 3:
            packages = parse_multiple_packages(command)
            for pkg in packages:
                results.append({
                    "package_name": pkg,
                    "command": command,
                    "description": description,
                    "manager": manager
                })
        elif manager == "pip":
            # For pip, extract the actual package from the command to preserve extras
            pip_packages = extract_pip_packages(command, package_name)
            for pkg in pip_packages:
                results.append({
                    "package_name": pkg,
                    "command": command,
                    "description": description,
                    "manager": manager
                })
        else:
            results.append({
                "package_name": package_name,
                "command": command,
                "description": description,
                "manager": manager
            })
    
    return results


def detect_manager(command: str) -> str:
    """Detect package manager from install command."""
    if "apt-get" in command or "apt" in command.split():
        return "apt"
    elif "npm" in command:
        return "npm"
    elif "pip" in command:
        return "pip"
    elif "brew" in command:
        return "brew"
    elif "cargo" in command:
        return "cargo"
    elif "gem" in command:
        return "gem"
    else:
        return "unknown"


def parse_multiple_packages(command: str) -> list:
    """Extract multiple package names from npm install command."""
    parts = command.split()
    packages = []
    
    after_global = False
    for part in parts:
        if part in ['-g', '--global']:
            after_global = True
            continue
        if after_global and not part.startswith('-'):
            pkg = part.strip().strip('"').strip("'")
            if pkg:
                packages.append(pkg)
    
    return packages if packages else [command.split()[-1]]


def parse_installation_section(content: str) -> list:
    """
    Parse the Installation section from SKILL.md content.

    Args:
        content: The markdown content to parse

    Returns:
        List of dictionaries with package info
    """
    results = []

    section_match = re.search(
        r'^(?:##|###)\s+Installation\s*\n(.*?)(?=\n(?:##|###)\s|\Z)',
        content,
        re.MULTILINE | re.DOTALL
    )

    if not section_match:
        return results

    section_content = section_match.group(1)

    code_block_pattern = re.compile(
        r'^```(?:bash|shell|sh)?\s*\n(.*?)\n^```',
        re.MULTILINE | re.DOTALL
    )

    for match in code_block_pattern.finditer(section_content):
        code_content = match.group(1)

        for line in code_content.split('\n'):
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            package_info = parse_install_command(line)
            if package_info:
                results.append(package_info)

    return results


def parse_install_command(line: str) -> Optional[dict]:
    """
    Parse a single bash command line and extract package info.

    Args:
        line: A single line of bash code

    Returns:
        Dictionary with package info or None if not an install command
    """
    line = line.strip()
    if not line:
        return None

    if 'pip install' in line:
        return parse_pip_command(line)
    elif 'npm install' in line or 'npm i ' in line:
        return parse_npm_command(line)
    elif 'apt-get install' in line or 'apt install' in line:
        return parse_apt_command(line)
    elif line.startswith('npx '):
        return parse_npx_command(line)

    return None


def parse_pip_command(line: str) -> Optional[dict]:
    """Parse pip install command."""
    # First try to match quoted packages with extras (e.g., 'markitdown[pptx]')
    quoted_match = re.search(r"pip\s+install\s+(?:-e\s+)?['\"]([^'\"]+)['\"]", line)
    if quoted_match:
        package_name = quoted_match.group(1).strip()
        # Filter out relative paths like packages/, ./, ../
        if '/' in package_name or package_name.startswith('packages/') or package_name.startswith('./') or package_name.startswith('../'):
            return None
        return {
            "package_name": package_name,
            "command": line,
            "description": "",
            "manager": "pip"
        }

    # Fallback to unquoted package name
    match = re.search(r"pip\s+install\s+(?:-e\s+)?([^'\"\s]+)", line)
    if match:
        package_name = match.group(1).strip()
        # Filter out relative paths
        if '/' in package_name or package_name.startswith('packages/') or package_name.startswith('./') or package_name.startswith('../'):
            return None
        return {
            "package_name": package_name,
            "command": line,
            "description": "",
            "manager": "pip"
        }
    return None


def parse_npm_command(line: str) -> Optional[dict]:
    """Parse npm install command."""
    packages = []

    if '-g' in line or '--global' in line:
        pattern = r'npm\s+(?:install|i)\s+(?:-g|--global)\s+(.+)'
        match = re.search(pattern, line)
        if match:
            pkg_part = match.group(1)
            for pkg in pkg_part.split():
                pkg = pkg.strip().strip('"\'')
                if pkg and not pkg.startswith('-'):
                    packages.append(pkg)
    else:
        pattern = r"npm\s+(?:install|i)\s+(['\"]?[^'\"\s]+)"
        match = re.search(pattern, line)
        if match:
            package_name = match.group(1).strip('"\'')
            packages.append(package_name)

    if packages:
        return {
            "package_name": packages[0],
            "command": line,
            "description": "",
            "manager": "npm"
        }
    return None


def parse_apt_command(line: str) -> Optional[dict]:
    """Parse apt-get/apt install command."""
    pattern = r"(?:apt-get|apt)\s+install\s+(?:-y\s+)?(['\"]?[^'\"\s]+)"
    match = re.search(pattern, line)
    if match:
        package_name = match.group(1).strip('"\'')
        return {
            "package_name": package_name,
            "command": line,
            "description": "",
            "manager": "apt"
        }
    return None


def parse_npx_command(line: str) -> Optional[dict]:
    """Parse npx command."""
    pattern = r'npx\s+\S+\s+(?:install\s+)?([\'"]?[^\s]+)'
    match = re.search(pattern, line)
    if match:
        package_name = match.group(1).strip('"\'')
        return {
            "package_name": package_name,
            "command": line,
            "description": "",
            "manager": "npm"
        }
    return None


def parse_inline_commands(content: str) -> list:
    """
    Pattern 3: Scan entire file for inline install command mentions.

    Fallback parser that looks for install commands in comments,
    backticks, or plain text when formal sections are not present.

    Args:
        content: The markdown content to parse

    Returns:
        List of dictionaries with package info extracted from inline mentions
    """
    results = []
    found_packages = set()

    # Patterns to match the entire command, not just individual packages
    # These capture the full command after the keyword (e.g., "Requires: pip install ...")
    command_patterns = [
        # pip install patterns - capture the entire rest of the line after "pip install"
        (r'(?:requires|requirement|needs|install|dependency|dependencies)\s*[:#-]?\s*(?:with\s*[:#-]?\s*)?(?:`?)(pip(?:3?))\s+install\s+(.+?)(?:\s*$|\s+#|\s*`|\s*,|\s+(?:and|or)\s)', 'pip'),
        (r'(?:requires|requirement|needs|install|dependency|dependencies)\s*[:#-]?\s*(?:with\s*[:#-]?\s*)?(?:`?)(python\s+-m\s+pip)\s+install\s+(.+?)(?:\s*$|\s+#|\s*`|\s*,|\s+(?:and|or)\s)', 'pip'),
        # npm install patterns
        (r'(?:requires|requirement|needs|install|dependency|dependencies)\s*[:#-]?\s*(?:with\s*[:#-]?\s*)?(?:`?)(npm)\s+(?:install|i)\s+(?:(?:-g|--global)\s+)?(.+?)(?:\s*$|\s+#|\s*`|\s*,|\s+(?:and|or)\s)', 'npm'),
        # apt install patterns
        (r'(?:requires|requirement|needs|install|dependency|dependencies)\s*[:#-]?\s*(?:with\s*[:#-]?\s*)?(?:`?)(?:apt-get|apt)\s+install\s+(?:-y\s+)?(.+?)(?:\s*$|\s+#|\s*`|\s*,|\s+(?:and|or)\s)', 'apt'),
        # Comment patterns with #
        (r'#\s*(?:requires|requirement|needs|install|dependency|dependencies)\s*[:#-]?\s*(?:with\s*[:#-]?\s*)?(?:`?)(pip(?:3?))\s+install\s+(.+?)(?:\s*$|\s+#|\s*`|\s*,|\s+(?:and|or)\s)', 'pip'),
        (r'#\s*(?:requires|requirement|needs|install|dependency|dependencies)\s*[:#-]?\s*(?:with\s*[:#-]?\s*)?(?:`?)(python\s+-m\s+pip)\s+install\s+(.+?)(?:\s*$|\s+#|\s*`|\s*,|\s+(?:and|or)\s)', 'pip'),
        (r'#\s*(?:requires|requirement|needs|install|dependency|dependencies)\s*[:#-]?\s*(?:with\s*[:#-]?\s*)?(?:`?)(npm)\s+(?:install|i)\s+(?:(?:-g|--global)\s+)?(.+?)(?:\s*$|\s+#|\s*`|\s*,|\s+(?:and|or)\s)', 'npm'),
        (r'#\s*(?:requires|requirement|needs|install|dependency|dependencies)\s*[:#-]?\s*(?:with\s*[:#-]?\s*)?(?:`?)(?:apt-get|apt)\s+install\s+(?:-y\s+)?(.+?)(?:\s*$|\s+#|\s*`|\s*,|\s+(?:and|or)\s)', 'apt'),
        # Backtick patterns
        (r'`(pip(?:3?))\s+install\s+(.+?)`', 'pip'),
        (r'`(python\s+-m\s+pip)\s+install\s+(.+?)`', 'pip'),
        (r'`(npm)\s+(?:install|i)\s+(?:(?:-g|--global)\s+)?(.+?)`', 'npm'),
        (r'`(?:apt-get|apt)\s+install\s+(?:-y\s+)?(.+?)`', 'apt'),
    ]

    lines = content.split('\n')

    for line in lines:
        line_stripped = line.strip()

        for pattern_tuple in command_patterns:
            pattern = pattern_tuple[0]
            manager = pattern_tuple[1]

            for match in re.finditer(pattern, line_stripped, re.IGNORECASE):
                if len(match.groups()) < 2:
                    continue

                # Get the full command text after the manager (e.g., everything after "pip install")
                command_suffix = match.group(2).strip()

                # Extract all packages from the command suffix
                packages = extract_packages_from_command_suffix(command_suffix, manager)

                for package_name in packages:
                    if not package_name or package_name in found_packages:
                        continue

                    if package_name.startswith('-'):
                        continue

                    # Reconstruct the full command for this package
                    manager_cmd = match.group(1)
                    command = f"{manager_cmd} install {package_name}"

                    found_packages.add(package_name)
                    results.append({
                        "package_name": package_name,
                        "command": command,
                        "description": "from inline mention",
                        "manager": manager
                    })

    return results


def extract_packages_from_command_suffix(suffix: str, manager: str) -> list:
    """
    Extract individual package names from the command suffix.
    Handles multiple packages separated by spaces.

    Args:
        suffix: The part of the command after "install" (e.g., "pkg1 pkg2 pkg3")
        manager: The package manager type

    Returns:
        List of package names
    """
    packages = []

    if manager == 'pip':
        # Handle pip install with potential -e flag and quoted packages
        # First check for quoted packages (which may contain extras like [pptx])
        quoted = re.findall(r"['\"]([^'\"]+)['\"]", suffix)
        for pkg in quoted:
            pkg = pkg.strip()
            if is_valid_package_name(pkg):
                packages.append(pkg)

        if not packages:
            # Split by whitespace and extract unquoted packages
            parts = suffix.split()
            for part in parts:
                if part.startswith('-'):
                    continue
                pkg = part.strip('"\'').strip(',').strip()
                if is_valid_package_name(pkg):
                    packages.append(pkg)

    elif manager == 'npm':
        # npm packages after -g flag
        parts = suffix.split()
        after_global = False
        for part in parts:
            if part in ['-g', '--global']:
                after_global = True
                continue
            if after_global and not part.startswith('-'):
                pkg = part.strip('"\'').strip(',').strip()
                if pkg:
                    packages.append(pkg)
        if not packages:
            # No -g flag, just split by space
            for part in parts:
                if not part.startswith('-'):
                    pkg = part.strip('"\'').strip(',').strip()
                    if pkg:
                        packages.append(pkg)

    elif manager == 'apt':
        # apt packages (may have -y flag)
        parts = suffix.split()
        for part in parts:
            if part.startswith('-'):
                continue
            pkg = part.strip('"\'').strip(',').strip()
            if pkg:
                packages.append(pkg)

    return packages


def extract_command_from_match(match, manager: str, line: str) -> str:
    """Extract the full install command from a regex match."""
    start = match.start()
    end = match.end()

    if '`' in line[:start] and '`' in line[end:]:
        cmd_start = line.rfind('`', 0, start) + 1
        cmd_end = line.find('`', end)
        if cmd_start > 0 and cmd_end > cmd_start:
            return line[cmd_start:cmd_end]

    if line.startswith('#'):
        comment_content = line.lstrip('#').strip()
        prefixes = ['requires:', 'requires :', 'requirement:', 'needs:', 'install:', 'install with:', 'you can install with:']
        for prefix in prefixes:
            if comment_content.lower().startswith(prefix):
                cmd = comment_content[len(prefix):].strip()
                if cmd.startswith('`') and cmd.endswith('`'):
                    cmd = cmd[1:-1]
                return cmd

    matched_text = match.group(0)
    cmd = matched_text

    prefixes_to_strip = ['requires:', 'requires :', 'needs:', 'install:', 'install with:', 'you can install with:']
    for prefix in prefixes_to_strip:
        if cmd.lower().startswith(prefix):
            cmd = cmd[len(prefix):].strip()
            break

    if cmd.startswith('`') and cmd.endswith('`'):
        cmd = cmd[1:-1]

    return cmd


def categorize_and_normalize(deps: list) -> dict:
    """
    Categorize packages by manager and handle special syntax cases.

    Args:
        deps: List of dependency dicts with keys: package_name, command, description, manager

    Returns:
        Dictionary with categorized packages: {"apt": [...], "pip": [...], "npm": [...]}
    """
    result = {
        "apt": [],
        "pip": [],
        "npm": []
    }

    seen = set()

    for dep in deps:
        command = dep.get("command", "")
        manager = dep.get("manager", "")

        if not manager:
            manager = detect_manager(command)

        if manager == "apt":
            packages = extract_apt_packages(command, dep.get("package_name", ""))
            for pkg in packages:
                pkg_lower = pkg.lower()
                key = (pkg_lower, "apt")
                if key not in seen:
                    seen.add(key)
                    result["apt"].append(pkg_lower)

        elif manager == "pip":
            packages = extract_pip_packages(command, dep.get("package_name", ""))
            for pkg in packages:
                key = (pkg, "pip")
                if key not in seen:
                    seen.add(key)
                    result["pip"].append(pkg)

        elif manager == "npm":
            packages = extract_npm_packages(command, dep.get("package_name", ""))
            for pkg in packages:
                key = (pkg, "npm")
                if key not in seen:
                    seen.add(key)
                    result["npm"].append(pkg)

    return result


def extract_apt_packages(command: str, default_package: str) -> list:
    """Extract package names from apt/apt-get install command."""
    packages = []

    match = re.search(r'(?:apt-get|apt)\s+install\s+(.*)', command)
    if match:
        args_part = match.group(1)
        parts = args_part.split()

        i = 0
        while i < len(parts):
            part = parts[i]
            if part.startswith('-'):
                if part in ('-y', '--yes', '--assume-yes'):
                    pass
                else:
                    i += 1
                    continue
            else:
                pkg = part.strip().strip('"\'')
                if pkg:
                    packages.append(pkg)
            i += 1

    if not packages and default_package:
        packages.append(default_package)

    return packages


def is_valid_package_name(pkg: str) -> bool:
    """Check if a string is a valid package name, not a path."""
    if not pkg:
        return False
    # Reject paths containing / or starting with relative directories
    if '/' in pkg:
        return False
    if pkg.startswith('packages/') or pkg.startswith('./') or pkg.startswith('../'):
        return False
    return True


def extract_pip_packages(command: str, default_package: str) -> list:
    """
    Extract package names from pip install command.
    Preserves extras syntax like markitdown[pptx].
    Handles editable installs with -e flag.
    Filters out relative paths.
    """
    packages = []

    match = re.search(r'pip\s+install\s+(.*)', command)
    if match:
        args_part = match.group(1)

        has_editable = '-e' in args_part or '--editable' in args_part

        if has_editable:
            # For editable installs, extract the package part after -e
            editable_pattern = r"(?:-e|--editable)\s+['\"]?([^'\"\s]+)['\"]?"
            editable_match = re.search(editable_pattern, args_part)
            if editable_match:
                pkg = editable_match.group(1).strip('"\'')
                # Filter out relative paths like packages/
                if is_valid_package_name(pkg):
                    packages.append(f"-e {pkg}")
        else:
            # First, look for quoted packages (handles extras like 'markitdown[pptx]')
            quoted_match = re.findall(r"['\"]([^'\"]+)['\"]", args_part)
            if quoted_match:
                for pkg in quoted_match:
                    pkg = pkg.strip()
                    if is_valid_package_name(pkg):
                        packages.append(pkg)

            # If no quoted packages found, split by whitespace and extract unquoted packages
            if not packages:
                parts = args_part.split()
                for part in parts:
                    if part.startswith('-'):
                        continue
                    pkg = part.strip('"\'')
                    if is_valid_package_name(pkg):
                        packages.append(pkg)

    if not packages and default_package and is_valid_package_name(default_package):
        packages.append(default_package)

    return packages


def extract_npm_packages(command: str, default_package: str) -> list:
    """
    Extract package names from npm install command.
    Splits multiple packages after -g flag.
    """
    packages = []

    global_match = re.search(r'npm\s+(?:install|i)\s+(?:-g|--global)\s+(.+)', command)
    if global_match:
        pkg_part = global_match.group(1)
        for pkg in pkg_part.split():
            pkg = pkg.strip().strip('"\'')
            if pkg and not pkg.startswith('-'):
                packages.append(pkg)
        return packages

    npx_match = re.search(r'npx\s+\S+\s+install\s+([\'"]?[^\s]+)', command)
    if npx_match:
        pkg = npx_match.group(1).strip('"\'')
        if pkg:
            packages.append(pkg)
        return packages

    match = re.search(r'npm\s+(?:install|i)\s+([\'"]?[^\s]+)', command)
    if match:
        pkg = match.group(1).strip('"\'')
        if pkg and not pkg.startswith('-'):
            packages.append(pkg)

    if not packages and default_package:
        packages.append(default_package)

    return packages


def main() -> int:
    """
    Main entry point for the script.
    
    Returns:
        Exit code (0 for success, 1 for error)
    """
    parser = argparse.ArgumentParser(
        description='Parse SKILL.md files to extract dependencies',
        prog='parse_skill_deps.py',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s --skill-path ~/.claude/skills
  %(prog)s --skill-path /path/to/SKILL.md --output deps.json
  %(prog)s --skill-path ~/.config/opencode/skills --verbose
        '''
    )
    
    parser.add_argument(
        '--skill-path',
        type=Path,
        required=True,
        help='Path to a single SKILL.md file or directory containing skills'
    )
    
    parser.add_argument(
        '--output',
        type=Path,
        default=None,
        help='Output JSON file path (default: stdout)'
    )
    
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Enable verbose logging'
    )
    
    args = parser.parse_args()
    
    setup_logging(args.verbose)
    logger = logging.getLogger(__name__)
    
    try:
        skill_files = discover_skill_files(args.skill_path)
        
        if not skill_files:
            logger.warning("No SKILL.md files found")
            return 0
        
        results = parse_all_skills(skill_files)
        json_output = format_output(results['skills'], str(args.output) if args.output else None)
        if not args.output:
            print(json_output)
        
        return 0
        
    except FileNotFoundError as e:
        logger.error(f"File not found: {e}")
        return 1
    except PermissionError as e:
        logger.error(f"Permission error: {e}")
        return 1
    except ValueError as e:
        logger.error(f"Invalid input: {e}")
        return 1
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
