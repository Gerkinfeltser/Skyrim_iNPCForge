unit dump_weapons;
{
  xEdit Apply Script: dump WEAP records from Skyrim.esm.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: SSEEdit -IKnowWhatImDoing -script:"dump_weapons.pas"
  Output: FormID <TAB> WEAP <TAB> EditorID <TAB> Name (Messages panel)
  Covers ALL weapon records.
}

function Process(e: IInterface): integer;
begin
  if Signature(e) <> 'WEAP' then begin
    Result := 0;
    Exit;
  end;
  if EditorID(e) = '' then begin
    Result := 0;
    Exit;
  end;
  AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'WEAP' + #9 + EditorID(e) + #9 + Name(e));
  Result := 0;
end;
end.
