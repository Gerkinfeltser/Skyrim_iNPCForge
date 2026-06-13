unit dump_armor;
{
  xEdit Apply Script: dump ARMO (armor/clothing) records.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: xEdit -> right-click Skyrim.esm (or DLC master) -> Apply Script...
  Output: FormID <TAB> ARMO <TAB> EditorID <TAB> Name (Messages panel)

  Filters to base armor/clothing items (excludes enchanted variants).
  Covers: Orcish, Iron, Steel, Hide, Leather, Elven, Ebony, Glass, Daedric,
  Dwarven, plus clothing (Apron, Blacksmith, Clothes*, Farm*, Mage*, Noble*).
  Extend the keyword list below to add more material types.
}

function Process(e: IInterface): integer;
var
  sig, edid: string;
  keep: boolean;
begin
  sig := Signature(e);
  if sig <> 'ARMO' then begin
    Result := 0;
    Exit;
  end;

  edid := EditorID(e);
  if edid = '' then begin
    Result := 0;
    Exit;
  end;

  // Exclude enchanted variants to keep output to base items
  if Pos('Ench', edid) > 0 then begin
    Result := 0;
    Exit;
  end;

  keep := (Pos('Orcish', edid) > 0)
       or (Pos('Iron', edid) > 0)
       or (Pos('Steel', edid) > 0)
       or (Pos('Hide', edid) > 0)
       or (Pos('Leather', edid) > 0)
       or (Pos('Elven', edid) > 0)
       or (Pos('Ebony', edid) > 0)
       or (Pos('Glass', edid) > 0)
       or (Pos('Daedric', edid) > 0)
       or (Pos('Dwarven', edid) > 0)
       or (Pos('Apron', edid) > 0)
       or (Pos('Blacksmith', edid) > 0)
       or (Pos('Clothes', edid) > 0)
       or (Pos('Clothing', edid) > 0)
       or (Pos('Farm', edid) > 0)
       or (Pos('Mage', edid) > 0)
       or (Pos('Noble', edid) > 0)
       or (Pos('Fine', edid) > 0)
       or (Pos('Jarl', edid) > 0)
       or (Pos('Robe', edid) > 0);

  if keep then
    AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'ARMO' + #9 + edid + #9 + Name(e));

  Result := 0;
end;

end.
