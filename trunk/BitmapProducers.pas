unit BitmapProducers;

interface

uses ZOpenGL, ZClasses, ZExpressions,ZBitmap;


type
  TBitmapProducerWithOptionalArgument  = class(TContentProducer)
  private
    function GetOptionalArgument(Stack : TZArrayList): TZBitmap;
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    UseBlankSource : boolean;
  end;

  TBitmapRect = class(TBitmapProducerWithOptionalArgument)
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

  TBitmapExpression = class(TBitmapProducerWithOptionalArgument)
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
    Amplify : single;
    Kind : (bkiSquare,bkiTriangle,bkiGaussian,bkiCorners);
    BlurDirection : (bdBoth, bdVertical, bdHorizontal);
  end;

  TBitmapLoad = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    Bitmap : TZBitmap;
    {$ifndef minimal}function GetDisplayName: AnsiString; override;{$endif}
  end;

  TBitmapCombine = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    Method : (cmeAdd,cmeSubtract,cmeMultiply);
    ExcludeAlpha : boolean;
  end;

  TBitmapCells = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    RandomSeed,BorderPixels, NOfPoints : integer;
    CellStyle : (cstStandard, cstNice1, cstTG1, cstTG2, cstTG3, cstWerk);
    PlacementStyle : (pstRandom, pstHoneycomb, pstSquares, pstUnregularSquares);
    UsedMetrics: (mtrEuclidean, mtrManhattan, mtrMaxMin, mtrProduct, mtrStripes);
  end;

  TBitmapDistort = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    Amount : single;
  end;

  TBitmapPixels = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    RandomSeed, NOfPoints, Color : integer;
  end;

  TBitmapConvolution = class(TContentProducer)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); override;
  public
    ConvArray : TDefineArray;
    SwapDim : boolean;
    Divisor, Bias : single;
  end;


implementation

uses {$ifdef zlog}ZLog,{$endif} ZMath, Renderer;

function GetIncrement(const X,Y,W,H : integer) : integer; inline;
begin
  //Wrap X & Y
  //Use the fact that W & H always are power-of-two values
  Result := (Y and (H-1)) * W + (X and (W-1));
end;

{ TBitmapRect }

procedure TBitmapRect.ProduceOutput(Content : TContent; Stack : TZArrayList);
var
  B : TZBitmap;
  HasArg : boolean;
begin
  //one optional argument
  B := GetOptionalArgument(Stack);
  HasArg := B<>nil;
  if not HasArg then
    B := TZBitmap.CreateFromBitmap( TZBitmap(Content) );

  B.RenderTargetBegin;

  if not HasArg then
  begin
    //Clear if no source
    glClearColor(0.0,0,0,0.0);
    glClear(GL_COLOR_BUFFER_BIT);
  end else
  begin
    //Fill screen with argument first
    glEnable(GL_TEXTURE_2D);
    glDisable(GL_TEXTURE_GEN_S);
    glDisable(GL_TEXTURE_GEN_T);
    B.UseTextureBegin;
    glPushMatrix();
    glScalef(2,2,2);
    RenderUnitQuad;
    glPopMatrix();
    glDisable(GL_TEXTURE_2D);
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
  List.AddProperty({$IFNDEF MINIMAL}'Color',{$ENDIF}integer(@Color), zptColorf);
    List.GetLast.DefaultValue.ColorfValue := MakeColorf(0.5,0.5,0.5,1.0);
  List.AddProperty({$IFNDEF MINIMAL}'Size',{$ENDIF}integer(@Size), zptRectf);
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
  List.AddProperty({$IFNDEF MINIMAL}'Zoom',{$ENDIF}integer(@Zoom), zptFloat);
  List.AddProperty({$IFNDEF MINIMAL}'Rotation',{$ENDIF}integer(@Rotation), zptFloat);
  List.AddProperty({$IFNDEF MINIMAL}'ScaleX',{$ENDIF}integer(@ScaleX), zptFloat);
    List.GetLast.DefaultValue.FloatValue := 1.0;
  List.AddProperty({$IFNDEF MINIMAL}'ScaleY',{$ENDIF}integer(@ScaleY), zptFloat);
    List.GetLast.DefaultValue.FloatValue := 1.0;
end;

{ TBitmapExpression }

procedure TBitmapExpression.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Expression',{$ENDIF}integer(@Expression), zptExpression);
    {$ifndef minimal}
    List.GetLast.DefaultValue.ExpressionValue.Source :=
      '//X,Y : current coordinate (0..1)'#13#10 +
      '//Pixel : current color (rgb)';
    {$endif}
  List.AddProperty({$IFNDEF MINIMAL}'X',{$ENDIF}integer(@X), zptFloat);
    List.GetLast.NeverPersist := True;
    {$ifndef minimal}List.GetLast.IsReadOnly := True;{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'Y',{$ENDIF}integer(@Y), zptFloat);
    List.GetLast.NeverPersist := True;
    {$ifndef minimal}List.GetLast.IsReadOnly := True;{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'Pixel',{$ENDIF}integer(@Pixel), zptColorf);
    List.GetLast.NeverPersist := True;
end;

procedure TBitmapExpression.ProduceOutput(Content : TContent; Stack: TZArrayList);
var
  SourceB,B : TZBitmap;
  H,W,I,J : integer;
  Pixels,P : PColorf;
  XStep,YStep : single;
begin
  SourceB := GetOptionalArgument(Stack);
  if SourceB<>nil then
  begin
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
  List.AddProperty({$IFNDEF MINIMAL}'BitmapFile',{$ENDIF}integer(@BitmapFile), zptBinary);
  List.AddProperty({$IFNDEF MINIMAL}'Transparency',{$ENDIF}integer(@Transparency), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['None','BlackColor','AlphaLayer']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'HasAlphaLayer',{$ENDIF}integer(@HasAlphaLayer), zptBoolean);
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

{ Convolution }

procedure ConvolveImage(SourceP, DestP: PColorf;ImageW, ImageH : integer; ConvMatrix : PFloat; ConvW,ConvH : integer; TmpDiv, Bias : single);
var
  Tot : TZVector3f;
  P,Tmp : PZVector3f;
  M : PFloat;
  I,J,K,L : integer;
  XBound,YBound : integer;
begin

  XBound := (ConvW-1) div 2;
  YBound := (ConvH-1) div 2;
  P := PZVector3f(DestP);
  for I := 0 to ImageH-1 do
    for J := 0 to ImageW-1 do
    begin
      FillChar(Tot,SizeOf(Tot),0);
      M := ConvMatrix;
      for L := -(YBound) to YBound do
        for K := -(XBound) to XBound do
        begin
          Tmp := PZVector3f(SourceP);
          Inc(Tmp, GetIncrement(J+K,I+L,ImageW,ImageH));
          Tot[0] := Tot[0] + Tmp^[0]*M^;
          Tot[1] := Tot[1] + Tmp^[1]*M^;
          Tot[2] := Tot[2] + Tmp^[2]*M^;
          Inc(M);
        end;
      VecDiv3(Tot, TmpDiv, P^);
      P^[0] := P^[0] + Bias;
      P^[1] := P^[1] + Bias;
      P^[2] := P^[2] + Bias;

      Inc(P);
    end;  //for J (the I cycle has no begin-end block)

end;

{ TBitmapBlur }

procedure TBitmapBlur.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Radius',{$ENDIF}integer(@Radius), zptInteger);
  List.AddProperty({$IFNDEF MINIMAL}'Amplify',{$ENDIF}integer(@Amplify), zptFloat);
    List.GetLast.DefaultValue.FloatValue := 1.0;
  List.AddProperty({$IFNDEF MINIMAL}'Kind',{$ENDIF}integer(@Kind), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['Square','Triangle','Gaussian', 'Corners']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'BlurDirection',{$ENDIF}integer(@BlurDirection), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['BothDirections','VerticalOnly','HorizontalOnly']);{$endif}
end;

procedure TBitmapBlur.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  SourceB,B : TZBitmap;
  H,W,N : integer;
  SourceP,DestP : PColorf;
  TmpDiv : single;
  SizeBytes : integer;
  ConvMatrix : PFloat;
  ConvTmp : PFloat;
  ConvW, ConvH : integer;
begin
  if Stack.Count=0 then
    Exit;

  SourceB := TZBitmap(Stack.Pop());
  B := TZBitmap.CreateFromBitmap( SourceB );
  SourceP := SourceB.GetCopyAs3f;
  SourceB.Free;

  W := B.PixelWidth;
  H := B.PixelHeight;

  SizeBytes := SizeOf(TZVector3f)*W*H;
  GetMem(DestP,SizeBytes);
  B.SetMemory(DestP,GL_RGB,GL_FLOAT);

  GetMem(ConvMatrix,SizeOf(single)*(Radius*2+1));
  ConvTmp := ConvMatrix;
  TmpDiv := 0;

  for N := -Radius to Radius do
  begin
    case Kind of
      bkiSquare: ConvTmp^ := 1;
      bkiTriangle: ConvTmp^ := Radius - abs(N);
      bkiGaussian: ConvTmp^ := Power(2.71, -(N*N)/(0.2*Radius*Radius));
      bkiCorners: ConvTmp^ := abs(N);
    end;
    TmpDiv := TmpDiv + ConvTmp^;
    Inc(ConvTmp);
  end; //FOR N
  TmpDiv := TmpDiv/Amplify;

  case BlurDirection of
    bdBoth:
      begin
        ConvH := Radius*2+1;
        ConvW := 1;
        ConvolveImage(SourceP, DestP, W, H, ConvMatrix, ConvW, ConvH, TmpDiv, 0);
        Move(DestP^,SourceP^,SizeBytes);
        ConvW := Radius*2+1;
        ConvH := 1;
      end;
    bdVertical:
      begin
        ConvW := 1;
        ConvH := Radius*2+1;
      end;
    else //bdHorizontal:
      begin
        ConvW := Radius*2+1;
        ConvH := 1;
      end;
  end;

  ConvolveImage(SourceP, DestP, W, H, ConvMatrix, ConvW, ConvH, TmpDiv, 0);

  //Needed to send the bitmap to opengl
  B.UseTextureBegin;

  FreeMem(SourceP);
  FreeMem(DestP);
  FreeMem(ConvMatrix);

  Stack.Push(B);
end;

{ TBitmapLoad }

procedure TBitmapLoad.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Bitmap',{$ENDIF}integer(@Bitmap), zptComponentRef);
    {$ifndef minimal}List.GetLast.SetChildClasses([TZBitmap]);{$endif}
end;

{$ifndef minimal}
function TBitmapLoad.GetDisplayName: AnsiString;
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
    ZLog.GetLog(Self.ClassName).Warning('Bitmap size must match target.');
    Exit;
  end;
  if Bitmap=Content then
  begin
    ZLog.GetLog(Self.ClassName).Warning('BitmapLoad cannot load itself.');
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
  List.AddProperty({$IFNDEF MINIMAL}'Method',{$ENDIF}integer(@Method), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['Add','Subtract','Multiply']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'ExcludeAlpha',{$ENDIF}integer(@ExcludeAlpha), zptBoolean);
end;

procedure TBitmapCombine.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  B,B1,B2 : TZBitmap;
  Data1,Data2,P1,P2 : PColorf;
  I,J,EndI : integer;
begin
  if Stack.Count<2 then
    Exit;

  B1 := TZBitmap(Stack.Pop());
  B2 := TZBitmap(Stack.Pop());

  {$ifndef minimal}
  if (B1.PixelWidth<>B2.PixelWidth) or
     (B1.PixelHeight<>B2.PixelHeight) then
  begin
    ZLog.GetLog(Self.ClassName).Warning('Bitmap sizes must match.');
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
      cmeMultiply:
        begin
           for J := 0 to EndI do
             P2^.V[J] := P1^.V[J] * P2^.V[J];
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

procedure TBitmapCells.ProduceOutput(Content : TContent; Stack : TZArrayList);
const
  MaxPoints = 64;
type
  PValueRecord = ^TValueRecord;
  TValueRecord =
    record
      DistFromCenter, DistSecondCenter, CPIndex, CPSecondIndex : integer;
    end;
var
  B : TZBitmap;
  IsBorder, IsSecondBorder : Boolean;
  H,W,I,J,K,Dist,SaveSeed,PixelCount,GlobalMax,XDist,YDist,NOfPointsCopy : integer;
  YIsNegative : integer; //used with the "Strip" style, used integer to avoid boolean conversion (if any)
  Pixels : PColorf;
  Pixel : PColorf;
  ValueBuffer,Value,Value2 : PValueRecord;
  PointIndexes : array[0..3] of
    record
      Increment, CPIndex, CPSecondIndex : integer;
    end;

  CP : array[0..MaxPoints-1] of
    record
      //Central points
      X,Y,MaxDist : integer;
      R,G,B : single;
    end;

begin
  B := TZBitmap.CreateFromBitmap( TZBitmap(Content) );

  W := B.PixelWidth;
  H := B.PixelHeight;
  PixelCount := W*H;

  GetMem(Pixels,PixelCount * Sizeof(TZColorf) );
  GetMem(ValueBuffer,PixelCount * SizeOf(TValueRecord));
  FillChar(ValueBuffer^,PixelCount * SizeOf(TValueRecord),0);

  B.SetMemory(Pixels,GL_RGBA,GL_FLOAT);

  SaveSeed := RandSeed;
  RandSeed := Self.RandomSeed;

  //I started using the break command in order to avoid the needing of that
  //MinVal function (previously I used it in the wrapping code, now it's unnecessary

  //Since with the presets I currenlty SET the NOfPoints (but this screws up things
  //also in the editor) I locally use a copy of the NOfPoints value.
  NOfPointsCopy := NOfPoints;
  for I := 0 to MaxPoints-1 do
  begin
    if I >= NOfPointsCopy then Break;

    case PlacementStyle of
      pstRandom :
        begin
          CP[I].Y := System.Random(H);
          CP[I].X := System.Random(W);
        end;
      pstSquares :
        begin
          K := Round(sqrt(NOfPointsCopy+1));
          CP[I].X := (I div K)*(W div K);
          CP[I].Y := (I mod K)*(H div K);
        end;
      pstUnregularSquares :
        begin
          K := Round(sqrt(NOfPointsCopy+1));
          CP[I].X := System.Random(W);
          CP[I].Y := (I mod K)*(H div K);
        end;
      pstHoneyComb :
        begin
          NOfPointsCopy := 4;
          CP[I].X := (I mod 2) * W div 2;
          CP[I].Y := I*H div 4;
        end;
    end;

    CP[I].R := System.Random;
    CP[I].G := System.Random;
    CP[I].B := System.Random;
    CP[I].MaxDist := 0;
  end;

  //For now, only "Computes" the pixels;

  Value := ValueBuffer;
  GlobalMax := 0;
  Dist := 0;
  for I := 0 to H-1 do    //I is height (Y)!
  begin
    for J := 0 to W-1 do  //J is width (X)!
    begin
      Value.DistFromCenter := 2147483647; //2^31-1
      Value.DistSecondCenter := 2147483647; //2^31-1
      for K := 0 to MaxPoints-1 do
      begin
        if K >= NOfPointsCopy then Break;

        XDist := abs(J-CP[K].X);
        YDist := CP[K].Y-I;
        if (YDist < 0) then YIsNegative := 1 else YIsNegative := 0;
        YDist := abs(YDist);

        if XDist > (W div 2) then
          XDist := W - XDist;
        if YDist > (H div 2) then
        begin
          YDist := H - YDist;
          YIsNegative := not YIsNegative;
        end;
        case UsedMetrics of
          mtrEuclidean: Dist := (XDist)*(XDist) + (YDist)*(YDist);
          mtrManhattan: Dist := XDist+YDist;
          mtrStripes:   Dist := YDist * 2048 + YIsNegative * 1024 + XDist;
          mtrMaxMin:    Dist := abs(XDist-YDist);
          mtrProduct:   Dist := (XDist+2)*(YDist+2);
        end;                      //   ^         ^
                        //it you add a higher constant to the mtrProduct, it will
                        //make the "carved lines" do disappear faster. IMO good
                        //values are the ones from 1 to 4

        if K = 0 then
        begin
          Value.DistFromCenter := Dist;
          Value.CPIndex := K;
        end
        else
        begin
          if Dist < Value.DistFromCenter then //if we found a new Minimal Distance:
          begin
            Value.DistSecondCenter := Value.DistFromCenter; //old min now is new second min
            Value.CPSecondIndex := Value.CPIndex;
            Value.DistFromCenter := Dist;
            Value.CPIndex := K;
          end
          else
          begin
            if Dist < Value.DistSecondCenter then
            begin
              Value.DistSecondCenter := Dist;
              Value.CPSecondIndex := K;
            end; //Found the new second nearest center
          end;
        end; //IF K = 0;
      end; //For K

      //now we know at what K our pixel belongs, seek the maxdist of the K-nth space!
      if (Value.DistFromCenter > CP[Value.CPIndex].MaxDist) then
      begin
        CP[Value.CPIndex].MaxDist := Value.DistFromCenter;

         //If the new distance is the new global max
        if GlobalMax < Value.DistFromCenter then
          GlobalMax := Value.DistFromCenter;
      end;

      Inc(Value);
    end; //For J
  end; //For I

//Now use the pre-calculated values to do something
  Pixel := Pixels;
  Value := ValueBuffer;
  for I := 0 to H-1 do    //I is height (Y)!
  begin
    for J := 0 to W-1 do  //J is width (X)!
    begin
      //Borders code: we do calculate the 4 "adiacent" pixels as an increment from the
      //actual Value pointer

      IsBorder := False;        //default: pixel is not a border one
      IsSecondBorder := False;
      if BorderPixels > 0 then  //I put it >0 because giving negative borders crashed the program.
      begin
        //north point
        PointIndexes[0].Increment := GetIncrement(J,I-BorderPixels,W,H);
        //east point
        PointIndexes[1].Increment := GetIncrement(J+BorderPixels,I,W,H);
        //south point
        PointIndexes[2].Increment := GetIncrement(J,I+BorderPixels,W,H);
        //west point
        PointIndexes[3].Increment := GetIncrement(J-BorderPixels,I,W,H);

        for K := 0 to 3 do
        begin
          Value2 := ValueBuffer;
          Inc(Value2, PointIndexes[K].Increment);
          if Value.CPIndex <> Value2.CPIndex then
            IsBorder := True;
          if Value.CPSecondIndex <> Value2.CPSecondIndex then
            IsSecondBorder := True;
        end;

      end;

      //Several kinds of processing
      Pixel.A := 1; //alpha is always the same
      K := Value.CPIndex;
      Dist := Value.DistFromCenter;

      //Dunno if you do prefere the "if -> else -> else chain"
      //personally I'm fine with the if/end, if/end blocks. Feel free to modify this!
      if (CellStyle = cstTG1) then   //TG effect number 1
      begin
        Pixel.R := sqrt(Dist/GlobalMax);
        if IsBorder then
          Pixel.R := Pixel.R + 0.25;
      end;

      if (CellStyle = cstTG2) then
      begin
        Pixel.R := (sqrt(Value.DistSecondCenter) - sqrt(Dist))/sqrt(GlobalMax);
        if (PlacementStyle = pstSquares) then
          Pixel.R := Pixel.R / 1.414;
        if (PlacementStyle = pstHoneycomb) then
          Pixel.R := Pixel.R / 1.732;
        if IsBorder then
          Pixel.R := 0;
      end;

      if (CellStyle = cstTG3) then
      begin
        Pixel.R := (sqrt(Dist)*sqrt(Value.DistSecondCenter))/GlobalMax;
      end;

      if (CellStyle = cstNice1) then //My nice effect
      begin
        Pixel.R := 1 - sqrt(Dist/CP[K].MaxDist);
        if IsBorder then
          Pixel.R := 0;
      end;

      if (CellStyle = cstWerk) then
      begin
        Pixel.R := Power((Dist/GlobalMax),1.5);
        if IsBorder then
          Pixel.R := Pixel.R + 0.25
        else if IsSecondBorder then
          Pixel.R := Power((Dist/GlobalMax),1.8);
      end;
      //All the styles except the standard one are just white or black, so
      //we save some instructions by adding the green and blue out of the IFs!
      Pixel.G := Pixel.R;
      Pixel.B := Pixel.G;

      if (CellStyle = cstStandard)  then //standard: coloured eventually with black borders
      begin
        if IsBorder then
        begin
          Pixel.R := 0;
          Pixel.G := 0;
          Pixel.B := 0;
        end
        else
        begin
          Pixel.R := CP[K].R;
          Pixel.G := CP[K].G;
          Pixel.B := CP[K].B;
        end;
      end;

      Inc(Pixel);
      Inc(Value);
    end;
  end;

  RandSeed := SaveSeed;

  //Needed to send the bitmap to opengl
  B.UseTextureBegin;

  FreeMem(Pixels);
  FreeMem(ValueBuffer);

  Stack.Push(B);
end;

procedure TBitmapCells.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'CellStyle',{$ENDIF}integer(@CellStyle), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['Standard','Nice1','TG1','TG2','TG3','Werk']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'PointsPlacement',{$ENDIF}integer(@PlacementStyle), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['Random','Honeycomb','Squares', 'Cobblestone']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'UsedMetrics',{$ENDIF}integer(@UsedMetrics), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['Euclidean','Manhattan','MaxMin','Product', 'Stripes']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'RandomSeed',{$ENDIF}integer(@RandomSeed), zptInteger);
    List.GetLast.DefaultValue.IntegerValue := 42;
  List.AddProperty({$IFNDEF MINIMAL}'BorderPixels',{$ENDIF}integer(@BorderPixels), zptInteger);
    List.GetLast.DefaultValue.IntegerValue := 2;
  List.AddProperty({$IFNDEF MINIMAL}'PointCount',{$ENDIF}integer(@NOfPoints), zptInteger);
    List.GetLast.DefaultValue.IntegerValue := 10;
end;

{ TBitmapDistort }

procedure TBitmapDistort.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Amount',{$ENDIF}integer(@Amount), zptScalar);
    List.GetLast.DefaultValue.FloatValue := 0.2;
end;

procedure TBitmapDistort.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  B,B1,B2 : TZBitmap;
  Data1,Data2,DataF,P1,P2,PF : PColorf;
  I,J,W,H : integer;
  Mw,Mh : single;
begin
  if Stack.Count<2 then
    Exit;

  B1 := TZBitmap(Stack.Pop());
  B2 := TZBitmap(Stack.Pop());

  {$ifndef minimal}
  if (B1.PixelWidth<>B2.PixelWidth) or
     (B1.PixelHeight<>B2.PixelHeight) then
  begin
    ZLog.GetLog(Self.ClassName).Warning('Bitmap sizes must match.');
    Exit;
  end;
  {$endif}

  B := TZBitmap.CreateFromBitmap(TZBitmap(Content));

  Data1 := B1.GetCopyAsFloats;
  Data2 := B2.GetCopyAsFloats;

  W := B.PixelWidth;
  H := B.PixelHeight;
  GetMem(DataF,H*W * Sizeof(TZColorf));

  B.SetMemory(DataF,GL_RGBA,GL_FLOAT);


  P2 := Data2;
  PF := DataF;

  Mw := W * Self.Amount;
  Mh := H * Self.Amount;

  for I := 0 to H-1 do
  begin
    for J := 0 to W-1 do
    begin
      P1 := Data1;
      Inc(P1, GetIncrement(J + Integer(Round(P2.B * Mw)),
                           I + Integer(Round(P2.G * Mh))  ,
                           W,H)
          );
      PF^ := P1^;
      Inc(PF);
      Inc(P2);
    end;
  end;
//Needed to send the bitmap to opengl
  B.UseTextureBegin;

  FreeMem(Data1);
  FreeMem(Data2);
  FreeMem(DataF);

  B1.Free;
  B2.Free;

  Stack.Push(B);
end;

{ TBitmapPixels}

procedure TBitmapPixels.ProduceOutput(Content : TContent; Stack : TZArrayList);
var
  B : TZBitmap;
  I,SaveSeed,PixelCount : integer;
  Temp : Single;
  Pixels : PColorf;
  Pixel : PColorf;
begin
  B := TZBitmap.CreateFromBitmap( TZBitmap(Content) );

  PixelCount := B.PixelHeight*B.PixelWidth;
  GetMem(Pixels,PixelCount * Sizeof(TZColorf) );
  FillChar(Pixels^,PixelCount * Sizeof(TZColorf),0);

  SaveSeed := RandSeed;
  RandSeed := Self.RandomSeed;
  for I := 0 to Round(NOfPoints*(PixelCount / 4096)) - 1 do    //the mean is <NOfPoints> pixels in 64x64 texture
  begin
    Pixel := Pixels;
    inc(Pixel,System.Random(PixelCount));
    Temp := 0.2 + System.Random() * 0.8;
    if (Color = 0) or (Color = 1) then Pixel.R := Temp;
    if (Color = 0) or (Color = 2) then Pixel.G := Temp;
    if (Color = 0) or (Color = 3) then Pixel.B := Temp;
    Pixel.A := Temp;
  end;
  RandSeed := SaveSeed;

  B.SetMemory(Pixels,GL_RGBA,GL_FLOAT);

  //Needed to send the bitmap to opengl
  B.UseTextureBegin;

  FreeMem(Pixels);

  Stack.Push(B);
end;

procedure TBitmapPixels.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'NOfPoints',{$ENDIF}integer(@NOfPoints), zptInteger);
    List.GetLast.DefaultValue.IntegerValue := 10;
  List.AddProperty({$IFNDEF MINIMAL}'Color',{$ENDIF}integer(@Color), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['White','Red','Green','Blue']);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'RandomSeed',{$ENDIF}integer(@RandomSeed), zptInteger);
    List.GetLast.DefaultValue.IntegerValue := 42;
end;

{ TBitmapConvolution }

procedure TBitmapConvolution.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'SwapDimensions',{$ENDIF}integer(@SwapDim), zptBoolean);
  List.AddProperty({$IFNDEF MINIMAL}'ConvArray',{$ENDIF}integer(@ConvArray), zptComponentRef);
    {$ifndef minimal}List.GetLast.SetChildClasses([TDefineArray]);{$endif}
  List.AddProperty({$IFNDEF MINIMAL}'Divisor',{$ENDIF}integer(@Divisor), zptFloat);
    List.GetLast.DefaultValue.FloatValue := 1;
  List.AddProperty({$IFNDEF MINIMAL}'Bias',{$ENDIF}integer(@Bias), zptFloat);
end;

procedure TBitmapConvolution.ProduceOutput(Content: TContent; Stack: TZArrayList);
var
  SourceB,B : TZBitmap;
  J,K,I1,I2 : integer;
  SourceP,DestP : PColorf;
  SizeBytes : integer;
  ConvMatrix : PFloat;
  ConvTmp : PFloat;
  P : PFloat;
  ConvW, ConvH : integer;
begin
  if Stack.Count=0 then
    Exit;

  {$ifndef minimal}
  if ConvArray=nil then
  begin
    ZLog.GetLog(Self.ClassName).Warning('Property ConvArray not set.');
    Exit;
  end;
  if ConvArray.Dimensions <> dadTwo then
  begin
    ZLog.GetLog(Self.ClassName).Warning('ConvArray must be 2D.');
    Exit;
  end;
  if (ConvArray.SizeDim1 and 1=0) or (ConvArray.SizeDim2 and 1=0) then
  begin
    ZLog.GetLog(Self.ClassName).Warning('ConvArray must be odd-sized.');
    Exit;
  end;
  {$endif}

  SourceB := TZBitmap(Stack.Pop());
  B := TZBitmap.CreateFromBitmap( SourceB );
  SourceP := SourceB.GetCopyAs3f;
  SourceB.Free;

  SizeBytes := SizeOf(TZVector3f)*B.PixelWidth*B.PixelHeight;
  GetMem(DestP,SizeBytes);
  B.SetMemory(DestP,GL_RGB,GL_FLOAT);

  if SwapDim then
  begin
    ConvH := ConvArray.SizeDim1;
    ConvW := ConvArray.SizeDim2;
  end
  else
  begin
    ConvW := ConvArray.SizeDim1;
    ConvH := ConvArray.SizeDim2;
  end;

  GetMem(ConvMatrix,SizeOf(single)*(ConvH*ConvW));
  ConvTmp := ConvMatrix;

  for J := 0 to (ConvW - 1) do
    for K := 0 to (ConvH - 1) do
    begin
      if SwapDim then
      begin
        I1 := K;
        I2 := J;
      end else
      begin
        I1 := J;
        I2 := K;
      end;
      P := ConvArray.GetData;
      Inc(P,I1 + ConvArray.SizeDim1 * I2);
      ConvTmp^ := P^;
      Inc(ConvTmp);
    end;

  ConvolveImage(SourceP, DestP, B.PixelWidth, B.PixelHeight, ConvMatrix, ConvW, ConvH, Divisor, Bias);

  //Needed to send the bitmap to opengl
  B.UseTextureBegin;

  FreeMem(SourceP);
  FreeMem(DestP);
  FreeMem(ConvMatrix);

  Stack.Push(B);
end;


{ TBitmapProducerWithOptionalArgument }

procedure TBitmapProducerWithOptionalArgument.DefineProperties(
  List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'UseBlankSource',{$ENDIF}integer(@UseBlankSource), zptBoolean);
end;

function TBitmapProducerWithOptionalArgument.GetOptionalArgument(Stack : TZArrayList): TZBitmap;
begin
  if (Stack.Count>0) and (not Self.UseBlankSource) then
    Result := TZBitmap(Stack.Pop())
  else
    Result := nil;
end;


initialization

  ZClasses.Register(TBitmapRect,BitmapRectClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ParamCount := 1;{$endif}
  ZClasses.Register(TBitmapZoomRotate,BitmapZoomRotateClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ParamCount := 1;{$endif}
  ZClasses.Register(TBitmapExpression,BitmapExpressionClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ParamCount := 1;{$endif}
  ZClasses.Register(TBitmapFromFile,BitmapFromFileClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
  ZClasses.Register(TBitmapBlur,BitmapBlurClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ParamCount := 1;{$endif}
  ZClasses.Register(TBitmapLoad,BitmapLoadClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
  ZClasses.Register(TBitmapCombine,BitmapCombineClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ParamCount := 2;{$endif}
  ZClasses.Register(TBitmapCells,BitmapCellsClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
  ZClasses.Register(TBitmapDistort,BitmapDistortClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ParamCount := 2;{$endif}
  ZClasses.Register(TBitmapPixels,BitmapPixelsClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
  ZClasses.Register(TBitmapConvolution,BitmapConvolutionClassId);
    {$ifndef minimal}ComponentManager.LastAdded.NeedParentComp := 'Bitmap';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ParamCount := 1;{$endif}



end.
