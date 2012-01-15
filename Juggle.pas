(*
 @Abstract(Juggle unit)
 (C) 2006-2011 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Created: Jan 28, 2011
 Unit contains library for fast and easy manipulation on entities
*)
{$Include GDefines.inc}
{$Include C2Defines.inc}
unit Juggle;

interface

{$DEFINE _juggle_uses}
uses
  Logger,
  {$I juggle_ext.inc}
  Basics, BaseStr, Props, BaseClasses, BaseTypes, json;
{$UNDEF _juggle_uses}

{$DEFINE _juggle_interface}
type
  // Query string type
  TJuggleQuery = AnsiString;

  { Delegate which called by TJItems.ForEach() method for each Item in selection.
    Item - current item, Index - item index in selection, Data - user supplied data.
    If the delegate return True ForEach() will exit. }
  TJForEachDelegate = function(Item: TItem; Index: Integer; Data: Pointer): Boolean of object;
  { Calback which called by TJItems.ForEach() method for each Item in selection.
    Item - current item, Index - item index in selection, Data - user supplied data.
    If the callback return True ForEach() will exit. }
  TJForEachCallback = function(Item: TItem; Index: Integer; Data: Pointer): Boolean;

  // Class of Juggle items
  CJItems = class of TJItems;

  // Query result class. Immutable.
  TJItems = class
  protected
    FQuery: TJuggleQuery;
    FItems: TItems;          // do not allow duplicate items
    FCount: Integer;

    function FilterByName(Item: TItem): TExtractCondition;
    function FilterByProperty(Item: TItem): TExtractCondition;   // [NOT IMPLEMENTED]
    procedure RetrieveChildsByMask(AParent: TItem; const Mask: AnsiString; var Result: TItems);

    constructor CreateWithFilter(CurrentItems: TItems; const AQuery: TJuggleQuery); overload;
    constructor CreateWithFilter(CurrentItems: TItems; ItemClass: CItem); overload;
  protected
    // Query string which used to create this instance
    property Query: TJuggleQuery read FQuery;

  public
    // Filtering
    // Filters the current set by performing the query over it and returns the result in a new TJItems instance
    function Filter(const Query: TJuggleQuery): TJItems; overload;
    // Finds items of the specified class or its descendant from the current set and returns the result in a new TJItems instance
    function Filter(ItemClass: CItem): TJItems; overload;

    // Calls the delegate for each item in the current set and returns self
    function ForEach(Delegate: TJForEachDelegate; Data: Pointer): TJItems; overload;
    // Calls the callback for each item in the current set and returns self
    function ForEach(Callback: TJForEachCallback; Data: Pointer): TJItems; overload;

    // Traverse
    // Clones each item in the current set and returns the result in a new TJItems instance
    function Clone(): TJItems;
    // Finds immediate childs for each item in the current set and returns the result in a new TJItems instance
    function Childs(): TJItems;
    // Finds all childs of any level for each item in the current set and returns the result in a new TJItems instance
    function Hierarchy(): TJItems;
    // Finds sibling items (same level items) for each item in the current set and returns the result in a new TJItems instance
    function Sibling(): TJItems;

    // Properties set
    // Sets the specified property for all items in the current set and returns self
    function Prop(PropertyName: TPropertyName; PropertyValue: TPropertyValue): TJItems;
    // [NOT IMPLEMENTED] Sets the specified as JSON property set for all items in the current set and returns self
    function Props(Properties: TPropertyPairs): TJItems;

    // Turns on the visibility of each item in the current set and returns self
    function Show(): TJItems;
    // Turns off the visibility of each item in the current set and returns self
    function Hide(): TJItems;
    // Toggles the visibility of each item in the current set and returns self
    function Toggle(): TJItems;

    {$I juggle_ext.inc}

  end;

  // Query management class. Immutable.
  TJuggle = class
  private
    FManager: TItemsManager;
  public
    // Creates an immutable instance of the class
    constructor Create(AManager: TItemsManager);
  end;

  // Juggle creation routine. Should be called first.
  procedure InitJuggle(AManager: TItemsManager);
  // Function to initiate query
  function Q(const Query: TJuggleQuery): TJItems; overload;
  function Q(ItemClass: CItem): TJItems; overload;

{$UNDEF _juggle_interface}

implementation

{$DEFINE _juggle_implementation}

var
  Jug: TJuggle = nil;

  procedure InitJuggle(AManager: TItemsManager);
  begin
    Jug := TJuggle.Create(AManager);
  end;

  function Q(const Query: TJuggleQuery): TJItems;
  begin
    Result := TJItems.CreateWithFilter(nil, Query);
  end;

  function Q(ItemClass: CItem): TJItems; overload;
  begin
    Result := TJItems.CreateWithFilter(nil, ItemClass);
  end;

{ TJuggle }

constructor TJuggle.Create(AManager: TItemsManager);
begin
  FManager := AManager;
  if FManager = nil then
    Log('TJuggle.Create: AManager should not be nil', lkError)
  else
    Jug := Self;
end;

{ TJItems }

function TJItems.FilterByName(Item: TItem): TExtractCondition;
begin
  Result := [];
  if MaskMatch(FQuery, Item.Name) then Include(Result, ecPassed);
end;

function TJItems.FilterByProperty(Item: TItem): TExtractCondition;
begin

end;

procedure TJItems.RetrieveChildsByMask(AParent: TItem; const Mask: AnsiString; var Result: TItems);
var i, cnt: Integer;
begin
  if AParent = nil then Exit;

  SetLength(Result, AParent.TotalChilds);

  cnt := 0;

  for i := 0 to AParent.TotalChilds-1 do
    if MaskMatch(Mask, AParent.Childs[i].Name) then begin
      Result[cnt] := AParent.Childs[i];
      Inc(cnt);
    end;

  SetLength(Result, cnt);
end;

constructor TJItems.CreateWithFilter(CurrentItems: TItems; const AQuery: TJuggleQuery);
var i, lastDelimPos: Integer; PropertyQuery: Boolean;
begin
  if Jug = nil then begin
    Log('Juggle: Call InitJuggle() before use');
    Exit;
  end;

  FQuery := AQuery;
  if Query = '' then Exit;

  // Find out type of query
  lastDelimPos  := 0;
  PropertyQuery := False;
  i := Length(Query);
  while (i >= 1) and not PropertyQuery do begin
    case Query[i] of
      '{': PropertyQuery := True;
      HierarchyDelimiter: if lastDelimPos = 0 then lastDelimPos := i;
    end;
    Dec(i);
  end;

  if lastDelimPos = 1 then lastDelimPos := 0;                 // Empty path

  if PropertyQuery then begin                                 // Property filter
    FCount := Jug.FManager.Root.Extract(FilterByProperty, FItems)
  end else if lastDelimPos = 0 then                           // Name filter
    FCount := Jug.FManager.Root.Extract(FilterByName, FItems)
  else begin                                                  // Path filter
    RetrieveChildsByMask(Jug.FManager.Root.GetItemByPath(Copy(FQuery, 1, lastDelimPos-1)),
                         Copy(FQuery, lastDelimPos+1, Length(FQuery)),
                         FItems);
  end;
end;

constructor TJItems.CreateWithFilter(CurrentItems: TItems; ItemClass: CItem);
var i: Integer;
begin
  if CurrentItems = nil then
    Jug.FManager.Root.ExtractByClass(ItemClass, FItems)
  else begin
    FCount := 0;
    for i := 0 to High(CurrentItems) do if CurrentItems[i] is ItemClass then begin
      if Length(FItems) <= FCount then SetLength(FItems, Length(FItems) + ItemsCapacityStep);
      FItems[FCount] := CurrentItems[i];
      Inc(FCount);
    end;
    SetLength(FItems, FCount);

  end;
end;

function TJItems.ForEach(Delegate: TJForEachDelegate; Data: Pointer): TJItems;
var i: Integer;
begin
  i := 0;
  while (i < FCount) and not Delegate(FItems[i], i, Data) do Inc(i);
  Result := Self;
end;

function TJItems.ForEach(Callback: TJForEachCallback; Data: Pointer): TJItems;
var i: Integer;
begin
  i := 0;
  while (i < FCount) and not Callback(FItems[i], i, Data) do Inc(i);
  Result := Self;
end;

function TJItems.Clone: TJItems;
var i: Integer;
begin
  Result := TJItems.Create;
  SetLength(Result.FItems, Length(FItems));
  Result.FCount := FCount;
  for i := 0 to FCount-1 do
    if Assigned(FItems[i]) then
      Result.FItems[i] := FItems[i].Clone;
end;

function TJItems.Childs: TJItems;
var i, j, ind: Integer;
begin
  Result := TJItems.Create;

  for i := 0 to FCount-1 do
    if Assigned(FItems[i]) and (FItems[i].TotalChilds > 0) then begin
      ind := Length(Result.FItems);
      SetLength(Result.FItems, ind + FItems[i].TotalChilds);
      for j := 0 to FItems[i].TotalChilds-1 do
        Result.FItems[j + ind] := FItems[i].Childs[j];
    end;

  Result.FCount := Length(Result.FItems);
end;

function TJItems.Hierarchy: TJItems;

  procedure TraverseExtract(Item: TItem);
  var i: Integer;
  begin
    if Length(Result.FItems) <= Result.FCount then SetLength(Result.FItems, Length(Result.FItems) + ItemsCapacityStep);
    Result.FItems[Result.FCount] := Item;
    Inc(Result.FCount);

    for i := 0 to Item.TotalChilds-1 do begin
      {$IFDEF DEBUGMODE}
      Assert(Item.Childs[i] <> nil, 'TRootItem.Extract.TraverseExtract: Childs[i] cannot be nil');
      {$ENDIF}
      TraverseExtract(Item.Childs[i]);
    end;
  end;

var i, j: Integer;
begin
  Result := TJItems.Create;

  for i := 0 to FCount-1 do
    if Assigned(FItems[i]) and (FItems[i].TotalChilds > 0) then
      for j := 0 to FItems[i].TotalChilds-1 do
        TraverseExtract(FItems[i].Childs[j]);
end;

function TJItems.Sibling: TJItems;
var i, j, ind: Integer;
begin
  Result := TJItems.Create;

  for i := 0 to FCount-1 do
    if Assigned(FItems[i]) and Assigned(FItems[i].Parent) and (FItems[i].Parent.TotalChilds > 1) then begin
      ind := Length(Result.FItems);
      SetLength(Result.FItems, ind + FItems[i].Parent.TotalChilds-1);
      for j := 0 to FItems[i].Parent.TotalChilds-1 do if FItems[i].Parent.Childs[j] <> FItems[i] then begin
        Result.FItems[ind] := FItems[i].Parent.Childs[j];
        Inc(ind);
      end;
    end;

  Result.FCount := Length(Result.FItems);
end;

function TJItems.Filter(ItemClass: CItem): TJItems;
begin

end;

function TJItems.Filter(const Query: TJuggleQuery): TJItems;
begin

end;

function TJItems.Prop(PropertyName: TPropertyName; PropertyValue: TPropertyValue): TJItems;
var i: Integer;
begin
  Result := Self;
  for i := 0 to High(FItems) do if Assigned(FItems[i]) then FItems[i].SetProperty(PropertyName, PropertyValue);
end;

function TJItems.Props(Properties: TPropertyPairs): TJItems;
begin

end;

{$I juggle_ext.inc}

function TJItems.Show: TJItems;
var i: Integer;
begin
  Result := Self;
  for i := 0 to High(FItems) do if Assigned(FItems[i]) then FItems[i].State := FItems[i].State + [isVisible];
end;

function TJItems.Hide: TJItems;
var i: Integer;
begin
  Result := Self;
  for i := 0 to High(FItems) do if Assigned(FItems[i]) then FItems[i].State := FItems[i].State - [isVisible];
end;

function TJItems.Toggle: TJItems;
var i: Integer;
begin
  Result := Self;
  for i := 0 to High(FItems) do if Assigned(FItems[i]) then
    FItems[i].State := FItems[i].State - (FItems[i].State * [isVisible]) + ([isVisible] - FItems[i].State);
end;

{$UNDEF _juggle_implementation}

initialization

finalization
  if Assigned(Jug) then begin
    Jug.Destroy();
    Jug := nil;
  end;

end.
