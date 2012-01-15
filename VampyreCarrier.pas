(*
 @Abstract(Vampyre carrier unit)
 (C) 2010 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Created: Feb 22, 2010 <br>
 Unit contains resource carrier implementation based on Vampyre Imaging library (http://imaginglib.sourceforge.net)
*)
{$I GDefines.inc}
{$I C2Defines.inc}
unit VampyreCarrier;

interface

uses
  SysUtils,
  Logger,
  BaseTypes, Basics, BaseStr, 
  BaseClasses, Resources,
  VCLHelper,
  Imaging, ImagingTypes;

type
  TVampyreCarrier = class(TImageCarrier)
  public
    procedure Init; override;
    function GetResourceClass: CItem; override;
    function DoLoad(Stream: TStream; const AURL: string; var Resource: TItem): Boolean; override;
  end;

  function VampyreToPixelFormat(Format: TImageFormat): TPixelFormat;

implementation

function VampyreToPixelFormat(Format: TImageFormat): TPixelFormat;
begin
  case Format of
    ifUnknown: Result := pfUndefined;
    ifDefault: Result := TPixelFormat(pfAuto);
    { Indexed formats using palette.}
    ifIndex8: Result := pfP8;
    { Grayscale/Luminance formats.}
    ifGray8:     Result := pfL8;
    ifA8Gray8:   Result := pfA8L8;
    ifGray16:    Result := pfD16;                             // fix
    ifGray32:    Result := pfD32;                             // fix
    ifGray64:    Result := pfUndefined;                       // fix
    ifA16Gray16: Result := pfV16U16;                        // fix
    { ARGB formats.}
    ifX5R1G1B1:     Result := pfUndefined;                  // fix
    ifR3G3B2:       Result := pfUndefined;                  // fix
    ifR5G6B5:       Result := pfR5G6B5;
    ifA1R5G5B5:     Result := pfA1R5G5B5;
    ifA4R4G4B4:     Result := pfA4R4G4B4;
    ifX1R5G5B5:     Result := pfX1R5G5B5;
    ifX4R4G4B4:     Result := pfX4R4G4B4;
    ifR8G8B8:       Result := pfB8G8R8;
    ifA8R8G8B8:     Result := pfA8R8G8B8;
    ifX8R8G8B8:     Result := pfX8R8G8B8;
    ifR16G16B16:    Result := pfUndefined;                  // fix
    ifA16R16G16B16: Result := pfUndefined;                  // fix
    ifB16G16R16:    Result := pfUndefined;                  // fix
    ifA16B16G16R16: Result := pfUndefined;                  // fix
    { Floating point formats.}
    ifR32F:          Result := pfUndefined;                 // fix
    ifA32R32G32B32F: Result := pfUndefined;                 // fix
    ifA32B32G32R32F: Result := pfUndefined;                 // fix
    ifR16F:          Result := pfATIDF16;                   // fix
    ifA16R16G16B16F: Result := pfUndefined;                 // fix
    ifA16B16G16R16F: Result := pfUndefined;                 // fix
    { Special formats.}
    ifDXT1:  Result := pfDXT1;                 // fix
    ifDXT3:  Result := pfDXT3;                 // fix
    ifDXT5:  Result := pfDXT5;                 // fix
    ifBTC:   Result := pfUndefined;                 // fix
    ifATI1N: Result := pfUndefined;                 // fix
    ifATI2N: Result := pfUndefined;                 // fix
    else Result := pfUndefined;
  end;
end;

{ TVampyreCarrier }

procedure TVampyreCarrier.Init;
var
  i, Index: Integer;
  Desc, Ext, Masks: string;
  CanSave, IsMultiImage: Boolean;
  Exts: TStringArray;

  procedure AddToTypesList(var TypesList: TResTypeList; ResTypeID: TResourceTypeID);
  begin
    SetLength(TypesList, Length(TypesList)+1);
    TypesList[High(TypesList)] := ResTypeID;
  end;

begin
  Index := 0;
  while EnumFileFormats(Index, Desc, Ext, Masks, CanSave, IsMultiImage) do begin
    for i := 0 to Split(Masks, ';', Exts, False)-1 do begin
      AddToTypesList(LoadingTypes, GetResTypeFromExt(GetFileExt(Exts[i])));
      if CanSave then AddToTypesList(SavingTypes, GetResTypeFromExt(GetFileExt(Exts[i])));
    end;
  end;
end;

function TVampyreCarrier.GetResourceClass: CItem;
begin
  Result := TImageResource;
end;

function TVampyreCarrier.DoLoad(Stream: TStream; const AURL: string; var Resource: TItem): Boolean;
var Img: TImageData; Garbage: IRefcountedContainer; VCLStream: TVCLStream; Format: TPixelFormat;
begin
  Result := False;

  Garbage := CreateRefcountedContainer;
  VCLStream := TVCLStream.Create;
  Garbage.AddObject(VCLStream);
  VCLStream.Stream := Stream;

  if LoadImageFromStream(VCLStream, Img) then begin
    Format := VampyreToPixelFormat(Img.Format);
    if (Format = pfUndefined) or (Format = pfP8) then begin
      if ConvertImage(Img, ifA8R8G8B8) then
        Format := pfA8R8G8B8
      else
        Log(ClassName + '.DoLoad: failed to convert image', lkError);
    end;
    Result := InitResource(Resource as TImageResource, AURL, Img.Width, Img.Height, Format, Img.Size, Img.Bits);
  end else Log(ClassName + '.DoLoad: failed to load URL "' + AURL + '"', lkError);
end;

end.
