unit dump_factions;
{
  xEdit Apply Script: dump FACT (faction) records from Skyrim.esm.
  ----------------------------------------------------------------
  Source repo: D:\gerkgit\Skyrim_iNPCForge
  Usage: xEdit -> right-click Skyrim.esm -> Apply Script... -> browse here
  Output: FormID <TAB> EditorID <TAB> Name (Messages panel)

  Purpose: verify faction FormIDs for NPC faction assignments.
  Critical because fabricated faction FormIDs silently break NPC behavior
  (e.g. BanditFaction was 00033A35, real is 0001BCC0 — discovered 2026-06-14).
}

function Process(e: IInterface): integer;
var
  sig: string;
begin
  sig := Signature(e);

  if sig = 'FACT' then begin
    AddMessage(
      IntToHex(GetLoadOrderFormID(e), 8) + #9 +
      EditorID(e) + #9 +
      Name(e)
    );
  end;

  Result := 0;
end;

end.
