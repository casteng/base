(*
  @Abstract(Geometry routines unit)
  (C) 2003-2011 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br/>
  The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br/>
  Created: Nov 20, 2011
  The unit contains geometry related types and routines
*)
{$Include GDefines.inc}
unit Geometry;

interface

uses Basics, BaseTypes, Template;

type
  // Point positions relative to a line
  TPointPosition = (ppLEFT, ppRIGHT, ppBEYOND, ppBEHIND, ppBETWEEN, ppORIGIN, ppDESTINATION);

  // Array of 2D points
  TPoints2D = array of TVector2s;
  // Array of 3D points
  TPoints3D = array of TVector3s;

  // Indices of three points in an array of points
  TTriangle = array[0..2] of TVector2s;
  // array of triangles
  TTriangles = array of TTriangle;

  // Set template linked list type and instantiate it
  _LinkedListValueType = TVector2s;
  {$MESSAGE 'Instantiating T2DPointList interface'}
  {$I gen_coll_linkedlist.inc}
  // List of 2-dimensional points
  T2DPointList = class(_GenLinkedList)
  private
    TriangulatedCount: Integer;
    Triangulated: TTriangles;
    procedure DoTriangulation(Poly: T2DPointList);
  public
    // Adds all points in the array to the list
    procedure AddAll(const APoints: TPoints2D);

    // Splits the list along the line between points in p1 and p2 nodes and returns splitted part as another list
    function Split(p1, p2: _LinkedListNodePTR): T2DPointList;
    // Returns next vertice which makes a convex vertice with next two vertices or nil if no such vertices found
    function GetNextConvexVertice(const Start: _LinkedListNodePTR): _LinkedListNodePTR;
    { Returns vertice which is inside a-b-c triangle and is farest from a-c edge, or nil if no such vertices found
      where b is next to a and c is next to b vertice }
    function GetFarestIntrudingVertex(a: _LinkedListNodePTR): _LinkedListNodePTR;
    // Returns array of triangles built over the points in the list as it is representing a polygon
    function Triangulate(): TTriangles;
  end;

const
  // Zero 2D vector
  ZeroVector2s: TVector2s = (X: 0; Y: 0);

  // Forces <b>Angle</b> to [0..2*pi] range
  procedure NormalizeAngle(var Angle: Single);

  // Returns a 2-dimensional vector with the specified components
  function GetVector2s(const X, Y: Single): TVector2s; overload; {$I inline.inc}
  // Returns a 2-dimensional vector with the specified components
  procedure GetVector2s(out Result: TVector2s; const X, Y: Single); overload; {$I inline.inc}
  // Returns a 2-dimensional vector with the specified components
  function Vec2s(const X, Y: Single): TVector2s; {$I inline.inc}

  // Returns a 3-dimensional vector with the specified components
  function Vec3s(const X, Y, Z: Single): TVector3s; {$I inline.inc}

  // Returns @True if <b>V1</b> and <b>V2</b> are equal
  function VecEquals(const V1, V2: TVector2s): Boolean; overload; {$I inline.inc}
  // Returns @True if <b>V1</b> and <b>V2</b> are equal
  function VecEquals(const V1, V2: TVector3s): Boolean; overload; {$I inline.inc}

  // Returns sum of two vectors
  function VecAdd(const V1, V2: TVector2s): TVector2s; overload; {$I inline.inc}
  // Returns difference of two vectors
  function VecSub(const V1, V2: TVector2s): TVector2s; overload; {$I inline.inc}
  // Returns scaled vector
  function VecScale(const V: TVector2s; Scale: Single): TVector2s; overload; {$I inline.inc}

  // Returns sum of two vectors
  function VecAdd(const V1, V2: TVector3s): TVector3s; overload; {$I inline.inc}
  // Returns difference of two vectors
  function VecSub(const V1, V2: TVector3s): TVector3s; overload; {$I inline.inc}
  // Returns scaled vector
  function VecScale(const V: TVector3s; Scale: Single): TVector3s; overload; {$I inline.inc}

  // Vectors dot product
  function DotProduct(const V1, V2: TVector2s): Single; overload; {$I inline.inc}
  // Vectors cartesian product
  function CartesianProduct(const V1, V2: TVector2s): TVector2s; overload; {$I inline.inc}
  // Z component of vectors cross product
  function CrossProductZ(const V1, V2: TVector2s): Single; overload; {$I inline.inc}

  // Vectors dot product
  function DotProduct(const V1, V2: TVector3s): Single; overload; {$I inline.inc}
  // Vectors cartesian product
  function CartesianProduct(const V1, V2: TVector3s): TVector3s; overload; {$I inline.inc}
  // Z component of vectors cross product
  function CrossProductZ(const V1, V2: TVector3s): Single; overload; {$I inline.inc}
  // Vectors cross product
  function CrossProduct(const V1, V2: TVector3s): TVector3s; {$I inline.inc}

  // Retuns a vector which is orthogonal to <b>V</b>
  procedure GetPerpendicular(out Result: TVector2s; const V: TVector2s); overload; {$I inline.inc}
  // Retuns a vector which is orthogonal to <b>V</b>
  function GetPerpendicular(const V: TVector2s): TVector2s; overload; {$I inline.inc}

  // Returns the squared magnitude of <b>V</b>
  function SqrMagnitude(const V: TVector2s): Single; overload; {$I inline.inc}
  // Returns the squared magnitude of <b>V</b>
  function SqrMagnitude(const V: TVector3s): Single; overload; {$I inline.inc}

  // Returns 2D point p position relative to a line span (p1-p2)
  function ClassifyPoint(const p, p0, p1: TVector2s): TPointPosition;

  // Returns True if both P1 and P2 points are at the same side of the ray
  function IsPointsSameSide(const P1, P2, Origin, Dir: TVector2s): Boolean; overload; {$I inline.inc}
  // Returns True if both P1 and P2 points are at the same side of the ray
  function IsPointsSameSide(const P1, P2, Origin, Dir: TVector3s): Boolean; overload; {$I inline.inc}

  // Returns True if point p within triangle abc.
  function PointInTriangle(p, a, b, c: TVector2s): Boolean; overload; {$I inline.inc}
  // Returns True if point p within triangle abc.
  function PointInTriangle(p, a, b, c: TVector3s): Boolean; overload; {$I inline.inc}

  // Returns point projection to a line
  procedure ProjectPointToLine(const p, l1, l2: TVector2s; out pp: TVector2s); overload;
  // Returns point projection to a line
  procedure ProjectPointToLine(const p, l1, l2: TVector3s; out pp: TVector3s); overload;

implementation

function _LinkedListEquals(const v1, v2: _LinkedListValueType): Boolean; {$I inline.inc}
begin
  Result := (v1.X = v2.X) and (v1.Y = v2.Y);
end;

{$MESSAGE 'Instantiating T2DPointList'}
{$I gen_coll_linkedlist.inc}
procedure T2DPointList.AddAll(const APoints: TPoints2D);
var i: Integer;
begin
  for i := 0 to High(APoints) do Add(APoints[i]);
end;

function T2DPointList.Split(p1, p2: _LinkedListNodePTR): T2DPointList;
var p: _LinkedListNodePTR;
begin
  Result := T2DPointList.Create();
  Result.AddNode(NewNode(p1^.V));
  p := GetNextNodeCyclic(p1);
  while (p <> nil) and (p^.Next <> p2^.Next) do begin
    Result.AddNode(NewNode(p^.V));
    p := RemoveNode(p);
    if p = nil then p := FFirst;
  end;
  Result.AddNode(NewNode(p2^.V));
end;

// Triangulate sub-polygon poly
procedure T2DPointList.DoTriangulation(Poly: T2DPointList);
var
  p, d: _LinkedListNodePTR;
  SpPoly, tPoly: T2DPointList;
  Done: Boolean;
begin
  Assert(Poly.Count >= 3, 'Invalid sub-polygon');

  Done := False;
  repeat
    if Poly.Count = 3 then begin
      Triangulated[TriangulatedCount][0] := Poly.FFirst^.V;
      Triangulated[TriangulatedCount][1] := Poly.GetNextNodeCyclic(Poly.FFirst)^.V;
      Triangulated[TriangulatedCount][2] := Poly.GetNextNodeCyclic(Poly.GetNextNodeCyclic(Poly.FFirst))^.V;
      Inc(TriangulatedCount);
      Done := True;
    end else begin
      p := Poly.GetNextConvexVertice(Poly.FFirst);
      if p <> nil then begin
        d := Poly.GetFarestIntrudingVertex(p);
        if d <> nil then begin
          SpPoly := Poly.Split(Poly.GetNextNodeCyclic(p), d);
          if SpPoly.Count > Poly.Count then begin
//            Swap(SpPoly, Poly);
            tPoly := SpPoly;
            SpPoly := Poly;
            Poly := tPoly;
          end;
          DoTriangulation(SpPoly);
        end else begin
          SpPoly := Poly.Split(p, Poly.GetNextNodeCyclic(Poly.GetNextNodeCyclic(p)));
          DoTriangulation(SpPoly);
        end;
      end else
        Done := True;
    end;
  until Done;
  if Poly <> Self then Poly.Free();
end;

function T2DPointList.Triangulate: TTriangles;
var
  Poly: T2DPointList;
  p: _LinkedListNodePTR;
begin
  SetLength(Triangulated, MaxI(0, Count-2));
  TriangulatedCount := 0;
  Poly := T2DPointList.Create();
  p := FFirst;
  while p <> nil do begin
    Poly.Add(p^.V);
    p := GetNextNode(p);
  end;

  DoTriangulation(Poly);

  Result := Triangulated;
end;

function T2DPointList.GetNextConvexVertice(const Start: _LinkedListNodePTR): _LinkedListNodePTR;
var b, c: _LinkedListNodePTR; i: Integer;
begin
  if Start = nil then
    Result := FFirst
  else
    Result := Start;

  b := GetNextNodeCyclic(Result);
  c := GetNextNodeCyclic(b);

  for i := 1 to Count do begin
    if CrossProductZ(VecSub(GetNodeValue(b), GetNodeValue(Result)), VecSub(GetNodeValue(c), GetNodeValue(Result))) > 0 then Exit;
    Result := b;
    b := c;
    c := GetNextNodeCyclic(c);
  end;
  Result := nil;
end;

function T2DPointList.GetFarestIntrudingVertex(a: _LinkedListNodePTR): _LinkedListNodePTR;
var
  b, c, p: _LinkedListNodePTR;
  t: _LinkedListValueType;
  d, maxD: Single;
begin
  Result := nil;

  b := GetNextNodeCyclic(a);
  c := GetNextNodeCyclic(b);

  maxD := -1;

  p := GetNextNodeCyclic(c);
  while p <> a do begin
    if PointInTriangle(GetNodeValue(p), GetNodeValue(a), GetNodeValue(b), GetNodeValue(c)) then begin
      ProjectPointToLine(GetNodeValue(p), GetNodeValue(a), GetNodeValue(c), t);
      d := SqrMagnitude(VecSub(t, GetNodeValue(p)));
      if d > maxD then begin
        maxD := d;
        Result := p;
      end;
    end;

    p := GetNextNodeCyclic(p);
  end;
end;

procedure NormalizeAngle(var Angle: Single);
begin
  while Angle < 0 do Angle := Angle + 2*pi;
  while Angle > 2*pi do Angle := Angle - 2*pi;
end;

function GetVector2s(const X, Y: Single): TVector2s;
begin
  Result.X := X; Result.Y := Y;
end;

procedure GetVector2s(out Result: TVector2s; const X, Y: Single); overload;
begin
  Result.X := X; Result.Y := Y;
end;

function Vec2s(const X, Y: Single): TVector2s;
begin
  Result.X := X; Result.Y := Y;
end;

function Vec3s(const X, Y, Z: Single): TVector3s;
begin
  Result.X := X; Result.Y := Y; Result.Z := Z;
end;

function VecEquals(const V1, V2: TVector2s): Boolean;
begin
  Result := (V1.X = V2.X) and (V1.Y = V2.Y);
end;

function VecEquals(const V1, V2: TVector3s): Boolean;
begin
  Result := (V1.X = V2.X) and (V1.Y = V2.Y) and (V1.Z = V2.Z);
end;

function VecAdd(const V1, V2: TVector2s): TVector2s; overload; {$I inline.inc}
begin
  Result.X := V1.X + V2.X;
  Result.Y := V1.Y + V2.Y;
end;

function VecSub(const V1, V2: TVector2s): TVector2s; overload; {$I inline.inc}
begin
  Result.X := V1.X - V2.X;
  Result.Y := V1.Y - V2.Y;
end;

function VecScale(const V: TVector2s; Scale: Single): TVector2s; overload; {$I inline.inc}
begin
  Result.X := V.X * Scale;
  Result.Y := V.Y * Scale;
end;

function VecAdd(const V1, V2: TVector3s): TVector3s; overload; {$I inline.inc}
begin
  Result.X := V1.X + V2.X;
  Result.Y := V1.Y + V2.Y;
  Result.Z := V1.Z + V2.Z;
end;

function VecSub(const V1, V2: TVector3s): TVector3s; overload; {$I inline.inc}
begin
  Result.X := V1.X - V2.X;
  Result.Y := V1.Y - V2.Y;
  Result.Z := V1.Z - V2.Z;
end;

function VecScale(const V: TVector3s; Scale: Single): TVector3s; overload; {$I inline.inc}
begin
  Result.X := V.X * Scale;
  Result.Y := V.Y * Scale;
  Result.Z := V.Z * Scale;
end;

function DotProduct(const V1, V2: TVector2s): Single;
begin
  Result := V1.X*V2.X + V1.Y*V2.Y;
end;

function CartesianProduct(const V1, V2: TVector2s): TVector2s;
begin
  with Result do begin
    X := V1.X*V2.X;
    Y := V1.Y*V2.Y;
  end;
end;

function CrossProductZ(const V1, V2: TVector2s): Single;
begin
  Result := V1.X*V2.Y - V1.Y*V2.X;
end;

function DotProduct(const V1, V2: TVector3s): Single;
begin
  Result := V1.X*V2.X + V1.Y*V2.Y + V1.Z*V2.Z;
end;

function CartesianProduct(const V1, V2: TVector3s): TVector3s;
begin
  with Result do begin
    X := V1.X*V2.X;
    Y := V1.Y*V2.Y;
    Z := V1.Z*V2.Z;
  end;
end;

function CrossProductZ(const V1, V2: TVector3s): Single;
begin
  Result := - (V1.Z*V2.X - V1.X*V2.Z);
end;

function CrossProduct(const V1, V2: TVector3s): TVector3s;
begin
  with Result do begin
    X := V1.Y*V2.Z - V1.Z*V2.Y;
    Y := V1.Z*V2.X - V1.X*V2.Z;
    Z := V1.X*V2.Y - V1.Y*V2.X;
  end;
end;

procedure GetPerpendicular(out Result: TVector2s; const V: TVector2s); overload;
begin
  Result.X :=  V.Y;
  Result.Y := -V.X;
end;

function GetPerpendicular(const V: TVector2s): TVector2s; overload;
begin
  Result.X :=  V.Y;
  Result.Y := -V.X;
end;

function SqrMagnitude(const V: TVector2s): Single;
begin
  Result := Sqr(V.X)+Sqr(V.Y);
end;

function SqrMagnitude(const V: TVector3s): Single;
begin
  Result := Sqr(V.X)+Sqr(V.Y)+Sqr(V.Z);
end;

function ClassifyPoint(const p, p0, p1: TVector2s): TPointPosition;
var a, b: TVector2s; sa: Single;
begin
  a := VecSub(p1, p0);
  b := VecSub(p, p0);
  sa := CrossProductZ(a, b);
  if sa < 0 then
    Result := ppLEFT
  else if sa > 0 then
    Result := ppRIGHT
  else if (a.x * b.x < 0.0) or (a.y * b.y < 0.0) then
    Result := ppBEHIND
  else if SqrMagnitude(a) < SqrMagnitude(b) then
    Result := ppBEYOND
  else if VecEquals(p0, p) then
    Result := ppORIGIN
  else if VecEquals(p1, p) then
    Result := ppDESTINATION
  else
    Result := ppBETWEEN;
end;

function PointInPolygon(p: TVector2s; Poly: array of TVector2s): Boolean;
begin
{  Result := False;
  if High(XP) <> High(YP) then Exit;
  J:=High(XP);
  for I:=0 to High(XP) do
  begin
    if ((((yp[I]<=y) and (y<yp[J])) OR ((yp[J]<=y) and (y<yp[I]))) and
        (x < (xp[J]-xp[I])*(y-yp[I])/(yp[J]-yp[I])+xp[I]))
    then Result:=not Result;
    J:=I+1;
  end;}

  (*
int GGG (double pX, double pY, int len, double *Xs, double *Ys, int *AAA, int *BBB)
{
  int ctr;
  for (ctr = 1; ctr < len; ctr++)
    {
      double aX = Xs[ctr-1], bX = Xs[ctr];
      double aY = Ys[ctr-1], bY = Ys[ctr];
      double isectX;
/*
                  1         2         3         4         5         6         7         8
Case #   123456789012345678901234567890123456789012345678901234567890123456789012345678901
aX ? pX |<<<<<<<<<<<<<<<<<<<<<<<<<<<===========================>>>>>>>>>>>>>>>>>>>>>>>>>>>
bX ? pX |<<<<<<<<<=========>>>>>>>>><<<<<<<<<=========>>>>>>>>><<<<<<<<<=========>>>>>>>>>
aY ? pY |<<<===>>><<<===>>><<<===>>><<<===>>><<<===>>><<<===>>><<<===>>><<<===>>><<<===>>>
bY ? pY |<=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=><=>
if#      1111111112   9   32   9   32  B9B  32AAA9AAA32  B9B  32   9   32   9   3244444443
if#                                                                               758e768 
result   iiiiiiiiii   b   ii   b   ii  bbb  iibbbbbbbii  bbb  ii   b   ii   b   ii`^,i`v,i
*/
      if ((aX < pX) && (bX < pX)) /* if# 1 */
        continue; /* ingnore */
      if ((aY < pY) && (bY < pY)) /* if# 2 */
        continue;
      if ((aY > pY) && (bY > pY)) /* if# 3 */
        continue;
      if ((aX > pX) && (bX > pX)) /* if# 4 */
        {
          if ((aY < pY) && (bY > pY)) /* if# 5 */
            (AAA[0]) += 2;
          else if ((aY > pY) && (bY < pY)) /* if# 6 */
            (BBB[0]) += 2;
          else if (aY < bY) /* if# 7 */
            (AAA[0]) ++;
          else if (aY > bY) /* if# 8 */
            (BBB[0]) ++;
          continue;
        }
      if ((aY == pY) && (bY == pY)) /* if# 9 */
        return OOO;
      if ((aX == pX) && (bX == pX)) /* if# A */
        return OOO;
      if ((aX == pX) && (aY == pY)) /* if# B */
        return OOO;
      isectX = FFF(aX,aY,bX,bY,pY);
      if (isectX < (pX - FLT_EPSILON))
        continue;
      if (isectX > (pX + FLT_EPSILON))
        {
          if ((aY < pY) && (bY > pY))
            (AAA[0]) += 2;
          else if ((aY > pY) && (bY < pY))
            (BBB[0]) += 2;
          else if (aY < bY)
            (AAA[0]) ++;
          else if (aY > bY)
            (BBB[0]) ++;
          continue;
        }
      return OOO;
    }
  return 0;
}
  *)
end;

function IsPointsSameSide(const P1, P2, Origin, Dir: TVector2s): Boolean;
begin
  Result := CrossProductZ(Dir, VecSub(P1, Origin)) * CrossProductZ(Dir, VecSub(P2, Origin)) >= 0;
end;

function IsPointsSameSide(const P1, P2, Origin, Dir: TVector3s): Boolean;
begin
  Result := DotProduct(CrossProduct(Dir, VecSub(P1, Origin)), CrossProduct(Dir, VecSub(P2, Origin))) >= 0;
end;

function PointInTriangle(p, a, b, c: TVector2s): Boolean;
begin
  Result := IsPointsSameSide(p, a, b, VecSub(c, b)) and
            IsPointsSameSide(p, b, a, VecSub(c, a)) and
            IsPointsSameSide(p, c, a, VecSub(b, a));
{  Result := (ClassifyPoint(p, a, b) <> ppLEFT) and
            (ClassifyPoint(p, b, c) <> ppLEFT) and
            (ClassifyPoint(p, c, a) <> ppLEFT);}
end;

function PointInTriangle(p, a, b, c: TVector3s): Boolean;
begin
  Result := IsPointsSameSide(p, a, b, VecSub(c, b)) and
            IsPointsSameSide(p, b, a, VecSub(c, a)) and
            IsPointsSameSide(p, c, a, VecSub(b, a));
end;

procedure ProjectPointToLine(const p, l1, l2: TVector2s; out pp: TVector2s);
var
  V, W: TVector2s;
  d: Single;
begin
  V := VecSub(l2, l1);
  W := VecSub(p, l1);

  d := DotProduct(V, W) / SqrMagnitude(V);

  pp := VecAdd(l1, VecScale(V, d));
end;

procedure ProjectPointToLine(const p, l1, l2: TVector3s; out pp: TVector3s);
var
  V, W: TVector3s;
  d: Single;
begin
  V := VecSub(l2, l1);
  W := VecSub(p, l1);

  d := DotProduct(V, W) / SqrMagnitude(V);

  pp := VecAdd(l1, VecScale(V, d));
end;

end.
