unit dump_clfm;
{
  xEdit Apply Script: dump CLFM (color) records from Skyrim.esm.
  Hair colors, eye colors, tint palettes.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: SSEEdit -IKnowWhatImDoing -script:"dump_clfm.pas"
  Output: FormID <TAB> CLFM <TAB> EditorID <TAB> Name (Messages panel)
}

function Process(e: IInterface): integer;
begin
  if Signature(e) <> 'CLFM' then begin
    Result := 0;
    Exit;
  end;
  if EditorID(e) = '' then begin
    Result := 0;
    Exit;
  end;
  AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'CLFM' + #9 + EditorID(e) + #9 + Name(e));
  Result := 0;
end;
end.
