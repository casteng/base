(*
 @Abstract(Basic 3D Unit)
 (C) 2003-2007 George "Mirage" Bakhtadze. <a href="http://www.casteng.com">www.casteng.com</a> <br>
 The source code may be used under either MPL 1.1 or LGPL 2.1 license. See included license.txt file <br>
 Unit contains basic 3D types and routines
*)
{$Include GDefines.inc}
unit Base3D;

interface

uses BaseTypes, Basics;

const
  // Size of sine table. Must be power of 2
  SinTableSize = 512;
  // Offset in sine table to compute cosines
  CosTabOffs = SinTableSize div 4;

type
  // 3x3 single-precision floating point matrix
  TMatrix3s = packed record
    case Integer of
      0: (_11, _12, _13: Single;
          _21, _22, _23: Single;
          _31, _32, _33: Single);
      1: (M: array [0..2, 0..2] of Single);
      2: (ViewRight, ViewUp, ViewForward: TVector3s);
      3: (A: array[0..8] of Single);
      4: (Rows: array[0..2] of TVector3s);
  end;
  // Pointer to 3x3 single-precision floating point matrix
  PMatrix3s = ^TMatrix3s;

  // 4x4 single-precision floating point matrix
  TMatrix4s = packed record
    case Integer of
      0: (_11, _12, _13, _14: Single;
          _21, _22, _23, _24: Single;
          _31, _32, _33, _34: Single;
          _41, _42, _43, _44: Single);
      1: (M: array [0..3, 0..3] of Single);
      2: (ViewRight: TVector3s;   _dummy1: Single;
          ViewUp: TVector3s;      _dummy2: Single;
          ViewForward: TVector3s; _dummy3: Single;
          ViewTranslate: TVector3s);
      3: (ViewRight4s, ViewUp4s, ViewForward4s, ViewTranslate4s: TVector4s);
      4: (A: array[0..15] of Single);
      5: (Rows: array[0..3] of TVector4s);
  end;
  // Pointer to 4x4 single-precision floating point matrix
  PMatrix4s = ^TMatrix4s;

  // Plane given by equation AX+BY+CZ+D = 0 or by normal and distance
  TPlane = packed record
    case Integer of
      0: (A, B, C, D: Single);                    // Plane equation coefficients
      1: (Normal: TVector3s; Distance: Single);
      2: (V: TVector4s);
  end;
  PPlane = ^TPlane;

  // Quaternion type. Used for specifying rotations
  TQuaternion = array[0..3] of Single;     // [s, (x, y, z)]

  // Axis-aligned (in model space) bounding box given by two points containing minimum and maximum coordinates for each axis
  TBoundingBox = record
    P1, P2: TVector3s;
  end;

const
  ZeroVector3s: TVector3s = (X: 0; Y: 0; Z: 0);
  ZeroVector4s: TVector4s = (X: 0; Y: 0; Z: 0; W: 0);
  IdentityMatrix3s: TMatrix3s = (m: ((1, 0, 0), (0, 1, 0), (0, 0, 1)) );
  IdentityMatrix4s: TMatrix4s = (m: ((1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0), (0, 0, 0, 1)));
  EmptyBoundingBox: TBoundingBox = (P1: (X: 0; Y: 0; Z: 0); P2: (X: 0; Y: 0; Z: 0));

    // Vectors
  // Returns a 3-dimensional vector with the specified components
  function GetVector3s(const X, Y, Z: Single): TVector3s; overload;
  // Returns a 3-dimensional vector with the specified components
  procedure GetVector3s(out Result: TVector3s; const X, Y, Z: Single); overload;
  // Returns a 3-dimensional vector with the specified components
  function Vec3s(const X, Y, Z: Single): TVector3s; overload;
  // Returns a 3-dimensional vector by two points (start, end)
  function Vec3s(const X1, Y1, Z1, X2, Y2, Z2: Single): TVector3s; overload;
  // Returns a 4-dimensional vector with the specified components
  function GetVector4s(const X, Y, Z, W: Single): TVector4s; overload;
  // Returns a 4-dimensional vector with the specified components
  procedure GetVector4s(out Result: TVector4s; const X, Y, Z, W: Single); overload;
  // Returns a 4-dimensional vector with the specified components
  function Vec4s(const X, Y, Z, W: Single): TVector4s; overload;

  // Returns @True if <b>V1</b> and <b>V2</b> are equal
  function EqualsVector3s(const V1, V2: TVector3s): Boolean;
  // Returns @True if <b>V1</b> and <b>V2</b> are equal
  function EqualsVector4s(const V1, V2: TVector4s): Boolean;

  function AddVector3s(const V1, V2: TVector3s): TVector3s; overload;
  procedure AddVector3s(out Result: TVector3s; const V1, V2: TVector3s); overload;
  function SubVector3s(const V1, V2: TVector3s): TVector3s; overload;
  procedure SubVector3s(out Result: TVector3s; const V1, V2: TVector3s); overload;
  // Scales the vector <b>V</b> by the specified factor
  function ScaleVector3s(const V: TVector3s; const Factor: Single): TVector3s; overload;
  // Scales the vector <b>V</b> by the specified factor and returns it in <b>Result</b>
  procedure ScaleVector3s(out Result: TVector3s; const V: TVector3s; const Factor: Single); overload;

  function AddVector4s(const V1, V2: TVector4s): TVector4s; overload;
  procedure AddVector4s(out Result: TVector4s; const V1, V2: TVector4s); overload;
  function SubVector4s(const V1, V2: TVector4s): TVector4s; overload;
  procedure SubVector4s(out Result: TVector4s; const V1, V2: TVector4s); overload;
  // Scales the vector <b>V</b> by the specified factor
  function ScaleVector4s(const V: TVector4s; const Factor: Single): TVector4s; overload;
  // Scales the vector <b>V</b> by the specified factor and returns it in <b>Result</b>
  procedure ScaleVector4s(out Result: TVector4s; const V: TVector4s; const Factor: Single); overload;

  // Vectors dot product
  function DotProductVector3s(const V1, V2: TVector3s): Single;
  // Vectors cartesian product
  function CartesianProductVector3s(const V1, V2: TVector3s): TVector3s;
  // Vectors cross product
  function CrossProductVector3s(const V1, V2: TVector3s): TVector3s; overload;
  // Vectors cross product
  procedure CrossProductVector3s(out Result: TVector3s; const V1, V2: TVector3s); overload;

  // Returns <b>V</b> reflected from surface with the normal <b>N</b>
  function ReflectVector3s(const V, N: TVector3s): TVector3s; overload;
  // Forces the vector <b>V</b>'s length to the specified length
  function NormalizeVector3s(const V: TVector3s; Length: Single = 1): TVector3s; overload;
  // Forces the vector <b>V</b>'s length to the specified length using fast @Link(InvSqrt)
  procedure FastNormalizeVector3s(var Result: TVector3s; Length: Single = 1); overload;

  // Returns <b>V</b> reflected from surface with the normal <b>N</b>
  procedure ReflectVector3s(out Result: TVector3s; const V, N: TVector3s); overload;
  // Forces then vector <b>V</b>'s length to the specified length
  procedure NormalizeVector3s(out Result: TVector3s; const V: TVector3s; Length: Single = 1); overload;
  // Retuns a vector which is orthogonal to <b>V</b>
  procedure GetPerpendicular3s(out Result: TVector3s; const V: TVector3s); overload;
  // Retuns a vector which is orthogonal to <b>V</b>
  function GetPerpendicular3s(const V: TVector3s): TVector3s; overload;

  // Forces the vector <b>V</b>'s length to the specified length
  function NormalizeVector4s(const V: TVector4s; Length: Single = 1): TVector4s;
  // Forces the vector <b>V</b>'s length to the specified length using fast @Link(InvSqrt)
  procedure FastNormalizeVector4s(var Result: TVector4s; Length: Single = 1);

  // Returns the squared magnitude of <b>V</b>
  function SqrMagnitude(const V: TVector3s): Single;
  // Returns approximated magnitude of <b>V</b> (need testing)
  function GetMagnitudeApprox(const V: TVector3s): Single;  

    // Planes
  // Returns a plane by the given equation coeficients (<i>AX + BY + CZ + D = 0</i>)
  function GetPlane(A, B, C, D: Single): TPlane;
  // Returns a plane by the specified point and normal
  function GetPlaneFromPointNormal(const Point, Normal: TVector3s): TPlane;
  // Returns a plane by the specified point and normal
  procedure PlaneFromPointNormal(out Result: TPlane; const Point, Normal: TVector3s);
  // Normalizes the plane equation coefficients
  procedure NormalizePlane(var APlane: TPlane);

    // Quaternions
  // Retuns a normalized quaternion by the specified axis and angle
  procedure GetQuaternion(out Result: TQuaternion; const Angle: Single; const Axis: TVector3s); overload;
  // Returns @True if the given quaternions are equal
  function EqualsQuaternions(Q1, Q2: TQuaternion): Boolean;
  // Returns product of <b>Quat1</b> and <b>Quat2</b>
  procedure MulQuaternion(out Result: TQuaternion; const Quat1, Quat2: TQuaternion); overload;
  // Retuns the normalized version of <b>Quat</b>
  procedure NormalizeQuaternion(out Result: TQuaternion; const Quat: TQuaternion); overload;

  // Retuns a normalized quaternion by the specified axis and angle
  function GetQuaternion(const Angle: Single; const Axis: TVector3s): TQuaternion; overload;
  // Returns product of <b>Quat1</b> and <b>Quat2</b>
  function MulQuaternion(const Quat1, Quat2: TQuaternion): TQuaternion; overload;
  // Retuns the normalized version of <b>Quat</b>
  function NormalizeQuaternion(const Quat: TQuaternion): TQuaternion; overload;

  { Returns a quaternion which specifies a rotation from <b>OldDir</b> to <b>NewDir</b>. <br>
    <b>OldDir</b> to <b>NewDir</b> should be normalized (needs testing) }
  procedure GetVectorRotateQuat(out Result: TQuaternion; const OldDir, NewDir: TVector3s); overload;
  { Returns a quaternion which specifies a rotation from <b>OldDir</b> to <b>NewDir</b>. <br>
    <b>OldDir</b> to <b>NewDir</b> should be normalized (needs testing) }
  function GetVectorRotateQuat(const OldDir, NewDir: TVector3s): TQuaternion; overload;

    // Matrices
  // Returns @True if <b>M1</b> and <b>M2</b> are equal
  function EqualsMatrix3s(const M1, M2: TMatrix3s): Boolean;
  // Returns @True if <b>M1</b> and <b>M2</b> are equal
  function EqualsMatrix4s(const M1, M2: TMatrix4s): Boolean;
  // Returns a 4x4 rotation matrix which specifies the same rotation as <b>Quat</b>
  function Matrix4sByQuat(const Quat: TQuaternion): TMatrix4s; overload;
  // Matrix multiplication
  function MulMatrix4s(const M1, M2: TMatrix4s): TMatrix4s; overload;
  // Matrix multiplication and transpose
  function TranspMulMatrix4s(const M1, M2: TMatrix4s): TMatrix4s; overload;
  // Returns transposed matrix
  function GetTransposedMatrix4s(const M: TMatrix4s): TMatrix4s; overload;
  // Returns scaling matrix
  function ScaleMatrix4s(const X, Y, Z: Single): TMatrix4s; overload;
  // Returns rotation over X-axis matrix
  function XRotationMatrix4s(const Angle: Single): TMatrix4s; overload;
  // Returns rotation over Y-axis matrix
  function YRotationMatrix4s(const Angle: Single): TMatrix4s; overload;
  // Returns rotation over Z-axis matrix
  function ZRotationMatrix4s(const Angle: Single): TMatrix4s; overload; {$I inline.inc}
  // Returns translation matrix
  function TranslationMatrix4s(const X, Y, Z: Single): TMatrix4s; overload; {$I inline.inc}

  // Returns 3-dimensional vector <b>V</b> transformed by matrix <b>M</b>
  function Transform4Vector33s(const M: TMatrix4s; const V: TVector3s): TVector3s; overload;
  // Returns expanded 3-dimensional vector <b>V</b> transformed by matrix <b>M</b>
  function Transform4Vector3s(const M: TMatrix4s; const V: TVector3s): TVector4s; overload;
  // Returns 4-dimensional vector <b>V</b> transformed by matrix <b>M</b>
  function Transform4Vector4s(const M: TMatrix4s; const V: TVector4s): TVector4s; overload;

  // 3x3 matrix inversion (current dummy implementation: transpose)
  function InvertMatrix3s(const M: TMatrix3s): TMatrix3s;
  // Returns @True if the specified matrix is affine (last column is 0, 0, 0, 1)
  function IsMatrixAffine(const M: TMatrix4s): Boolean;
  // Returns determinant of the specified matrix
  function MatDet(const M: TMatrix4s): Single;
  // Returns inversion of the specified matrix
  function InvertMatrix4s(const M: TMatrix4s): TMatrix4s;
  // Returns inversion of a matrix which contains affine transfomations (rotations, translations and scaling). Faster then @Link(InvertMatrix4s)
  function InvertAffineMatrix4s(const M: TMatrix4s): TMatrix4s;
  // Returns inversion of a matrix which contains only rotations and translations. Faster then @Link(InvertAffineMatrix4s)
  procedure InvertRotTransMatrix(out Result: TMatrix4s; const M: TMatrix4s); overload;
  // Returns inversion of a matrix which contains only rotations and translations. Faster then @Link(InvertAffineMatrix4s)
  function InvertRotTransMatrix(const M: TMatrix4s): TMatrix4s; overload;

  // Returns matrix containing reflection by the specified plane transformation
  procedure ReflectionMatrix4s(out Result: TMatrix4s; const PlanePoint, PlaneNormal: TVector3s); overload;
  // Returns matrix containing reflection by the specified plane transformation
  function ReflectionMatrix4s(const PlanePoint, PlaneNormal: TVector3s): TMatrix4s; overload;

  // Fills <b>Result</b> with a 4x4 rotation matrix which specifies the same rotation as <b>Quat</b>.
  procedure Matrix4sByQuat(var Result: TMatrix4s; const Quat: TQuaternion); overload;
  // Matrix multiplication
  procedure MulMatrix4s(out Result: TMatrix4s; const M1, M2: TMatrix4s); overload;
  // Matrix multiplication and transpose
  procedure TranspMulMatrix4s(out Result: TMatrix4s; const M1, M2: TMatrix4s); overload;
  // Returns transposed matrix
  procedure GetTransposedMatrix4s(out Result: TMatrix4s; const M: TMatrix4s); overload;
  // Returns scaling matrix
  procedure ScaleMatrix4s(out Result: TMatrix4s; const X, Y, Z: Single); overload;
  // Returns rotation over X-axis matrix
  procedure XRotationMatrix4s(out Result: TMatrix4s; const Angle: Single); overload;
  // Returns rotation over Y-axis matrix
  procedure YRotationMatrix4s(out Result: TMatrix4s; const Angle: Single); overload;
  // Returns rotation over Z-axis matrix
  procedure ZRotationMatrix4s(out Result: TMatrix4s; const Angle: Single); overload;
  // Returns translation matrix
  procedure TranslationMatrix4s(out Result: TMatrix4s; const X, Y, Z: Single); overload;

  // Returns 3-dimensional vector <b>V</b> transformed by matrix <b>M</b>
  procedure Transform4Vector33s(out Result: TVector3s; const M: TMatrix4s; const V: TVector3s); overload;
  // Returns expanded 3-dimensional vector <b>V</b> transformed by matrix <b>M</b>
  procedure Transform4Vector3s(out Result: TVector4s; const M: TMatrix4s; const V: TVector3s); overload;
  // Returns 4-dimensional vector <b>V</b> transformed by matrix <b>M</b>
  procedure Transform4Vector4s(out Result: TVector4s; const M: TMatrix4s; const V: TVector4s); overload;

  // Returns transposed matrix
  procedure TransposeMatrix4s(var M: TMatrix4s);

  // Expands a 3-dimensional vector to 4-dimensional by filling w-component with 1
  function ExpandVector3s(const V: Tvector3s): TVector4s; overload;
  // Cuts 3x3 matrix from the specified 4x4 matrix
  function CutMatrix3s(const M: TMatrix4s): TMatrix3s; overload;
  // Expands a 3x3 matrix to 4x3 matrix by filling new components with 0 except _44 which filled with 1
  function ExpandMatrix3s(const M: TMatrix3s): TMatrix4s; overload;
  // Returns a 3x3 rotation matrix which specifies the same rotation as <b>Quat</b>
  function Matrix3sByQuat(const Quat: TQuaternion): TMatrix3s; overload;

  // Matrix multiplication
  function MulMatrix3s(const M1, M2: TMatrix3s): TMatrix3s; overload;
  // Matrix multiplication and transpose
  function TranspMulMatrix3s(const M1, M2: TMatrix3s): TMatrix3s; overload;
  // Returns transposed matrix
  function GetTransposedMatrix3s(const M: TMatrix3s): TMatrix3s; overload;
  // Returns rotation over X-axis matrix
  function XRotationMatrix3s(const Angle: Single): TMatrix3s; overload;
  // Returns rotation over Y-axis matrix
  function YRotationMatrix3s(const Angle: Single): TMatrix3s; overload;
  // Returns rotation over Z-axis matrix
  function ZRotationMatrix3s(const Angle: Single): TMatrix3s; overload;
  // Returns 3-dimensional vector <b>V</b> transformed by matrix <b>M</b>
  function Transform3Vector3s(const M: TMatrix3s; const V: TVector3s): TVector3s; overload;
  // Returns 3-dimensional vector <b>V</b> transformed by transposed matrix <b>M</b>
  function Transform3Vector3sTransp(const M: TMatrix3s; const V: TVector3s): TVector3s; overload;

  // Expands a 3-dimensional vector to 4-dimensional by filling w-component by 1
  procedure ExpandVector3s(out Result: TVector4s; const V: Tvector3s); overload;
  // Cuts 3x3 matrix from the specified 4x4 matrix
  procedure CutMatrix3s(out Result: TMatrix3s; const M: TMatrix4s); overload;
  // Fills <b>Result</b> with a 3x3 rotation matrix which specifies the same rotation as <b>Quat</b>.
  procedure Matrix3sByQuat(var Result: TMatrix3s; const Quat: TQuaternion); overload;

  // Matrix multiplication
  procedure MulMatrix3s(out Result: TMatrix3s; const M1, M2: TMatrix3s); overload;
  // Matrix multiplication and transpose
  procedure TranspMulMatrix3s(out Result: TMatrix3s; const M1, M2: TMatrix3s); overload;
  // Returns transposed matrix
  procedure GetTransposedMatrix3s(out Result: TMatrix3s; const M: TMatrix3s); overload;
  // Returns rotation over X-axis matrix
  procedure XRotationMatrix3s(out Result: TMatrix3s; const Angle: Single); overload;
  // Returns rotation over Y-axis matrix
  procedure YRotationMatrix3s(out Result: TMatrix3s; const Angle: Single); overload;
  // Returns rotation over Z-axis matrix
  procedure ZRotationMatrix3s(out Result: TMatrix3s; const Angle: Single); overload;
  // Returns 3-dimensional vector <b>V</b> transformed by matrix <b>M</b>
  procedure Transform3Vector3s(out Result: TVector3s; const M: TMatrix3s; const V: TVector3s); overload;

  // Returns transposed matrix
  procedure TransposeMatrix3s(var M: TMatrix3s);

  // Returns True if both P1 and P2 points are at the same side of the ray
  function IsPointsSameSide(const Origin, Dir, P1, P2: TVector3s): Boolean;

  // Expands the bounding box to fit the given coordinates
  procedure ExpandBBox(var BoundingBox: TBoundingBox; const X, Y, Z: Single); overload;
  // Expands the bounding box to fit the given point
  procedure ExpandBBox(var BoundingBox: TBoundingBox; const Point: TVector3s); overload;

//  function RaySphereColDet(RayOrigin, RayDir, SphereOrigin: TVector3s; SphereRadius: Single; var Point: TVector3s): Boolean;
//  function RayCircleColDet(RayOrigin, RayDir, SphereOrigin: TVector3s; SphereRadius: Single; var Point: TVector3s): Boolean;

{  function SphereOOBBColDet(M1, M2: TMatrix3s; P1, P2: TVector3s; const Sphere, OOBB: TBoundingVolume; CoordStep: Integer): Boolean;   // ѕересечение сферы и бокса
  function OOBBOOBBColDet(M1, M2: TMatrix3s; P1, P2: TVector3s; const OOBB1, OOBB2: TBoundingVolume): Boolean;     // ѕересечение двух боксов
  function OOBBOOBBColDet2D(M1, M2: TMatrix3s; P1, P2: TVector3s; const OOBB1, OOBB2: TBoundingVolume): Boolean;    // ToFix: Add scale support
  function VolumeColDet(const Volume1, Volume2: TBoundingVolumes): TCollisionResult;                               // ѕересечение двух наборов объемов
  function VolumeColTest(const Volume1, Volume2: TBoundingVolumes): Boolean;                                       //
  function VolumeColDet2D(const Volume1, Volume2: TBoundingVolumes): TCollisionResult;     // ToFix: Take location in account
  function VolumeColTest2D(const Volume1, Volume2: TBoundingVolumes): Boolean;                                       //

  function NewBoundingVolume(AVolumeKind: Cardinal; AOffset, ADimensions: TVector3s; ANext: PBoundingVolume = nil): PBoundingVolume;
  procedure DisposeBoundingVolumes(var Volumes: TBoundingVolumes);}

  // Arctangent
  function ArcTan2(const Y, X: Extended): Extended;

var
  // Sinus table
  SinTable: array[0..SinTableSize + CosTabOffs] of Single;

implementation

function GetVector3s(const X, Y, Z: Single): TVector3s;
begin
  Result.X := X; Result.Y := Y; Result.Z := Z;
end;

procedure GetVector3s(out Result: TVector3s; const X, Y, Z: Single); overload;
begin
  Result.X := X; Result.Y := Y; Result.Z := Z;
end;

function Vec3s(const X, Y, Z: Single): TVector3s; overload;
begin
  Result.X := X; Result.Y := Y; Result.Z := Z;
end;

function Vec3s(const X1, Y1, Z1, X2, Y2, Z2: Single): TVector3s; overload;
begin
  Result.X := X2-X1; Result.Y := Y2-Y1; Result.Z := Z2-Z1;
end;

function GetVector4s(const X, Y, Z, W: Single): TVector4s; overload;
begin
  Result.X := X; Result.Y := Y; Result.Z := Z; Result.W := W;
end;

procedure GetVector4s(out Result: TVector4s; const X, Y, Z, W: Single); overload;
begin
  Result.X := X; Result.Y := Y; Result.Z := Z; Result.W := W;
end;

function Vec4s(const X, Y, Z, W: Single): TVector4s; overload;
begin
  Result.X := X; Result.Y := Y; Result.Z := Z; Result.W := W;
end;

function EqualsVector3s(const V1, V2: TVector3s): Boolean;
begin
  Result := (V1.X = V2.X) and (V1.Y = V2.Y) and (V1.Z = V2.Z);
end;

function EqualsVector4s(const V1, V2: TVector4s): Boolean;
begin
  Result := (V1.X = V2.X) and (V1.Y = V2.Y) and (V1.Z = V2.Z) and (V1.W = V2.W);
end;

function AddVector3s(const V1, V2: TVector3s): TVector3s; overload;
begin
  with Result do begin
    X := V1.X+V2.X; Y := V1.Y+V2.Y; Z := V1.Z+V2.Z;
  end;
end;

procedure AddVector3s(out Result: TVector3s; const V1, V2: TVector3s); overload;
begin
  with Result do begin
    X := V1.X+V2.X; Y := V1.Y+V2.Y; Z := V1.Z+V2.Z;
  end;
end;

function SubVector3s(const V1, V2: TVector3s): TVector3s; overload;
begin
  with Result do begin
    X := V1.X - V2.X; Y := V1.Y - V2.Y; Z := V1.Z - V2.Z;
  end;
end;

procedure SubVector3s(out Result: TVector3s; const V1, V2: TVector3s); overload;
begin
  with Result do begin
    X := V1.X - V2.X; Y := V1.Y - V2.Y; Z := V1.Z - V2.Z;
  end;
end;

function ScaleVector3s(const V: TVector3s; const Factor: Single): TVector3s; overload;
begin
  Result.X := V.X * Factor; Result.Y := V.Y * Factor; Result.Z := V.Z * Factor;
end;

procedure ScaleVector3s(out Result: TVector3s; const V: TVector3s; const Factor: Single); overload;
begin
  Result.X := V.X * Factor; Result.Y := V.Y * Factor; Result.Z := V.Z * Factor;
end;

function AddVector4s(const V1, V2: TVector4s): TVector4s; overload;
begin
  with Result do begin
    X := V1.X+V2.X; Y := V1.Y+V2.Y; Z := V1.Z+V2.Z; W := V1.W+V2.W;
  end;
end;

procedure AddVector4s(out Result: TVector4s; const V1, V2: TVector4s); overload;
begin
  with Result do begin
    X := V1.X+V2.X; Y := V1.Y+V2.Y; Z := V1.Z+V2.Z; W := V1.W+V2.W;
  end;
end;

function SubVector4s(const V1, V2: TVector4s): TVector4s; overload;
begin
  with Result do begin
    X := V1.X - V2.X; Y := V1.Y - V2.Y; Z := V1.Z - V2.Z; W := V1.W - V2.W;
  end;
end;

procedure SubVector4s(out Result: TVector4s; const V1, V2: TVector4s); overload;
begin
  with Result do begin
    X := V1.X - V2.X; Y := V1.Y - V2.Y; Z := V1.Z - V2.Z; W := V1.W - V2.W;
  end;
end;

function ScaleVector4s(const V: TVector4s; const Factor: Single): TVector4s; overload;
begin
  Result.X := V.X * Factor; Result.Y := V.Y * Factor; Result.Z := V.Z * Factor; Result.W := V.W * Factor;
end;

procedure ScaleVector4s(out Result: TVector4s; const V: TVector4s; const Factor: Single); overload;
begin
  Result.X := V.X * Factor; Result.Y := V.Y * Factor; Result.Z := V.Z * Factor; Result.W := V.W * Factor;
end;

function DotProductVector3s(const V1, V2: TVector3s): Single;
begin
  Result := V1.X*V2.X + V1.Y*V2.Y + V1.Z*V2.Z;
end;

function CartesianProductVector3s(const V1, V2: TVector3s): TVector3s;
begin
  with Result do begin
    X := V1.X*V2.X; Y := V1.Y*V2.Y; Z := V1.Z*V2.Z;
  end;
end;

function CrossProductVector3s(const V1, V2: TVector3s): TVector3s; overload;
begin
  with Result do begin
    X := V1.Y*V2.Z - V1.Z*V2.Y;
    Y := V1.Z*V2.X - V1.X*V2.Z;
    Z := V1.X*V2.Y - V1.Y*V2.X;
  end;
end;

function ReflectVector3s(const V, N: TVector3s): TVector3s; overload;
// N - reflecting surface's normal
var d : Single;
begin
  d := -dotProductVector3s(V, N) * 2;
  Result.X := (d * N.X) + V.X;
  Result.Y := (d * N.Y) + V.Y;
  Result.Z := (d * N.Z) + V.Z;
end;

function RotateVector3s(const V: TVector3s; const XA, YA, ZA: Single): TVector3s; overload;
// Y axis only
begin
  Result.X := V.X * Cos(YA) + V.Z * Sin(YA);
  Result.Y := V.Y;
  Result.Z := -V.X * Sin(YA) + V.Z * Cos(YA);
end;

function NormalizeVector3s(const V: TVector3s; Length: Single = 1): TVector3s; overload;
var Sq: Single;
begin
  Sq := sqrt(sqr(V.X) + sqr(V.Y) + sqr(V.Z));
  if Sq > 0 then Length := Length / Sq else Length := 0;
  Result.X := Length * V.X;
  Result.Y := Length * V.Y;
  Result.Z := Length * V.Z;
end;

procedure FastNormalizeVector3s(var Result: TVector3s; Length: Single = 1);
begin
  Length := Length * InvSqrt(sqr(Result.X) + sqr(Result.Y) + sqr(Result.Z));
  Result.X := Length * Result.X;
  Result.Y := Length * Result.Y;
  Result.Z := Length * Result.Z;
end;

procedure CrossProductVector3s(out Result: TVector3s; const V1, V2: TVector3s); overload;
begin
  with Result do begin
    X := V1.Y*V2.Z - V1.Z*V2.Y;
    Y := V1.Z*V2.X - V1.X*V2.Z;
    Z := V1.X*V2.Y - V1.Y*V2.X;
  end;
end;

procedure ReflectVector3s(out Result: TVector3s; const V, N: TVector3s); overload;
// N - reflecting surface's normal
var d : Single;
begin
  d := dotProductVector3s(V, N) * 2;
  Result.X := V.X - (d * N.X);
  Result.Y := V.Y - (d * N.Y);
  Result.Z := V.Z - (d * N.Z);
end;

procedure RotateVector3s(out Result: TVector3s; const V: TVector3s; const XA, YA, ZA: Single); overload;
// Y axis only
begin
  Result.X := V.X * Cos(YA) + V.Z * Sin(YA);
  Result.Y := V.Y;
  Result.Z := -V.X * Sin(YA) + V.Z * Cos(YA);
end;

procedure NormalizeVector3s(out Result: TVector3s; const V: TVector3s; Length: Single = 1); overload;
var Sq: Single;
begin
  Sq := sqrt(sqr(V.X) + sqr(V.Y) + sqr(V.Z));
  if Sq > 0 then Length := Length / Sq else Length := 0;
  Result.X := Length * V.X;
  Result.Y := Length * V.Y;
  Result.Z := Length * V.Z;
end;

procedure GetPerpendicular3s(out Result: TVector3s; const V: TVector3s);
var i, j: Integer;
begin
  Result := V;
  for i := 0 to 2 do begin
    if i < 2 then j := i+1 else j := 0;
    if V.V[i] <> 0 then begin
      Result.V[i] := V.V[j];
      Result.V[j] := V.V[i];
      Exit;
    end;
  end;
end;

function GetPerpendicular3s(const V: TVector3s): TVector3s;
var i, j: Integer;
begin
  Result := V;
  for i := 0 to 2 do begin
    if i < 2 then j := i+1 else j := 0;
    if V.V[i] <> 0 then begin
      Result.V[i] := V.V[j];
      Result.V[j] := V.V[i];
      Exit;
    end;
  end;
end;

procedure FastNormalizeVector4s(var Result: TVector4s; Length: Single = 1);
begin
  Length := Length * InvSqrt(sqr(Result.X) + sqr(Result.Y) + sqr(Result.Z) + sqr(Result.W));
  Result.X := Length * Result.X;
  Result.Y := Length * Result.Y;
  Result.Z := Length * Result.Z;
  Result.W := Length * Result.W;
end;

function NormalizeVector4s(const V: TVector4s; Length: Single = 1): TVector4s;
var Sq: Single;
begin
  Sq := Sqrt(sqr(V.X) + sqr(V.Y) + sqr(V.Z) + sqr(V.W));
  if Sq > 0 then Length := Length / Sq else Length := 0;
  Result.X := Length * V.X;
  Result.Y := Length * V.Y;
  Result.Z := Length * V.Z;
  Result.W := Length * V.W;
end;

function SqrMagnitude(const V: TVector3s): Single;
begin
  Result := Sqr(V.X)+Sqr(V.Y)+Sqr(V.Z);
end;

function GetMagnitudeApprox(const V: TVector3s): Single;  // need test
var t, x, y, z: Single;
begin
  x := abs(V.X) * 1024;
  y := abs(V.Y) * 1024;
  z := abs(V.Z) * 1024;
// Sort
  if y < x then begin t := x; x := y; y := t; end;
  if z < y then begin t := y; y := z; z := t; end;
  if y < x then begin t := x; x := y; y := t; end;

  Result := (z + 11 * (y / 32) + (x / 4) ) / 1024;
end;

function GetPlane(A, B, C, D: Single): TPlane;
begin
  Result.A := A; Result.B := B; Result.C := C; Result.D := D;
end;

function GetPlaneFromPointNormal(const Point, Normal: TVector3s): TPlane;
begin
  PlaneFromPointNormal(Result, Point, Normal);
end;

procedure PlaneFromPointNormal(out Result: TPlane; const Point, Normal: TVector3s);
var k: Single;
begin
  if Abs(1 - SqrMagnitude(Normal)) < epsilon then k := 1 else k := InvSqrt(SqrMagnitude(Normal));
  Result.A := Normal.X * k;
  Result.B := Normal.Y * k;
  Result.C := Normal.Z * k;
  Result.D := -(Result.A * Point.X + Result.B * Point.Y + Result.C * Point.Z);
end;

procedure NormalizePlane(var APlane: TPlane);
var d: Single;
begin
  d := 1/Sqrt(Sqr(APlane.A) + Sqr(APlane.B) + Sqr(APlane.C));
  APlane.A := APlane.A * d;
  APlane.B := APlane.B * d;
  APlane.C := APlane.C * d;
  APlane.D := APlane.D * d;
end;

procedure GetQuaternion(out Result: TQuaternion; const Angle: Single; const Axis: TVector3s);
var Dist: Single;
begin
  {$IFDEF DEBUGMODE}
//  Assert(Sqr(Axis.X) + Sqr(Axis.Y) + Sqr(Axis.Z) > epsilon, 'GetQuaternion: Axis is zero-length');
  {$ENDIF}
  Result[0] := Cos(Angle/2);
  Dist := Sqrt(Sqr(Axis.X) + Sqr(Axis.Y) + Sqr(Axis.Z));
  if Dist > epsilon then Dist := Sin(Angle/2) / Dist else Dist := 0;   
  Result[1] := Axis.X * Dist;
  Result[2] := Axis.Y * Dist;
  Result[3] := Axis.Z * Dist;
end;

procedure MulQuaternion(out Result: TQuaternion; const Quat1, Quat2: TQuaternion);
begin
  Result[0] := Quat1[0]*Quat2[0] - Quat1[1]*Quat2[1] - Quat1[2]*Quat2[2] - Quat1[3]*Quat2[3];
  Result[1] := Quat1[0]*Quat2[1] + Quat2[0]*Quat1[1] + Quat1[2]*Quat2[3] - Quat1[3]*Quat2[2];
  Result[2] := Quat1[0]*Quat2[2] + Quat2[0]*Quat1[2] + Quat1[3]*Quat2[1] - Quat1[1]*Quat2[3];
  Result[3] := Quat1[0]*Quat2[3] + Quat2[0]*Quat1[3] + Quat1[1]*Quat2[2] - Quat1[2]*Quat2[1];
end;

procedure NormalizeQuaternion(out Result: TQuaternion; const Quat: TQuaternion); overload;
var Dist: Single;
begin
  {$IFDEF DEBUGMODE}
  Assert(Sqr(Quat[0]) + Sqr(Quat[1]) + Sqr(Quat[2]) + Sqr(Quat[3]) > epsilon, 'NormalizeQuaternion: Quaternion is zero-length');
  {$ENDIF}
  Dist := 1/Sqrt(Sqr(Quat[0]) + Sqr(Quat[1]) + Sqr(Quat[2]) + Sqr(Quat[3]));
  Result[0] := Quat[0]*Dist;
  Result[1] := Quat[1]*Dist;
  Result[2] := Quat[2]*Dist;
  Result[3] := Quat[3]*Dist;
end;

function GetQuaternion(const Angle: Single; const Axis: TVector3s): TQuaternion; overload;
begin
  GetQuaternion(Result, Angle, Axis);
end;

function EqualsQuaternions(Q1, Q2: TQuaternion): Boolean;
begin
  Result := (Q1[0] = Q2[0]) and (Q1[1] = Q2[1]) and (Q1[2] = Q2[2]) and (Q1[3] = Q2[3]);
end;

function MulQuaternion(const Quat1, Quat2: TQuaternion): TQuaternion; overload;
begin
  MulQuaternion(Result, Quat1, Quat2);
end;

function NormalizeQuaternion(const Quat: TQuaternion): TQuaternion; overload;
var Dist: Single;
begin
  Dist := 1/Sqrt(Sqr(Quat[0]) + Sqr(Quat[1]) + Sqr(Quat[2]) + Sqr(Quat[3]));
  Result[0] := Quat[0]*Dist;
  Result[1] := Quat[1]*Dist;
  Result[2] := Quat[2]*Dist;
  Result[3] := Quat[3]*Dist;
end;

procedure GetVectorRotateQuat(out Result: TQuaternion; const OldDir, NewDir: TVector3s); overload;
var Dist, S, C: Single; Axis, Med: TVector3s;                                            
begin
  CrossProductVector3s(Axis, OldDir, NewDir);

  ScaleVector3s(Med, AddVector3s(OldDir, NewDir), 0.5);                   // Median
  C := SqrMagnitude(Med);                                                 // Cos^2 alpha/2
  S := Sqrt(1 - C);                                                       // Sin alpha/2
  C := Sqrt(C);                                                           // Cos alpha/2
//  S := Sqrt(SqrMagnitude(SubVector3s(OldDir, Med)));                      // Sin alpha/2
//  Assert(C*C + S*S - 1 < epsilon);

  Dist := Sqrt(Sqr(Axis.X) + Sqr(Axis.Y) + Sqr(Axis.Z));
  if Dist > epsilon then
    Dist := S / Dist
  else begin
    Dist := 0;
    if DotProductVector3s(OldDir, NewDir) > 0 then
      C := 1
    else
      C := -1;
  end;

  Result[0] := C;
  Result[1] := Axis.X * Dist;
  Result[2] := Axis.Y * Dist;
  Result[3] := Axis.Z * Dist;
end;

function GetVectorRotateQuat(const OldDir, NewDir: TVector3s): TQuaternion; overload;
begin
  GetVectorRotateQuat(Result, OldDir, NewDir);
end;

function MulMatrix4s(const M1, M2: TMatrix4s): TMatrix4s; overload;
var i, j : Integer;
begin
  for j := 0 to 3 do for i := 0 to 3 do
   Result.M[j, i] := (M1.M[j, 0] * M2.M[0, i]) +
                     (M1.M[j, 1] * M2.M[1, i]) +
                     (M1.M[j, 2] * M2.M[2, i]) +
                     (M1.M[j, 3] * M2.M[3, i]);
end;

function TranspMulMatrix4s(const M1, M2: TMatrix4s): TMatrix4s; overload;
var i, j : Integer;
begin
  for j := 0 to 3 do for i := 0 to 3 do
   Result.M[j, i] := (M1.M[j, 0] * M2.M[i, 0]) +
                     (M1.M[j, 1] * M2.M[i, 1]) +
                     (M1.M[j, 2] * M2.M[i, 2]) +
                     (M1.M[j, 3] * M2.M[i, 3]);
end;

function GetTransposedMatrix4s(const M: TMatrix4s): TMatrix4s; overload;
var i, j : Integer;
begin
  for j := 0 to 3 do for i := 0 to 3 do Result.M[j, i] := M.M[i, j];
end;

function ScaleMatrix4s(const X, Y, Z: Single): TMatrix4s; overload;
begin
  with Result do begin
    M[0,0] := X; M[0,1] := 0; M[0,2] := 0; M[0,3] := 0;
    M[1,0] := 0; M[1,1] := Y; M[1,2] := 0; M[1,3] := 0;
    M[2,0] := 0; M[2,1] := 0; M[2,2] := Z; M[2,3] := 0;
    M[3,0] := 0; M[3,1] := 0; M[3,2] := 0; M[3,3] := 1;
  end;
end;

function XRotationMatrix4s(const Angle: Single): TMatrix4s; overload;
var s, c : Single;
begin
  s := Sin(Angle); c := Cos(Angle);
  with Result do begin
    M[0,0] := 1; M[0,1] := 0; M[0,2] := 0; M[0,3] := 0;
    M[1,0] := 0; M[1,1] := c; M[1,2] := s; M[1,3] := 0;
    M[2,0] := 0; M[2,1] :=-s; M[2,2] := c; M[2,3] := 0;
    M[3,0] := 0; M[3,1] := 0; M[3,2] := 0; M[3,3] := 1;
  end;
end;

function YRotationMatrix4s(const Angle: Single): TMatrix4s; overload;
var s, c: Single;
begin
  s := Sin(Angle); c := Cos(Angle);
  with Result do begin
    M[0,0] :=  c; M[0,1] := 0; M[0,2] :=-s; M[0,3] := 0;
    M[1,0] :=  0; M[1,1] := 1; M[1,2] := 0; M[1,3] := 0;
    M[2,0] :=  s; M[2,1] := 0; M[2,2] := c; M[2,3] := 0;
    M[3,0] :=  0; M[3,1] := 0; M[3,2] := 0; M[3,3] := 1;
  end;
end;

function ZRotationMatrix4s(const Angle: Single): TMatrix4s; overload;
var s, c: Single;
begin
  SinCos(Angle, s, c);
//  s := Sin(Angle); c := Cos(Angle);
  with Result do begin
    M[0,0] := c; M[0,1] := s; M[0,2] := 0; M[0,3] := 0;
    M[1,0] :=-s; M[1,1] := c; M[1,2] := 0; M[1,3] := 0;
    M[2,0] := 0; M[2,1] := 0; M[2,2] := 1; M[2,3] := 0;
    M[3,0] := 0; M[3,1] := 0; M[3,2] := 0; M[3,3] := 1;
  end;
end;

function TranslationMatrix4s(const X, Y, Z: Single): TMatrix4s; overload;
begin
  with Result do begin
    M[0,0] := 1; M[0,1] := 0; M[0,2] := 0; M[0,3] := 0;
    M[1,0] := 0; M[1,1] := 1; M[1,2] := 0; M[1,3] := 0;
    M[2,0] := 0; M[2,1] := 0; M[2,2] := 1; M[2,3] := 0;
    M[3,0] := X; M[3,1] := Y; M[3,2] := Z; M[3,3] := 1;
  end;
end;

function Transform4Vector33s(const M: TMatrix4s; const V: TVector3s): TVector3s; overload;
begin
  Result.X := M.M[0, 0] * V.X + M.M[1, 0] * V.Y + M.M[2, 0] * V.Z + M.M[3, 0];
  Result.Y := M.M[0, 1] * V.X + M.M[1, 1] * V.Y + M.M[2, 1] * V.Z + M.M[3, 1];
  Result.Z := M.M[0, 2] * V.X + M.M[1, 2] * V.Y + M.M[2, 2] * V.Z + M.M[3, 2];
end;


function Transform4Vector3s(const M: TMatrix4s; const V: TVector3s): TVector4s; overload;
begin
  Result.X := M.M[0, 0] * V.X + M.M[1, 0] * V.Y + M.M[2, 0] * V.Z + M.M[3, 0];
  Result.Y := M.M[0, 1] * V.X + M.M[1, 1] * V.Y + M.M[2, 1] * V.Z + M.M[3, 1];
  Result.Z := M.M[0, 2] * V.X + M.M[1, 2] * V.Y + M.M[2, 2] * V.Z + M.M[3, 2];
  Result.W := M.M[0, 3] * V.X + M.M[1, 3] * V.Y + M.M[2, 3] * V.Z + M.M[3, 3];
end;

function Transform4Vector4s(const M: TMatrix4s; const V: TVector4s): TVector4s; overload;
begin
  Result.X := M.M[0, 0] * V.X + M.M[1, 0] * V.Y + M.M[2, 0] * V.Z + M.M[3, 0] * V.W;
  Result.Y := M.M[0, 1] * V.X + M.M[1, 1] * V.Y + M.M[2, 1] * V.Z + M.M[3, 1] * V.W;
  Result.Z := M.M[0, 2] * V.X + M.M[1, 2] * V.Y + M.M[2, 2] * V.Z + M.M[3, 2] * V.W;
  Result.W := M.M[0, 3] * V.X + M.M[1, 3] * V.Y + M.M[2, 3] * V.Z + M.M[3, 3] * V.W;
end;

procedure InvertRotTransMatrix(out Result: TMatrix4s; const M: TMatrix4s); overload;       // Get an inverted of translation * rotation matrix
begin
  // Inverse rotation
  Result._11 := M._11;
  Result._12 := M._21;
  Result._13 := M._31;
  Result._21 := M._12;
  Result._22 := M._22;
  Result._23 := M._32;
  Result._31 := M._13;
  Result._32 := M._23;
  Result._33 := M._33;
// Inverse translation
  Result._41 := -M._41 * M._11 - M._42 * M._12 - M._43 * M._13;
  Result._42 := -M._41 * M._21 - M._42 * M._22 - M._43 * M._23;
  Result._43 := -M._41 * M._31 - M._42 * M._32 - M._43 * M._33;
// Fill other values
  Result._14 := M._14;
  Result._24 := M._24;
  Result._34 := M._34;
  Result._44 := M._44;
end;

function InvertRotTransMatrix(const M: TMatrix4s): TMatrix4s; overload;       // Return inversion of matrix containing only translation and rotation
begin
  InvertRotTransMatrix(Result, M);
end;

procedure ReflectionMatrix4s(out Result: TMatrix4s; const PlanePoint, PlaneNormal: TVector3s);
var PNDot: Single;
begin
  PNDot := PlanePoint.X * PlaneNormal.X + PlanePoint.Y * PlaneNormal.Y + PlanePoint.Z * PlaneNormal.Z;

  Result.M[0, 0] := 1 - 2 * PlaneNormal.V[0] * PlaneNormal.V[0];
  Result.M[1, 0] :=   - 2 * PlaneNormal.V[0] * PlaneNormal.V[1];
  Result.M[2, 0] :=   - 2 * PlaneNormal.V[0] * PlaneNormal.V[2];
  Result.M[3, 0] :=     2 * PNDot * PlaneNormal.V[0];

  Result.M[0, 1] :=  - 2 * PlaneNormal.V[1] * PlaneNormal.V[0];
  Result.M[1, 1] := 1- 2 * PlaneNormal.V[1] * PlaneNormal.V[1];
  Result.M[2, 1] :=  - 2 * PlaneNormal.V[1] * PlaneNormal.V[2];
  Result.M[3, 1] :=    2 * PNDot * PlaneNormal.V[1];

  Result.M[0, 2] :=   - 2 * PlaneNormal.V[2] * PlaneNormal.V[0];
  Result.M[1, 2] :=   - 2 * PlaneNormal.V[2] * PlaneNormal.V[1];
  Result.M[2, 2] := 1 - 2 * PlaneNormal.V[2] * PlaneNormal.V[2];
  Result.M[3, 2] := 2 * PNDot * PlaneNormal.V[2];

  Result.M[0, 3] := 0;
  Result.M[1, 3] := 0;
  Result.M[2, 3] := 0;
  Result.M[3, 3] := 1;
{

GLfloat* p = (Glfloat*)plane_point;
Glfloat* v = (Glfloat*)plane_normal;
float pv = p[0]*v[0]+p[1]*v[1]+p[2]*v[2];

reflection_matrix[0][0] = 1 - 2 * v[0] * v[0];
reflection_matrix[1][0] = - 2 * v[0] * v[1];
reflection_matrix[2][0] = - 2 * v[0] * v[2];
reflection_matrix[3][0] = 2 * pv * v[0];

reflection_matrix[0][1] = - 2 * v[0] * v[1];
reflection_matrix[1][1] = 1- 2 * v[1] * v[1];
reflection_matrix[2][1] = - 2 * v[1] * v[2];
reflection_matrix[3][1] = 2 * pv * v[1];

reflection_matrix[0][2] = - 2 * v[0] * v[2];
reflection_matrix[1][2] = - 2 * v[1] * v[2];
reflection_matrix[2][2] = 1 - 2 * v[2] * v[2];
reflection_matrix[3][2] = 2 * pv * v[2];

reflection_matrix[0][3] = 0;
reflection_matrix[1][3] = 0;
reflection_matrix[2][3] = 0;
reflection_matrix[3][3] = 1;
}
end;

function ReflectionMatrix4s(const PlanePoint, PlaneNormal: TVector3s): TMatrix4s;
begin
  ReflectionMatrix4s(Result, PlanePoint, PlaneNormal);
end;

function InvertMatrix3s(const M: TMatrix3s): TMatrix3s;                       // ToDo: Dummy, uses transpose
begin
  Result := GetTransposedMatrix3s(M);
end;

function IsMatrixAffine(const M: TMatrix4s): Boolean;
begin
  Result := (abs(M._14) < epsilon) and (abs(M._24) < epsilon) and (abs(M._34) < epsilon) and (abs(1-M._44) < epsilon);
end;

function MatDet(const M: TMatrix4s): Single;
begin
  Result :=
    M.A[3] * M.A[6] * M.A[09] * M.A[12]-M.A[2] * M.A[7] * M.A[09] * M.A[12]-M.A[3] * M.A[5] * M.A[10] * M.A[12]+M.A[1] * M.A[7] * M.A[10] * M.A[12]+
    M.A[2] * M.A[5] * M.A[11] * M.A[12]-M.A[1] * M.A[6] * M.A[11] * M.A[12]-M.A[3] * M.A[6] * M.A[08] * M.A[13]+M.A[2] * M.A[7] * M.A[08] * M.A[13]+
    M.A[3] * M.A[4] * M.A[10] * M.A[13]-M.A[0] * M.A[7] * M.A[10] * M.A[13]-M.A[2] * M.A[4] * M.A[11] * M.A[13]+M.A[0] * M.A[6] * M.A[11] * M.A[13]+
    M.A[3] * M.A[5] * M.A[08] * M.A[14]-M.A[1] * M.A[7] * M.A[08] * M.A[14]-M.A[3] * M.A[4] * M.A[09] * M.A[14]+M.A[0] * M.A[7] * M.A[09] * M.A[14]+
    M.A[1] * M.A[4] * M.A[11] * M.A[14]-M.A[0] * M.A[5] * M.A[11] * M.A[14]-M.A[2] * M.A[5] * M.A[08] * M.A[15]+M.A[1] * M.A[6] * M.A[08] * M.A[15]+
    M.A[2] * M.A[4] * M.A[09] * M.A[15]-M.A[0] * M.A[6] * M.A[09] * M.A[15]-M.A[1] * M.A[4] * M.A[10] * M.A[15]+M.A[0] * M.A[5] * M.A[10] * M.A[15];
end;

function InvertMatrix4s(const M: TMatrix4s): TMatrix4s;
var det, OneOverDet: Single;

  function MatDet3x3(a, b, c,
                     d, e, f,
                     g, h, i: Single): Single; {$I inline.inc}
  begin
    Result := a*e*i + b*f*g + c*d*h - a*f*h - b*d*i - c*e*g;
  end;

begin
  det := MatDet(M);
  if det <> 0 then begin
    OneOverDet := 1/Det;
    Result._11 :=  matdet3x3(M.A[05], M.A[09], M.A[13], M.A[06], M.A[10], M.A[14], M.A[07], M.A[11], M.A[15])*OneOverDet;
    Result._12 := -matdet3x3(M.A[01], M.A[09], M.A[13], M.A[02], M.A[10], M.A[14], M.A[03], M.A[11], M.A[15])*OneOverDet;
    Result._13 :=  matdet3x3(M.A[01], M.A[05], M.A[13], M.A[02], M.A[06], M.A[14], M.A[03], M.A[07], M.A[15])*OneOverDet;
    Result._14 := -matdet3x3(M.A[01], M.A[05], M.A[09], M.A[02], M.A[06], M.A[10], M.A[03], M.A[07], M.A[11])*OneOverDet;

    Result._21 := -matdet3x3(M.A[04], M.A[08], M.A[12], M.A[06], M.A[10], M.A[14], M.A[07], M.A[11], M.A[15])*OneOverDet;
    Result._22 :=  matdet3x3(M.A[00], M.A[08], M.A[12], M.A[02], M.A[10], M.A[14], M.A[03], M.A[11], M.A[15])*OneOverDet;
    Result._23 := -matdet3x3(M.A[00], M.A[04], M.A[12], M.A[02], M.A[06], M.A[14], M.A[03], M.A[07], M.A[15])*OneOverDet;
    Result._24 :=  matdet3x3(M.A[00], M.A[04], M.A[08], M.A[02], M.A[06], M.A[10], M.A[03], M.A[07], M.A[11])*OneOverDet;

    Result._31 :=  matdet3x3(M.A[04], M.A[08], M.A[12], M.A[05], M.A[09], M.A[13], M.A[07], M.A[11], M.A[15])*OneOverDet;
    Result._32 := -matdet3x3(M.A[00], M.A[08], M.A[12], M.A[01], M.A[09], M.A[13], M.A[03], M.A[11], M.A[15])*OneOverDet;
    Result._33 :=  matdet3x3(M.A[00], M.A[04], M.A[12], M.A[01], M.A[05], M.A[13], M.A[03], M.A[07], M.A[15])*OneOverDet;
    Result._34 := -matdet3x3(M.A[00], M.A[04], M.A[08], M.A[01], M.A[05], M.A[09], M.A[03], M.A[07], M.A[11])*OneOverDet;

    Result._41 := -matdet3x3(M.A[04], M.A[08], M.A[12], M.A[05], M.A[09], M.A[13], M.A[06], M.A[10], M.A[14])*OneOverDet;
    Result._42 :=  matdet3x3(M.A[00], M.A[08], M.A[12], M.A[01], M.A[09], M.A[13], M.A[02], M.A[10], M.A[14])*OneOverDet;
    Result._43 := -matdet3x3(M.A[00], M.A[04], M.A[12], M.A[01], M.A[05], M.A[13], M.A[02], M.A[06], M.A[14])*OneOverDet;
    Result._44 :=  matdet3x3(M.A[00], M.A[04], M.A[08], M.A[01], M.A[05], M.A[09], M.A[02], M.A[06], M.A[10])*OneOverDet;
  end else Result := IdentityMatrix4s;
end;

function InvertAffineMatrix4s(const M: TMatrix4s): TMatrix4s;
var DetInv: Single;
begin
  Assert(IsMatrixAffine(M), 'InvertAffineMatrix4s can only invert affine matrices');
  if not IsMatrixAffine(M) then Exit;

  DetInv := 1 /( M._11 * ( M._22 * M._33 - M._23 * M._32 ) -                // 0  1  2  3
                 M._12 * ( M._21 * M._33 - M._23 * M._31 ) +                // 4  5  6  7
                 M._13 * ( M._21 * M._32 - M._22 * M._31 ) );               // 8  9  10 11
                                                                            // 12 13 14 15
  Result._11 :=  ( M._22 * M._33 - M._23 * M._32 ) * DetInv;
  Result._12 := -( M._12 * M._33 - M._13 * M._32 ) * DetInv;
  Result._13 :=  ( M._12 * M._23 - M._13 * M._22 ) * DetInv;
  Result._14 :=  0;

  Result._21 := -( M._21 * M._33 - M._23 * M._31 ) * DetInv;
  Result._22 :=  ( M._11 * M._33 - M._13 * M._31 ) * DetInv;
  Result._23 := -( M._11 * M._23 - M._13 * M._21 ) * DetInv;
  Result._24 :=  0;

  Result._31 :=  ( M._21 * M._32 - M._22 * M._31 ) * DetInv;
  Result._32 := -( M._11 * M._32 - M._12 * M._31 ) * DetInv;
  Result._33 :=  ( M._11 * M._22 - M._12 * M._21 ) * DetInv;
  Result._34 :=  0;

  Result._41 := -( M._41 * Result._11 + M._42 * Result._21 + M._43 * Result._31);
  Result._42 := -( M._41 * Result._12 + M._42 * Result._22 + M._43 * Result._32);
  Result._43 := -( M._41 * Result._13 + M._42 * Result._23 + M._43 * Result._33);

  Result._44 :=  1;
end;

procedure Matrix4sByQuat(var Result: TMatrix4s; const Quat: TQuaternion);
begin
  Result.M[0, 0] := 1.0 - 2.0 * (Quat[2]*Quat[2] + Quat[3]*Quat[3]);
  Result.M[0, 1] := 2.0 * (Quat[1]*Quat[2] + Quat[0]*Quat[3]);
  Result.M[0, 2] := 2.0 * (Quat[1]*Quat[3] - Quat[0]*Quat[2]);

  Result.M[1, 0] := 2.0 * (Quat[1]*Quat[2] - Quat[0]*Quat[3]);
  Result.M[1, 1] := 1.0 - 2.0 * (Quat[1]*Quat[1] + Quat[3]*Quat[3]);
  Result.M[1, 2] := 2.0 * (Quat[2]*Quat[3] + Quat[0]*Quat[1]);

  Result.M[2, 0] := 2.0 * (Quat[1]*Quat[3] + Quat[0]*Quat[2]);
  Result.M[2, 1] := 2.0 * (Quat[2]*Quat[3] - Quat[0]*Quat[1]);
  Result.M[2, 2] := 1.0 - 2.0 * (Quat[1]*Quat[1] + Quat[2]*Quat[2]);

//    [ 1-2*(y*y+z*z)   2*(x*y-w*z)     2*(x*z+w*y)   ]
//A = [ 2*(x*y+w*z)     1-2*(x*x-z*z)   2*(y*z-w*x)   ]
//    [ 2*(x*z-w*y)     2*(y*z+w*x)     1-2*(x*x-y*y) ].
end;

function EqualsMatrix3s(const M1, M2: TMatrix3s): Boolean;
var i: Integer;
begin
  i := 3*3-1;
  while (i >= 0) and (M1.A[i] = M2.A[i]) do Dec(i);
  Result := i < 0;
end;

function EqualsMatrix4s(const M1, M2: TMatrix4s): Boolean;
var i: Integer;
begin
  i := 4*4-1;
  while (i >= 0) and (M1.A[i] = M2.A[i]) do Dec(i);
  Result := i < 0;
end;

function Matrix4sByQuat(const Quat: TQuaternion): TMatrix4s;
begin
  Matrix4sByQuat(Result, Quat);
end;

procedure MulMatrix4s(out Result: TMatrix4s; const M1, M2: TMatrix4s); overload;
var i, j : Integer;
begin
  for j := 0 to 3 do for i := 0 to 3 do
   Result.M[j, i] := (M1.M[j, 0] * M2.M[0, i]) +
                     (M1.M[j, 1] * M2.M[1, i]) +
                     (M1.M[j, 2] * M2.M[2, i]) +
                     (M1.M[j, 3] * M2.M[3, i]);
end;

procedure TranspMulMatrix4s(out Result: TMatrix4s; const M1, M2: TMatrix4s); overload;
var i, j : Integer;
begin
  for j := 0 to 3 do for i := 0 to 3 do
   Result.M[j, i] := (M1.M[j, 0] * M2.M[i, 0]) +
                     (M1.M[j, 1] * M2.M[i, 1]) +
                     (M1.M[j, 2] * M2.M[i, 2]) +
                     (M1.M[j, 3] * M2.M[i, 3]);
end;

procedure GetTransposedMatrix4s(out Result: TMatrix4s; const M: TMatrix4s); overload;
var i, j : Integer;
begin
  for j := 0 to 3 do for i := 0 to 3 do Result.M[j, i] := M.M[i, j];
end;

procedure ScaleMatrix4s(out Result: TMatrix4s; const X, Y, Z: Single); overload;
begin
  with Result do begin
    M[0,0] := X; M[0,1] := 0; M[0,2] := 0; M[0,3] := 0;
    M[1,0] := 0; M[1,1] := Y; M[1,2] := 0; M[1,3] := 0;
    M[2,0] := 0; M[2,1] := 0; M[2,2] := Z; M[2,3] := 0;
    M[3,0] := 0; M[3,1] := 0; M[3,2] := 0; M[3,3] := 1;
  end;
end;

procedure XRotationMatrix4s(out Result: TMatrix4s; const Angle: Single); overload;
var s, c : Single;
begin
  s := Sin(Angle); c := Cos(Angle);
  with Result do begin
    M[0,0] := 1; M[0,1] := 0; M[0,2] := 0; M[0,3] := 0;
    M[1,0] := 0; M[1,1] := c; M[1,2] := s; M[1,3] := 0;
    M[2,0] := 0; M[2,1] :=-s; M[2,2] := c; M[2,3] := 0;
    M[3,0] := 0; M[3,1] := 0; M[3,2] := 0; M[3,3] := 1;
  end;
end;

procedure YRotationMatrix4s(out Result: TMatrix4s; const Angle: Single); overload;
var s, c: Single;
begin
  s := Sin(Angle); c := Cos(Angle);
  with Result do begin
    M[0,0] :=  c; M[0,1] := 0; M[0,2] :=-s; M[0,3] := 0;
    M[1,0] :=  0; M[1,1] := 1; M[1,2] := 0; M[1,3] := 0;
    M[2,0] :=  s; M[2,1] := 0; M[2,2] := c; M[2,3] := 0;
    M[3,0] :=  0; M[3,1] := 0; M[3,2] := 0; M[3,3] := 1;
  end;
end;

procedure ZRotationMatrix4s(out Result: TMatrix4s; const Angle: Single); overload;
var s, c: Single;
begin
  SinCos(Angle, s, c);
  with Result do begin
    M[0,0] := c; M[0,1] := s; M[0,2] := 0; M[0,3] := 0;
    M[1,0] :=-s; M[1,1] := c; M[1,2] := 0; M[1,3] := 0;
    M[2,0] := 0; M[2,1] := 0; M[2,2] := 1; M[2,3] := 0;
    M[3,0] := 0; M[3,1] := 0; M[3,2] := 0; M[3,3] := 1;
  end;
end;

procedure TranslationMatrix4s(out Result: TMatrix4s; const X, Y, Z: Single); overload;
begin
  with Result do begin
    M[0,0] := 1; M[0,1] := 0; M[0,2] := 0; M[0,3] := 0;
    M[1,0] := 0; M[1,1] := 1; M[1,2] := 0; M[1,3] := 0;
    M[2,0] := 0; M[2,1] := 0; M[2,2] := 1; M[2,3] := 0;
    M[3,0] := X; M[3,1] := Y; M[3,2] := Z; M[3,3] := 1;
  end;
end;

procedure Transform4Vector33s(out Result: TVector3s; const M: TMatrix4s; const V: TVector3s); overload;
begin
  Result.X := M.M[0, 0] * V.X + M.M[1, 0] * V.Y + M.M[2, 0] * V.Z + M.M[3, 0];
  Result.Y := M.M[0, 1] * V.X + M.M[1, 1] * V.Y + M.M[2, 1] * V.Z + M.M[3, 1];
  Result.Z := M.M[0, 2] * V.X + M.M[1, 2] * V.Y + M.M[2, 2] * V.Z + M.M[3, 2];
end;

procedure Transform4Vector3s(out Result: TVector4s; const M: TMatrix4s; const V: TVector3s); overload;
begin
  Result.X := M.M[0, 0] * V.X + M.M[1, 0] * V.Y + M.M[2, 0] * V.Z + M.M[3, 0];
  Result.Y := M.M[0, 1] * V.X + M.M[1, 1] * V.Y + M.M[2, 1] * V.Z + M.M[3, 1];
  Result.Z := M.M[0, 2] * V.X + M.M[1, 2] * V.Y + M.M[2, 2] * V.Z + M.M[3, 2];
  Result.W := M.M[0, 3] * V.X + M.M[1, 3] * V.Y + M.M[2, 3] * V.Z + M.M[3, 3];
end;

procedure Transform4Vector4s(out Result: TVector4s; const M: TMatrix4s; const V: TVector4s); overload;
begin
  Result.X := M.M[0, 0] * V.X + M.M[1, 0] * V.Y + M.M[2, 0] * V.Z + M.M[3, 0] * V.W;
  Result.Y := M.M[0, 1] * V.X + M.M[1, 1] * V.Y + M.M[2, 1] * V.Z + M.M[3, 1] * V.W;
  Result.Z := M.M[0, 2] * V.X + M.M[1, 2] * V.Y + M.M[2, 2] * V.Z + M.M[3, 2] * V.W;
  Result.W := M.M[0, 3] * V.X + M.M[1, 3] * V.Y + M.M[2, 3] * V.Z + M.M[3, 3] * V.W;
end;

procedure TransposeMatrix4s(var M: TMatrix4s);
var i, j: Integer; t: Single;
begin
  for i := 0 to 2 do for j := i + 1 to 3 do begin
    t         := M.M[i, j];
    M.M[i, j] := M.M[j, i];
    M.M[j, i] := t;
  end;
end;

function ExpandVector3s(const V: Tvector3s): TVector4s; overload;
begin
  Result.X := V.X; Result.Y := V.Y; Result.Z := V.Z; Result.W := 1;
end;

function CutMatrix3s(const M: TMatrix4s): TMatrix3s; overload;
var i, j: Integer;
begin
  for i := 0 to 2 do for j := 0 to 2 do Result.M[i, j] := M.M[i, j];
end;

function ExpandMatrix3s(const M: TMatrix3s): TMatrix4s; overload;
var i, j: Integer;
begin
  for i := 0 to 2 do for j := 0 to 2 do Result.M[i, j] := M.M[i, j];
  for i := 0 to 2 do begin Result.M[i, 3] := 0; Result.M[3, i] := 0; end;
  Result.M[3, 3] := 1; 
end;

function MulMatrix3s(const M1, M2: TMatrix3s): TMatrix3s; overload;
var i, j : Integer;
begin
  for j := 0 to 2 do for i := 0 to 2 do
   Result.M[j, i] := (M1.M[j, 0] * M2.M[0, i]) +
                     (M1.M[j, 1] * M2.M[1, i]) +
                     (M1.M[j, 2] * M2.M[2, i]);
end;

function TranspMulMatrix3s(const M1, M2: TMatrix3s): TMatrix3s; overload;
var i, j : Integer;
begin
  for j := 0 to 2 do for i := 0 to 2 do
   Result.M[j, i] := (M1.M[j, 0] * M2.M[i, 0]) +
                     (M1.M[j, 1] * M2.M[i, 1]) +
                     (M1.M[j, 2] * M2.M[i, 2]);

{  for i := 0 to 2 do for j := 0 to 2 do
   Result.M[i, j] := (M1.M[0,j] * M2.M[0, i]) +
                     (M1.M[1,j] * M2.M[1, i]) +
                     (M1.M[2,j] * M2.M[2, i]);}
end;

function GetTransposedMatrix3s(const M: TMatrix3s): TMatrix3s; overload;
var i, j : Integer;
begin
  for j := 0 to 2 do for i := 0 to 2 do Result.M[j, i] := M.M[i, j];
end;

function XRotationMatrix3s(const Angle: Single): TMatrix3s; overload;
var s, c : Single;
begin
  s := Sin(Angle); c := Cos(Angle);
  with Result do begin
    M[0,0] := 1; M[0,1] :=  0; M[0,2] := 0;
    M[1,0] := 0; M[1,1] :=  c; M[1,2] := s;
    M[2,0] := 0; M[2,1] := -s; M[2,2] := c;
  end;
end;

function YRotationMatrix3s(const Angle: Single): TMatrix3s; overload;
var s, c: Single;
begin
  s := Sin(Angle); c := Cos(Angle);
  with Result do begin
    M[0,0] := c; M[0,1] := 0; M[0,2] := -s;
    M[1,0] := 0; M[1,1] := 1; M[1,2] :=  0;
    M[2,0] := s; M[2,1] := 0; M[2,2] :=  c;
  end;
end;

function ZRotationMatrix3s(const Angle: Single): TMatrix3s; overload;
var s, c: Single;
begin
  s := Sin(Angle); c := Cos(Angle);
  with Result do begin
    M[0,0] :=  c; M[0,1] := s; M[0,2] := 0;
    M[1,0] := -s; M[1,1] := c; M[1,2] := 0;
    M[2,0] :=  0; M[2,1] := 0; M[2,2] := 1;
  end;
end;

function Transform3Vector3s(const M: TMatrix3s; const V: TVector3s): TVector3s; overload;
begin
  Result.X := M.M[0, 0] * V.X + M.M[1, 0] * V.Y + M.M[2, 0] * V.Z;
  Result.Y := M.M[0, 1] * V.X + M.M[1, 1] * V.Y + M.M[2, 1] * V.Z;
  Result.Z := M.M[0, 2] * V.X + M.M[1, 2] * V.Y + M.M[2, 2] * V.Z;
end;

function Transform3Vector3sTransp(const M: TMatrix3s; const V: TVector3s): TVector3s; overload;
begin
  Result.X := M.M[0, 0] * V.X + M.M[0, 1] * V.Y + M.M[0, 2] * V.Z;
  Result.Y := M.M[1, 0] * V.X + M.M[1, 1] * V.Y + M.M[1, 2] * V.Z;
  Result.Z := M.M[2, 0] * V.X + M.M[2, 1] * V.Y + M.M[2, 2] * V.Z;
end;

procedure ExpandVector3s(out Result: TVector4s; const V: Tvector3s); overload;
begin
  Result.X := V.X; Result.Y := V.Y; Result.Z := V.Z; Result.W := 1;
end;

procedure CutMatrix3s(out Result: TMatrix3s; const M: TMatrix4s); overload;
var i, j: Integer;
begin
  for i := 0 to 2 do for j := 0 to 2 do Result.M[i, j] := M.M[i, j];
end;

procedure Matrix3sByQuat(var Result: TMatrix3s; const Quat: TQuaternion);
begin
  Result.M[0, 0]:= ( 1.0 - 2.0*Quat[1]*Quat[1] - 2.0*Quat[2]*Quat[2]);
  Result.M[0, 1]:= ( 2.0*Quat[0]*Quat[1] + 2.0*Quat[3]*Quat[2] );
  Result.M[0, 2]:= ( 2.0*Quat[0]*Quat[2] - 2.0*Quat[3]*Quat[1] );

  Result.M[1, 0]:= ( 2.0*Quat[0]*Quat[1] - 2.0*Quat[3]*Quat[2] );
  Result.M[1, 1]:= ( 1.0 - 2.0*Quat[0]*Quat[0] - 2.0*Quat[2]*Quat[2] );
  Result.M[1, 2]:= ( 2.0*Quat[1]*Quat[2] + 2.0*Quat[3]*Quat[0] );

  Result.M[2, 0]:= ( 2.0*Quat[0]*Quat[2] + 2.0*Quat[3]*Quat[1] );
  Result.M[2, 1]:= ( 2.0*Quat[1]*Quat[2] - 2.0*Quat[3]*Quat[0] );
  Result.M[2, 2]:= ( 1.0 - 2.0*Quat[0]*Quat[0] - 2.0*Quat[1]*Quat[1] );
end;

function Matrix3sByQuat(const Quat: TQuaternion): TMatrix3s;
begin
  Matrix3sByQuat(Result, Quat);
end;

procedure MulMatrix3s(out Result: TMatrix3s; const M1, M2: TMatrix3s); overload;
var i, j : Integer;
begin
  for j := 0 to 2 do for i := 0 to 2 do
   Result.M[j, i] := (M1.M[j, 0] * M2.M[0, i]) +
                     (M1.M[j, 1] * M2.M[1, i]) +
                     (M1.M[j, 2] * M2.M[2, i]);
end;

procedure TranspMulMatrix3s(out Result: TMatrix3s; const M1, M2: TMatrix3s); overload;
var i, j : Integer;
begin
  for j := 0 to 2 do for i := 0 to 2 do
   Result.M[j, i] := (M1.M[j, 0] * M2.M[i, 0]) +
                     (M1.M[j, 1] * M2.M[i, 1]) +
                     (M1.M[j, 2] * M2.M[i, 2]);

{  for i := 0 to 2 do for j := 0 to 2 do
   Result.M[i, j] := (M1.M[0,j] * M2.M[0, i]) +
                     (M1.M[1,j] * M2.M[1, i]) +
                     (M1.M[2,j] * M2.M[2, i]);}
end;

procedure GetTransposedMatrix3s(out Result: TMatrix3s; const M: TMatrix3s); overload;
var i, j : Integer;
begin
  for j := 0 to 2 do for i := 0 to 2 do Result.M[j, i] := M.M[i, j];
end;

procedure XRotationMatrix3s(out Result: TMatrix3s; const Angle: Single); overload;
var s, c : Single;
begin
  s := Sin(Angle); c := Cos(Angle);
  with Result do begin
    M[0,0] := 1; M[0,1] :=  0; M[0,2] := 0;
    M[1,0] := 0; M[1,1] :=  c; M[1,2] := s;
    M[2,0] := 0; M[2,1] := -s; M[2,2] := c;
  end;
end;

procedure YRotationMatrix3s(out Result: TMatrix3s; const Angle: Single); overload;
var s, c: Single;
begin
  s := Sin(Angle); c := Cos(Angle);
  with Result do begin
    M[0,0] := c; M[0,1] := 0; M[0,2] := -s;
    M[1,0] := 0; M[1,1] := 1; M[1,2] :=  0;
    M[2,0] := s; M[2,1] := 0; M[2,2] :=  c;
  end;
end;

procedure ZRotationMatrix3s(out Result: TMatrix3s; const Angle: Single); overload;
var s, c: Single;
begin
  s := Sin(Angle); c := Cos(Angle);
  with Result do begin
    M[0,0] :=  c; M[0,1] := s; M[0,2] := 0;
    M[1,0] := -s; M[1,1] := c; M[1,2] := 0;
    M[2,0] :=  0; M[2,1] := 0; M[2,2] := 1;
  end;
end;

procedure Transform3Vector3s(out Result: TVector3s; const M: TMatrix3s; const V: TVector3s); overload;
begin
  Result.X := M.M[0, 0] * V.X + M.M[1, 0] * V.Y + M.M[2, 0] * V.Z;
  Result.Y := M.M[0, 1] * V.X + M.M[1, 1] * V.Y + M.M[2, 1] * V.Z;
  Result.Z := M.M[0, 2] * V.X + M.M[1, 2] * V.Y + M.M[2, 2] * V.Z;
end;

procedure TransposeMatrix3s(var M: TMatrix3s);
var t: Single;
begin
  t := M.M[0, 1]; M.M[0, 1] := M.M[1, 0]; M.M[1, 0] := t;
  t := M.M[0, 2]; M.M[0, 2] := M.M[2, 0]; M.M[2, 0] := t;
  t := M.M[1, 2]; M.M[1, 2] := M.M[2, 1]; M.M[2, 1] := t;
end;

function IsPointsSameSide(const Origin, Dir, P1, P2: TVector3s): Boolean;
var a, b: TVector3s;
begin
  CrossProductVector3s(a, Dir, SubVector3s(P1, Origin));
  CrossProductVector3s(b, Dir, SubVector3s(P2, Origin));
  Result := DotProductVector3s(a, b) >= 0;
end;

procedure ExpandBBox(var BoundingBox: TBoundingBox; const X, Y, Z: Single);
begin
  BoundingBox.P1.X := MinS(BoundingBox.P1.X, X);
  BoundingBox.P1.Y := MinS(BoundingBox.P1.Y, Y);
  BoundingBox.P1.Z := MinS(BoundingBox.P1.Z, Z);
  BoundingBox.P2.X := MaxS(BoundingBox.P2.X, X);
  BoundingBox.P2.Y := MaxS(BoundingBox.P2.Y, Y);
  BoundingBox.P2.Z := MaxS(BoundingBox.P2.Z, Z);
end;

procedure ExpandBBox(var BoundingBox: TBoundingBox; const Point: TVector3s);
begin
  ExpandBBox(BoundingBox, Point.X, Point.Y, Point.Z);
end;

//----------------------------------------------------------------------------------

{function SphereOOBBColDet(M1, M2: TMatrix3s; P1, P2: TVector3s; const Sphere, OOBB: TBoundingVolume): Boolean;
var d, a: Single; i: Integer; SPos: TVector3s; Temp: TMatrix3s;
begin
  Temp := TransposeMatrix3s(M1);
  Temp._11 := 1; Temp._22 := 1; Temp._33 := 1;
  P1 := AddVector3s(P1, Transform3Vector3s(M1, Sphere.Offset));         // Position of sphere in world system
  P2 := AddVector3s(P2, Transform3Vector3s(M2, OOBB.Offset));         // Position of box 2 in world system
  SPos := Transform3Vector3s(Temp, SubVector3s(P1, P2));
  d := 0;
  for i := 0 to 2 do begin
    if (SPos.v[i] < -OOBB.Dimensions.v[i]*M2.M[i, i]) then begin
      a := SPos.v[i] + OOBB.Dimensions.v[i]*M2.M[i, i];
      d := d + a * a;
    end else if (SPos.v[i] > OOBB.Dimensions.v[i]*M2.M[i, i]) then begin
      a := SPos.v[i] - OOBB.Dimensions.v[i]*M2.M[i, i];
      d := d + a * a;
    end;
  end;
  Result := d <= Sphere.Dimensions.X * Sphere.Dimensions.X;
end;}

{function LineIntersect(A, ADir, B, BDir: TVector3s; out IPoint: TVector3s): Boolean;
begin
  IPoint.X := (B.X * ADir.X + A.X * BDir.X)/(BDir.X - ADir.X);
  IPoint.Y := (B.Y * ADir.Y + A.Y * BDir.Y)/(BDir.Y - ADir.Y);
  IPoint.Z := (B.Z * ADir.Z + A.Z * BDir.Z)/(BDir.Z - ADir.Z);
(*  bool intersection(Point2f start1, Point2f end1, Point2f start2, Point2f end2, Point2f *out_intersection)
    {
        Point2f dir1 = end1 - start1;
        Point2f dir2 = end2 - start2;

        //считаем уравнени€ пр€мых проход€щих через отрезки
        float a1 = -dir1.y;
        float b1 = +dir1.x;
        float d1 = -(a1*start1.x + b1*start1.y);

        float a2 = -dir2.y;
        float b2 = +dir2.x;
        float d2 = -(a2*start2.x + b2*start2.y);

        //подставл€ем концы отрезков, дл€ вы€снени€ в каких полуплоскот€х они
        float seg1_line2_start = a2*start1.x + b2*start1.y + d2;
        float seg1_line2_end = a2*end1.x + b2*end1.y + d2;

        float seg2_line1_start = a1*start2.x + b1*start2.y + d1;
        float seg2_line1_end = a1*end2.x + b1*end2.y + d1;

        //если концы одного отрезка имеют один знак, значит он в одной полуплоскости и пересечени€ нет.
        if (seg1_line2_start * seg1_line2_end >= 0 || seg2_line1_start * seg2_line1_end >= 0)
            return false;

        float u = seg1_line2_start / (seg1_line2_start - seg1_line2_end);
        *out_intersection =  start1 + u*dir1;

        return true;
    *)
end;}

function RaySphereColDet(RayOrigin, RayDir, SphereOrigin: TVector3s; SphereRadius: Single; var Point: TVector3s): Boolean;
var B, C, D, t1, t2: Single;
begin
  Result := False;
  Point := SubVector3s(AddVector3s(RayOrigin, RayDir), SphereOrigin);
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

function RayCircleColDet(RayOrigin, RayDir, SphereOrigin: TVector3s; SphereRadius: Single; var Point: TVector3s): Boolean;
var B, C, D, t1, t2: Single;
begin
  Result := False;

  RayDir.Y := 0; RayOrigin.Y := 0; SphereOrigin.Y := 0;

  Point := SubVector3s(AddVector3s(RayOrigin, RayDir), SphereOrigin);
  
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

(*function SphereOOBBColDet(M1, M2: TMatrix3s; P1, P2: TVector3s; const Sphere, OOBB: TBoundingVolume; CoordStep: Integer): Boolean;
var d, a: Single; i: Integer; SPos: TVector3s; Temp: TMatrix3s;
begin
  Temp := TransposeMatrix3s(M2);
//  Temp._11 := 1; Temp._22 := 1; Temp._33 := 1;
  P1 := AddVector3s(P1, Transform3Vector3s(M1, Sphere.Offset));         // Position of sphere in world system
  P2 := AddVector3s(P2, Transform3Vector3s(M2, OOBB.Offset));         // Position of box 2 in world system
  SPos := Transform3Vector3s(Temp, SubVector3s(P2, P1));
  d := 0; i := 0;
  while i <= 2 do begin
    if (SPos.v[i] < -OOBB.Dimensions.v[i]{*M2.M[i, i]}) then begin
      a := SPos.v[i] + OOBB.Dimensions.v[i]{*M2.M[i, i]};
      d := d + a * a;
    end else if (SPos.v[i] > OOBB.Dimensions.v[i]{*M2.M[i, i]}) then begin
      a := SPos.v[i] - OOBB.Dimensions.v[i]{*M2.M[i, i]};
      d := d + a * a;
    end;
    Inc(i, CoordStep);
  end;
  Result := d <= Sphere.Dimensions.X * Sphere.Dimensions.X;
end;

function OOBBOOBBColDet(M1, M2: TMatrix3s; P1, P2: TVector3s; const OOBB1, OOBB2: TBoundingVolume): Boolean;    // ToFix: Add scale support
var R: TMatrix3s; v, T: TVector3s; temp, ra, rb: Single; i: Integer;
begin
  Result := False;
  P1 := AddVector3s(P1, Transform3Vector3s(M1, OOBB1.Offset));         // Position of box 1 in world system
  P2 := AddVector3s(P2, Transform3Vector3s(M2, OOBB2.Offset));         // Position of box 2 in world system
  v := SubVector3s(P2, P1);
  T := Transform3Vector3s(TransposeMatrix3s(M1), v);
  R := TranspMulMatrix3s(M1, M2);
//  v := SubVector3s(OOBB2.Offset, OOBB1.Offset);
//  T := Transform3Vector3s(TransposeMatrix3s(OOBB1.Matrix), v);
//  R := TranspMulMatrix3s(OOBB1.Matrix, OOBB2.Matrix);
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

function OOBBOOBBColDet2D(M1, M2: TMatrix3s; P1, P2: TVector3s; const OOBB1, OOBB2: TBoundingVolume): Boolean;    // ToFix: Add scale support
var R: TMatrix3s; v, T: TVector3s; temp, ra, rb: Single; i: Integer;
begin
  Result := False;
  P1 := AddVector3s(P1, Transform3Vector3s(M1, OOBB1.Offset));         // Position of box 1 in world system
  P2 := AddVector3s(P2, Transform3Vector3s(M2, OOBB2.Offset));         // Position of box 2 in world system
  v := SubVector3s(P2, P1);
  T := Transform3Vector3s(TransposeMatrix3s(M1), v);
  R := TranspMulMatrix3s(M1, M2);
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

function VolumeColDet(const Volume1, Volume2: TBoundingVolumes): TCollisionResult;     // ToFix: Take location in account
begin
  with Result do begin
    Vol1 := Volume1.First;
    while Vol1 <> nil do begin
      Vol2 := Volume2.First;
      case Vol1^.VolumeKind of
        vkSphere: while Vol2 <> nil do begin
          case Vol2^.VolumeKind of
            vkSphere: if SqrMagnitude(SubVector3s(AddVector3s(Volume1.Location, Transform3Vector3s(Volume1.Matrix, Vol1.Offset)),
                                                  AddVector3s(Volume2.Location, Transform3Vector3s(Volume2.Matrix, Vol2.Offset)))) < Sqr(Vol1^.Dimensions.X + Vol2^.Dimensions.X) then Exit;
            vkOOBB: if SphereOOBBColDet(Volume1.Matrix, Volume2.Matrix, Volume1.Location, Volume2.Location, Vol1^, Vol2^, 1) then Exit;
          end;
          Vol2 := Vol2^.Next;
        end;
        vkOOBB: while Vol2 <> nil do begin
          case Vol2^.VolumeKind of
            vkSphere: if SphereOOBBColDet(Volume2.Matrix, Volume1.Matrix, Volume2.Location, Volume1.Location, Vol2^, Vol1^, 1) then Exit;
            vkOOBB: if OOBBOOBBColDet(Volume1.Matrix, Volume2.Matrix, Volume1.Location, Volume2.Location, Vol1^, Vol2^) then Exit;
          end;
          Vol2 := Vol2^.Next;
        end;
      end;
      Vol1 := Vol1^.Next;
    end;
    Vol1 := nil; Vol2 := nil;
  end;
end;

function VolumeColDet2D(const Volume1, Volume2: TBoundingVolumes): TCollisionResult;     // ToFix: Take location in account
var tv: TVector3s;
begin
  with Result do begin
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
  end;
end;

function VolumeColTest(const Volume1, Volume2: TBoundingVolumes): Boolean;
begin
  Result := VolumeColDet(Volume1, Volume2).Vol1 <> nil;
end;

function VolumeColTest2D(const Volume1, Volume2: TBoundingVolumes): Boolean;
begin
  Result := VolumeColDet2D(Volume1, Volume2).Vol1 <> nil;
end;

function NewBoundingVolume(AVolumeKind: Cardinal; AOffset, ADimensions: TVector3s; ANext: PBoundingVolume = nil): PBoundingVolume;
begin
  GetMem(Result, SizeOf(TBoundingVolume));
  Result.VolumeKind := AVolumeKind;
  Result.Offset := AOffset;
  Result.Dimensions := ADimensions;
  Result.Next := ANext;
end;

procedure DisposeBoundingVolumes(var Volumes: TBoundingVolumes);
var CurVolume, TempVolume: PBoundingVolume;
begin
  CurVolume := Volumes.First;
  while CurVolume <> nil do begin
    TempVolume := CurVolume;
    CurVolume := CurVolume.Next;
    FreeMem(TempVolume);
  end;
  Volumes.First := nil;
  Volumes.Last := nil;
end; *)

function ArcTan2(const Y, X: Extended): Extended; assembler;
asm
  FLD     Y
  FLD     X
  FPATAN
  FWAIT
end;

var i: Integer;

begin
  for i := 0 to SinTableSize+CosTabOffs do SinTable[i] := Sin(2.0*pi*i/SinTableSize);
end.

bool PointProjectionInsideTriangle(const Vector3 &p1, const Vector3 &p2, const Vector3 &p3, const Vector3 &point)
{
  Vector3 n = (p2 - p1) ^ (p3 - p1);

  Vector3 n1 = (p2 - p1) ^ n;
  Vector3 n2 = (p3 - p2) ^ n;
  Vector3 n3 = (p1 - p3) ^ n;

  double proj1 = (point - p2) * n1;
  double proj2 = (point - p3) * n2;
  double proj3 = (point - p1) * n3;

  if(proj1 > 0.0f)
    return 0;
  if(proj2 > 0.0f)
    return 0;
  if(proj3 > 0.0f)
    return 0;
  return 1;
}
