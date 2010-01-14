{Copyright (c) 2008 Ville Krumlinde

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.}

//Meshes and models
unit Meshes;

interface

uses ZClasses, ZBitmap, ZExpressions, ZOpenGL;

type
  PMeshVertexIndex = ^TMeshVertexIndex;
  TMeshVertexIndex = integer; //word,integer
  PIndicesArray = ^TIndicesArray;
  TIndicesArray = array[0..10000] of TMeshVertexIndex;

  PMeshVertexColor = ^TMeshVertexColor;
  TMeshVertexColor = integer;
  PMeshColorArray = ^TMeshColorArray;
  TMeshColorArray = array[0..10000] of TMeshVertexColor;

  TMesh = class(TContent)
  private
    VboHandles: array[0..1] of GLuint;
    VboOffsets : array[0..2] of integer;
    procedure FreeData;
  protected
    procedure Transform(const Matrix,NormalMatrix : TZMatrix4f);
    procedure CopyAndDestroy(Source : TContent); override;
    procedure DefineProperties(List: TZPropertyList); override;
    {$ifndef minimal}
    procedure UpdateBounds;
    {$endif}
  public
    //Note: keep fields in sync with CopyAndDestroy-method
    Vertices : PZVector3Array;
    VerticesCount : TMeshVertexIndex;
    Indices : PIndicesArray;
    IndicesCount : integer;
    Normals : PZVector3Array;
    TexCoords : PZVector2Array;
    Colors : PMeshColorArray;
    Style : (msTris,msQuads);
    CurrentRecursion : integer;
    {$ifndef minimal}
    BoundSphere :
      record
        Center : TZVector3f;
        Radius : single;
      end;
    {$endif}
    IsDynamic : boolean;   //True if vertices can be changed in runtime
    procedure Scale(const V : TZVector3f);
    procedure MakeNet(XCount,YCount : integer);
    procedure BeforeRender;
    procedure CreateData(VQuantity,TQuantity : integer; WithTexCoords : boolean = False;
      WithColors : boolean = False);
    procedure ComputeNormals;
    destructor Destroy; override;
  end;

  TMeshProducer = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Scale : TZVector3f;
  end;

  TMeshBox = class(TMeshProducer)
  protected
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Grid2DOnly : boolean;
    XCount,YCount : integer;
  end;

  TMeshSphere = class(TMeshProducer)
  protected
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    ZSamples,RadialSamples : integer;
  end;

  //Add noise to vertices
  TMeshNoise = class(TMeshProducer)
  protected
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    NoiseSpeed : TZVector3f;
    NoiseScale : TZVector3f;
    SymmetryX,SymmetryY,SymmetryZ : boolean;
  end;

  //Change vertices using a zexpression
  TMeshExpression = class(TMeshProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack: TZArrayList); override;
  public
    Expression : TZExpressionPropValue;
    V,N : TZVector3f;
    C : TZColorf;
    TexCoord : TZVector2f;
    AutoNormals,VertexColors,HasTexCoords : boolean;
  end;

  //Created by 3ds-import
  TMeshImport = class(TMeshProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack: TZArrayList); override;
  public
    HasVertexColors : boolean;
    HasTextureCoords : boolean;
    MeshData : TZBinaryPropValue;
  end;

  //Combine the vertexes of two meshes
  TMeshCombine = class(TMeshProducer)
  protected
    procedure ProduceOutput(Content : TContent; Stack: TZArrayList); override;
  public
  end;

  //Loads a copy of another mesh onto the stack
  TMeshLoad = class(TMeshProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack: TZArrayList); override;
  public
    Mesh : TMesh;
    {$ifndef minimal}function GetDisplayName: AnsiString; override;{$endif}
  end;

  //Transforms the vertices of the incoming mesh
  TMeshTransform = class(TMeshProducer)
  protected
    Matrix,NormalMatrix : TZMatrix4f;
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack: TZArrayList); override;
  public
    Position : TZVector3f;
    Rotation : TZVector3f;
    Accumulate : boolean;
  end;

  TMeshLoop = class(TMeshProducer)
  protected
    procedure ProduceOutput(Content : TContent; Stack: TZArrayList); override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Count : integer;
    RecursionCount : integer;
    OnIteration : TZComponentList;
    Iteration : integer;
    Position : TZVector3f;
    Rotation : TZVector3f;
  end;

  //State for models
  TModelState = class(TStateBase)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    OnCollision : TZComponentList;
  end;

  TSetModelState = class(TCommand)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    State : TModelState;
    procedure Execute; override;
    {$ifndef minimal}
    function GetDisplayName: AnsiString; override;
    {$endif}
  end;

  TCollisionStyle = (csRect2D,csSphere3D,csBox3D,csRect2D_OBB,csCircle2D);
  PCollisionCoordinates = ^TCollisionCoordinates;
  TCollisionCoordinates =
    record
      case Integer of
        0 : (Rect : TZRectf);
        1 : (Box : TZBox3D);
        2 : (OBB : TOBB_2D);
    end;

  TModel = class(TZComponent)
  private
    CurrentState : TModelState;
  protected
    ChildModelRefs : TZArrayList;  //referenser till models som denna har spawnat
    ParentModel : TModel;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Definitions : TZComponentList;
    OnRender : TZComponentList;
    OnUpdate : TZComponentList;       //uppdateringslogik
    OnSpawn : TZComponentList;
    OnRemove : TZComponentList;
    OnCollision : TZComponentList;
    CollisionStyle : TCollisionStyle;
    States : TZComponentList;
    Position : TZVector3f;
    Rotation : TZVector3f;
    Velocity : TZVector3f;
    Scale : TZVector3f;
    RotationVelocity : TZVector3f;
    Category : byte;
    CollisionBounds : TZRectf;
    CollisionOffset : TZVector3f;
    IsSpawnedAsReference : boolean;
    Active : boolean;
    Personality : single;  //Varje instans har egen random "personlighet", som kan anv�ndas i expressions.
    LastPosition : TZVector3f;  //Anv�nds i collision
    CollisionCoordinates : TCollisionCoordinates;
    CollisionCoordinatesUpdatedTime : single;
    RenderOrder : (roNormal,roDepthsorted);
    SortKey : single; //Used when depthsorting models
    procedure Update; override;        //anropas ej ifall active=false
    procedure UpdateCollisionCoordinates;
    procedure Collision(Hit : TModel);
    {$ifndef minimal}
    procedure DesignerUpdate;
    procedure DesignerReset; override;
    {$endif}
    procedure RunRenderCommands;
    constructor Create(OwnerList: TZComponentList); override;
    destructor Destroy; override;
  end;

  //Models-list owned by application
  //Models are divided into collision categories
  TModels = class
  private
    RemoveList : TZArrayList;
    procedure ClearAll;
  public
    Cats : TZArrayList;
    constructor Create;
    destructor Destroy; override;
    procedure Update;
    procedure RegisterCat(Cat : integer);
    function Get(Cat : integer) : TZArrayList;
    procedure Add(M : TModel);
    procedure Remove(M : TModel);
    procedure RemoveAll;
    procedure FlushRemoveList;
  end;

  TSpawnModel = class(TCommand)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Model : TModel;
    Position : TZVector3f;
    Rotation : TZVector3f;
    Scale : TZVector3f;
    SpawnStyle : (ssClone,ssReference);
    UseSpawnerPosition : boolean;
    SpawnerIsParent : boolean;  //Spawned model becomes child to currentmodel
    procedure Execute; override;
    {$ifndef minimal}function GetDisplayName: AnsiString; override;{$endif}
  end;

  TRemoveModel = class(TCommand)
  public
    procedure Execute; override;
  end;

  TRemoveAllModels = class(TCommand)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    OfType : TModel;
    procedure Execute; override;
    {$ifndef minimal}function GetDisplayName: AnsiString; override;{$endif}
  end;


var
  CurrentModel : TModel;  //Set to the model that is currently updated



{$ifndef minimal}
const
  CollisionStyleNames : array[0..4] of string =
('Rect2D','Sphere3D','Box3D','Rect2D_OBB','Circle2D');
{$endif}

implementation

uses ZMath, ZApplication
{$ifndef minimal}, Animators, Renderer{$endif}
{$ifdef zdebug}, ZLog, Sysutils{$endif}
;

procedure ExecuteWithCurrentModel(M : TModel; CommandList : TZComponentList);
var
  SaveCurrent : TModel;
begin
  SaveCurrent := CurrentModel;
  CurrentModel := M;
  CommandList.ExecuteCommands;
  CurrentModel := SaveCurrent;
end;

{ TMesh }

procedure TMesh.ComputeNormals;
var
  C : array[0..2] of TZVector3f;
  ax,ay,az,bx,by,bz,nx,ny,nz : single;
  I,I1,I2,I3 : integer;
begin
  if Style<>msTris then
    Exit;

  //One normal for each vertex
//  GetMem(Normals,SizeOf(TZVector3f) * VerticesCount);
  FillChar(Normals^,SizeOf(TZVector3f) * VerticesCount,0);

  for I := 0 to (IndicesCount div 3)-1 do
  begin
    I1 := Indices^[(I*3)];
    I2 := Indices^[(I*3)+1];
    I3 := Indices^[(I*3)+2];

    C[0] := Vertices^[ I1 ];
    C[1] := Vertices^[ I2 ];
    C[2] := Vertices^[ I3 ];

    //Calc normal vector
    //http://www.tjhsst.edu/~dhyatt/supercomp/n310.html
    ax:=c[1][0] - c[0][0];
    ay:=c[1][1] - c[0][1];
    az:=c[1][2] - c[0][2];

    bx:=c[2][0] - c[1][0];
    by:=c[2][1] - c[1][1];
    bz:=c[2][2] - c[1][2];

    nx:=ay * bz - az * by;
    ny:=az * bx - ax * bz;
    nz:=ax * by - ay * bx;

    //Add normals for each face
    Normals^[ I1 ][0] := Normals^[ I1 ][0] + NX;
    Normals^[ I1 ][1] := Normals^[ I1 ][1] + NY;
    Normals^[ I1 ][2] := Normals^[ I1 ][2] + NZ;

    Normals^[ I2 ][0] := Normals^[ I2 ][0] + NX;
    Normals^[ I2 ][1] := Normals^[ I2 ][1] + NY;
    Normals^[ I2 ][2] := Normals^[ I2 ][2] + NZ;

    Normals^[ I3 ][0] := Normals^[ I3 ][0] + NX;
    Normals^[ I3 ][1] := Normals^[ I3 ][1] + NY;
    Normals^[ I3 ][2] := Normals^[ I3 ][2] + NZ;
  end;

  //Normalize
  for I := 0 to VerticesCount-1 do
    VecNormalize3(Normals^[I]);
end;

procedure TMesh.Transform(const Matrix,NormalMatrix : TZMatrix4f);
var
  I : integer;
  V : TZVector3f;
begin
  for I := 0 to Self.VerticesCount-1 do
  begin
    VecCopy3(Self.Vertices^[I],V);
    VectorTransform(V,Matrix,Self.Vertices^[I]);
    VecCopy3(Self.Normals^[I],V);
    VectorTransform(V,NormalMatrix,Self.Normals^[I]);
  end;
end;

procedure TMesh.CopyAndDestroy(Source: TContent);
var
  M : TMesh;
begin
  {$ifndef minimal}
  if Source=nil then Exit;
  {$endif}
  FreeData;
  M := TMesh(Source);
  Vertices := M.Vertices;
  VerticesCount := M.VerticesCount;
  Indices := M.Indices;
  IndicesCount := M.IndicesCount;
  Normals := M.Normals;
  TexCoords := M.TexCoords;
  Colors := M.Colors;
  Style := M.Style;
  IsDynamic := M.IsDynamic;
  M.Vertices :=nil;
  M.Indices :=nil;
  M.Normals :=nil;
  M.TexCoords :=nil;
  M.Colors :=nil;
  M.Free;
  {$ifdef zlog}
  if CurrentRecursion=0 then
  begin
    if VerticesCount>=High(TMeshVertexIndex) then
      ZLog.GetLog(Self.ClassName).Error('Too many vertices: ' + IntToStr(Self.VerticesCount) )
    else if (not ZApp.DesignerIsRunning) then
      ZLog.GetLog(Self.ClassName).Write('Triangles ' + IntToStr(Self.IndicesCount div 3) );
  end;
  {$endif}
end;

procedure TMesh.CreateData(VQuantity, TQuantity: integer; WithTexCoords : boolean = False;
  WithColors : boolean = False);
begin
  if (Vertices<>nil) then
  begin
    //Already allocated
    if (VerticesCount=VQuantity) then
      Exit; //Same count, just exit
    FreeData; //Otherwise dealloc old
  end;
  VerticesCount := VQuantity;
  IndicesCount := 3*TQuantity;

  GetMem(Vertices, SizeOf(TZVector3f) * VerticesCount);

  //New memory can contain junk, normals must be zeroed out
  GetMem(Normals,SizeOf(TZVector3f) * VerticesCount);
  FillChar(Normals^,SizeOf(TZVector3f) * VerticesCount,0);

  GetMem(Indices, SizeOf(TMeshVertexIndex) * IndicesCount);

  if WithTexCoords then
    GetMem(TexCoords, SizeOf(TZVector2f) * VerticesCount);
  if WithColors then
    GetMem(Colors, SizeOf(TMeshVertexColor) * VerticesCount);

  //Use VBOs for larger meshes only
  IsDynamic := TQuantity<1024;
end;

procedure TMesh.FreeData;
begin
  VerticesCount := 0;
  IndicesCount := 0;
  if Vertices<>nil then
    FreeMem(Vertices);
  if Indices<>nil then
    FreeMem(Indices);
  if Normals<>nil then
    FreeMem(Normals);
  if TexCoords<>nil then
    FreeMem(TexCoords);
  if Colors<>nil then
  begin
    FreeMem(Colors);
    Colors := nil;
  end;

  if ZOpenGL.VbosSupported and (VboHandles[0]<>0) then
  begin
    glDeleteBuffersARB(2, @VboHandles);
    VboHandles[0]:=0;
  end;
end;

destructor TMesh.Destroy;
begin
  FreeData;
  inherited;
end;

procedure TMesh.BeforeRender;
var
  VertSize,NormSize,ColsSize,TexSize : integer;
begin
  if (Vertices=nil) or (Producers.IsChanged) or (IsChanged) then
  begin
    RefreshFromProducers;
    {$ifndef minimal}
    UpdateBounds;
    {$endif}
  end;

  if ZOpenGL.VbosSupported and (not IsDynamic) then
  begin

    if Self.VboHandles[0]=0 then
    begin
      glGenBuffersARB(2, @VboHandles);

      VertSize := VerticesCount * SizeOf(TZVector3f);
      NormSize := VertSize;

      if Colors<>nil then
        ColsSize:= VerticesCount * SizeOf(TMeshVertexColor)
      else
        ColsSize:= 0;

      if TexCoords<>nil then
        TexSize:= VerticesCount * SizeOf(TZVector2f)
      else
        TexSize:= 0;

      glBindBufferARB(GL_ARRAY_BUFFER_ARB, VboHandles[0]);
      glBufferDataARB(GL_ARRAY_BUFFER_ARB, VertSize + NormSize + ColsSize + TexSize, nil, STATIC_DRAW_ARB);

      glBufferSubDataARB(GL_ARRAY_BUFFER_ARB, 0, VertSize, Vertices);

      VboOffsets[0] := VertSize;
      glBufferSubDataARB(GL_ARRAY_BUFFER_ARB, VboOffsets[0], NormSize, Normals);

      VboOffsets[1]:=VboOffsets[0]+NormSize;
      if ColsSize>0 then
        glBufferSubDataARB(GL_ARRAY_BUFFER_ARB, VboOffsets[1], ColsSize, Colors);

      VboOffsets[2]:=VboOffsets[1]+ColsSize;
      if TexSize>0 then
        glBufferSubDataARB(GL_ARRAY_BUFFER_ARB, VboOffsets[2], TexSize, TexCoords);

      glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, VboHandles[1]);
      glBufferDataARB(GL_ELEMENT_ARRAY_BUFFER_ARB, IndicesCount * SizeOf(TMeshVertexIndex), Indices, STATIC_DRAW_ARB);
    end;
    glBindBufferARB(GL_ELEMENT_ARRAY_BUFFER_ARB, VboHandles[1]);

    glBindBufferARB(GL_ARRAY_BUFFER_ARB, VboHandles[0]);
    glEnableClientState(GL_NORMAL_ARRAY);
    glNormalPointer(GL_FLOAT,0,pointer(VboOffsets[0]));

    if Colors<>nil then
    begin
      glEnableClientState(GL_COLOR_ARRAY);
      glColorPointer(4,GL_UNSIGNED_BYTE,0,pointer(VboOffsets[1]));
    end;

    if TexCoords<>nil then
    begin
      glEnableClientState(GL_TEXTURE_COORD_ARRAY);
      glTexCoordPointer(2,GL_FLOAT,0,pointer(VboOffsets[2]));
    end;

    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(3,GL_FLOAT,0,nil);
  end;

end;

procedure TMesh.Scale(const V: TZVector3f);
var
  I : integer;
begin
  if VecIsIdentity3(V) then
    Exit;
  for I := 0 to VerticesCount-1 do
    VecMult3(Vertices^[I],V);
  if Normals<>nil then
    for I := 0 to VerticesCount-1 do
    begin
      VecMult3(Normals^[I],V);
      VecNormalize3( Normals^[I] );
    end;
end;

{$ifndef minimal}
procedure TMesh.UpdateBounds;
//http://www.mvps.org/directx/articles/using_bounding_spheres.htm
var
  VertP : PZVector3f;
  I : integer;
  C,V : TZVector3f;
  R,DistSq : single;
begin
  // find center
  VertP := pointer(Self.Vertices);
  C := Vector3f(0,0,0);
  for I := 0 to Self.VerticesCount - 1 do
  begin
    VecAdd3(C,VertP^,C);
    Inc(VertP);
  end;
  VecDiv3(C,Self.VerticesCount,C);
  Self.BoundSphere.Center := C;

  // find farthest point in set
  R := 0;
  VertP := pointer(Self.Vertices);
  for I := 0 to Self.VerticesCount - 1 do
  begin
    VecSub3(VertP^,C,V);
    DistSq := ZMath.VecLengthSquared3(V);
    if DistSq>R then
      R := DistSq;
    Inc(VertP);
  end;

  Self.BoundSphere.Radius := sqrt(R);
end;
{$endif}

procedure TMesh.DefineProperties(List: TZPropertyList);
begin
  inherited;
  {$ifndef minimal}
  List.GetByName('Producers').SetChildClasses([TMeshProducer]);
  {$endif}
  List.AddProperty({$IFNDEF MINIMAL}'CurrentRecursion',{$ENDIF}integer(@CurrentRecursion), zptInteger);
    List.GetLast.NeverPersist := True;
    {$ifndef minimal}List.GetLast.IsReadOnly := True;{$endif}
end;

procedure TMesh.MakeNet(XCount, YCount: integer);
var
  VertCount,TriCount : integer;
  P : PZVector3f;
  XStep,YStep,CurX,CurY : single;
  Ind : PMeshVertexIndex;
  Tex : PZVector2f;
  CurI,X,Y : integer;
begin
  VertCount := (2+XCount) * (2+YCount);
  TriCount := 2*((XCount+1)*(YCount+1));
  CreateData(VertCount,TriCount,True);
  P := pointer(Vertices);
  XStep := 1/(XCount+1);
  YStep := 1/(YCount+1);

  Tex := pointer(TexCoords);

  //Generate vertices and texcoords
  CurY := -0.5;
  for Y := 0 to YCount+1 do
  begin
    CurX := -0.5;
    for X := 0 to XCount+1 do
    begin
      //Vertex interval -0.5 .. 0.5
      P^[0] := CurX;
      P^[1] := CurY;
      P^[2] := 0;

      //Texcoords interval 1..0
      Tex^[0] := CurX+0.5;
      Tex^[1] := 1.0 - (0.5 - CurY);

      CurX := CurX + XStep;
      Inc(P);
      Inc(Tex);
    end;
    CurY := CurY + YStep;
  end;

  //Generate two triangles for each quad in net
  //CCW direction
  CurI := 0;
  Ind := PMeshVertexIndex(Indices);
  for Y := 0 to YCount do
  begin
    for X := 0 to XCount do
    begin
      Ind^:= CurI; Inc(Ind);
      Ind^:= CurI+1; Inc(Ind);
      Ind^:= CurI+2+XCount; Inc(Ind);

      Ind^:= CurI+1; Inc(Ind);
      Ind^:= CurI+3+XCount; Inc(Ind);
      Ind^:= CurI+2+XCount; Inc(Ind);

      Inc(CurI);
    end;
    Inc(CurI);
  end;
{
      curx=0
      xstep=1/xcount
      while(cury<1)
        while(curx<1)
          addvertice(curx,cury)
      skapa indices
        tri1 �r v1,v2,v3
        tri2 �r v2,v4,v3
}
  ComputeNormals;
end;

{ TModel }

procedure TModel.Collision(Hit: TModel);
begin
  ZApp.EventState.CollidedCategory := Hit.Category;
  Meshes.CurrentModel := Self;
  OnCollision.ExecuteCommands;
  if (CurrentState<>nil) then
    CurrentState.OnCollision.ExecuteCommands;
end;

procedure TModel.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Definitions',{$ENDIF}integer(@Definitions), zptComponentList);
    {$ifndef minimal}{List.GetLast.SetChildClasses([TDefineVariable,TDefineConstant,TMesh,TModel,TZBitmap]);}{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'States',{$ENDIF}integer(@States), zptComponentList);
    {$ifndef minimal}List.GetLast.SetChildClasses([TModelState]);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'OnRender',{$ENDIF}integer(@OnRender), zptComponentList);
  List.AddProperty({$IFNDEF MINIMAL}'OnUpdate',{$ENDIF}integer(@OnUpdate), zptComponentList);
  List.AddProperty({$IFNDEF MINIMAL}'OnSpawn',{$ENDIF}integer(@OnSpawn), zptComponentList);
  List.AddProperty({$IFNDEF MINIMAL}'OnRemove',{$ENDIF}integer(@OnRemove), zptComponentList);
  List.AddProperty({$IFNDEF MINIMAL}'OnCollision',{$ENDIF}integer(@OnCollision), zptComponentList);
  List.AddProperty({$IFNDEF MINIMAL}'Position',{$ENDIF}integer(@Position), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'Rotation',{$ENDIF}integer(@Rotation), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'Velocity',{$ENDIF}integer(@Velocity), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'Scale',{$ENDIF}integer(@Scale), zptVector3f);
    List.GetLast.DefaultValue.Vector3fValue := ZMath.UNIT_XYZ3;
  List.AddProperty({$IFNDEF MINIMAL}'RotationVelocity',{$ENDIF}integer(@RotationVelocity), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'Category',{$ENDIF}integer(@Category), zptByte);
  List.AddProperty({$IFNDEF MINIMAL}'CollisionBounds',{$ENDIF}integer(@CollisionBounds), zptRectf);
  List.AddProperty({$IFNDEF MINIMAL}'CollisionOffset',{$ENDIF}integer(@CollisionOffset), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'CollisionStyle',{$ENDIF}integer(@CollisionStyle), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(CollisionStyleNames);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'RenderOrder',{$ENDIF}integer(@RenderOrder), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['Normal','Depthsorted']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'Personality',{$ENDIF}integer(@Personality), zptFloat);
    List.GetLast.NeverPersist := True;
    List.GetLast.DontClone := True;
    {$ifndef minimal}List.GetLast.IsReadOnly := True;{$endif}
end;

procedure TModel.UpdateCollisionCoordinates;
var
  W,H,A,S,C : single;
  Start : TZVector3f;
  I : integer;
  Result : PCollisionCoordinates;
begin
  if Self.CollisionCoordinatesUpdatedTime=ZApp.Time then
    Exit; //Only update once per frame
  Self.CollisionCoordinatesUpdatedTime:=ZApp.Time;

  Result := @Self.CollisionCoordinates;

  VecAdd3(CollisionOffset,Position, Start);
  case Self.CollisionStyle of
    csRect2D:
      begin
        W := CollisionBounds.Area[0] * 0.5;
        H := CollisionBounds.Area[1] * 0.5;
        Result.Rect.Left := Start[0] - W;
        Result.Rect.Right := Start[0] + W;
        Result.Rect.Top := Start[1] - H;
        Result.Rect.Bottom := Start[1] + H;
      end;
    csSphere3D:
      begin
        Result.Rect.Area[0] := Start[0];
        Result.Rect.Area[1] := Start[1];
        Result.Rect.Area[2] := Start[2];
        Result.Rect.Area[3] := CollisionBounds.Area[0];
      end;
    csBox3D:
      begin
        VecSub3(Start,PZVector3f(@CollisionBounds.Area)^,Result.Box.Min);
        VecAdd3(Start,PZVector3f(@CollisionBounds.Area)^,Result.Box.Max);
      end;
    csRect2D_OBB:
      begin
        for I := 0 to 1 do
        begin
          Result.OBB.C[I] := Start[I];
          Result.OBB.E[I] := CollisionBounds.Area[I] * Scale[I] * 0.5;
        end;
        A := CycleToRad(Self.Rotation[2]);
        S := Sin(A);
        C := Cos(A);
        Result.OBB.U[0][0] := C;
        Result.OBB.U[0][1] := S;
        Result.OBB.U[1][0] := -S;
        Result.OBB.U[1][1] := C;
      end;
    csCircle2D :
      begin
        Result.Rect.Area[0] := Start[0];
        Result.Rect.Area[1] := Start[1];
        Result.Rect.Area[2] := CollisionBounds.Area[0] * Scale[0];
      end;
  end;
end;

procedure TModel.Update;
var
  I : integer;
begin
  if Active then
  begin
    //Update movement
    VecCopy3(Position,Self.LastPosition);
    if not VecIsNull3(Self.Velocity) then
    begin
      for I := 0 to 2 do
        Position[I] := Position[I] + (Velocity[I] * ZApp.DeltaTime);
    end;

    //Update rotation
    if not VecIsNull3(Self.RotationVelocity) then
      for I := 0 to 2 do
        Rotation[I] := Rotation[I] + (RotationVelocity[I] * ZApp.DeltaTime);

    OnUpdate.ExecuteCommands;
    //Update renderers: particlesystems, beams etc
    OnRender.Update;

    //Update current state
    if CurrentState<>nil then
      CurrentState.Update;
  end;
end;

procedure TModel.RunRenderCommands;
//Called from render.rendermodel
begin
  OnRender.ExecuteCommands;
  if CurrentState<>nil then
    CurrentState.OnRender.ExecuteCommands;
end;


{$ifndef minimal}
procedure TModel.DesignerUpdate;
begin
  //Update renderers: particlesystems, beams etc
  OnRender.Update;
end;

procedure TModel.DesignerReset;
begin
  inherited;
//  OnRender.DesignerReset;
end;
{$endif}

constructor TModel.Create(OwnerList: TZComponentList);
begin
  inherited Create(OwnerList);
  ChildModelRefs := TZArrayList.CreateReferenced;
  Personality := System.Random;
end;

destructor TModel.Destroy;
begin
  ChildModelRefs.Free;
  inherited;
end;

{ TMeshSphere }

procedure TMeshSphere.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'ZSamples',{$ENDIF}integer(@ZSamples), zptInteger);
    List.GetLast.DefaultValue.IntegerValue := 10;
  List.AddProperty({$IFNDEF MINIMAL}'RadialSamples',{$ENDIF}integer(@RadialSamples), zptInteger);
    List.GetLast.DefaultValue.IntegerValue := 10;
end;

procedure TMeshSphere.ProduceOutput(Content : TContent; Stack : TZArrayList);
const
  Radius : single = 1.0;
var
  ZSm1,ZSm2,ZSm3,RSp1,VQuantity,TQuantity : integer;
  R, Z, ZStart, i, Save : integer;
  InvRS,ZFactor,Angle,ZFraction,fZ,SliceRadius{,RadialFraction} : single;
  afSin,afCos : PFloatArray;
  SliceCenter,Normal,Radial : TZVector3f;
  Mesh : TMesh;
  LocalIndex : PIndicesArray;
  i0,i1,i2,i3 : integer;
  VQm1,VQm2,Offset : integer;
begin
  {$ifndef minimal}
  if (ZSamples<=2) or (RadialSamples<=2) then
    Exit;
  {$endif}
  Mesh := TMesh.Create(nil);
  Mesh.Style := msTris;

  ZSm1 := ZSamples-1;
  ZSm2 := ZSamples-2;
  ZSm3 := ZSamples-3;

  RSp1 := RadialSamples+1;
  VQuantity := ZSm2*RSp1 + 2;
  TQuantity := 2*ZSm2*RadialSamples;
  Mesh.CreateData(VQuantity,TQuantity);

  // generate geometry
  InvRS := 1.0/RadialSamples;
  ZFactor := 2.0/ZSm1;

  // Generate points on the unit circle to be used in computing the mesh
  // points on a cylinder slice.
  GetMem(afSin,sizeOf(single) * RSp1);
  GetMem(afCos,sizeOf(single) * RSp1);

  for R := 0 to RadialSamples-1 do
  begin
    Angle := (PI*2)*InvRS*R;
    afCos^[R] := Cos(Angle);
    afSin^[R] := Sin(Angle);
  end;

  afSin^[RadialSamples] := afSin^[0];
  afCos^[RadialSamples] := afCos^[0];

  // generate the cylinder itself
  I := 0;
  for Z := 1 to ZSm1-1 do
  begin
    ZFraction := -1.0 + ZFactor*Z;  // in (-1,1)
    fZ := Radius*ZFraction;

    // compute center of slice
    SliceCenter := Vector3f(0.0,0.0,fZ);

    // compute radius of slice
    SliceRadius := Sqrt(Abs(Radius*Radius-fZ*fZ));

    // compute slice vertices with duplication at end point
    Save := i;
    for R := 0 to RadialSamples-1 do
    begin
//      RadialFraction := R*InvRS;  // in [0,1)
      Radial := Vector3f(afCos^[R],afSin^[R],0.0);
      VecCopy3(VecAdd3( SliceCenter, VecScalarMult3(Radial,SliceRadius)), Mesh.Vertices^[I]);
      VecCopy3(Mesh.Vertices^[I],Normal);
      VecNormalize3(Normal);
      VecCopy3(Normal,Mesh.Normals^[I]);
      I := I +1;
    end;

    VecCopy3(Mesh.Vertices^[Save],Mesh.Vertices^[I]);
    VecCopy3(Mesh.Normals^[Save],Mesh.Normals^[I]);

    I := I + 1;
  end;

  // south pole
  VecCopy3(VecScalarMult3(UNIT_Z3,-Radius),Mesh.Vertices^[I]);
  VecCopy3(VecScalarMult3(UNIT_Z3,-1),Mesh.Normals^[I]);

  I := I + 1;

  // north pole
  VecCopy3(VecScalarMult3(UNIT_Z3,Radius),Mesh.Vertices^[I]);
  VecCopy3(UNIT_Z3,Mesh.Normals^[I]);

//  Assert( i == VQuantity );

  // generate connectivity
  LocalIndex := Mesh.Indices;
  ZStart := 0;
  for Z := 0 to ZSm3-1 do
  begin
    i0 := ZStart;
    i1 := i0 + 1;
    Inc(ZStart,RSp1);
    i2 := ZStart;
    i3 := i2 + 1;
    for I := 0 to RadialSamples-1 do
    begin
      LocalIndex^[0] := i0; Inc(i0);
      LocalIndex^[1] := i1;
      LocalIndex^[2] := i2;
      LocalIndex^[3] := i1; Inc(i1);
      LocalIndex^[4] := i3; Inc(i3);
      LocalIndex^[5] := i2; Inc(i2);
      LocalIndex := @LocalIndex^[6];
    end;
  end;

  // south pole triangles
  VQm2 := VQuantity-2;
  for i := 0 to RadialSamples-1 do
  begin
    LocalIndex^[0] := i;
    LocalIndex^[1] := VQm2;
    LocalIndex^[2] := i+1;
//    Inc(LocalIndex,3);
    LocalIndex := @LocalIndex^[3];
  end;

  // north pole triangles
  VQm1 := VQuantity-1;
  Offset := ZSm3 * RSp1;
  for i := 0 to RadialSamples-1 do
  begin
    LocalIndex^[0] := VQm1;
    LocalIndex^[1] := i+offset;
    LocalIndex^[2] := i+1+offset;
    LocalIndex := @LocalIndex^[3];
  end;

//  assert( aiLocalIndex == m_aiIndex + 3*iTQuantity );
  FreeMem(afCos);
  FreeMem(afSin);

//  Mesh.Scale( Vector3f(0.25,2,1) );
  Mesh.Scale( Self.Scale );

//     Mesh.Normals := nil;
//     Mesh.ComputeNormals;

  Stack.Push(Mesh);
end;

{ TMeshNoise }

procedure TMeshNoise.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'NoiseSpeed',{$ENDIF}integer(@NoiseSpeed), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'NoiseScale',{$ENDIF}integer(@NoiseScale), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'SymmetryX',{$ENDIF}integer(@SymmetryX), zptBoolean);
  List.AddProperty({$IFNDEF MINIMAL}'SymmetryY',{$ENDIF}integer(@SymmetryY), zptBoolean);
  List.AddProperty({$IFNDEF MINIMAL}'SymmetryZ',{$ENDIF}integer(@SymmetryZ), zptBoolean);
end;

procedure TMeshNoise.ProduceOutput(Content : TContent; Stack: TZArrayList);
var
  Mesh : TMesh;
  I : integer;
  V : TZVector3f;
  S : single;
begin
  {$ifndef minimal}
  if Stack.Count=0 then exit;
  {$endif}
  Mesh := TMesh(Stack.Pop);

  for I := 0 to Mesh.VerticesCount-1 do
  begin
    V := Mesh.Vertices^[I];
    if SymmetryX then
      V[0] := Abs(V[0]);
    if SymmetryY then
      V[1] := Abs(V[1]);
    if SymmetryZ then
      V[2] := Abs(V[2]);

    S := PerlinNoise3(
      NoiseSpeed[0]*V[0],
      NoiseSpeed[1]*V[1],
      NoiseSpeed[2]*V[2]
      );
    V[0] := 1.0 + S * NoiseScale[0];
    V[1] := 1.0 + S * NoiseScale[1];
    V[2] := 1.0 + S * NoiseScale[2];
    VecMult3(Mesh.Vertices^[I],V);
    //Mesh.Vertices^[I] := VecAdd3(Mesh.Vertices^[I],V);

    if Mesh.Normals<>nil then
    begin
      VecMult3(Mesh.Normals^[I],V);
      //Mesh.Normals^[I] := VecAdd3(Mesh.Normals^[I],V);
      VecNormalize3( Mesh.Normals^[I] );
    end;
  end;

  Mesh.Scale( Self.Scale );

  Stack.Push(Mesh);
end;

{ TMeshExpression }

procedure TMeshExpression.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Expression',{$ENDIF}integer(@Expression), zptExpression);
    {$ifndef minimal}
    List.GetLast.DefaultValue.ExpressionValue.Source := '//V : current vertex'#13#10+
      '//N : current normal (turn off AutoNormals when modifying normals)'#13#10+
      '//C : current color (turn on VertexColors)'#13#10 +
      '//TexCoord : current texture coordinate (turn on HasTexCoords)';
    {$endif}
  List.AddProperty({$IFNDEF MINIMAL}'AutoNormals',{$ENDIF}integer(@AutoNormals), zptBoolean);
    List.GetLast.DefaultValue.BooleanValue := True;
  List.AddProperty({$IFNDEF MINIMAL}'VertexColors',{$ENDIF}integer(@VertexColors), zptBoolean);
  List.AddProperty({$IFNDEF MINIMAL}'HasTexCoords',{$ENDIF}integer(@HasTexCoords), zptBoolean);
  List.AddProperty({$IFNDEF MINIMAL}'V',{$ENDIF}integer(@V), zptVector3f);
    List.GetLast.NeverPersist := True;
  List.AddProperty({$IFNDEF MINIMAL}'N',{$ENDIF}integer(@N), zptVector3f);
    List.GetLast.NeverPersist := True;
  List.AddProperty({$IFNDEF MINIMAL}'C',{$ENDIF}integer(@C), zptColorf);
    List.GetLast.NeverPersist := True;
  List.AddProperty({$IFNDEF MINIMAL}'TexCoord',{$ENDIF}integer(@TexCoord), zptVector3f);
    List.GetLast.NeverPersist := True;
end;

procedure TMeshExpression.ProduceOutput(Content : TContent; Stack: TZArrayList);
var
  Mesh : TMesh;
  I : integer;
  PColor : PMeshVertexColor;
  PTex : PZVector2f;
begin
  {$ifndef minimal}
  if Stack.Count=0 then exit;
  {$endif}
  Mesh := TMesh(Stack.Pop);

  if VertexColors and (Mesh.Colors=nil) then
    GetMem(Mesh.Colors,Mesh.VerticesCount * 4);
  PColor := PMeshVertexColor(Mesh.Colors);

  if HasTexCoords and (Mesh.TexCoords=nil) then
    GetMem(Mesh.TexCoords,SizeOf(TZVector2f) * Mesh.VerticesCount);
  PTex := pointer(Mesh.TexCoords);

  for I := 0 to Mesh.VerticesCount-1 do
  begin
    VecCopy3(Mesh.Vertices^[I],Self.V);
    VecCopy3(Mesh.Normals^[I],Self.N);
    if HasTexCoords then
      PZVector2f(@Self.TexCoord)^ := PTex^;
    ZExpressions.RunCode(Expression.Code);
    VecCopy3(Self.V,Mesh.Vertices^[I]);
    VecCopy3(Self.N,Mesh.Normals^[I]);
    if VertexColors then
    begin
      PColor^ := ColorFtoB(Self.C);
      Inc(PColor);
    end;
    if HasTexCoords then
    begin
      PTex^ := Self.TexCoord;
      Inc(PTex);
    end;
  end;

  Mesh.Scale( Self.Scale );

  if AutoNormals then
    Mesh.ComputeNormals;

  Stack.Push(Mesh);
end;

{ TMeshProducer }

procedure TMeshProducer.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Scale',{$ENDIF}integer(@Scale), zptVector3f);
    List.GetLast.DefaultValue.Vector3fValue := ZMath.UNIT_XYZ3;
end;


{ TSpawnModel }


{$ifndef minimal}
const
  SpawnStyleNames : array[0..1] of string = ('Clone','Reference');
{$endif}

procedure TSpawnModel.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Model',{$ENDIF}integer(@Model), zptComponentRef);
    {$ifndef minimal}List.GetLast.SetChildClasses([TModel]);{$endif}
    {$ifndef minimal}List.GetLast.NeedRefreshNodeName := True;{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'Position',{$ENDIF}integer(@Position), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'Rotation',{$ENDIF}integer(@Rotation), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'Scale',{$ENDIF}integer(@Scale), zptVector3f);
    VecCopy3(ZMath.UNIT_XYZ3,List.GetLast.DefaultValue.Vector3fValue);
  List.AddProperty({$IFNDEF MINIMAL}'SpawnStyle',{$ENDIF}integer(@SpawnStyle), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(SpawnStyleNames);{$endif}
    {$ifndef minimal}List.GetLast.NeedRefreshNodeName := True;{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'UseSpawnerPosition',{$ENDIF}integer(@UseSpawnerPosition), zptBoolean);
  List.AddProperty({$IFNDEF MINIMAL}'SpawnerIsParent',{$ENDIF}integer(@SpawnerIsParent), zptBoolean);
end;


procedure TSpawnModel.Execute;
var
  Spawned : TModel;
begin
  {$ifndef minimal}
  AssertNotRenderMode;
  {$endif}
  if Model<>nil then
  begin
    if SpawnStyle=ssClone then
      //Clone copy owned by app
      Spawned := TModel(Model.Clone)
    else
    begin
      //Reference to original, keep ownership
      Spawned := Model;
      Spawned.IsSpawnedAsReference := True;
    end;

    if UseSpawnerPosition and (CurrentModel<>nil) then
    begin
      VecCopy3( VecAdd3(CurrentModel.Position,Self.Position), Spawned.Position);
      //VecCopy3(CurrentModel.Position,Spawned.Position)
    end
    else
    begin
      if not VecIsNull3(Position) then
        VecCopy3(Self.Position,Spawned.Position);
    end;

    if not VecIsIdentity3(Self.Scale) then
      VecCopy3(Self.Scale,Spawned.Scale);
    if not VecIsNull3(Self.Rotation) then
      VecCopy3(Self.Rotation,Spawned.Rotation);

    if (SpawnStyle=ssReference) and Spawned.Active then
      //Do nothing: Respawning a already actice reference should not add the
      //same model instance to model-list
    else
    begin
      Spawned.Active:=True;
      ZApp.AddModel( Spawned );
      if SpawnerIsParent then
      begin
        CurrentModel.ChildModelRefs.Add(Spawned);
        Spawned.ParentModel := CurrentModel;
      end;
    end;

    //CurrentModel must be spawned
    ExecuteWithCurrentModel(Spawned,Spawned.OnSpawn);
  end;
end;

{$ifndef minimal}
function TSpawnModel.GetDisplayName: AnsiString;
begin
  Result := inherited GetDisplayName;
  if Assigned(Model) then
  begin
    Result := Result + '  ' + Model.Name;
    if Ord(SpawnStyle)<>0 then
      Result := Result + ' (' + AnsiString(SpawnStyleNames[integer(SpawnStyle)]) + ')';
  end;
end;
{$endif}

{ TModels }

procedure TModels.Add(M: TModel);
begin
  TZArrayList(Cats[M.Category]).Add(M);
end;

procedure TModels.Remove(M: TModel);
begin
  if RemoveList.IndexOf(M)=-1 then
  begin
    M.Active := False;
    RemoveList.Add(M);

    if not ZApp.Terminating then
      ExecuteWithCurrentModel(M,M.OnRemove);

    //Also remove child models
    while M.ChildModelRefs.Count>0 do
      //Nested calls to remove will shorten list
      Remove( TModel(M.ChildModelRefs.Last) );

    //Remove reference to parent
    if M.ParentModel<>nil then
      M.ParentModel.ChildModelRefs.Remove(M);
  end;
end;

procedure TModels.ClearAll;
begin
  RemoveAll;
  FlushRemoveList;
end;

constructor TModels.Create;
begin
  Cats := TZArrayList.Create;
  RemoveList := TZArrayList.Create;
end;

destructor TModels.Destroy;
begin
  ClearAll;
  Cats.Free;
  RemoveList.Free;
  inherited;
end;

function TModels.Get(Cat: integer): TZArrayList;
begin
  if Cats.Count<=Cat then
    RegisterCat(Cat);
  Result := TZArrayList(Cats[Cat]);
end;

procedure TModels.RegisterCat(Cat: integer);
begin
  while Cats.Count<=Cat do
    Cats.Add( TZArrayList.CreateReferenced );
end;

procedure TModels.Update;
var
  I,J : integer;
  List : TZArrayList;
  M : TModel;
begin
  //Run Update and animators on all models in all categories
  for I := 0 to Cats.Count-1 do
  begin
    List := TZArrayList(Cats[I]);
    for J := 0 to List.Count-1 do
    begin
      M := TModel(List[J]);
      Meshes.CurrentModel := M;
      if M.Active then
        M.Update;
    end;
  end;
  Meshes.CurrentModel := nil;
  //Update can insert models in removelist
  FlushRemoveList;
end;

procedure TModels.RemoveAll;
var
  I,J : integer;
  List : TZArrayList;
  M : TModel;
begin
  //Add models to be removed in removelist, they are freed after next call to models.update
  for I := 0 to Cats.Count-1 do
  begin
    List := TZArrayList(Cats[I]);
    for J := 0 to List.Count-1 do
    begin
      M := TModel(List[J]);
      Remove(M);
    end;
  end;
end;

procedure TModels.FlushRemoveList;
var
  I : integer;
  M : TModel;
begin
  for I := 0 to RemoveList.Count-1 do
  begin
    M := TModel(RemoveList[I]);
    Get(M.Category).Remove(M);
    if M.IsSpawnedAsReference then
      //If referenced, remove from list to keep it from being freed below
      RemoveList[I]:=nil;
  end;
  //Emtpy removelist, instances are freed
  RemoveList.Clear;
end;

{ TRemoveModel }

procedure TRemoveModel.Execute;
begin
  {$ifndef minimal}
  AssertNotRenderMode;
  {$endif}
  ZApp.Models.Remove( Meshes.CurrentModel );
end;

{ TRemoveAllModels }

procedure TRemoveAllModels.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'OfType',{$ENDIF}integer(@OfType), zptComponentRef);
    {$ifndef minimal}List.GetLast.SetChildClasses([TModel]);{$endif}
end;

procedure TRemoveAllModels.Execute;
var
  I : integer;
  List : TZArrayList;
  M : TModel;
begin
  {$ifndef minimal}
  AssertNotRenderMode;
  {$endif}

  if OfType=nil then
    ZApp.Models.RemoveAll
  else
  begin
    List := ZApp.Models.Get(OfType.Category);
    for I := 0 to List.Count - 1 do
    begin
      M := TModel(List[I]);
      //todo: all are of same class TModel, should test some other property
      //now all of same category are removed
      //if M is OfType.ClassType then
      ZApp.Models.Remove(M);
    end;
  end;
end;

{$ifndef minimal}
function TRemoveAllModels.GetDisplayName: AnsiString;
begin
  Result := inherited GetDisplayName;
  if Assigned(OfType) then
    Result := Result + ' of type ' + OfType.Name;
end;
{$endif}

{ TSetModelState }

procedure TSetModelState.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'State',{$ENDIF}integer(@State), zptComponentRef);
    {$ifndef minimal}List.GetLast.SetChildClasses([TModelState]);{$endif}
end;

procedure TSetModelState.Execute;
var
  OldState : TModelState;
begin
  {$ifndef minimal}if (State=nil) or (CurrentModel=nil) then Exit;{$endif}
  OldState := CurrentModel.CurrentState;
  CurrentModel.CurrentState := State;
  if OldState<>nil then
    OldState.OnLeave.ExecuteCommands;
  State.OnStart.ExecuteCommands;
end;

{$ifndef minimal}
function TSetModelState.GetDisplayName: AnsiString;
begin
  Result := inherited GetDisplayName;
  if Assigned(State) then
    Result := Result + '  ' + State.Name;
end;
{$endif}


{ TModelState }

procedure TModelState.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'OnCollision',{$ENDIF}integer(@OnCollision), zptComponentList);
end;

{ TMeshBox }

procedure TMeshBox.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'XCount',{$ENDIF}integer(@XCount), zptInteger);
  List.AddProperty({$IFNDEF MINIMAL}'YCount',{$ENDIF}integer(@YCount), zptInteger);
  List.AddProperty({$IFNDEF MINIMAL}'Grid2DOnly',{$ENDIF}integer(@Grid2DOnly), zptBoolean);
end;

procedure TMeshBox.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  Mesh,SrcMesh : TMesh;
  VertP : PZVector3f;
  TexP : PZVector2f;
  IndP : PMeshVertexIndex;
  M,DefaultM,RotM : TZMatrix4f;
  IndOffset,I : integer;

  procedure InCopyTransform;
  var
    I : integer;
    SrcVP : PZVector3f;
    SrcIndP : PMeshVertexIndex;
  begin
    SrcVP := pointer(SrcMesh.Vertices);
    for I := 0 to SrcMesh.VerticesCount - 1 do
    begin
      VectorTransform(SrcVP^,M,VertP^);
      Inc(VertP);
      Inc(SrcVP);
    end;
    SrcIndP := pointer(SrcMesh.Indices);
    for I := 0 to SrcMesh.IndicesCount - 1 do
    begin
      IndP^ := SrcIndP^ + IndOffset;
      Inc(IndP);
      Inc(SrcIndP);
    end;
    Inc(IndOffset,SrcMesh.VerticesCount);
    Move(SrcMesh.TexCoords^,TexP^,SrcMesh.VerticesCount * SizeOf(TZVector2f));
    Inc(TexP,SrcMesh.VerticesCount);
  end;

begin
  Mesh := TMesh.Create(nil);
  Mesh.Style := msTris;

  if Grid2DOnly then
  begin
    //Create a simple 2d-grid
    Mesh.MakeNet(Self.XCount,Self.YCount);
    Mesh.Scale(Vector3f(2,2,1));
  end else
  begin
    SrcMesh := TMesh.Create(nil);
    SrcMesh.MakeNet( Self.XCount ,Self.YCount );

    Mesh.CreateData( (SrcMesh.VerticesCount) * 6,(SrcMesh.IndicesCount*6) div 3,True);

    VertP := pointer(Mesh.Vertices);
    TexP := pointer(Mesh.TexCoords);
    IndP := pointer(Mesh.Indices);

    IndOffset := 0;

    //MakeNet g�r ett n�t -0.5 till 0.5
    //�ka till -1 .. 1, samt flytta fram mot kameran
    CreateScaleAndTranslationMatrix(
      Vector3f(2,2,1),
      Vector3f(0,0,1),
      DefaultM);

    //Sides
    for I := 0 to 3  do
    begin
      CreateRotationMatrixY( (PI/2)*I ,RotM);
      M := MatrixMultiply(DefaultM,RotM);
      InCopyTransform;
    end;

    //Top and bottom
    for I := 0 to 1  do
    begin
      CreateRotationMatrixX( (PI/2) * (-1.0 + I*2) ,RotM);
      M := MatrixMultiply(DefaultM,RotM);
      InCopyTransform;
    end;

    SrcMesh.Free;
  end;

  Mesh.Scale( Self.Scale );
  Mesh.ComputeNormals;

  Stack.Push(Mesh);
end;

{ TMeshImport }

procedure TMeshImport.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'MeshData',{$ENDIF}integer(@MeshData), zptBinary);
  List.AddProperty({$IFNDEF MINIMAL}'HasVertexColors',{$ENDIF}integer(@HasVertexColors), zptBoolean);
  List.AddProperty({$IFNDEF MINIMAL}'HasTextureCoords',{$ENDIF}integer(@HasTextureCoords), zptBoolean);
end;

procedure TMeshImport.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  Mesh : TMesh;
  VertP : PZVector3f;
  PrevIndP,IndP : PMeshVertexIndex;
  I,J : integer;
  Stream : TZInputStream;
  TriCount,VertCount : integer;
  MinV,DiffV : TZVector3f;
  W : word;
  Sm,Sm2 : smallint;
  PColor : PMeshVertexColor;
  PTex : PZVector2f;
begin
  Stream := TZInputStream.CreateFromMemory(MeshData.Data,MeshData.Size);

  Stream.Read(VertCount,4);
  Stream.Read(TriCount,4);

  Mesh := TMesh.Create(nil);
  Mesh.Style := msTris;
  Mesh.CreateData( VertCount,TriCount, Self.HasTextureCoords, Self.HasVertexColors);

  Stream.Read(MinV,3*4);
  Stream.Read(DiffV,3*4);

  //Vertices
  VertP := pointer(Mesh.Vertices);
  for I := 0 to VertCount - 1 do
  begin
    for J := 0 to 2 do
    begin
      Stream.Read(W,2);
      VertP^[J] := W / High(Word);
    end;
    VecMult3(VertP^,DiffV);
    VecAdd3(VertP^,MinV,VertP^);
    Inc(VertP);
  end;

  //Indices
  IndP := pointer(Mesh.Indices);
  PrevIndP := IndP;
  {$if sizeof(TMeshVertexIndex)=2}
  Stream.Read(IndP^,2*3);
  Inc(IndP,3);
  {$else}
  for I := 0 to 2 do
  begin
    Stream.Read(Sm,2);
    IndP^:=Sm;
    Inc(IndP);
  end;
  {$ifend}
  for I := 0 to ((TriCount-1)*3)-1 do
  begin
    Stream.Read(Sm,2);
    IndP^ := PrevIndP^ + Sm;
    Inc(IndP);
    Inc(PrevIndP);
  end;

  //Vertex colors
  if Self.HasVertexColors then
  begin
    PColor := PMeshVertexColor(Mesh.Colors);
    Stream.Read(PColor^,VertCount * 4);
  end;

  //Texture coordinates
  if Self.HasTextureCoords then
  begin
    for J := 0 to 1 do
    begin
      PTex := pointer(Mesh.TexCoords);
      Stream.Read(Sm,2);
      PTex^[J] := Sm / High(Smallint);
      for I := 0 to VertCount-2 do
      begin
        Inc(PTex);
        Stream.Read(Sm2,2);
        Inc(Sm,Sm2);
        PTex^[J] := Sm / High(Smallint);
      end;
    end;

//    Stream.Read(PTex^,VertCount * 8);
  end;

  Mesh.Scale( Self.Scale );
  Mesh.ComputeNormals;

  Stream.Free;

  Stack.Push(Mesh);
end;

{ TMeshCombine }

procedure TMeshCombine.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  M,Mesh1,Mesh2 : TMesh;
  CopyTex,CopyCols : boolean;
  I : integer;
begin
  if Stack.Count<2 then
    Exit;

  Mesh1 := TMesh(Stack.Pop);
  Mesh2 := TMesh(Stack.Pop);

  M := TMesh.Create(nil);

  CopyTex := (Mesh1.TexCoords<>nil) and (Mesh2.TexCoords<>nil);
  CopyCols := (Mesh1.Colors<>nil) or (Mesh2.Colors<>nil);
  M.CreateData(Mesh1.VerticesCount + Mesh2.VerticesCount,
    (Mesh1.IndicesCount + Mesh2.IndicesCount) div 3,
    CopyTex,CopyCols);

  Move(Mesh1.Vertices^,M.Vertices^,Mesh1.VerticesCount * SizeOf(TZVector3f));
  Move(Mesh2.Vertices^,M.Vertices^[Mesh1.VerticesCount],Mesh2.VerticesCount * SizeOf(TZVector3f));

  Move(Mesh1.Normals^,M.Normals^,Mesh1.VerticesCount * SizeOf(TZVector3f));
  Move(Mesh2.Normals^,M.Normals^[Mesh1.VerticesCount],Mesh2.VerticesCount * SizeOf(TZVector3f));

  Move(Mesh1.Indices^,M.Indices^,Mesh1.IndicesCount * SizeOf(TMeshVertexIndex));
  Move(Mesh2.Indices^,M.Indices^[Mesh1.IndicesCount],Mesh2.IndicesCount * SizeOf(TMeshVertexIndex));
  for I := Mesh1.IndicesCount to M.IndicesCount - 1 do
    Inc(M.Indices^[I],Mesh1.VerticesCount);

  if CopyCols then
  begin
    if Mesh1.Colors<>nil then
      Move(Mesh1.Colors^,M.Colors^,Mesh1.VerticesCount * SizeOf(TMeshVertexColor));
    if Mesh2.Colors<>nil then
      Move(Mesh2.Colors^,M.Colors^[Mesh1.VerticesCount],Mesh2.VerticesCount * SizeOf(TMeshVertexColor));
  end;

  if CopyTex then
  begin
    Move(Mesh1.TexCoords^,M.TexCoords^,Mesh1.VerticesCount * SizeOf(TZVector2f));
    Move(Mesh2.TexCoords^,M.TexCoords^[Mesh1.VerticesCount],Mesh2.VerticesCount * SizeOf(TZVector2f));
  end;

  Stack.Push(M);

  Mesh1.Free;
  Mesh2.Free;
end;

{ TMeshLoad }

procedure TMeshLoad.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Mesh',{$ENDIF}integer(@Mesh), zptComponentRef);
    {$ifndef minimal}List.GetLast.SetChildClasses([TMesh]);{$endif}
end;

{$ifndef minimal}
function TMeshLoad.GetDisplayName: AnsiString;
begin
  Result := inherited GetDisplayName;
  if Assigned(Mesh) then
    Result := Result + '  ' + Mesh.Name;
end;
{$endif}

procedure TMeshLoad.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  M : TMesh;
begin
  if Mesh=nil then
    Exit;

  {$ifndef minimal}
  if Mesh=Content then
  begin
    ZLog.GetLog(Self.ClassName).Warning('MeshLoad cannot load itself.');
    Exit;
  end;
  {$endif}

  M := TMesh(Mesh.Clone);
  M.RefreshFromProducers;

  Stack.Push(M);
end;

{ TMeshTransform }

procedure TMeshTransform.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Position',{$ENDIF}integer(@Position), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'Rotation',{$ENDIF}integer(@Rotation), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'Accumulate',{$ENDIF}integer(@Accumulate), zptBoolean);
end;

procedure TMeshTransform.ProduceOutput(Content : TContent; Stack: TZArrayList);
var
  Mesh : TMesh;
begin
  {$ifndef minimal}
  if Stack.Count=0 then exit;
  {$endif}
  Mesh := TMesh(Stack.Pop);

  if not Self.Accumulate then
  begin
    Self.Matrix := IdentityHmgMatrix;
    Self.NormalMatrix := IdentityHmgMatrix;
  end;

  Self.Matrix := MatrixMultiply(CreateTransform(Self.Rotation,Self.Scale,Self.Position),Self.Matrix);
  Self.NormalMatrix := MatrixMultiply(CreateTransform(Self.Rotation,UNIT_XYZ3,Vector3f(0,0,0)),Self.NormalMatrix);

  Mesh.Transform(Matrix,NormalMatrix);

  Stack.Push(Mesh);
end;

{ TMeshLoop }

procedure TMeshLoop.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Count',{$ENDIF}integer(@Count), zptInteger);
  List.AddProperty({$IFNDEF MINIMAL}'RecursionCount',{$ENDIF}integer(@RecursionCount), zptInteger);
  List.AddProperty({$IFNDEF MINIMAL}'OnIteration',{$ENDIF}integer(@OnIteration), zptComponentList);
  List.AddProperty({$IFNDEF MINIMAL}'Iteration',{$ENDIF}integer(@Iteration), zptInteger);
    List.GetLast.NeverPersist:=True;
    {$ifndef minimal}List.GetLast.IsReadOnly := True;{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'Position',{$ENDIF}integer(@Position), zptVector3f);
  List.AddProperty({$IFNDEF MINIMAL}'Rotation',{$ENDIF}integer(@Rotation), zptVector3f);
end;

procedure TMeshLoop.ProduceOutput(Content : TContent; Stack: TZArrayList);
var
  Mesh : TMesh;
  I : integer;
  Matrix,NormalMatrix : TZMatrix4f;
  Combiner : TMeshCombine;
  CombineStack : TZArrayList;
begin
  Matrix := IdentityHmgMatrix;
  NormalMatrix := IdentityHmgMatrix;

  CombineStack := TZArrayList.CreateReferenced;
  Combiner := TMeshCombine.Create(nil);

  Self.Iteration := 0;
  for I := 0 to Count-1 do
  begin

    if (RecursionCount>0) and (Self.Iteration=Count-1) then
    begin
      if TMesh(Content).CurrentRecursion>=RecursionCount then
        Break
      else
      begin
        Mesh := TMesh(Content.Clone);
        Mesh.CurrentRecursion := TMesh(Content).CurrentRecursion + 1;
        Mesh.RefreshFromProducers;
        Stack.Push(Mesh);
      end;
    end else
      OnIteration.ExecuteCommands;

    Inc(Self.Iteration);

    if (I>0) and (Stack.Count>0) then
    begin
      Mesh := TMesh(Stack.Pop);
      Mesh.Transform(Matrix,NormalMatrix);

      if (Stack.Count>0) then
      begin
        CombineStack.Clear;
        CombineStack.Push(Mesh);
        CombineStack.Push(Stack.Pop);
        Combiner.ProduceOutput(nil,CombineStack);
        Mesh := TMesh(CombineStack.Pop);
      end;

      Stack.Push(Mesh);
    end;

    Matrix := MatrixMultiply(CreateTransform(Self.Rotation,Self.Scale,Self.Position),Matrix);
    NormalMatrix := MatrixMultiply(CreateTransform(Self.Rotation,UNIT_XYZ3,Vector3f(0,0,0)),NormalMatrix);
  end;

  CombineStack.Free;
  Combiner.Free;
end;

initialization

  ZClasses.Register(TMesh,MeshClassId);
    {$ifndef minimal}ComponentManager.LastAdded.AutoName := True;{$endif}

  ZClasses.Register(TMeshBox,MeshBoxClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Mesh';{$endif}
  ZClasses.Register(TMeshSphere,MeshSphereClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Mesh';{$endif}
  ZClasses.Register(TMeshNoise,MeshNoiseClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Mesh';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ParamCount := 1;{$endif}
  ZClasses.Register(TMeshExpression,MeshExpressionClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Mesh';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ParamCount := 1;{$endif}
  ZClasses.Register(TMeshImport,MeshImportClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Mesh';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.NoUserCreate := True;{$endif}
  ZClasses.Register(TMeshCombine,MeshCombineClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Mesh';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ParamCount := 2;{$endif}
  ZClasses.Register(TMeshLoad,MeshLoadClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Mesh';{$endif}
  ZClasses.Register(TMeshTransform,MeshTransformClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Mesh';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ParamCount := 1;{$endif}
  ZClasses.Register(TMeshLoop,MeshLoopClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Mesh';{$endif}

  ZClasses.Register(TModel,ModelClassId);
    {$ifndef minimal}ComponentManager.LastAdded.ImageIndex := 13;{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.AutoName := True;{$endif}

  ZClasses.Register(TSpawnModel,SpawnModelClassId);
    {$ifndef minimal}ComponentManager.LastAdded.ImageIndex := 14;{$endif}
  ZClasses.Register(TRemoveModel,RemoveModelClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Model';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ImageIndex := 15;{$endif}
  ZClasses.Register(TRemoveAllModels,RemoveAllModelsClassId);

  ZClasses.Register(TModelState,ModelStateClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Model';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentList := 'States';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.AutoName := True;{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ImageIndex:=19;{$endif}
  ZClasses.Register(TSetModelState,SetModelStateClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Model';{$endif}

end.

