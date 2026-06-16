unit dump_all_armor;
{
  xEdit Apply Script: dump ALL ARMO records from Skyrim.esm.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: SSEEdit -IKnowWhatImDoing -script:"dump_all_armor.pas"
  Output: FormID <TAB> ARMO <TAB> EditorID <TAB> Name (Messages panel)
  Covers: ALL armor/clothing records including enchanted variants.
}

function Process(e: IInterface): integer;
begin
  if Signature(e) <> 'ARMO' then begin
    Result := 0;
    Exit;
  end;
  if EditorID(e) = '' then begin
    Result := 0;
    Exit;
  end;
  AddMessage(IntToHex(GetLoadOrderFormID(e), 8) + #9 + 'ARMO' + #9 + EditorID(e) + #9 + Name(e));
  Result := 0;
end;
end.
