unit dump_races;
{
  xEdit Apply Script: dump all RACE records from Skyrim.esm.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: xEdit -> right-click Skyrim.esm -> Apply Script... -> browse here
  Output: FormID <TAB> RACE <TAB> EditorID <TAB> Name (Messages panel)
}

function Process(e: IInterface): integer;
var
  sig, edid: string;
begin
  sig := Signature(e);
  if sig <> 'RACE' then begin
    Result := 0;
    Exit;
  end;

  edid := EditorID(e);
  AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'RACE' + #9 + edid + #9 + Name(e));
  Result := 0;
end;

end.
