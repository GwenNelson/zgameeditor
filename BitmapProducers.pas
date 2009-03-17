unit BitmapProducers;

interface

uses ZOpenGL, ZClasses, ZExpressions,ZBitmap;

type
  TBitmapRect = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    Color : TZColorf;
    Size : TZRectf;
  end;

  TBitmapZoomRotate = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    Zoom,Rotation,ScaleX,ScaleY : single;
  end;

  TBitmapExpression = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    Expression : TZExpressionPropValue;
    X,Y : single;
    Pixel : TZColorf;
  end;

  TBitmapFromFile = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    BitmapFile : TZBinaryPropValue;
    Transparency : (btNone,btBlackColor,btAlphaLayer);
    HasAlphaLayer : boolean;
  end;

  TBitmapBlur = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    Radius : integer;
  end;

  TBitmapLoad = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    Bitmap : TZBitmap;
    {$ifndef minimal}function GetDisplayName: String; override;{$endif}
  end;

  TBitmapCombine = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    Method : (cmeAdd,cmeSubtract);
    ExcludeAlpha : boolean;
  end;

  TBitmapCells = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    RandomSeed,BorderPixels, NOfPoints : integer;
    CellStyle : (Standard, NiceTwo, NiceOne);
  end;

implementation

uses {$ifdef zlog}ZLog,{$endif} ZMath;

{ TBitmapRect }

procedure TBitmapRect.ProduceOutput(Content : TContent; Stack : TZArrayList);
var
  B : TZBitmap;
  Arg : boolean;
begin
  //one optional argument
  Arg := Stack.Count>0;
  if Arg then
    B := TZBitmap(Stack.Pop())
  else
  begin
    B := TZBitmap.CreateFromBitmap( TZBitmap(Content) );
  end;

  B.RenderTargetBegin;

  if not Arg then
  begin
    //Clear if no source
    glClearColor(0.0,0,0,0.0);
    glClear(GL_COLOR_BUFFER_BIT);
  end;

//    glColor3f(0.0,1.0,0.0);
  glColor3fv(@Color);
  glBegin(GL_QUADS);
    glVertex2f(Size.Left,Size.Top);
    glVertex2f(Size.Left,Size.Bottom);
    glVertex2f(Size.Right,Size.Bottom);
    glVertex2f(Size.Right,Size.Top);
  glEnd();
  glColor3f(1.0,1.0,1.0);

  B.RenderTargetEnd;

  Stack.Push(B);
end;

procedure TBitmapRect.DefineProperties(List: TZPropertyList);
const DefSize = 0.2;
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Color',{$ENDIF}integer(@Color) - integer(Self), zptColorf);
    List.GetLast.DefaultValue.ColorfValue := MakeColorf(0.5,0.5,0.5,1.0);
  List.AddProperty({$IFNDEF MINIMAL}'Size',{$ENDIF}integer(@Size) - integer(Self), zptRectf);
    List.GetLast.DefaultValue.RectfValue := TZRectf(MakeColorf(-DefSize,-DefSize,DefSize,DefSize));
end;

{ TBitmapZoomRotate }

procedure TBitmapZoomRotate.ProduceOutput(Content : TContent; Stack : TZArrayList);
const
  Size = 9;
var
  B,SourceB : TZBitmap;
  TexLeft : single;
  TexTop : single;
  TexRight : single;
  TexBottom : single;
  Z : single;
begin
  //one argument required
  if Stack.Count=0 then
    Exit;
  SourceB := TZBitmap(Stack.Pop());

  B := TZBitmap.CreateFromBitmap( TZBitmap(Content) );

  B.RenderTargetBegin;

  SourceB.UseTextureBegin;

  Z := -Zoom;

  TexLeft := 0 - Z;
  TexRight := Size + Z;
  TexTop := 0 - Z;
  TexBottom := Size + Z;

  //1.0 = one full circle = 360 degrees in opengl
  if Rotation<>0 then
    glRotatef( (Rotation*360) , 0, 0, 1);

  glEnable(GL_TEXTURE_2D);
  glDisable(GL_TEXTURE_GEN_S);
  glDisable(GL_TEXTURE_GEN_T);

  glScalef(ScaleX,ScaleY,1);
  glBegin(GL_QUADS);
    glTexCoord2f(TexLeft, TexTop);
    glVertex2f(-Size,-Size);
    glTexCoord2f(TexLeft, TexBottom);
    glVertex2f(-Size,Size);
    glTexCoord2f(TexRight, TexBottom);
    glVertex2f(Size,Size);
    glTexCoord2f(TexRight, TexTop);
    glVertex2f(Size,-Size);
  glEnd();

//  SourceB.UseTextureEnd;
  SourceB.Free;

  B.RenderTargetEnd;

  Stack.Push(B);
end;

procedure TBitmapZoomRotate.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Zoom',{$ENDIF}integer(@Zoom) - integer(Self), zptFloat);
  List.AddProperty({$IFNDEF MINIMAL}'Rotation',{$ENDIF}integer(@Rotation) - integer(Self), zptFloat);
  List.AddProperty({$IFNDEF MINIMAL}'ScaleX',{$ENDIF}integer(@ScaleX) - integer(Self), zptFloat);
    List.GetLast.DefaultValue.FloatValue := 1.0;
  List.AddProperty({$IFNDEF MINIMAL}'ScaleY',{$ENDIF}integer(@ScaleY) - integer(Self), zptFloat);
    List.GetLast.DefaultValue.FloatValue := 1.0;
end;

{ TBitmapExpression }

procedure TBitmapExpression.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Expression',{$ENDIF}integer(@Expression) - integer(Self), zptExpression);
    {$ifndef minimal}
    List.GetLast.DefaultValue.ExpressionValue.Source :=
      '//X,Y : current coordinate (0..1)'#13#10 +
      '//Pixel : current color (rgb)';
    {$endif}
  List.AddProperty({$IFNDEF MINIMAL}'X',{$ENDIF}integer(@X) - integer(Self), zptFloat);
    List.GetLast.NeverPersist := True;
    {$ifndef minimal}List.GetLast.IsReadOnly := True;{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'Y',{$ENDIF}integer(@Y) - integer(Self), zptFloat);
    List.GetLast.NeverPersist := True;
    {$ifndef minimal}List.GetLast.IsReadOnly := True;{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'Pixel',{$ENDIF}integer(@Pixel) - integer(Self), zptColorf);
    List.GetLast.NeverPersist := True;
end;

procedure TBitmapExpression.ProduceOutput(Content : TContent; Stack: TZArrayList);
var
  SourceB,B : TZBitmap;
  H,W,I,J : integer;
  Pixels,P : PColorf;
  XStep,YStep : single;
begin
  if Stack.Count>0 then
  begin
    SourceB := TZBitmap(Stack.Pop());
    B := TZBitmap.CreateFromBitmap( SourceB );
    Pixels := SourceB.GetCopyAsFloats;
    SourceB.Free;
  end
  else
  begin
    B := TZBitmap.CreateFromBitmap( TZBitmap(Content) );
    Pixels := nil;
  end;

  W := B.PixelWidth;
  H := B.PixelHeight;

  if Pixels=nil then
  begin
    GetMem(Pixels,W * H * Sizeof(Pixel) );
    FillChar(Pixels^,W * H * Sizeof(Pixel),0);
  end;

  B.SetMemory(Pixels,GL_RGBA,GL_FLOAT);

  P := Pixels;
  Y := 0;
  XStep := 1/W;
  YStep := 1/H;
  for I := 0 to H-1 do
  begin
    X := 0;
    for J := 0 to W-1 do
    begin
      Pixel := P^;
      ZExpressions.RunCode(Expression.Code);
      P^ := Pixel;
      Inc(P);
      X := X + XStep;
    end;
    Y := Y + YStep;
  end;

  //Needed to send the bitmap to opengl
  B.UseTextureBegin;
//  B.UseTextureEnd;

  FreeMem(Pixels);

  Stack.Push(B);
end;

{ TBitmapFromFile }

procedure TBitmapFromFile.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'BitmapFile',{$ENDIF}integer(@BitmapFile) - integer(Self), zptBinary);
  List.AddProperty({$IFNDEF MINIMAL}'Transparency',{$ENDIF}integer(@Transparency) - integer(Self), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['None','BlackColor','AlphaLayer']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'HasAlphaLayer',{$ENDIF}integer(@HasAlphaLayer) - integer(Self), zptBoolean);
    {$ifndef minimal}List.GetLast.IsReadOnly := True;{$endif}
end;

procedure TBitmapFromFile.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  BM : TZBitmap;
  SP,DP,Mem : PByte;
  IsTransparent : boolean;
  PixelCount,Pixel : integer;
  I: Integer;
  B : byte;
begin
  BM := TZBitmap.CreateFromBitmap( TZBitmap(Content) );
  Mem := nil;

  PixelCount := BM.PixelWidth*BM.PixelHeight;

  {$ifndef minimal}
  if BitmapFile.Size<(PixelCount*3) then
  begin
    BM.Free;
    Exit;
  end;
  {$endif}

  //Ifall det beh�vs format och storleksdata om bitmappen
  //s� kan man l�gga till properties senare.

  IsTransparent := Transparency<>btNone;
  if IsTransparent or HasAlphaLayer then
  begin
    GetMem(Mem,PixelCount*4);
    SP := BitmapFile.Data;
    DP := Mem;
    Pixel := 0;
    for I := 0 to (PixelCount*3) - 1 do
    begin
      B := SP^;
      DP^ := B;
      Inc(Pixel,B);
      Inc(SP);
      Inc(DP);
      if (I mod 3)=2 then
      begin
        case Transparency of
          btBlackColor :
            if Pixel=0 then
              DP^ := 0
            else
              DP^ := High(Byte);
          btAlphaLayer :
            begin
              DP^ := SP^;
            end;
        end;
        if HasAlphaLayer then
          Inc(SP);
        Inc(DP);
        Pixel := 0;
      end;
    end;
    BM.SetMemory(Mem,GL_RGBA,GL_UNSIGNED_BYTE);
  end else
  begin
    BM.SetMemory(BitmapFile.Data,GL_RGB,GL_UNSIGNED_BYTE);
  end;

  //Needed to send the bitmap to opengl
  BM.UseTextureBegin;
//  BM.UseTextureEnd;

  if Mem<>nil then
    FreeMem(Mem);

  Stack.Push(BM);
end;

{ TBitmapBlur }

procedure TBitmapBlur.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Radius',{$ENDIF}integer(@Radius) - integer(Self), zptInteger);
end;

procedure TBitmapBlur.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  SourceB,B : TZBitmap;
  H,W,I,J,K,L : integer;
  SourceP,DestP : PColorf;
  Tot : TZVector3f;
  P : PZVector3f;

  procedure InAdd(X,Y:integer);
  var
    Tmp : PZVector4f;
  begin
    if (X<0) then
      X:=0
    else if (X>W-1) then
      X := W-1;
    if Y<0 then
      Y := 0
    else if (Y>H-1) then
      Y := H-1;
    Tmp := PZVector4f(SourceP);
    Inc(Tmp, Y*W + X);
    VecAdd3(PZVector3f(Tmp)^,Tot,Tot)
  end;

begin
  if Stack.Count=0 then
    Exit;

  SourceB := TZBitmap(Stack.Pop());
  B := TZBitmap.CreateFromBitmap( SourceB );
  SourceP := SourceB.GetCopyAsFloats;
  SourceB.Free;

  W := B.PixelWidth;
  H := B.PixelHeight;

  GetMem(DestP,SizeOf(TZVector3f)*W*H);
  B.SetMemory(DestP,GL_RGB,GL_FLOAT);

  //Reference: http://www.blackpawn.com/texts/blur/default.html
  P := PZVector3f(DestP);
  for I := 0 to H-1 do
  begin
    for J := 0 to W-1 do
    begin
      FillChar(Tot,SizeOf(Tot),0);
      for K := -Radius to Radius do
        for L := -Radius to Radius do
          InAdd(J+K,I + L);
      VecDiv3(Tot, Power(Radius*2+1,2),P^);
      Inc(P);
    end;
  end;

  //Needed to send the bitmap to opengl
  B.UseTextureBegin;

  FreeMem(SourceP);
  FreeMem(DestP);

  Stack.Push(B);
end;

{ TBitmapLoad }

procedure TBitmapLoad.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Bitmap',{$ENDIF}integer(@Bitmap) - integer(Self), zptComponentRef);
    {$ifndef minimal}List.GetLast.SetChildClasses([TZBitmap]);{$endif}
end;

{$ifndef minimal}
function TBitmapLoad.GetDisplayName: String;
begin
  Result := inherited GetDisplayName;
  if Assigned(Bitmap) then
    Result := Result + '  ' + Bitmap.Name;
end;
{$endif}

procedure TBitmapLoad.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  B : TZBitmap;
  Pixels : pointer;
begin
  if Bitmap=nil then
    Exit;
  {$ifndef minimal}
  if (Bitmap.PixelWidth<>TZBitmap(Content).PixelWidth) or
     (Bitmap.PixelHeight<>TZBitmap(Content).PixelHeight) then
  begin
    ZLog.GetLog(Self.ClassName).Write('Bitmap size must match target.');
    Exit;
  end;
  {$endif}

  B := TZBitmap.CreateFromBitmap(TZBitmap(Content));

  Pixels := Bitmap.GetCopyAsFloats;

  B.SetMemory(Pixels,GL_RGBA,GL_FLOAT);

  //Needed to send the bitmap to opengl
  B.UseTextureBegin;

  FreeMem(Pixels);

  Stack.Push(B);
end;

{ TBitmapCombine }

procedure TBitmapCombine.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Method',{$ENDIF}integer(@Method) - integer(Self), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['Add','Subtract']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'ExcludeAlpha',{$ENDIF}integer(@ExcludeAlpha) - integer(Self), zptBoolean);
end;

procedure TBitmapCombine.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  B,B1,B2 : TZBitmap;
  Data1,Data2,P1,P2 : PColorf;
  I,J,EndI : integer;
begin
  if Stack.Count<2 then
    Exit;

  B2 := TZBitmap(Stack.Pop());
  B1 := TZBitmap(Stack.Pop());

  {$ifndef minimal}
  if (B1.PixelWidth<>B2.PixelWidth) or
     (B1.PixelHeight<>B2.PixelHeight) then
  begin
    ZLog.GetLog(Self.ClassName).Write('Bitmap sizes must match.');
    Exit;
  end;
  {$endif}

  B := TZBitmap.CreateFromBitmap(TZBitmap(Content));

  Data1 := B1.GetCopyAsFloats;
  Data2 := B2.GetCopyAsFloats;

  P1 := Data1;
  P2 := Data2;

  if Self.ExcludeAlpha then
    EndI := 2
  else
    EndI := 3;

  for I := 0 to B1.PixelWidth*B1.PixelHeight-1 do
  begin
    case Method of
      cmeAdd :
        begin
          for J := 0 to EndI do
            P2^.V[J] := Clamp(P1^.V[J] + P2^.V[J],0,1);
        end;
      cmeSubtract :
        begin
          for J := 0 to EndI do
            P2^.V[J] := Clamp(P1^.V[J] - P2^.V[J],0,1);
        end;
    end;
    Inc(P1);
    Inc(P2);
  end;

  B.SetMemory(Data2,GL_RGBA,GL_FLOAT);

  //Needed to send the bitmap to opengl
  B.UseTextureBegin;

  FreeMem(Data1);
  FreeMem(Data2);

  B1.Free;
  B2.Free;

  Stack.Push(B);
end;

{ TBitmapCells }

function MinVal(A, B : Integer) : Integer;
begin
  // Return the lowest of 2 numbers
  if A < B
  then Result := A
  else Result := B;
end;

procedure TBitmapCells.ProduceOutput(Content : TContent; Stack : TZArrayList);
type
  PValueRecord = ^TValueRecord;
  TValueRecord =
    record
      DistFromCenter, CPIndex : integer;
    end;
var
  B : TZBitmap;
  H,W,I,J,K,MinDist,Dist,SaveSeed,PixelCount : integer;
  Pixels,P : PColorf;
  Pixel : TZColorf;
  ValueBuffer,Value : PValueRecord;
  CP : array[0..24] of
    record
      //Central points
      X,Y,R,G,B,MaxDist : integer;
    end;
begin

  {$ifndef minimal}
  ZLog.GetLog(Self.ClassName).BeginTimer;
  {$endif}


  B := TZBitmap.CreateFromBitmap( TZBitmap(Content) );

  W := B.PixelWidth;
  H := B.PixelHeight;
  PixelCount := W*H;

  GetMem(Pixels,PixelCount * Sizeof(Pixel) );
  GetMem(ValueBuffer,PixelCount * SizeOf(TValueRecord));
  FillChar(ValueBuffer^,PixelCount * SizeOf(TValueRecord),0);

  B.SetMemory(Pixels,GL_RGBA,GL_FLOAT);

  SaveSeed := RandSeed;
  RandSeed := Self.RandomSeed;
  for I := 0 to MinVal(24, NOfPoints-1) do
  begin
    CP[I].Y := Random(H);
    CP[I].X := Random(W);
    CP[I].R := Random(5)*64;
    CP[I].G := Random(5)*64;
    CP[I].B := Random(5)*64;
    CP[I].MaxDist := 0;
  end;


  //For now, only "Computes" the pixels;

  Value := ValueBuffer;
  for I := 0 to H-1 do    //I is height (Y)!
  begin
    for J := 0 to W-1 do  //J is width (X)!
    begin
      MinDist := (J-1)*(J-1)+(H-1)*(H-1);

      for K := 0 to MinVal(24, NOfPoints-1) do
      begin
        Dist := (I-CP[K].Y)*(I-CP[K].Y) + (J-CP[K].X)*(J-CP[K].X);

        Dist := MinVal(Dist, (J+W-CP[K].X)*(J+W-CP[K].X) + (I-CP[K].Y)*(I-CP[K].Y));
        Dist := MinVal(Dist, (J-W-CP[K].X)*(J-W-CP[K].X) + (I-CP[K].Y)*(I-CP[K].Y));
        Dist := MinVal(Dist, (J-CP[K].X)*(J-CP[K].X) + (I+H-CP[K].Y)*(I+H-CP[K].Y));
        Dist := MinVal(Dist, (J-CP[K].X)*(J-CP[K].X) + (I-H-CP[K].Y)*(I-H-CP[K].Y));
        Dist := MinVal(Dist, (J+W-CP[K].X)*(J+W-CP[K].X) + (I+H-CP[K].Y)*(I+H-CP[K].Y));
        Dist := MinVal(Dist, (J+W-CP[K].X)*(J+W-CP[K].X) + (I-H-CP[K].Y)*(I-H-CP[K].Y));
        Dist := MinVal(Dist, (J-W-CP[K].X)*(J-W-CP[K].X) + (I+H-CP[K].Y)*(I+H-CP[K].Y));
        Dist := MinVal(Dist, (J-W-CP[K].X)*(J-W-CP[K].X) + (I-H-CP[K].Y)*(I-H-CP[K].Y));

        if Dist < MinDist then //if we found a new Minimal Distance:
        begin
          MinDist := Dist;
          Value.DistFromCenter := Dist;
          Value.CPIndex := K;
        end;
      end; //For K

      //now we know at what K our pixel belongs, seek the maxdist of the K-nth space!
      if (Value.DistFromCenter > CP[Value.CPIndex].MaxDist) then
         CP[Value.CPIndex].MaxDist := Value.DistFromCenter;

      Inc(Value);
    end; //For J
  end; //For I

//Now use the pre-calculated values to do something
  P := Pixels;
  Value := ValueBuffer;
  for I := 0 to H-1 do    //I is height (Y)!
  begin
    for J := 0 to W-1 do  //J is width (X)!
    begin
      //I use K and Dist as a temp variable for optimization
      K := Value.CPIndex;
      Dist := Value.DistFromCenter;
//Several kinds of processing
      if (CellStyle = Standard)  then //standard/coloured with no borders
      begin
        Pixel.R := CP[K].R/256.0;
        Pixel.G := CP[K].G/256.0;
        Pixel.B := CP[K].B/256.0;
        Pixel.A := 1;
      end;
      //Dunno if you do prefere the "if -> else -> else chain"
      //personally I'm fine with the if/end, if/end blocks. Feel free to modify this!
      if (CellStyle = NiceOne) or (CellStyle = NiceTwo) then   //Nice effect number 1
      begin
        Pixel.R := sqrt(Dist)/sqrt(CP[K].MaxDist);
        Pixel.G := Pixel.R;
        Pixel.B := Pixel.G;
      end;

      //DEBUG: INVERT COLORS
      if (CellStyle = NiceOne) then
      begin
        Pixel.R := 0.75- Pixel.R/2.0;
        Pixel.G := Pixel.R; //0.75-Pixel.G/2.0;
        Pixel.B := Pixel.G; //0.75-Pixel.B/2.0;
      end;

      P^ := Pixel;
      Inc(P);
      Inc(Value);
    end;
  end;

  RandSeed := SaveSeed;

  //Needed to send the bitmap to opengl
  B.UseTextureBegin;

  FreeMem(Pixels);
  FreeMem(ValueBuffer);

  Stack.Push(B);

  {$ifndef minimal}
  ZLog.GetLog(Self.ClassName).EndTimer('Cell refresh time');
  {$endif}
end;

procedure TBitmapCells.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'CellStyle',{$ENDIF}integer(@CellStyle) - integer(Self), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['Standard','Nice style','Freakin nice style']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'RandomSeed',{$ENDIF}integer(@RandomSeed) - integer(Self), zptInteger);
  List.AddProperty({$IFNDEF MINIMAL}'BorderPixels',{$ENDIF}integer(@BorderPixels) - integer(Self), zptInteger);
    List.GetLast.DefaultValue.IntegerValue := 3;
  List.AddProperty({$IFNDEF MINIMAL}'PointCount',{$ENDIF}integer(@NOfPoints) - integer(Self), zptInteger);
    List.GetLast.DefaultValue.IntegerValue := 10;
end;


initialization

  ZClasses.Register(TBitmapRect,BitmapRectClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
  ZClasses.Register(TBitmapZoomRotate,BitmapZoomRotateClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
  ZClasses.Register(TBitmapExpression,BitmapExpressionClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
  ZClasses.Register(TBitmapFromFile,BitmapFromFileClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
  ZClasses.Register(TBitmapBlur,BitmapBlurClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
  ZClasses.Register(TBitmapLoad,BitmapLoadClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
  ZClasses.Register(TBitmapCombine,BitmapCombineClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
  ZClasses.Register(TBitmapCells,BitmapCellsClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}

end.