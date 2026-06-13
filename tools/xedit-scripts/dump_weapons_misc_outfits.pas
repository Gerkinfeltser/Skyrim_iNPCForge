unit dump_weapons_misc_outfits;
{
  xEdit Apply Script: dump WEAP, MISC, and OTFT records from Skyrim.esm.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: xEdit -> right-click Skyrim.esm -> Apply Script... -> browse here
  Output: FormID <TAB> Signature <TAB> EditorID <TAB> Name (Messages panel)

  Purpose: verify weapon/misc item EditorIDs + FormIDs for NPC inventory,
  and verify OTFT (outfit) record FormIDs in data/outfits.yaml.

  Dumps:
    - OTFT: all outfit records
    - WEAP: weapons matching Orcish*, Steel*, Iron*
    - MISC: Gold001, Lockpick, and common misc items
}

function Process(e: IInterface): integer;
var
  sig, edid: string;
  keep: boolean;
begin
  sig := Signature(e);
  edid := EditorID(e);
  if edid = '' then begin
    Result := 0;
    Exit;
  end;

  // Outfits: dump all
  if sig = 'OTFT' then begin
    AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'OTFT' + #9 + edid + #9 + Name(e));
    Result := 0;
    Exit;
  end;

  // Weapons: Iron/Steel/Orcish
  if sig = 'WEAP' then begin
    keep := (Pos('Iron', edid) > 0)
         or (Pos('Steel', edid) > 0)
         or (Pos('Orcish', edid) > 0);
    if keep then
      AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'WEAP' + #9 + edid + #9 + Name(e));
    Result := 0;
    Exit;
  end;

  // Misc: gold, lockpicks, common vendor items
  if sig = 'MISC' then begin
    keep := (edid = 'Gold001')
         or (edid = 'Lockpick')
         or (edid = 'GemRing')
         or (edid = 'GemFlawless')
         or (Pos('Gold', edid) = 1);
    if keep then
      AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'MISC' + #9 + edid + #9 + Name(e));
    Result := 0;
    Exit;
  end;

  Result := 0;
end;

end.
