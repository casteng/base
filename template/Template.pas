(*
  @Abstract(Base code template support unit)
  (C) 2011 George "Mirage" Bakhtadze.
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file
  Created: Sep 24, 2011
  The unit contains template related constants
*)
{$Include GDefines.inc}
unit Template;

interface
  //  Template option constants
  const
    // sort in descending order
    soDescending = 0;
    // sort data can be extremely quicksort-unfriendly
    soBadData = 1;

    // data structure value can be nil
    dsNullable = 0;
    // data structure should perform range checking
    dsRangeCheck = 1;

    // data structure allow random access
    dsRandomAccess = 2;

  type
    // Type for collection indexes, sizes etc
    __CollectionIndexType = Integer;

    TCollection = interface

    end;

    TGenList = interface

    end;

    TMap = interface

    end;

    // Implemets base interface for template classes
    TTemplateInterface = class(TObject, IInterface)
    protected
      function QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
      function _AddRef:  Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
      function _Release: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
    end;

implementation

{ TTemplateInterface }

function TTemplateInterface.QueryInterface({$IFDEF FPC_HAS_CONSTREF}constref{$ELSE}const{$ENDIF} IID: TGUID; out Obj): HResult; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TTemplateInterface._AddRef: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  Result := 1;
end;

function TTemplateInterface._Release: Integer; {$IF (not defined(WINDOWS)) AND (FPC_FULLVERSION>=20501)}cdecl{$ELSE}stdcall{$IFEND};
begin
  Result := 1;
end;

end.