(*
  Template linked list collection
  (C) George Bakhtadze
Usage - once per unit:
  type
    _LinkedListValueType = <some type>;
    $I gen_coll_linkedlist.inc}

    T<xxx>LinkedList = class(_GenLinkedList)
    end;

  implementation

   [ function _LinkedListEquals(const v1, v2: _LinkedListValueType): Boolean;
     begin
       Result := v1 = v2;      // actual comparing code
     end;]

    $I gen_coll_linkedlist.inc}
*)

{$IF Declared(_LinkedListOptions)}
  {$I gen_coll_linkedlist_opt.inc}
{$IFEND}

{$IFNDEF _LINKEDLISTIMPL}     // Interface

  {$I _T.inc} = _LinkedListValueType;
  _LinkedListDelegate = function(const e: _LinkedListValueType; Data: Pointer): Boolean of object;
  {$I _Dg.inc} = _LinkedListDelegate;
  _IGenLinkedList = interface
    {$MESSAGE 'Instantiating _IGenVector interface for a template linked list type'}
    {$I gen_coll_list.inc}
  end;

  // Template linked list node type
  {$IF not Declared(_LinkedListNodePTR)}
  _LinkedListNodePTR = ^_LinkedListNode;
  {$IFEND}
  {$IF not Declared(_LinkedListNode)}
  _LinkedListNode = record
    // List value
    V: _LinkedListValueType;
    // Pointer to next node
    Next: _LinkedListNodePTR;
  end;
  {$IFEND}

  {
    Template linked list implementation.
    Performance of addition and insertion is O(Const).
    Performance of non-last node removal is also O(Const).
    Performance of a value removal or last node removal is O(Count).
    Not thread safe.
  }
  _GenLinkedList = class(TTemplateInterface, _IGenLinkedList)
  protected
    FFirst, FLast: _LinkedListNodePTR;
    FCount: __CollectionIndexType;

    // Returns list value at the specified position
    procedure SetValue(Index: __CollectionIndexType; const e: _LinkedListValueType); {$I inline.inc}
    //function GetPrev(p: _LinkedListNodePTR): _LinkedListNodePTR; {$I inline.inc}
    // Returns the value assotiated with node p
    function GetNodeValue(p: _LinkedListNodePTR): _LinkedListValueType; {$I inline.inc}
  public
    // Constructs a new empty list
    constructor Create();
    // Frees all nodes and destroys the list
    destructor Destroy(); override;

    { Collection interface }

    // Returns the number of elements in the collection
    function GetCount(): __CollectionIndexType; {$I inline.inc}
    // Returns True if the collection contains no elements
    function IsEmpty(): Boolean; {$I inline.inc}
    // Returns True if the collection contains the specified element
    function Contains(const e: _LinkedListValueType): Boolean;
    // Calls the delegate for each element in the collection
    procedure ForEach(Delegate: _LinkedListDelegate; Data: Pointer);
    {/ Ensures that the collection contains the specified element.
       Returns True if the element was successfully added or False if the collection
       already contains the element and duplicates are not allowed.
       Otherwise the method should raise an error. /}
    function Add(const e: _LinkedListValueType): Boolean; {$I inline.inc}
    {/ Removes the specified element from the collection.
       Returns True if the collection contained the element./}
    function Remove(const e: _LinkedListValueType): Boolean;
    // Frees all nodes makes the list empty
    procedure Clear(); {$I inline.inc}
    // Number of elements
    property Count: __CollectionIndexType read FCount;

    { List interface }

    {/ Returns the element at the specified position in the list.
       Throws an error on invalid index if dsRangeCheck was included in the list options before instantiation. }
    function Get(Index: __CollectionIndexType): _LinkedListValueType; {$I inline.inc}
    {/ Replaces the element at the specified position in the list with the specified element.
       Returns the element previously at the specified position.
       Throws an error on invalid index if dsRangeCheck was included in the list options when instantiation. }
    function Put(Index: __CollectionIndexType; const e: _LinkedListValueType): _LinkedListValueType; {$I inline.inc}
    {/ Inserts the element at the specified position in the list
       Throws an error on invalid index if dsRangeCheck was included in the list options when instantiation. }
    procedure Insert(Index: __CollectionIndexType; const e: _LinkedListValueType);
    {/ Removes the element at the specified position in the list
       Returns the element that was removed from the list. }
    function RemoveBy(Index: __CollectionIndexType): _LinkedListValueType;  {$I inline.inc}
    {/ Returns the index of the first occurrence of the specified element in the list,
       or -1 if the list does not contain the element. }
    function IndexOf(const e: _LinkedListValueType): __CollectionIndexType; {$I inline.inc}
    {/ Returns the index of the last occurrence of the specified element in the list,
       or -1 if the list does not contain the element. }
    function LastIndexOf(const e: _LinkedListValueType): __CollectionIndexType; {$I inline.inc}
    // Values retrieved by index
    property Values[Index: __CollectionIndexType]: _LinkedListValueType read Get write SetValue; default;

    { Linked List interface }

    // Creates and returns a new stand alone node with the same value as p
    function NewNode(const e: _LinkedListValueType): _LinkedListNodePTR; {$I inline.inc}
    // Adds a new node p to the end of the list
    procedure AddNode(p: _LinkedListNodePTR); {$I inline.inc}
    // Inserts a new element e to the beginning of the list
    procedure InsertNodeFirst(const e: _LinkedListValueType); {$I inline.inc}
    // Adds a new element e after the specified node
    procedure InsertNode(Node: _LinkedListNodePTR; const e: _LinkedListValueType); {$I inline.inc}
    // Returns first occured node containing the element
    function GetNode(const e: _LinkedListValueType): _LinkedListNodePTR; {$I inline.inc}
    // Returns note at the specified index
    function GetNodeBy(Index: __CollectionIndexType): _LinkedListNodePTR; {$I inline.inc}

    // Returns a node next to p or nil if p is the last node
    function GetNextNode(p: _LinkedListNodePTR): _LinkedListNodePTR; {$I inline.inc}
    // Returns a node next to p or first node if p is the last node
    function GetNextNodeCyclic(p: _LinkedListNodePTR): _LinkedListNodePTR; {$I inline.inc}

    // Removes p and returns next node
    function RemoveNode(p: _LinkedListNodePTR): _LinkedListNodePTR;
  end;

  {$DEFINE _LINKEDLISTIMPL}
{$ELSE}                    // Implementation

  { _GenLinkedList }

  procedure _GenLinkedList.SetValue(Index: __CollectionIndexType; const e: _LinkedListValueType);
  begin
    GetNodeBy(Index)^.V := e;
  end;

  {function _GenLinkedList.GetPrev(p: _LinkedListNodePTR): _LinkedListNodePTR;
  begin
    Result := p^.Prev;
    if Result = nil then Result := FLast;
  end;}

  function _GenLinkedList.GetNodeValue(p: _LinkedListNodePTR): _LinkedListValueType;
  begin
    Result := p^.V;
  end;

  constructor _GenLinkedList.Create();
  begin
    FFirst := nil;
    FLast := nil;
    FCount := 0;
  end;

  destructor _GenLinkedList.Destroy();
  begin
    Clear();
    inherited;
  end;

  { Collection interface }

  function _GenLinkedList.GetCount(): __CollectionIndexType;
  begin
    Result := FCount;
  end;

  function _GenLinkedList.IsEmpty(): Boolean;
  begin
    Result := FCount = 0;
  end;

  function _GenLinkedList.Contains(const e: _LinkedListValueType): Boolean;
  begin
    Result := IndexOf(e) >= 0;
  end;

  procedure _GenLinkedList.ForEach(Delegate: _LinkedListDelegate; Data: Pointer);
  var p: _LinkedListNodePTR;
  begin
    p := FFirst;
    while p <> nil do begin
      Delegate(p^.V, Data);
      p := p^.Next;
    end;
  end;

  function _GenLinkedList.Add(const e: _LinkedListValueType): Boolean;
  begin
    AddNode(NewNode(e));
    Result := True;
  end;

  function _GenLinkedList.Remove(const e: _LinkedListValueType): Boolean;
  var p: _LinkedListNodePTR;
  begin
    p := GetNode(e);
    Result := p <> nil;
    if Result then RemoveNode(p);
  end;

  procedure _GenLinkedList.Clear();
  begin
    while FFirst <> nil do RemoveNode(FFirst);
    Assert(FLast = nil);
    Assert(FCount = 0);
  end;

  { List interface }

  function _GenLinkedList.Get(Index: __CollectionIndexType): _LinkedListValueType;
  begin
    Result := GetNodeBy(Index)^.V;
  end;

  function _GenLinkedList.Put(Index: __CollectionIndexType; const e: _LinkedListValueType): _LinkedListValueType;
  var p: _LinkedListNodePTR;
  begin
    p := GetNodeBy(Index);
    Result := p^.V;
    p^.V := e;
  end;

  procedure _GenLinkedList.Insert(Index: __CollectionIndexType; const e: _LinkedListValueType);
  begin
    if Index = 0 then
      InsertNodeFirst(e)
    else
      InsertNode(GetNodeBy(Index-1), e);
  end;

  function _GenLinkedList.RemoveBy(Index: __CollectionIndexType): _LinkedListValueType;
  var p: _LinkedListNodePTR;
  begin
    p := GetNodeBy(Index);
    Result := p^.V;
    RemoveNode(p);
  end;

  function _GenLinkedList.IndexOf(const e: _LinkedListValueType): __CollectionIndexType;
  var p: _LinkedListNodePTR;
  begin
    Result := 0;
    p := FFirst;
    while p <> nil do begin
      {$IF Declared(_LinkedListEquals)}
        if _LinkedListEquals(p^.V, e) then Break;
      {$ELSE}
        if (p^.V = e) then Break;
      {$IFEND}
      p := p^.Next;
      Inc(Result);
    end;

    if Result >= FCount then Result := -1;
  end;

  function _GenLinkedList.LastIndexOf(const e: _LinkedListValueType): __CollectionIndexType;
  var
    p: _LinkedListNodePTR;
    i: __CollectionIndexType;
  begin
    Result := -1;
    p := FFirst;
    i := 0;
    while p <> nil do begin
      {$IF Declared(_LinkedListEquals)}
        if _LinkedListEquals(p^.V, e) then Result := i;
      {$ELSE}
        if (p^.V = e) then Result := i;
      {$IFEND}
      p := p^.Next;
      Inc(i);
    end;
  end;

  { Linked List interface }

  function _GenLinkedList.NewNode(const e: _LinkedListValueType): _LinkedListNodePTR;
  begin
    New(Result);
    Result^.V := e;
  end;

  procedure _GenLinkedList.AddNode(p: _LinkedListNodePTR);
  begin
  //  p^.Prev := FLast;
    p^.Next := nil;
    if FLast <> nil then FLast^.Next := p;
    FLast := p;
    if FFirst = nil then FFirst := p;

    Inc(FCount);
  end;

  procedure _GenLinkedList.InsertNodeFirst(const e: _LinkedListValueType);
  var p: _LinkedListNodePTR;
  begin
    p := NewNode(e);
    p^.Next := FFirst;
    FFirst := p;
    if FLast = nil then FLast := p;
  end;

  procedure _GenLinkedList.InsertNode(Node: _LinkedListNodePTR; const e: _LinkedListValueType);
  var p: _LinkedListNodePTR;
  begin
    Assert(Node <> nil, 'Invalid node');
    p := NewNode(e);

    p^.Next := Node^.Next;
    Node^.Next := p;
    Assert(FLast <> nil, 'Invalid list');
    if Node = FLast then FLast := p;
    if FFirst = nil then FFirst := p;

    Inc(FCount);
  end;

  function _GenLinkedList.GetNode(const e: _LinkedListValueType): _LinkedListNodePTR;
  begin
    Result := FFirst;
    while Result <> nil do
      {$IF Declared(_LinkedListEquals)}
        if _LinkedListEquals(Result^.V, e) then Break else Result := Result^.Next;
      {$ELSE}
        if (Result^.V = e) then Break else Result := Result^.Next;
      {$IFEND}
  end;

  function _GenLinkedList.GetNodeBy(Index: __CollectionIndexType): _LinkedListNodePTR;
  begin
    {$IFDEF _RANGECHECK}
      if (Index < 0) or (Index >= FCount) then Assert(False, 'Range check error');
    {$ENDIF}
    Result := FFirst;
    while Index > 0 do begin
      Dec(Index);
      Result := Result^.Next;
    end;
    Assert(Result <> nil, 'Invalid list');
  end;

  function _GenLinkedList.GetNextNode(p: _LinkedListNodePTR): _LinkedListNodePTR;
  begin
    if p = nil then
      Result := FFirst
    else
      Result := p^.Next;
  end;

  function _GenLinkedList.GetNextNodeCyclic(p: _LinkedListNodePTR): _LinkedListNodePTR;
  begin
    Result := GetNextNode(p);
    if Result = nil then Result := FFirst;
  end;

  function _GenLinkedList.RemoveNode(p: _LinkedListNodePTR): _LinkedListNodePTR;
  var tp: _LinkedListNodePTR;
  begin
    // If p is not the FLast element copy next to p and remove next !!! Too dangerous !!!
{    if p^.Next <> nil then begin
      Assert(FLast <> p, 'FLast.next is not nil');
      tp := p^.Next;
      p^.V := tp^.V;
      p^.Next := tp^.Next;
      if FLast = tp then FLast := p;
      Result := p;
      Dispose(tp);
    end else begin}
  //    Assert(FLast = p, 'next is nil for not FLast');
      if FFirst = p then
        FFirst := p^.Next
      else begin
        // Find previous
        tp := FFirst;
        while tp^.Next <> p do tp := tp^.Next;
        tp^.Next := p^.Next;
      end;
      if FLast = p then FLast := nil;
      Result := p^.Next;
      {$IFDEF DEBUG}
        FillChar(p^.V, SizeOf(p^.V), 0);
        p^.Next := nil;
      {$ENDIF}
      Dispose(p);
//    end;

    Dec(FCount);
  end;

  {$UNDEF _LINKEDLISTIMPL}
{$ENDIF}