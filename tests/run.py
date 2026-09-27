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

supplied = Path("C:/Users/Public/Documents/Elder Scrolls Online/live/AddOns")
hodor_path = supplied / "HodorReflexes"
library_path = supplied / "LibGroupCombatStats/LibGroupCombatStats.lua"
provider_source = ""
if hodor_path.exists() and library_path.exists():
    provider_source = "\n".join(p.read_text(encoding="utf-8-sig") for p in hodor_path.rglob("*.lua"))
    provider_source += "\n" + library_path.read_text(encoding="utf-8-sig")

reference = ROOT / ".reference/esoui"
if reference.exists():
    api = (reference / "ESOUIDocumentation.txt").read_text(encoding="utf-8-sig")
    sources = "\n".join(p.read_text(encoding="utf-8-sig", errors="replace")
                        for p in (reference / "esoui").rglob("*") if p.suffix in (".lua", ".xml"))
    own = "\n".join(p.read_text(encoding="utf-8") for p in files
                    if provider_source or p.parent.name != "Integrations")
    # Check every all-caps native constant and every directly called global ESO function.
    constants = set(re.findall(r"\b[A-Z][A-Z0-9]+(?:_[A-Z0-9]+)+\b", own))
    calls = set(re.findall(r"(?<![.:\w])([A-Z][A-Za-z0-9_]+)\s*\(", own))
    custom = {"GroupFramePlus"}
    missing = [name for name in sorted((constants | calls) - custom)
               if not re.search(r"\b" + re.escape(name) + r"\b", api + sources + provider_source)]
    # Comments may contain an uppercase explanatory term, so keep the audit strict and explicit.
    assert not missing, f"Unverified native names: {missing}"
    print(f"PASS: {len(constants | calls)} native identifiers found in API/source")

lua.globals().load_module = lambda name: lua.execute(
    (ROOT / "GroupFramePlus" / name).read_text(encoding="utf-8"))
lua.execute((ROOT / "tests/behavior.lua").read_text(encoding="utf-8"))
lua.execute((ROOT / "tests/shared_stats.lua").read_text(encoding="utf-8"))

if library_path.exists():
    source = library_path.read_text(encoding="utf-8-sig")
    # Execute the supplied encoder functions unchanged, with boundary fixtures.
    # This catches the README/Hodor HPS display scaling discrepancy.
    start = source.index("local function updatePlayerDps()")
    end = source.index("local function updatePlayerSlottedUlts()", start)
    encoders = source[start:end]
    lua.execute("""
        local DAMAGE_UNKNOWN, DAMAGE_TOTAL, DAMAGE_BOSS = 0, 1, 2
        local zo_floor = math.floor
        local input = { DPSOut = 87200, HPSOut = 24300, OHPSOut = 90000,
            damageOutTotal = 4000000, bossFight = false }
        local combat = { GetData = function() return input end }
        local playerStats = { dps = {}, hps = {} }
    """ + encoders + """
        updatePlayerDps(); updatePlayerHps()
        assert(playerStats.dps.dps == 87 and playerStats.hps.hps == 24)
        input.bossFight, input.bossDamageTotal, input.bossTime = true, 1000000, 10
        updatePlayerDps()
        assert(playerStats.dps.dps == 87 and playerStats.dps.dmg == 1000)
        input.DPSOut, input.HPSOut, input.OHPSOut = 0, 0, 0
        updatePlayerDps(); updatePlayerHps()
        assert(playerStats.dps.dps == 0 and playerStats.hps.hps == 0)
    """)
    print("PASS: actual supplied LGCS encoder: total/boss DPS, HPS scale and zero")
    start = source.index("function lib.RegisterAddon(addonName, neededStats)")
    end = source.index("--[[ doc.lua end ]]", start)
    lua.execute("""
        local lib, _registeredAddons = {}, {}
        local DPS, HPS, ULT, SKILLLINES = 'DPS', 'HPS', 'ULT', 'SKILLLINES'
        local _statsShared = { DPS=false, HPS=false, ULT=false, SKILLLINES=false }
        local LOG_LEVEL_ERROR, LOG_LEVEL_DEBUG, LOG_LEVEL_INFO = 'E', 'D', 'I'
        local function Log() end
        local function forbidden() error('Reader enabled a broadcaster') end
        local enablePlayerBroadcastDPS, enablePlayerBroadcastHPS = forbidden, forbidden
        local enablePlayerBroadcastULT, enablePlayerBroadcastSkillLines = forbidden, forbidden
        local _CombatStatsObject = { New = function() return { reader = true } end }
    """ + source[start:end] + """
        assert(lib.RegisterAddon('ReaderTest', {}).reader)
        for _, enabled in pairs(_statsShared) do assert(enabled == false) end
    """)
    print("PASS: actual supplied LGCS empty registration never enables broadcasting")
