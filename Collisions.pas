(*
 @Abstract(Collisions unit)
 (C) 2006-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains collision detection routines
*)
{$Include GDefines.inc}
unit Collisions;

interface

uses BaseTypes, Base3D;

type
  // Bounding volume kind
  TBoundingVolumeKind = (// Object-oriented bounding box
                         bvkOOBB,
                         // Bounding sphere
                         bvkSphere,
                         // Cylinder. Not supported by default implementation.
                         bvkCylinder,
                         // Cone. Not supported by default implementation.
                         bvkCone,
                         // Capsule. Not supported by default implementation.
                         bvkCapsule,
                         // Chamfer Cylinder. Not supported by default implementation.
                         bvkChamferCylinder
                         );

  { Bounding volume data structure
    <b>VolumeKind</b>    - type of bounding volume -- see @Link(TBoundingVolumeKind)
    <b>Offset</b>        - offset of the volume's center
    <b>Dimensions</b>    - half-size of a box or radius of a sphere (in x component) }
  TBoundingVolume = record
    VolumeKind: TBoundingVolumeKind;
    Offset, Dimensions: BaseTypes.TVector3s;
  end;

  // Array of bounding volumes
  TBoundingVolumes = array of TBoundingVolume;

  // Data structure of a collision-test result. Contains the two collided volumes or <b>nils</b> if no collision detected
  TCollisionResult = record
    Vol1, Vol2: ^TBoundingVolume;
  end;

  { Returns <b>True</b> if a ray with the specified origin and direction intersects with a sphere with the specified origin and radius.
    Point is filled with the nearest to ray origin intersection point if any }
  function RaySphereColDet(const RayOrigin, RayDir, SphereOrigin: BaseTypes.TVector3s; SphereRadius: Single; var Point: BaseTypes.TVector3s): Boolean;
  { Returns <b>True</b> if a ray with the specified origin and direction intersects with a sphere with the specified origin and radius.
    Point is filled with the nearest to ray origin intersection point if any }
  function RayCircleColDet(const RayOrigin, RayDir, SphereOrigin: BaseTypes.TVector3s; SphereRadius: Single; var Point: BaseTypes.TVector3s): Boolean;

  { Returns <b>True</b> if the given sphere intersects with the given OOBB.
    <b>Transform1</b> and <b>Transform2</b> specifies location and orientation of the volumes within the world space and should not contain scale. }
  function SphereOOBBColDet(const Transform1, Transform2: Base3D.TMatrix4s; const Sphere, OOBB: TBoundingVolume): Boolean;
  { Returns <b>True</b> if the two given OOBBs intersects.  Only spheres and OOBB as bounding volumes supported.
    <b>Transform1</b> and <b>Transform2</b> specifies location and orientation of the volumes within the world space and should not contain scale. }
  function OOBBOOBBColDet  (const Transform1, Transform2: Base3D.TMatrix4s; const OOBB1, OOBB2: TBoundingVolume): Boolean;
  { Returns <b>True</b> if the two given OOBBs intersects in XZ plane. It's faster then @Link(OOBBOOBBColDet) a little.  Only spheres and OOBB as bounding volumes supported.
    <b>Transform1</b> and <b>Transform2</b> specifies location and orientation of the volumes within the world space and should not contain scale. }
  function OOBBOOBBColDet2D(const Transform1, Transform2: Base3D.TMatrix4s; const OOBB1, OOBB2: TBoundingVolume): Boolean;
  { Checks two arrays of bounding volumes for collision and returns result in @Link(TCollisionResult) structure. Only spheres and OOBB as bounding volumes supported.
    <b>Transform1</b> and <b>Transform2</b> specifies location and orientation of the volume arrays within the world space and should not contain scale. }
  function VolumeColDet(Volume1, Volume2: TBoundingVolumes; const Transform1, Transform2: Base3D.TMatrix4s): TCollisionResult;
  { Returns <b>True</b> if there is an intersection between bounding volumes from the given arrays. Only spheres and OOBB as bounding volumes supported.
    <b>Transform1</b> and <b>Transform2</b> specifies location and orientation of the volume arrays within the world space and should not contain scale. }
  function VolumeColTest(const Volume1, Volume2: TBoundingVolumes; const Transform1, Transform2: Base3D.TMatrix4s): Boolean;                                       //
//  function VolumeColDet2D(const Volume1, Volume2: TBoundingVolumes; const Transform1, Transform2: Base3D.TMatrix4s): TCollisionResult;     // ToFix: Take location in account
//  function VolumeColTest2D(const Volume1, Volume2: TBoundingVolumes; const Transform1, Transform2: Base3D.TMatrix4s): Boolean;                                       //

implementation

function RaySphereColDet(const RayOrigin, RayDir, SphereOrigin: BaseTypes.TVector3s; SphereRadius: Single; var Point: BaseTypes.TVector3s): Boolean;
var B, C, D, t1, t2: Single;
begin
  Result := False;
  Point := SubVector3s(RayOrigin, SphereOrigin);
  B := 2 * DotProductVector3s(Point, RayDir);
  C := SqrMagnitude(Point) - Sqr(SphereRadius);
  D := B*B - 4 * C;
  if D < 0 then Exit;
  if D > 0 then begin
    t1 := -B - Sqrt(D);
    t2 := -B + Sqrt(D);
    if (t1 < 0) and (t2 < 0) then Exit;
    if (t1 < t2) and (t1 >= 0) then B := -t1 else if t2 >= 0 then B := -t2 else B := -t1;
  end;
  Point := AddVector3s(RayOrigin, ScaleVector3s(RayDir, -B * 0.5));
  Result := True;
end;

function RayCircleColDet(const RayOrigin, RayDir, SphereOrigin: BaseTypes.TVector3s; SphereRadius: Single; var Point: BaseTypes.TVector3s): Boolean;
var B, C, D, t1, t2: Single;
begin
  Result := False;

  Point := SubVector3s(RayOrigin, SphereOrigin);
  Point.Y := 0;

  B := 2 * DotProductVector3s(Point, RayDir);
  C := SqrMagnitude(Point) - Sqr(SphereRadius);
  D := B*B - 4 * C;
  if D < 0 then Exit;
  if D > 0 then begin
    t1 := -B - Sqrt(D);
    t2 := -B + Sqrt(D);
    if (t1 < 0) and (t2 < 0) then Exit;
    if (t1 < t2) and (t1 >= 0) then B := -t1 else if t2 >= 0 then B := -t2 else B := -t1;
  end;              
  Point := AddVector3s(RayOrigin, ScaleVector3s(RayDir, -B * 0.5));
  Point.Y := 0;
  Result := True;
end;

function SphereOOBBColDet(const Transform1, Transform2: Base3D.TMatrix4s; const Sphere, OOBB: TBoundingVolume): Boolean;
var d, a: Single; i: Integer; SPos: BaseTypes.TVector3s; InverseT2: Base3D.TMatrix3s;
begin
  InverseT2 := CutMatrix3s(Transform2);
  TransposeMatrix3s(InverseT2);

  SPos := SubVector4s(Transform4Vector3s(Transform2, OOBB.Offset), Transform4Vector3s(Transform1, Sphere.Offset)).xyz;
  SPos := Transform3Vector3s(InverseT2, SPos);

  d := 0; i := 0;
  while i <= 2 do begin
    if (SPos.v[i] < -OOBB.Dimensions.v[i]{*M2.M[i, i]}) then begin
      a := SPos.v[i] + OOBB.Dimensions.v[i]{*M2.M[i, i]};
      d := d + a * a;
    end else if (SPos.v[i] > OOBB.Dimensions.v[i]{*M2.M[i, i]}) then begin
      a := SPos.v[i] - OOBB.Dimensions.v[i]{*M2.M[i, i]};
      d := d + a * a;
    end;
    Inc(i);
  end;
  Result := d <= Sphere.Dimensions.X * Sphere.Dimensions.X;
end;

function OOBBOOBBColDet(const Transform1, Transform2: Base3D.TMatrix4s; const OOBB1, OOBB2: TBoundingVolume): Boolean;     // Пересечение двух боксов
var R: Base3D.TMatrix3s; T: BaseTypes.TVector3s; temp, ra, rb: Single; i: Integer;
begin
  Result := False;

  T := SubVector4s( Transform4Vector3s(Transform2, OOBB2.Offset), Transform4Vector3s(Transform1, OOBB1.Offset) ).xyz;

  T := Transform3Vector3s(GetTransposedMatrix3s(CutMatrix3s(Transform1)), T);
  R := TranspMulMatrix3s(CutMatrix3s(Transform1), CutMatrix3s(Transform2));            // Transform from Transform2 to Transform1

  //Mat1 system
  for i := 0 to 2 do begin
    ra := OOBB1.Dimensions.v[i];
    rb := OOBB2.Dimensions.v[0]*abs(R.M[i][0]) + OOBB2.Dimensions.v[1]*abs(R.M[i][1]) + OOBB2.Dimensions.v[2]*abs(R.M[i][2]);
    if ( abs( T.v[i] ) > ra + rb ) then Exit;
  end;
  //Mat2 system
  for i := 0 to 2 do begin
    ra := OOBB1.Dimensions.v[0]*abs(R.M[0][i]) + OOBB1.Dimensions.v[1]*abs(R.M[1][i]) + OOBB1.Dimensions.v[2]*abs(R.M[2][i]);
    rb := OOBB2.Dimensions.v[i];
    Temp := abs( T.v[0]*R.M[0][i] + T.v[1]*R.M[1][i] + T.v[2]*R.M[2][i] );
    if ( Temp > ra + rb ) then Exit;
  end;
  //9 cross products
  //L = A0 x B0
  ra := OOBB1.Dimensions.v[1]*abs(R.M[2][0]) + OOBB1.Dimensions.v[2]*abs(R.M[1][0]);
  rb := OOBB2.Dimensions.v[1]*abs(R.M[0][2]) + OOBB2.Dimensions.v[2]*abs(R.M[0][1]);
  if ( abs( T.v[2]*R.M[1][0] - T.v[1]*R.M[2][0] ) > ra + rb ) then Exit;
  //L = A0 x B1
  ra := OOBB1.Dimensions.v[1]*abs(R.M[2][1]) + OOBB1.Dimensions.v[2]*abs(R.M[1][1]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[0][2]) + OOBB2.Dimensions.v[2]*abs(R.M[0][0]);
  if ( abs( T.v[2]*R.M[1][1] - T.v[1]*R.M[2][1] ) > ra + rb ) then Exit;
  //L = A0 x B2
  ra := OOBB1.Dimensions.v[1]*abs(R.M[2][2]) + OOBB1.Dimensions.v[2]*abs(R.M[1][2]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[0][1]) + OOBB2.Dimensions.v[1]*abs(R.M[0][0]);
  if ( abs( T.v[2]*R.M[1][2] - T.v[1]*R.M[2][2] ) > ra + rb ) then Exit;
  //L = A1 x B0
  ra := OOBB1.Dimensions.v[0]*abs(R.M[2][0]) + OOBB1.Dimensions.v[2]*abs(R.M[0][0]);
  rb := OOBB2.Dimensions.v[1]*abs(R.M[1][2]) + OOBB2.Dimensions.v[2]*abs(R.M[1][1]);
  if ( abs( T.v[0]*R.M[2][0] - T.v[2]*R.M[0][0] ) > ra + rb ) then Exit;
  //L = A1 x B1
  ra := OOBB1.Dimensions.v[0]*abs(R.M[2][1]) + OOBB1.Dimensions.v[2]*abs(R.M[0][1]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[1][2]) + OOBB2.Dimensions.v[2]*abs(R.M[1][0]);
  if ( abs( T.v[0]*R.M[2][1] - T.v[2]*R.M[0][1] ) > ra + rb ) then Exit;
  //L = A1 x B2
  ra := OOBB1.Dimensions.v[0]*abs(R.M[2][2]) + OOBB1.Dimensions.v[2]*abs(R.M[0][2]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[1][1]) + OOBB2.Dimensions.v[1]*abs(R.M[1][0]);
  if ( abs( T.v[0]*R.M[2][2] - T.v[2]*R.M[0][2] ) > ra + rb ) then Exit;
  //L = A2 x B0
  ra := OOBB1.Dimensions.v[0]*abs(R.M[1][0]) + OOBB1.Dimensions.v[1]*abs(R.M[0][0]);
  rb := OOBB2.Dimensions.v[1]*abs(R.M[2][2]) + OOBB2.Dimensions.v[2]*abs(R.M[2][1]);
  if ( abs( T.v[1]*R.M[0][0] - T.v[0]*R.M[1][0] ) > ra + rb ) then Exit;
  //L = A2 x B1
  ra := OOBB1.Dimensions.v[0]*abs(R.M[1][1]) + OOBB1.Dimensions.v[1]*abs(R.M[0][1]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[2][2]) + OOBB2.Dimensions.v[2]*abs(R.M[2][0]);
  if ( abs( T.v[1]*R.M[0][1] - T.v[0]*R.M[1][1] ) > ra + rb ) then Exit;
  //L = A2 x B2
  ra := OOBB1.Dimensions.v[0]*abs(R.M[1][2]) + OOBB1.Dimensions.v[1]*abs(R.M[0][2]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[2][1]) + OOBB2.Dimensions.v[1]*abs(R.M[2][0]);
  if ( abs( T.v[1]*R.M[0][2] - T.v[0]*R.M[1][2] ) > ra + rb ) then Exit;
  Result := True;
end;

function OOBBOOBBColDet2D(const Transform1, Transform2: Base3D.TMatrix4s; const OOBB1, OOBB2: TBoundingVolume): Boolean;    // ToFix: Add scale support
var R: Base3D.TMatrix3s; v, T: BaseTypes.TVector3s; temp, ra, rb: Single; i: Integer;
begin
  Result := False;
  v := SubVector4s( Transform4Vector3s(Transform2, OOBB2.Offset), Transform4Vector3s(Transform1, OOBB1.Offset) ).XYZ;
  T := Transform3Vector3s(GetTransposedMatrix3s(CutMatrix3s(Transform1)), v);
  R := TranspMulMatrix3s(CutMatrix3s(Transform1), CutMatrix3s(Transform2));
{  v := SubVector3s(P2, P1);
  T := Transform3Vector3s(TransposeMatrix3s(M1), v);
  R := TranspMulMatrix3s(M1, M2);}
//  v := SubVector3s(OOBB2.Offset, OOBB1.Offset);
//  T := Transform3Vector3s(TransposeMatrix3s(OOBB1.Matrix), v);
//  R := TranspMulMatrix3s(OOBB1.Matrix, OOBB2.Matrix);

  i := 0;
  while i <= 2 do begin
//Mat1 system
    ra := OOBB1.Dimensions.v[i];
    rb := OOBB2.Dimensions.v[0]*abs(R.M[i][0]) + OOBB2.Dimensions.v[1]*abs(R.M[i][1]) + OOBB2.Dimensions.v[2]*abs(R.M[i][2]);
    if ( abs( T.v[i] ) > ra + rb ) then Exit;
//Mat2 system
    ra := OOBB1.Dimensions.v[0]*abs(R.M[0][i]) + OOBB1.Dimensions.v[1]*abs(R.M[1][i]) + OOBB1.Dimensions.v[2]*abs(R.M[2][i]);
    rb := OOBB2.Dimensions.v[i];
    Temp := abs( T.v[0]*R.M[0][i] + T.v[1]*R.M[1][i] + T.v[2]*R.M[2][i] );
    if ( Temp > ra + rb ) then Exit;
    Inc(i, 2);
  end;
  //9 cross products
  //L = A0 x B0
  ra := OOBB1.Dimensions.v[1]*abs(R.M[2][0]) + OOBB1.Dimensions.v[2]*abs(R.M[1][0]);
  rb := OOBB2.Dimensions.v[1]*abs(R.M[0][2]) + OOBB2.Dimensions.v[2]*abs(R.M[0][1]);
  if ( abs( T.v[2]*R.M[1][0] - T.v[1]*R.M[2][0] ) > ra + rb ) then Exit;
{  //L = A0 x B1
  ra := OOBB1.Dimensions.v[1]*abs(R.M[2][1]) + OOBB1.Dimensions.v[2]*abs(R.M[1][1]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[0][2]) + OOBB2.Dimensions.v[2]*abs(R.M[0][0]);
  if ( abs( T.v[2]*R.M[1][1] - T.v[1]*R.M[2][1] ) > ra + rb ) then Exit;}
  //L = A0 x B2
  ra := OOBB1.Dimensions.v[1]*abs(R.M[2][2]) + OOBB1.Dimensions.v[2]*abs(R.M[1][2]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[0][1]) + OOBB2.Dimensions.v[1]*abs(R.M[0][0]);
  if ( abs( T.v[2]*R.M[1][2] - T.v[1]*R.M[2][2] ) > ra + rb ) then Exit;
{  //L = A1 x B0
  ra := OOBB1.Dimensions.v[0]*abs(R.M[2][0]) + OOBB1.Dimensions.v[2]*abs(R.M[0][0]);
  rb := OOBB2.Dimensions.v[1]*abs(R.M[1][2]) + OOBB2.Dimensions.v[2]*abs(R.M[1][1]);
  if ( abs( T.v[0]*R.M[2][0] - T.v[2]*R.M[0][0] ) > ra + rb ) then Exit;
  //L = A1 x B1
  ra := OOBB1.Dimensions.v[0]*abs(R.M[2][1]) + OOBB1.Dimensions.v[2]*abs(R.M[0][1]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[1][2]) + OOBB2.Dimensions.v[2]*abs(R.M[1][0]);
  if ( abs( T.v[0]*R.M[2][1] - T.v[2]*R.M[0][1] ) > ra + rb ) then Exit;
  //L = A1 x B2
  ra := OOBB1.Dimensions.v[0]*abs(R.M[2][2]) + OOBB1.Dimensions.v[2]*abs(R.M[0][2]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[1][1]) + OOBB2.Dimensions.v[1]*abs(R.M[1][0]);
  if ( abs( T.v[0]*R.M[2][2] - T.v[2]*R.M[0][2] ) > ra + rb ) then Exit; }
  //L = A2 x B0
  ra := OOBB1.Dimensions.v[0]*abs(R.M[1][0]) + OOBB1.Dimensions.v[1]*abs(R.M[0][0]);
  rb := OOBB2.Dimensions.v[1]*abs(R.M[2][2]) + OOBB2.Dimensions.v[2]*abs(R.M[2][1]);
  if ( abs( T.v[1]*R.M[0][0] - T.v[0]*R.M[1][0] ) > ra + rb ) then Exit;
  //L = A2 x B1
{  ra := OOBB1.Dimensions.v[0]*abs(R.M[1][1]) + OOBB1.Dimensions.v[1]*abs(R.M[0][1]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[2][2]) + OOBB2.Dimensions.v[2]*abs(R.M[2][0]);
  if ( abs( T.v[1]*R.M[0][1] - T.v[0]*R.M[1][1] ) > ra + rb ) then Exit; }
  //L = A2 x B2
  ra := OOBB1.Dimensions.v[0]*abs(R.M[1][2]) + OOBB1.Dimensions.v[1]*abs(R.M[0][2]);
  rb := OOBB2.Dimensions.v[0]*abs(R.M[2][1]) + OOBB2.Dimensions.v[1]*abs(R.M[2][0]);
  if ( abs( T.v[1]*R.M[0][2] - T.v[0]*R.M[1][2] ) > ra + rb ) then Exit;
  Result := True;
end;

function VolumeColDet(Volume1, Volume2: TBoundingVolumes; const Transform1, Transform2: Base3D.TMatrix4s): TCollisionResult;     // ToFix: Take location in account
var i, j: Integer;
begin
//  Assert(Assigned(Volume1) and Assigned(Volume2));
  with Result do begin
    for i := 0 to High(Volume1) do begin
      Vol1 := @Volume1[i];
      case Vol1^.VolumeKind of
        bvkSphere: for j := 0 to High(Volume2) do begin
          Vol2 := @Volume2[j];
          case Vol2^.VolumeKind of
            bvkSphere: if SqrMagnitude(SubVector4s(Transform4Vector3s(Transform1, Vol1^.Offset),
                                                              Transform4Vector3s(Transform2, Vol2^.Offset)).XYZ) < Sqr(Vol1^.Dimensions.X + Vol2^.Dimensions.X) then Exit;
            bvkOOBB: if SphereOOBBColDet(Transform1, Transform2, Vol1^, Vol2^) then Exit;
          end;
        end;
        bvkOOBB: for j := 0 to High(Volume2) do begin
          Vol2 := @Volume2[j];
          case Vol2^.VolumeKind of
            bvkSphere: if SphereOOBBColDet(Transform1, Transform2, Vol2^, Vol1^) then Exit;
            bvkOOBB: if OOBBOOBBColDet(Transform1, Transform2, Vol1^, Vol2^) then Exit;
          end;
        end;
      end;
    end;
    Vol1 := nil; Vol2 := nil;
  end;
end;

function VolumeColDet2D(const Volume1, Volume2: TBoundingVolumes; const Transform1, Transform2: Base3D.TMatrix4s): TCollisionResult;     // ToFix: Take location in account
//var tv: BaseTypes.TVector3s;
begin
{  with Result do begin
    Vol1 := Volume1.First;
    while Vol1 <> nil do begin
      Vol2 := Volume2.First;
      case Vol1^.VolumeKind of
        vkSphere: while Vol2 <> nil do begin
          case Vol2^.VolumeKind of
            vkSphere: begin
              tv := SubVector3s(AddVector3s(Volume1.Location, Transform3Vector3s(Volume1.Matrix, Vol1.Offset)),
                                AddVector3s(Volume2.Location, Transform3Vector3s(Volume2.Matrix, Vol2.Offset)));
              tv.Y := 0;
              if SqrMagnitude(tv) < Sqr(Vol1^.Dimensions.X + Vol2^.Dimensions.X) then Exit;
            end;  
            vkOOBB: if SphereOOBBColDet(Volume1.Matrix, Volume2.Matrix, Volume1.Location, Volume2.Location, Vol1^, Vol2^, 2) then Exit;
          end;
          Vol2 := Vol2^.Next;
        end;
        vkOOBB: while Vol2 <> nil do begin
          case Vol2^.VolumeKind of
            vkSphere: if SphereOOBBColDet(Volume2.Matrix, Volume1.Matrix, Volume2.Location, Volume1.Location, Vol2^, Vol1^, 2) then Exit;
            vkOOBB: if OOBBOOBBColDet2D(Volume1.Matrix, Volume2.Matrix, Volume1.Location, Volume2.Location, Vol1^, Vol2^) then Exit;
          end;
          Vol2 := Vol2^.Next;
        end;
      end;
      Vol1 := Vol1^.Next;
    end;
    Vol1 := nil; Vol2 := nil;
  end;}
end;

function VolumeColTest(const Volume1, Volume2: TBoundingVolumes; const Transform1, Transform2: Base3D.TMatrix4s): Boolean;                                       //
begin
  Result := VolumeColDet(Volume1, Volume2, Transform1, Transform2).Vol1 <> nil;
end;

function VolumeColTest2D(const Volume1, Volume2: TBoundingVolumes; const Transform1, Transform2: Base3D.TMatrix4s): Boolean;                                       //
begin
  Result := VolumeColDet2D(Volume1, Volume2, Transform1, Transform2).Vol1 <> nil;
end;

end.
