unit Draw;

interface

uses Graphics, Windows, Classes;

procedure PutPixel(X, Y : integer; Color : dword; Where : TCanvas = nil);
procedure Bar(Bounds : TRect; Color : DWord; Where : TCanvas = nil); overload;
procedure Bar(X1, Y1, X2, Y2 : Integer; Color : DWord; Where : TCanvas = nil); overload;
procedure Rectangle(Bounds : TRect; Color : dword; Where : TCanvas = nil); overload;
procedure Rectangle(X1, Y1, X2, Y2 : integer; Color : dword; Where : TCanvas = nil); overload;
procedure XorRectangle(Bounds : TRect; Color : dword; Where : TCanvas = nil); overload;
procedure XorRectangle(X1, Y1, X2, Y2 : integer; Color : dword; Where : TCanvas = nil); overload;
procedure Circle(CenX, CenY, Rad : integer; Color : dword; Where : TCanvas = nil);
procedure Ellipse(CenX, CenY, XRad, YRad : integer; Color : dword; Where : TCanvas = nil);
procedure FillEllipse(CenX, CenY, XRad, YRad : integer; Color : dword; Where : TCanvas = nil);
procedure FillCircle(CenX, CenY, Rad : integer; Color : dword; Where : TCanvas = nil);
procedure Line(X1, Y1, X2, Y2 : integer; Color : dword; Where : TCanvas = nil);
procedure OutTextXY(X, Y: Integer; Color : dword; const Text: string; Where : TCanvas = nil);

var DefaultCanvas : Pointer;

implementation

procedure PutPixel(X, Y : integer; Color : dword; Where : TCanvas = nil);
begin
 if Where=nil then begin if DefaultCanvas=nil then exit; Where:=DefaultCanvas; end;
 Where.Pixels[x,y] := Color;
end;

procedure Bar(Bounds : TRect; Color: DWord; Where : TCanvas = nil);overload;
begin
  Bar(Bounds.Left, Bounds.Top, Bounds.Right, Bounds.Bottom, Color, Where);
end;

procedure Bar(X1, Y1, X2, Y2 : Integer; Color : DWord; Where : TCanvas = nil); overload;
begin
 if Where = nil then begin if DefaultCanvas = nil then Exit; Where := DefaultCanvas; end;
 Where.Brush.Color := Color;
 Where.Pen.Color := Color;
 Where.FillRect(Rect(X1,Y1,X2,Y2));
end;

procedure Rectangle(Bounds : TRect; Color : dword; Where : TCanvas = nil);overload;
begin
 if Where=nil then begin if DefaultCanvas=nil then exit; Where:=DefaultCanvas; end;
 Where.Pen.Color := Color;
 Where.Brush.Color := Color;
 Where.FrameRect(Bounds);
end;

procedure Rectangle(X1, Y1, X2, Y2 : integer; Color : dword; Where : TCanvas = nil); overload;
begin
 if Where=nil then begin if DefaultCanvas=nil then exit; Where:=DefaultCanvas; end;
 Where.Pen.Color := Color;
 Where.Brush.Color := Color;
 Where.FrameRect(Rect(X1,Y1,X2,Y2));
end;

procedure XorRectangle(Bounds : TRect; Color : dword; Where : TCanvas = nil);overload;
begin
 if Where=nil then begin if DefaultCanvas=nil then exit; Where:=DefaultCanvas; end;
 Where.Pen.Mode := pmXor;
 Where.Pen.Color := Color;
 Where.Brush.Style := bsClear;
// with Bounds do Where.Polyline([Point(Left, Top), Point(Right, Top), Point(Right, Bottom), Point(Left, Bottom)]);
 Where.Rectangle(Bounds);
 Where.Brush.Style := bsSolid;
 Where.Pen.Mode := pmCopy;
end;

procedure XorRectangle(X1, Y1, X2, Y2 : integer; Color : dword; Where : TCanvas = nil); overload;
begin
 if Where=nil then begin if DefaultCanvas=nil then exit; Where:=DefaultCanvas; end;
 Where.Pen.Mode := pmXor;
 Where.Pen.Color := Color;
 Where.Brush.Style := bsClear;
 Where.Rectangle(X1, Y1, X2, Y2);
// Where.Polyline([Point(X1, Y1), Point(X2, Y1), Point(X2, Y2), Point(X1, Y2)]);
 Where.Brush.Style := bsSolid;
 Where.Pen.Mode := pmCopy;
end;

procedure Ellipse;
begin
 if Where=nil then begin if DefaultCanvas=nil then exit;Where:=DefaultCanvas;end;
 Where.Brush.Style:=bsClear;
 Where.Pen.Color:=color;
 Where.Ellipse(CenX-XRad, CenY-YRad, CenX+XRad, CenY+YRad);
end;

procedure Circle;
begin
 if Where=nil then begin if DefaultCanvas=nil then exit;Where:=DefaultCanvas;end;
 Where.Brush.Style:=bsClear;
 Where.Pen.Color:=color;
 Where.Ellipse(CenX-Rad, CenY-Rad, CenX+Rad, CenY+Rad);
end;

procedure FillEllipse;
begin
 if Where=nil then begin if DefaultCanvas=nil then exit;Where:=DefaultCanvas;end;
 Where.Brush.Style:=bsSolid;
 Where.Brush.Color:=color;
 Where.Pen.Color:=color;
 Where.Ellipse(CenX-XRad, CenY-YRad, CenX+XRad, CenY+YRad);
end;

procedure FillCircle;
begin
 if Where=nil then begin if DefaultCanvas=nil then exit;Where:=DefaultCanvas;end;
 Where.Brush.Style := bsSolid;
 Where.Brush.Color := Color;
 Where.Pen.Color := Color;
 Where.Ellipse(CenX-Rad, CenY-Rad, CenX+Rad, CenY+Rad);
end;

procedure Line;
begin
 if Where=nil then begin if DefaultCanvas=nil then exit;Where:=DefaultCanvas;end;
 Where.Pen.Color:=color;
 Where.MoveTo(X1, Y1);
 Where.LineTo(X2, Y2);
end;

procedure OutTextXY(X, Y: Integer; Color : dword; const Text: string; Where : TCanvas = nil );
begin
  if Where = nil then begin if DefaultCanvas = nil then Exit; Where := DefaultCanvas; end;
  Where.Brush.Style := bsClear;
  Where.Font.Color := Color;
//  Where.Brush.Color := Color;
  Where.TextOut(X, Y, Text);
end;

end.
