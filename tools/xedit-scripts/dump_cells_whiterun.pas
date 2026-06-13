unit dump_cells_whiterun;
{
  xEdit Apply Script: dump CELL records matching known location keywords.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: xEdit -> right-click Skyrim.esm -> Apply Script... -> browse here
  Output: FormID <TAB> CELL <TAB> EditorID <TAB> Name (Messages panel)

  Filters to cells whose EditorID contains location-relevant keywords
  (city names, taverns, shops, known dungeons). Keeps output manageable.
  To add more locations, extend the keyword list below.
}

function Process(e: IInterface): integer;
var
  sig, edid, edidLower: string;
  keep: boolean;
begin
  sig := Signature(e);
  if sig <> 'CELL' then begin
    Result := 0;
    Exit;
  end;

  edid := EditorID(e);
  if edid = '' then begin
    Result := 0;
    Exit;
  end;

  edidLower := LowerCase(edid);

  // Filter to known location keywords.
  // Covers all entries currently in data/locations.yaml plus common extras.
  keep := (Pos('whiterun', edidLower) > 0)
       or (Pos('breezehome', edidLower) > 0)
       or (Pos('drunkenhuntsman', edidLower) > 0)
       or (Pos('bannermare', edidLower) > 0)
       or (Pos('arcadia', edidLower) > 0)
       or (Pos('warmaiden', edidLower) > 0)
       or (Pos('dragonsreach', edidLower) > 0)
       or (Pos('jorrvaskr', edidLower) > 0)
       or (Pos('solitude', edidLower) > 0)
       or (Pos('winkingskeever', edidLower) > 0)
       or (Pos('radiant', edidLower) > 0)
       or (Pos('bluepalace', edidLower) > 0)
       or (Pos('riften', edidLower) > 0)
       or (Pos('beeandbarb', edidLower) > 0)
       or (Pos('raggedflagon', edidLower) > 0)
       or (Pos('honeyside', edidLower) > 0)
       or (Pos('windhelm', edidLower) > 0)
       or (Pos('candlehearth', edidLower) > 0)
       or (Pos('palaceofthekings', edidLower) > 0)
       or (Pos('markarth', edidLower) > 0)
       or (Pos('silverblood', edidLower) > 0)
       or (Pos('understonekeep', edidLower) > 0)
       or (Pos('riverwood', edidLower) > 0)
       or (Pos('sleepinggiant', edidLower) > 0)
       or (Pos('alvor', edidLower) > 0)
       or (Pos('riverwoodtrader', edidLower) > 0)
       or (Pos('falkreath', edidLower) > 0)
       or (Pos('deadmansdrink', edidLower) > 0)
       or (Pos('morthal', edidLower) > 0)
       or (Pos('moorside', edidLower) > 0)
       or (Pos('dawnstar', edidLower) > 0)
       or (Pos('windpeak', edidLower) > 0)
       or (Pos('winterhold', edidLower) > 0)
       or (Pos('frozenhearth', edidLower) > 0)
       or (Pos('bleakfallsbarrow', edidLower) > 0)
       or (Pos('whiteriverwatch', edidLower) > 0);

  if keep then
    AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'CELL' + #9 + edid + #9 + Name(e));

  Result := 0;
end;

end.
