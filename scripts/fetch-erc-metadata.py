#!/usr/bin/env python3
"""
Fetch real ERC metadata (title, author, status) from the ethereum/ercs repo
and update the local stub files in EIPS/ so the /erc listing page works properly.
"""

import os
import re
import sys
import json
import urllib.request
import urllib.error

ERCS_BASE = "https://raw.githubusercontent.com/ethereum/ercs/master/ERCS"
EIPS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "EIPS")

def fetch_url(url):
    """Fetch a URL and return the text content, or None on failure."""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "erc-fetch-script"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        print(f"  HTTP {e.code} for {url}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"  Error fetching {url}: {e}", file=sys.stderr)
        return None

def parse_front_matter(text):
    """Parse YAML front matter from markdown text. Returns dict or None."""
    match = re.match(r'^---\s*\n(.*?)\n---', text, re.DOTALL)
    if not match:
        return None
    yaml_text = match.group(1)
    result = {}
    for line in yaml_text.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        m = re.match(r'^([a-zA-Z_-]+):\s*(.*)', line)
        if m:
            key = m.group(1)
            value = m.group(2).strip()
            # Remove surrounding quotes if present
            if (value.startswith('"') and value.endswith('"')) or \
               (value.startswith("'") and value.endswith("'")):
                value = value[1:-1]
            result[key] = value
    return result

def patch_stub_file(filepath, eip_num, metadata):
    """Update a stub ERC file with real front matter metadata."""
    with open(filepath, 'r') as f:
        content = f.read()

    # Parse existing front matter
    existing = parse_front_matter(content)
    if existing is None:
        print(f"  WARNING: Cannot parse existing front matter in {filepath}", file=sys.stderr)
        return False

    # Build new front matter - keep existing fields, add/update from metadata
    new_fm = {
        'eip': str(eip_num),
        'title': metadata.get('title', existing.get('title', '')),
        'author': metadata.get('author', existing.get('author', '')),
        'type': metadata.get('type', existing.get('type', 'Standards Track')),
        'category': metadata.get('category', existing.get('category', 'ERC')),
        'status': metadata.get('status', existing.get('status', '')),
    }
    
    # Only add fields that have values
    ordered_keys = ['eip', 'title', 'author', 'type', 'category', 'status']
    # Add extra fields from metadata that aren't in our basic list
    extra_keys = [k for k in metadata.keys() if k not in ordered_keys and k not in ('description', 'created', 'discussions-to', 'requires')]
    all_keys = ordered_keys + extra_keys
    
    # Build the new front matter string
    fm_lines = ['---']
    for key in all_keys:
        val = new_fm.get(key) or metadata.get(key)
        if val:
            if key == 'eip':
                fm_lines.append(f'{key}: {val}')
            else:
                fm_lines.append(f'{key}: {val}')
    fm_lines.append('---')

    # Preserve the body (content after front matter)
    body_match = re.search(r'^---\s*\n.*?\n---\s*\n(.*)', content, re.DOTALL)
    body = body_match.group(1) if body_match else ''

    new_content = '\n'.join(fm_lines) + '\n' + body

    with open(filepath, 'w') as f:
        f.write(new_content)

    return True

def main():
    print("=" * 60)
    print("ERC Metadata Fetcher")
    print("Fetches real title/author/status from ethereum/ercs")
    print("=" * 60)
    
    # Find all ERC stub files
    erc_files = []
    for filename in os.listdir(EIPS_DIR):
        if not filename.startswith('eip-') or not filename.endswith('.md'):
            continue
        filepath = os.path.join(EIPS_DIR, filename)
        with open(filepath, 'r') as f:
            header = f.read(500)
        if 'category: ERC' in header:
            erc_files.append((filepath, filename))

    if not erc_files:
        print("No ERC stub files found!")
        return

    print(f"\nFound {len(erc_files)} ERC stub files to process.\n")

    success_count = 0
    skip_count = 0
    fail_count = 0

    for filepath, filename in erc_files:
        # Extract EIP number from filename (eip-1155.md -> 1155)
        m = re.match(r'eip-(\d+)\.md', filename)
        if not m:
            continue
        eip_num = m.group(1)

        erc_filename = f"erc-{eip_num}.md"
        erc_url = f"{ERCS_BASE}/{erc_filename}"

        print(f"  [{eip_num}] {filename} -> fetching {erc_filename}...", end=' ')

        erc_content = fetch_url(erc_url)
        if erc_content is None:
            print("SKIP (not in ercs repo)")
            skip_count += 1
            continue

        metadata = parse_front_matter(erc_content)
        if metadata is None:
            print("FAIL (cannot parse front matter)")
            fail_count += 1
            continue

        if patch_stub_file(filepath, eip_num, metadata):
            print(f"OK (status: {metadata.get('status', '?')}, title: {metadata.get('title', '?')[:40]}...)")
            success_count += 1
        else:
            print("FAIL")
            fail_count += 1

    print(f"\n{'=' * 60}")
    print(f"Done: {success_count} updated, {skip_count} skipped, {fail_count} failed")
    print(f"{'=' * 60}")

if __name__ == '__main__':
    main()
