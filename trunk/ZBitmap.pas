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

unit ZBitmap;

interface

uses ZOpenGL, ZClasses;

type
  TBitmapSize = (bs16,bs32,bs64,bs128,bs256,bs512,bs1024,bs2048);

  //32 bits per pixel image
  TZBitmap = class(TContent)
  strict private
    IsInitialized : boolean;
    Memory : pointer;
    MemFormat,MemType : GLuint;
    procedure ReInit;
    procedure CleanUp;
  protected
    procedure CopyAndDestroy(Source : TContent); override;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Handle: GLuint;
    //Keep fields in sync with CopyAndDestroy + CreateFromBitmap
    PropWidth,PropHeight : TBitmapSize;
    Filter : (bmfLinear,bmfNearest,bmfMipmap);
    constructor CreateFromBitmap(B : TZBitmap);
    destructor Destroy; override;
    procedure Update; override;
    procedure UseTextureBegin;
    //procedure UseTextureEnd;
    procedure RenderTargetBegin;
    procedure RenderTargetEnd;
    procedure SetMemory(P : pointer; MemFormat, MemType : GLuint);
    function PixelWidth : integer;
    function PixelHeight : integer;
    function GetCopyAsFloats : pointer;
    function GetCopyAs3f: pointer;
    {$ifndef minimal}
    procedure DesignerFreeResources; override;
    {$endif}
  end;

implementation

{$ifndef minimal}
uses BitmapProducers,ZApplication,ZLog;
{$endif}

{ TZBitmap }

constructor TZBitmap.CreateFromBitmap(B: TZBitmap);
begin
  inherited Create(nil);
  PropHeight := B.PropHeight;
  PropWidth := B.PropWidth;
  Filter := B.Filter;
end;

destructor TZBitmap.Destroy;
begin
  CleanUp;
  inherited;
end;

function TZBitmap.GetCopyAsFloats: pointer;
var
  P : PFloat;
begin
  GetMem(P,PixelHeight * PixelWidth * 4 * SizeOf(single));
  UseTextureBegin;
  glGetTexImage(GL_TEXTURE_2D,0,GL_RGBA,GL_FLOAT,P);
  Result := P;
end;

function TZBitmap.GetCopyAs3f: pointer;
var
  P : PFloat;
begin
  GetMem(P,PixelHeight * PixelWidth * 3 * SizeOf(single));
  UseTextureBegin;
  glGetTexImage(GL_TEXTURE_2D,0,GL_RGB,GL_FLOAT,P);
  Result := P;
end;

procedure TZBitmap.CleanUp;
begin
  if IsInitialized then
  begin
    IsInitialized := False;
    glDeleteTextures(1, @Handle);
  end;
end;

procedure TZBitmap.CopyAndDestroy(Source: TContent);
var
  B : TZBitmap;
begin
  CleanUp;
  B := TZBitmap(Source);
  Self.Handle := B.Handle;
  Self.IsInitialized := B.IsInitialized;
  Self.PropHeight := B.PropHeight;
  Self.PropWidth := B.PropWidth;
  Self.Memory := B.Memory;
  Self.MemFormat := B.MemFormat;
  Self.MemType := B.MemType;
  Self.Filter := B.Filter;
  B.Handle := 0;
  B.IsInitialized := False;
  B.Free;
end;

//Call this when bitmap size have changed
procedure TZBitmap.ReInit;
const
  FilterTypes : array[0..2] of integer = (GL_LINEAR,GL_NEAREST,GL_LINEAR_MIPMAP_LINEAR);
var
  Size,W,H,I : integer;
  P : pointer;
begin
  CleanUp;

  if Producers.Count>0 then
  begin
    //Create from child content producers
    RefreshFromProducers;
  end
  else
  begin
    //Create as a texgen buffer
    glGenTextures(1, @Handle);
    glBindTexture(GL_TEXTURE_2D, Handle);

    W := PixelWidth;
    H := PixelHeight;

    //Generate mipmaps automatically, must be set before call to glTexImage2D
    if Filter=bmfMipmap then
      glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);

    if Memory<>nil then
    begin
      glTexImage2D(GL_TEXTURE_2D, 0, 4, W, H, 0, Self.MemFormat, Self.MemType, Memory);
      Memory := nil;
    end else
    begin
      //Must be set to something, otherwise copy from framebuffer won't work
      Size := H*W*4;
      GetMem(P, Size);
      FillChar(P^,Size,$ff);
      glTexImage2D(GL_TEXTURE_2D, 0, 4, W, H, 0, GL_RGBA, GL_UNSIGNED_BYTE, P);
      FreeMem(P);
    end;

    if Self.Filter=bmfMipmap then
      I := GL_LINEAR  //Mipmap is not a valid mag-filter
    else
      I := FilterTypes[Ord(Self.Filter)];
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, I );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, FilterTypes[Ord(Self.Filter)] ); //GL_NEAREST_MIPMAP_LINEAR);
  end;
  IsChanged := False;
  Producers.IsChanged := False;
  IsInitialized := True;
end;


procedure TZBitmap.RenderTargetBegin;
begin
  if not IsInitialized then
    ReInit;

  glPushAttrib(GL_ALL_ATTRIB_BITS);
    //Skippa perspektiv och s�tt upp -1.0 .. 1.0 uppl�sning
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    glOrtho(-1, 1, -1, 1, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity;
    glDisable(GL_LIGHTING);
    glDisable(GL_CULL_FACE);
    //Clear
    {$ifndef minimal}
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
    {$endif}
    glViewport(0, 0, PixelWidth, PixelHeight);
    {$ifdef zgeviz}
    ZApp.ViewportChanged;
    {$endif}
end;

procedure TZBitmap.RenderTargetEnd;
begin
    glBindTexture(GL_TEXTURE_2D, Handle);
    glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, PixelWidth, PixelHeight);
  glPopAttrib;
  {$ifdef zgeviz}
  ZApp.ViewportChanged;
  {$endif}
end;

//Set this bitmap as current opengl texture
procedure TZBitmap.UseTextureBegin;
begin
  if (not IsInitialized)
   {$ifndef minimal}or Producers.IsChanged or IsChanged{$endif} then
    ReInit;
  glBindTexture(GL_TEXTURE_2D, Handle);
end;

procedure TZBitmap.Update;
begin
  //Dynamic bitmap must be updated before draw begins since backbuffer is being used
  if (not IsInitialized) or (Producers.IsChanged) or (IsChanged) then
    ReInit;
end;

procedure TZBitmap.SetMemory(P: pointer; MemFormat,MemType : GLUInt);
begin
  Self.Memory := P;
  Self.MemFormat := MemFormat;
  Self.MemType := MemType;
end;

function TZBitmap.PixelHeight: integer;
begin
  Result := 16 shl ord(PropHeight);
end;

function TZBitmap.PixelWidth: integer;
begin
  Result := 16 shl ord(PropWidth);
end;

{$ifndef minimal}
procedure TZBitmap.DesignerFreeResources;
begin
  CleanUp;
  inherited;
end;
{$endif}

procedure TZBitmap.DefineProperties(List: TZPropertyList);
begin
  inherited;
  {$ifndef minimal}
//  List.GetByName('Producers').SetChildClasses([TBitmapExpression,TBitmapRect,TBitmapZoomRotate]);
  {$endif}
  List.AddProperty({$IFNDEF MINIMAL}'Width',{$ENDIF}integer(@PropWidth), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['16','32','64','128','256','512','1024','2048']);{$endif}
    List.GetLast.DefaultValue.ByteValue := Ord(bs64);
  List.AddProperty({$IFNDEF MINIMAL}'Height',{$ENDIF}integer(@PropHeight), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['16','32','64','128','256','512','1024','2048']);{$endif}
    List.GetLast.DefaultValue.ByteValue := Ord(bs64);
  List.AddProperty({$IFNDEF MINIMAL}'Filter',{$ENDIF}integer(@Filter), zptByte);
    {$ifndef minimal}List.GetLast.SetOptions(['Linear','Nearest','Mipmap']);{$endif}
end;

initialization

  ZClasses.Register(TZBitmap,ZBitmapClassId);
    {$ifndef minimal}ComponentManager.LastAdded.ZClassName := 'Bitmap';{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ImageIndex:=9;{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.AutoName := True;{$endif}

end.
