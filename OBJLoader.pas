//------------------------------------------------------------------------
//
// Author      : Jan Horn
// Email       : jhorn@global.co.za
// Website     : http://home.global.co.za/~jhorn
// Date        : 13 May 2001
// Version     : 1.0
// Description : Wavefront OPJ loader
//
//------------------------------------------------------------------------
unit OBJLoader;

interface

Uses OpenGL, Windows, SysUtils;

type TColor = Record           // Stores a RGB (0-1) Color
       R, G, B : glFLoat;
     end;
     TCoord = Record           // Stores X, Y, Z coordinates
       X, Y, Z : glFLoat;
     end;
     TTexCoord = Record        // Stores texture coordinates
       U, V : glFloat;
     end;

     TMaterial = Record        // Material Structure
       Name : String;
       Ambient   : TColor;
       Diffuse   : TColor;
       Specular  : TColor;
       Shininess : glFloat;
       Texture   : glUint;     
     end;

     TFace = Record
       Count : Integer;            // Number of vertices in faces
       vIndex : Array of Integer;  // indexes to vertices
       tIndex : Array of Integer;  // indexes to vertex textures
       nIndex : Array of Integer;  // indexes to vertex normals
     end;

     TGroup = Record
       Name : String;
       Faces : Integer;            // Number of faces
       Face  : Array of TFace;     // The faces in the group
       mIndex : Integer;           // index to Material
     end;

     TModel = Record
       Name : String;
       MaterialFile : String;
       Vertices  : Integer;
       Normals   : Integer;
       TexCoords : Integer;
       Groups    : Integer;
       Materials : Integer;
       Vertex    : Array of TCoord;
       Normal    : Array of TCoord;
       TexCoord  : Array of TTexCoord;
       Group     : Array of TGroup;
       Material  : Array of TMaterial;
     end;

  function LoadModel(filename : String) : TModel;
  procedure DrawModel(M : TModel);
  
implementation


{-------------------------------------------------------------------------------}
{  Find the position of a substring in a string starting at a certain position  }
{-------------------------------------------------------------------------------}
Function PosEx(const substr : AnsiString; const s : AnsiString; const start: Integer ) : Integer ;
Type StrRec = record
       allocSiz: Longint;
       refCnt: Longint;
       length: Longint;
     end;
Const  skew = sizeof(StrRec);
asm
{     ->EAX     Pointer to substr               }
{       EDX     Pointer to string               }
{       ECX     Pointer to start      //cs      }
{     <-EAX     Position of substr in s or 0    }

        TEST    EAX,EAX
        JE      @@noWork
        TEST    EDX,EDX
        JE      @@stringEmpty
        TEST    ECX,ECX           //cs
        JE      @@stringEmpty     //cs

        PUSH    EBX
        PUSH    ESI
        PUSH    EDI

        MOV     ESI,EAX                         { Point ESI to  }
        MOV     EDI,EDX                         { Point EDI to  }

        MOV     EBX,ECX        //cs save start
        MOV     ECX,[EDI-skew].StrRec.length    { ECX =    }
        PUSH    EDI                             { remember s position to calculate index }

        CMP     EBX,ECX        //cs
        JG      @@fail         //cs

        MOV     EDX,[ESI-skew].StrRec.length    { EDX = bstr)          }

        DEC     EDX                             { EDX = Length(substr) -   }
        JS      @@fail                          { < 0 ? return             }
        MOV     AL,[ESI]                        { AL = first char of       }
        INC     ESI                             { Point ESI to 2'nd char of substr }
        SUB     ECX,EDX                         { #positions in s to look  }
                                                { = Length(s) - Length(substr) + 1      }
        JLE     @@fail
        DEC     EBX       //cs
        SUB     ECX,EBX   //cs
        JLE     @@fail    //cs
        ADD     EDI,EBX   //cs

@@loop:
        REPNE   SCASB
        JNE     @@fail
        MOV     EBX,ECX                         { save outer loop                }
        PUSH    ESI                             { save outer loop substr pointer }
        PUSH    EDI                             { save outer loop s              }

        MOV     ECX,EDX
        REPE    CMPSB
        POP     EDI                             { restore outer loop s pointer      }
        POP     ESI                             { restore outer loop substr pointer }
        JE      @@found
        MOV     ECX,EBX                         { restore outer loop nter    }
        JMP     @@loop

@@fail:
        POP     EDX                             { get rid of saved s nter    }
        XOR     EAX,EAX
        JMP     @@exit

@@stringEmpty:
        XOR     EAX,EAX
        JMP     @@noWork

@@found:
        POP     EDX                             { restore pointer to first char of s    }
        MOV     EAX,EDI                         { EDI points of char after match        }
        SUB     EAX,EDX                         { the difference is the correct index   }
@@exit:
        POP     EDI
        POP     ESI
        POP     EBX
@@noWork:
end;


{------------------------------------------------------------------}
{  Initialises a model                                             }
{------------------------------------------------------------------}
procedure InitModel(var M : TModel);
begin
  with M do
  begin
    Name :='';
    MaterialFile :='';
    Vertices  :=0;
    Normals   :=0;
    TexCoords :=0;
    Groups    :=0;
    Materials :=0;
    SetLength(Vertex, 0);
    SetLength(Normal, 0);
    SetLength(TexCoord, 0);
    SetLength(Group, 0);
    SetLength(Material, 0);
  end;
end;


{------------------------------------------------------------------}
{  Gets the X, Y, Z coordinates from a String                      }
{------------------------------------------------------------------}
function GetCoords(S : String) : TCoord;
var P, P2 : Integer;
    C : TCoord;
begin
  S :=Trim(Copy(S, 3, Length(S)));
  P :=Pos(' ', S);
  P2 :=PosEx(' ', S, P+1);
  S := StringReplace(S, '.', DecimalSeparator, [rfReplaceAll]);

  C.X :=StrToFloat(Copy(S, 1, P-1));
  C.Y :=StrToFloat(Copy(S, P+1, P2-P-1));
  C.Z :=StrToFloat(Copy(S, P2+1, Length(S)));
  Result :=C;
end;


{-------------------------------------------------------------------}
{  Returns the U, V texture coordinates of a texture from a String  }
{-------------------------------------------------------------------}
function GetTexCoords(S : String) : TTexCoord;
var P, P2 : Integer;
    T : TTexCoord;
begin
  P :=Pos(' ', S);
  P2 :=PosEx(' ', S, P+1);
  S := StringReplace(S, '.', DecimalSeparator, [rfReplaceAll]);

  T.U :=StrToFloat(Copy(S, P+1, P2-P-1));
  T.V :=StrToFloat(Copy(S, P2+1, Length(S)));
  Result :=T;
end;


{------------------------------------------------------------------}
{  Reads Vertex coords, Normals and Texture coords from a String   }
{------------------------------------------------------------------}
procedure ReadVertexData(S : String; var M : TModel);
var C : TCoord;
    T : TTexCoord;
begin
  case S[2] of
    ' ' : begin                      // Read the vertex coords
            C :=GetCoords(S);
            Inc(M.Vertices);
            SetLength(M.Vertex, M.Vertices+1);
            M.Vertex[M.Vertices] :=C;
          end;
    'N' : begin                      // Read the vertex normals
            C :=GetCoords(S);
            Inc(M.Normals);
            SetLength(M.Normal, M.Normals+1);
            M.Normal[M.Normals] :=C;
          end;
    'T' : begin                      // Read the vertex texture coords
            T :=GetTexCoords(S);
            Inc(M.TexCoords);
            SetLength(M.TexCoord, M.TexCoords+1);
            M.TexCoord[M.TexCoords] :=T;
          end;
  end;
end;


{------------------------------------------------------------------}
{  Reads the faces/triangles info for the model                    }
{  Data is stored as "f f f" OR "f/t f/t /ft" OR "f/t/n .. f/t/n"  }
{------------------------------------------------------------------}
procedure ReadFaceData(S : String; var M : TModel);
var P, P2, P3 : Integer;
    F : TFace;
begin
  P :=Pos(' ', S);
  S :=Trim(Copy(S, P+1, length(S)));

  Inc(M.Group[M.Groups].Faces);
  SetLength(M.Group[M.Groups].Face, M.Group[M.Groups].Faces+1);

  F.Count :=0;
  While Length(S) > 0 do
  begin
    P :=Pos('/', S);      // check for position of first /
    P3 :=Pos(' ', S);
    if P3 = 0 then      // if we reach the end
      P3 :=Length(S)+1;

    if P > 0 then              // there are normals or texture coords
    begin
      Inc(F.Count);
      SetLength(F.vIndex, F.Count);
      F.vIndex[F.Count-1] :=StrToInt(Copy(S, 1, P-1));
      P2 :=PosEx('/', S, P+1);   // check for position of second /
      if P2 > P+1 then          // there are normals AND texture coords
      begin
        SetLength(F.tIndex, F.Count);
        SetLength(F.nIndex, F.Count);
        F.tIndex[F.Count-1] :=StrToInt(Copy(S, P+1, P2-1));
        F.nIndex[F.Count-1] :=StrToInt(Copy(S, P2+1, P3-1));
      end
      else
      begin
        SetLength(F.nIndex, F.Count);
        F.nIndex[F.Count-1] :=StrToInt(Copy(S, P2+1, P3-1 - P2));
      end;
    end
    else
    begin
      Inc(F.Count);
      SetLength(F.vIndex, F.Count);
      F.vIndex[F.Count-1] :=StrToInt(Copy(S, 1, P3-1));
    end;
    S :=Copy(S, P3+1, length(S));
  end;

  M.Group[M.Groups].Face[M.Group[M.Groups].Faces] :=F;
end;


{------------------------------------------------------------------}
{  Get the name of the material for the group                      }
{------------------------------------------------------------------}
procedure GetMaterialName(S : String; var M : TModel);
var I, P : Integer;
begin
  if copy(S, 1, 6) <> 'USEMTL' then exit;  // false call

  P :=Pos(' ', S);
  S :=Copy(S, P+1, length(S));

  For I :=1 to M.Materials do
    if M.Material[I].Name = S then
      M.Group[M.Groups].mIndex :=I;
end;


{------------------------------------}
{  Create a new material             }
{------------------------------------}
procedure CreateMaterial(S : String; var M : TModel);
begin
  if Copy(S, 1, 6) <> 'NEWMTL' then exit;
  Inc(M.Materials);
  SetLength(M.Material, M.Materials+1);
  S :=Trim(Copy(S, 7, length(S)));
  FillChar(M.Material[M.Materials].Ambient, 0, Sizeof(M.Material[M.Materials].Ambient));
  FillChar(M.Material[M.Materials].Diffuse, 0, Sizeof(M.Material[M.Materials].Diffuse));
  FillChar(M.Material[M.Materials].Specular, 0, Sizeof(M.Material[M.Materials].Specular));
  M.Material[M.Materials].Shininess :=60;
  M.Material[M.Materials].Texture :=0;
  M.Material[M.Materials].Name :=S;
end;


{------------------------------------}
{  Get Material Color values         }
{------------------------------------}
procedure GetMaterial(S : String; var M : TModel);
var C : TColor;
    P, P2 : Integer;
    Ch : Char;
begin
  Ch :=S[2];
  S :=Trim(Copy(S, 3, Length(S)));
  P :=Pos(' ', S);
  P2 :=PosEx(' ', S, P+1);
  S := StringReplace(S, '.', DecimalSeparator, [rfReplaceAll]);

  C.R :=StrToFloat(Copy(S, 1, P-1));
  C.G :=StrToFloat(Copy(S, P+1, P2-P-1));
  C.B :=StrToFloat(Copy(S, P2+1, Length(S)));

  case CH of
    'A' : M.Material[M.Materials].Ambient :=C;
    'D' : M.Material[M.Materials].Diffuse :=C;
    'S' : M.Material[M.Materials].Specular :=C;
  end;
end;


{------------------------------------}
{  Get material specular highlight   }
{------------------------------------}
procedure GetShininess(S : String; var M : TModel);
begin
  S :=Trim(Copy(S, 3, Length(S)));
  S := StringReplace(S, '.', DecimalSeparator, [rfReplaceAll]);

  M.Material[m.Materials].Shininess :=StrToFloat(S);
end;


{------------------------------------}
{  Load texture for material         }
{------------------------------------}
procedure GetTexture(S : String; var M : TModel);
begin
// texturename = get the name from "map_Kd textures/fabric1.rgb"
// LoadTexture( texturename, M.Material[M.Materials].Texture);
end;


{------------------------------------------------------------------}
{  Load the materials from the material file                       }
{------------------------------------------------------------------}
procedure LoadMaterials(S : String; var M : TModel);
var P : Integer;
    filename : String;
    F : TextFile;
begin
  if copy(S, 1, 6) <> 'MTLLIB' then exit;  // false call

  P :=Pos(' ', S);
  filename :=Copy(S, P+1, length(S));
  if FileExists(filename) then
  begin
    AssignFile(F, filename);
    Reset(F);
    while not(EOF(F)) do
    begin
      Readln(F, S);
      if (S <> '') AND (S[1] <> '#') then
      begin
        S :=Uppercase(S);
        Case S[1] of
          'N' : begin
                  if S[2] = 'S' then GetShininess(S, M);  // Get specular highlight amount
                  if S[2] = 'E' then CreateMaterial(S, M);  // create new material
                end;
          'K' : GetMaterial(S, M);     // Material properties
          'M' : GetTexture(S, M);      // Map material to texture
        end;
      end;
    end;
    closeFile(F);
  end
  else
    MessageBox(0, PChar('Cannot find the material file : ' + filename), 'Load Model Material', MB_OK);
end;


{------------------------------------------------------------------}
{  Loads a Alias Wavefront .OBJ file                               }
{------------------------------------------------------------------}
function LoadModel(filename : String) : TModel;
var F : TextFile;
    M : TModel;
    S, S2 : String;
    P : Integer;
begin
  InitModel(M);

  P :=Pos('.', filename)-1;
  if P < 1 then P :=Length(filename);
  M.Name :=Copy(filename, 1, P);

  if FileExists(filename) then
  begin
    AssignFile(F, filename);
    Reset(F);

    while not(EOF(F)) do
    begin
      Readln(F, S);
      if (S <> '') AND (S[1] <> '#') then
      begin
        S :=Uppercase(S);
        case S[1] of
          'G' : begin
                  Inc(M.Groups);
                  SetLength(M.Group, M.Groups+1);
                  S2 :=Trim(Copy(S, 2, length(S)));
                  M.Group[M.Groups].Name :=S2;
                end;
          'V' : ReadVertexData(S, M);  // Read Vertex Date (coord, normal, texture)
          'F' : ReadFaceData(S, M);    // Read faces
          'U' : GetMaterialName(S, M); // Get the material name
          'M' : LoadMaterials(S, M); // Get the material name
        end;
      end;
    end;

    Closefile(F);
  end
  else
    MessageBox(0, PChar('Cannot find the model : ' + filename), 'Load Model', MB_OK);
  result :=M;
end;


{------------------------------------------------------------------}
{  Draws a Alias Wavefront .OBJ model                              }
{------------------------------------------------------------------}
procedure DrawModel(M : TModel);
var I, J, K : Integer;
begin
  For I :=1 to M.Groups do
  begin
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, @M.Material[M.Group[I].mIndex].Diffuse);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, @M.Material[M.Group[I].mIndex].Specular);
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, @M.Material[M.Group[I].mIndex].Ambient);
    glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, @M.Material[M.Group[I].mIndex].Shininess);

//    if M.Material[M.Group[I].mIndex].Texture <> 0 then  // its a physical texture
//    begin
//      glEnable(GL_TEXTURE_2D);                     // Enable Texture Mapping
//      glBindTexture(GL_TEXTURE_2D, M.Material[M.Group[I].mIndex].Texture);
//    end
//    else
      glDisable(GL_TEXTURE_2D);
    For J :=1 to M.Group[I].Faces do
    begin
      with M.Group[I].Face[J] do
      begin
        case Count of
          3 : glBegin(GL_TRIANGLES);
          4 : glBegin(GL_QUADS);
        else
          glBegin(GL_POLYGON);
        end;

        for K :=0 to Count-1 do
        begin
          if M.Normals > 0 then
            glNormal3fv( @M.Normal[nIndex[K]] );
          if M.TexCoords > 0 then
            glTexCoord2fv( @M.TexCoord[tIndex[K]] );
          glVertex3fv( @M.Vertex[vIndex[K]] );
        end;
        glEnd();
      end;
    end;
  end;
end;

end.