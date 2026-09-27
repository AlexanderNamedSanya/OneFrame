"""Run with Python + lupa (Lua 5.1); no ESO client or network needed for unit tests.

Optional API audit reads a checkout of github.com/esoui/esoui at .reference/esoui.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".reference/python"))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
compile_lua = lua.eval("function(s,n) local f,e=loadstring(s,n); assert(f,e) end")
files = sorted((ROOT / "GroupFramePlus").rglob("*.lua"))
for path in files:
    compile_lua(path.read_text(encoding="utf-8"), str(path))
print(f"PASS: syntax of {len(files)} Lua 5.1 modules")
manifest = (ROOT / "GroupFramePlus/GroupFramePlus.txt").read_text().splitlines()
for line in manifest:
    if line and not line.startswith("##"):
        assert (ROOT / "GroupFramePlus" / line).is_file(), line
print("PASS: manifest file paths")

reference = ROOT / ".reference/esoui"
if reference.exists():
    api = (reference / "ESOUIDocumentation.txt").read_text(encoding="utf-8-sig")
    sources = "\n".join(p.read_text(encoding="utf-8-sig", errors="replace")
                        for p in (reference / "esoui").rglob("*") if p.suffix in (".lua", ".xml"))
    own = "\n".join(p.read_text(encoding="utf-8") for p in files)
    # Check every all-caps native constant and every directly called global ESO function.
    constants = set(re.findall(r"\b[A-Z][A-Z0-9]+(?:_[A-Z0-9]+)+\b", own))
    calls = set(re.findall(r"(?<![.:\w])([A-Z][A-Za-z0-9_]+)\s*\(", own))
    custom = {"GroupFramePlus"}
    missing = [name for name in sorted((constants | calls) - custom)
               if not re.search(r"\b" + re.escape(name) + r"\b", api + sources)]
    # Comments may contain an uppercase explanatory term, so keep the audit strict and explicit.
    assert not missing, f"Unverified native names: {missing}"
    print(f"PASS: {len(constants | calls)} native identifiers found in API/source")

lua.globals().load_module = lambda name: lua.execute(
    (ROOT / "GroupFramePlus" / name).read_text(encoding="utf-8"))
lua.execute((ROOT / "tests/behavior.lua").read_text(encoding="utf-8"))
