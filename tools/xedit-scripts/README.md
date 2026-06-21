# xEdit Scripts for iNPCForge

Reusable xEdit (SSEEdit) Apply Scripts for verifying FormIDs against the live
Skyrim.esm. These exist because xEdit's native copy-paste only exports the
FormID column — these scripts dump FormID **+ EditorID + Name** in one run.

## Usage

1. Load Skyrim.esm in xEdit (via your MO2 instance)
2. Right-click **`Skyrim.esm`** (top node) → **Apply Script...**
3. Browse to one of the `.pas` files below → **OK**
4. Output appears in the **Messages** panel (bottom)
5. Click in Messages → **Ctrl+A** → **Ctrl+C** → paste wherever needed

## Scripts

| Script | Signature | Dumps | Purpose |
|--------|-----------|-------|---------|
| `dump_voices.pas` | `VTYP` | All voice types | Verify `data/voices.yaml` |
| `dump_armor.pas` | `ARMO` | Base armor/clothing (excludes enchanted) | Verify outfit item EditorIDs + FormIDs |
| `dump_weapons_misc_outfits.pas` | `WEAP`, `MISC`, `OTFT` | Iron/Steel/Orcish weapons, gold/lockpick, all outfits | Verify inventory items + `data/outfits.yaml` |
| `dump_races.pas` | `RACE` | All races | Verify `data/races.yaml` |
| `dump_cells_whiterun.pas` | `CELL` | Interior cells matching location keywords | Verify `data/locations.yaml` |
| `dump_factions.pas` | `FACT` | All factions | Verify `data/factions.yaml` |
| `dump_packages.pas` | `PACK` | All AI packages | Verify `data/ai_packages.yaml` |
| `dump_headparts.pas` | `HDPT` | All headparts | Verify `data/headparts.yaml` |
| `dump_clfm.pas` | `CLFM` | All color forms | Verify `data/colors.yaml` |
| `dump_classes.pas` | `CLAS` | All classes | Verify NPC `Class:` references |
| `DumpNpcAppearance.pas` | `NPC_` | Winning appearance records (headparts, morphs, tints) to JSON | Clone NPC faces offline |

## Scope

These scripts target **`Skyrim.esm` only** by default. DLC masters
(Dawnguard.esm, Dragonborn.esm, Hearthfires.esm) and mod plugins are not
covered. To verify DLC records, run the same scripts against DLC masters
individually: right-click `Dawnguard.esm` → Apply Script → select the dump
script. The scripts have no hardcoded plugin filter — they process whatever
file you right-click on.

## DumpNpcAppearance.pas (JSON Output)

Unlike the other scripts, `DumpNpcAppearance.pas` writes its output to a JSON
file rather than the Messages panel. It dumps winning `NPC_` appearance records
(headparts, face morphs, tint layers, race, height, weight, hair color) from
the loaded profile — useful for offline NPC face cloning.

**Output:** `_tmp/xedit-dumps/npc_appearance_dump.json` (about 7 MB for full Skyrim.esm dump)

**Command-line usage (via MO2):**
```text
/D:"<modlist>\Game Root\Data" /S:"tools\xedit-scripts" /IKnowWhatImDoing /autoload /AllowDirectories /script:"DumpNpcAppearance.pas" /autoexit
```

See the script's header comment for the full working invocation.

## Adding New Scripts

Copy the pattern from an existing script. The skeleton:

```pascal
unit my_script_name;

function Process(e: IInterface): integer;
var
  sig, edid: string;
begin
  sig := Signature(e);
  if sig <> 'TARGET_SIG' then begin
    Result := 0;  // 0 = continue, 1 = stop (use 0 in most cases)
    Exit;
  end;

  edid := EditorID(e);
  if edid = '' then begin
    Result := 0;
    Exit;
  end;

  // Your filter logic here
  AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + edid + #9 + Name(e));

  Result := 0;
end;

end.
```

### Key Functions

- `Signature(e)` — record signature (e.g. `'VTYP'`, `'ARMO'`, `'OTFT'`, `'NPC_'`)
- `EditorID(e)` — the EditorID string (more reliable than `GetElementEditValues(e, 'EDID')`)
- `GetLoadOrderFormID(e)` — returns integer FormID; wrap with `IntToHex(..., 8)` for hex
- `Name(e)` — display name (includes EditorID and FormID suffix in xEdit format)
- `AddMessage(...)` — write a line to the Messages panel
- `Result := 0` — continue processing; `Result := 1` — abort (use sparingly)

### Gotchas

- Always null-check `EditorID(e)` — some records have empty EditorIDs and will
  crash string operations
- The `Process` function is called once per record — there's no built-in batching
- Scripts abort with `[EAbort] Operation aborted` if you hit a malformed record;
  guard with null checks
- xEdit's copy-paste (Ctrl+C on selected records) only copies the **first column**
  (FormID). These scripts exist specifically to work around that limitation.
- **Pascal structure**: function body ends with `end;` (semicolon); unit ends with
  `end.` (period). Two `end.` in a row causes a parse error on line 62+.

## Deployment

xEdit only sees scripts in its own `Edit Scripts\` directory. To use these:

```powershell
# Copy to your MO2's xEdit scripts folder (path varies by modlist)
$XEDIT_SCRIPTS_DIR = "<path-to-this-repo>\tools\xedit-scripts"
$MO2_XEDIT_SCRIPTS_DIR = "<path-to-modlist>\tools\xEdit\Edit Scripts"
Copy-Item "$XEDIT_SCRIPTS_DIR\*.pas" $MO2_XEDIT_SCRIPTS_DIR
```

Adjust the destination path for your MO2 instance.
