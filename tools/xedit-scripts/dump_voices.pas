unit dump_voices;
{
  xEdit Apply Script: dump all VTYP (voice type) records.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: xEdit -> right-click Skyrim.esm (or DLC master) -> Apply Script...
  Output: FormID <TAB> VTYP <TAB> EditorID <TAB> Name (Messages panel)

  Use to verify data/voices.yaml against live records.
}

function Process(e: IInterface): integer;
var
  sig, edid: string;
begin
  sig := Signature(e);
  if sig <> 'VTYP' then begin
    Result := 0;
    Exit;
  end;

  edid := EditorID(e);
  AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'VTYP' + #9 + edid + #9 + Name(e));
  Result := 0;
end;

end.
