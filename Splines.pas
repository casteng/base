unit Splines;

interface

type
  TPoints2D = array[0..MaxInt div SizeOf(Single) div 2-1] of record X, Y : Single end;
  PPoints2D = ^TPoints2D;
  TSingleBuffer = array[0..MaxInt div SizeOf(Single)-1] of Single;
  PSingleBuffer = ^TSingleBuffer;
  procedure Spline1D(PointsCount, Resolution: Word; CtrlPt, Curve: PSingleBuffer; CurveStride: Integer = 1);
  procedure Spline2D(PointsCount, Resolution: Word; CtrlPt, Curve: PPoints2D);
  procedure SplineND(PointsCount, Resolution, N: Word; ControlPoints, FinalCurve: Pointer; ControlStride, CurveStride: Integer);

implementation

procedure Spline1D(PointsCount, Resolution: Word; CtrlPt, Curve: PSingleBuffer; CurveStride: Integer = 1);
var
  i, j: Integer;
  Ap, Bp, Cp, Dp: Single;
  OverR, T: Single;
  CI: LongWord;
begin
  CI := 0;
  OverR:=1 / Resolution;
  CtrlPt^[0] := CtrlPt^[1];
  CtrlPt^[PointsCount] := CtrlPt^[PointsCount-1];
  for i := 1 to PointsCount-1 do begin
//Coeffs
    Ap :=  -CtrlPt^[i-1] + 3*CtrlPt^[i] - 3*CtrlPt^[i+1] + CtrlPt^[i+2];
    Bp := 2*CtrlPt^[i-1] - 5*CtrlPt^[i] + 4*CtrlPt^[i+1] - CtrlPt^[i+2];
    Cp :=  -CtrlPt^[i-1] + CtrlPt^[i+1];
    Dp := 2*CtrlPt^[i];
//Calc
    Curve[CI] := CtrlPt^[i];
    Inc(CI, CurveStride);
    T := OverR;
    for j := 1 to Resolution-1 do begin
      Curve[CI] := ((Ap*T*T*T) + (Bp*T*T) + (Cp*T) + Dp)*0.5;  { Calc x value }
      T := T + OverR;
      Inc(CI, CurveStride);
    end;
  end;
//  Curve[CI] := CtrlPt^[PointsCount];
end;

procedure Spline2D(PointsCount, Resolution: Word; CtrlPt, Curve: PPoints2D);
var
 I, J: Integer;
 Ap, Bp, Cp, Dp: record X, Y: Single end;
 OverR, T, T2, T3: Single;
 CI: Word;
begin
   CI := 0;
   CtrlPt[0] := CtrlPt[1];
   CtrlPt[PointsCount+1] := CtrlPt[PointsCount];
   OverR:=1 / Resolution;
   for i := 1 to PointsCount-1 do begin
//Coeffs
     Ap.X :=  -CtrlPt[I-1].X + 3*CtrlPt[I].X - 3*CtrlPt[I+1].X + CtrlPt[I+2].X;
     Bp.X := 2*CtrlPt[I-1].X - 5*CtrlPt[I].X + 4*CtrlPt[I+1].X - CtrlPt[I+2].X;
     Cp.X :=  -CtrlPt[I-1].X + CtrlPt[I+1].X;
     Dp.X := 2*CtrlPt[I].X;
     Ap.Y :=  -CtrlPt[I-1].Y + 3*CtrlPt[I].Y - 3*CtrlPt[I+1].Y + CtrlPt[I+2].Y;
     Bp.Y := 2*CtrlPt[I-1].Y - 5*CtrlPt[I].Y + 4*CtrlPt[I+1].Y - CtrlPt[I+2].Y;
     Cp.Y :=  -CtrlPt[I-1].Y + CtrlPt[I+1].Y;
     Dp.Y := 2*CtrlPt[I].Y;
//Calc
     T2 := 0;                                   { Square of t }
     T3 := 0;                                      { Cube of t }
     Curve[CI].X := ((Ap.X*T3) + (Bp.X*T2) + (Cp.X*0) + Dp.X)/2;  { Calc x value }
     Curve[CI].Y := ((Ap.Y*T3) + (Bp.Y*T2) + (Cp.Y*0) + Dp.Y)/2;  { Calc y value }
     inc(CI);
     T:=OverR;
     for j := 1 to Resolution-1 do begin
       T2:=T*T; T3:=T2*T;
       Curve[CI].X := ((Ap.X*T3) + (Bp.X*T2) + (Cp.X*T) + Dp.X)/2;  { Calc x value }
       Curve[CI].Y := ((Ap.Y*T3) + (Bp.Y*T2) + (Cp.Y*T) + Dp.Y)/2;  { Calc y value }
       T:=T+OverR;
       Inc(CI);
     end;
   end;
   Curve[CI] := CtrlPt[PointsCount];
end;

procedure SplineND(PointsCount, Resolution, N: Word; ControlPoints, FinalCurve: Pointer; ControlStride, CurveStride: Integer);
var
 I, J, k: Integer;
 Ap, Bp, Cp, Dp: array of Single;
 OverR, T, T2, T3: Single;
 CI: Word;
 CtrlPt, Curve: PSingleBuffer;
begin
   CtrlPt := ControlPoints; Curve := FinalCurve;
   CI := 0;
   for j := 0 to N-1 do begin
     CtrlPt[0+j] := CtrlPt[1*ControlStride+j];
     CtrlPt[(PointsCount+1)*ControlStride+j] := CtrlPt[PointsCount*ControlStride+j];
   end;
   OverR:=1 / Resolution;
   SetLength(Ap, N); SetLength(Bp, N); SetLength(Cp, N); SetLength(Dp, N);

   for i := 1 to PointsCount-1 do begin
//Coeffs
     for j := 0 to N-1 do begin
       Ap[j] :=  -CtrlPt[(I-1)*ControlStride+j] + 3*CtrlPt[I*ControlStride+j] - 3*CtrlPt[(I+1)*ControlStride+j] + CtrlPt[(I+2)*ControlStride+j];
       Bp[j]:= 2*CtrlPt[(I-1)*ControlStride+j] - 5*CtrlPt[I*ControlStride+j] + 4*CtrlPt[(I+1)*ControlStride+j] - CtrlPt[(I+2)*ControlStride+j];
       Cp[j] :=  -CtrlPt[(I-1)*ControlStride+j] + CtrlPt[(I+1)*ControlStride+j];
       Dp[j] := 2*CtrlPt[I*ControlStride+j];
       Curve[CI*CurveStride+j] := Dp[j]/2;  { Calc x value }
     end;
//Calc
     Inc(CI);
     T := OverR;
     for k := 1 to Resolution-1 do begin
       T2:=T*T; T3:=T2*T;
       for j := 0 to N-1 do Curve[CI*CurveStride+j] := ((Ap[j]*T3) + (Bp[j]*T2) + (Cp[j]*T) + Dp[j])/2;  { Calc x value }
       T:=T+OverR;
       Inc(CI);
     end;
   end;
   for j := 0 to N-1 do Curve[CI*CurveStride+j] := CtrlPt[PointsCount*ControlStride+j];
end;

end.
