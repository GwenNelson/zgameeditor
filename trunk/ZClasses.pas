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

//Main classes and component model

unit ZClasses;

interface

{$ifndef minimal}
uses uSymTab,Contnrs;
{$endif}

type
  //Baseclasses for all central concepts in ZGE

  //List with unique ClassIDs
  TZClassIds = (
 LogicalGroupClassId,ZBitmapClassId,
 BitmapRectClassId,BitmapZoomRotateClassId,BitmapExpressionClassId,BitmapFromFileClassId,BitmapBlurClassId,
 BitmapLoadClassId,BitmapCombineClassId,BitmapCellsClassId,BitmapDistortClassId,BitmapPixelsClassId,
 BitmapConvolutionClassId,BitmapNoiseClassId,
 MeshClassId,ModelClassId,MaterialClassId,MaterialTextureClassId,SpawnModelClassId,RemoveModelClassId,
 MeshBoxClassId,MeshSphereClassId,MeshNoiseClassId,MeshExpressionClassId,
 MeshCombineClassId,MeshLoadClassId,MeshTransformClassId,MeshLoopClassId,
 RemoveAllModelsClassId,
 MeshImplicitClassId,ImplicitPrimitiveClassId,ImplicitExpressionClassId,ImplicitCombineClassId,
 ImplicitWarpClassId,MeshImportClassId,
 FontClassId,ModelStateClassId,SetModelStateClassId,
 AnimatorGroupClassId,AnimatorSimpleClassId,MouseModelControllerClassId,
 StartAnimatorClassId,
 UseMaterialClassId,RenderMeshClassId,RenderTransformClassId,RenderSpriteClassId,
 RenderBeamsClassId,RenderTransformGroupClassId,RenderTextClassId,RenderSetColorClassId,RenderNetClassId,
 RenderParticlesClassId,ShaderClassId,ShaderVariableClassId,
 RenderTargetClassId,SetRenderTargetClassId,
 RepeatClassId,ConditionClassId,KeyPressClassId,RefreshContentClassId,ZTimerClassId,WebOpenClassId,
 ApplicationClassId,AppStateClassId,SetAppStateClassId,CallComponentClassId,
 ZExpressionClassId,ExpConstantFloatClassId,ExpConstantIntClassId,
 ExpOpBinaryFloatClassId,ExpOpBinaryIntClassId,ExpPropValue4ClassId,ExpPropValue1ClassId,
 ExpPropPtrClassId,ExpJumpClassId,DefineVariableClassId,ExpFuncCallClassId,ExpExternalFuncCallClassId,
 ExpArrayReadClassId,ExpArrayWriteClassId,ExpStackFrameClassId,ExpAccessLocalClassId,
 ExpReturnClassId,ExpMiscClassId,ExpUserFuncCallClassId,ExpConvertClassId,
 ExpAssign4ClassId,ExpAssign1ClassId,ExpStringConstantClassId,ExpStringConCatClassId,
 ExpStringFuncCallClassId,
 DefineConstantClassId,DefineArrayClassId,ZLibraryClassId,ExternalLibraryClassId,
 DefineCollisionClassId,
 SoundClassId,PlaySoundClassId,AudioMixerClassId,
 MusicClassId,MusicControlClassId,
 SteeringControllerClassId,SteeringBehaviourClassId,
 ZFileClassId,FileActionClassId,FileMoveDataClassId
);

  TZComponent = class;
  TZComponentClass = class of TZComponent;
  TZProperty = class;

  //Datatyp som  zptString-properties ska deklareras som i components (se app.caption)
  TPropString = PAnsiChar;
  PPropString = ^TPropString;

  PObjectArray = ^TObjectArray;
  TObjectArray = array[0..100000] of TObject;

  PPAnsiChar = ^PAnsiChar;

  TBytes = array[0..100000] of byte;
  PBytes = ^TBytes;
  TWords = array[0..100000] of word;
  PWords = ^TWords;
//  PByte = ^byte;

  PBoolean = ^ByteBool;
  PFloat = ^single;
  TFloatArray = array[0..10000] of single;
  PFloatArray = ^TFloatArray;
  {$ifndef minimal}
  PString = ^string;
  {$endif}

  PPointer = ^pointer;

  PZVector2f = ^TZVector2f;
  TZVector2f = array[0..1] of single;
  PZVector2Array = ^TZVector2Array;
  TZVector2Array = packed array[0..0] of TZVector2f;

  PZVector3f = ^TZVector3f;
  TZVector3f = array[0..2] of single;
  PZVector4f = ^TZVector4f;
  TZVector4f = array[0..3] of single;

  TZMatrix4f = array[0..3] of TZVector4f;

  PZVector3Array = ^TZVector3Array;
  TZVector3Array = packed array[0..100000] of TZVector3f;

  TZPointf =
    record
      X,Y : single;
    end;

  TZPointi =
    record
      X,Y : integer;
    end;

  PColorf = ^TZColorf;
  TZColorf =
    packed record
      case integer of
        0 : (V : TZVector4f);
        1 : (R, G, B, A: single);
    end;

  PRectf = ^TZRectf;
  TZRectf =
    record
      case integer of
        0 : (Area : TZVector4f);
        1 : (Left, Top, Right, Bottom: single);
        2 : (TopLeft, BottomRight: TZPointf);
    end;

  TZBox3D =
    record //3D-box defined as Min/Max for each axis
      Min : TZVector3f;
      Max : TZVector3f;
    end;

  //Oriented bounding box 2D collision info
  //http://www.gamedev.net/community/forums/topic.asp?topic_id=364789
  TOBB_2D =
    record
      C : TZVector2f;                 //Center
      U : array[0..1] of TZVector2f;  //X and Y axis
      E : array[0..1] of single;      //Extents
    end;

  TZArrayList = class
  private
    List : PObjectArray;
    Capacity : integer;
    FCount: integer;
    procedure Grow;
    function GetItem(Index: Integer): TObject;
    procedure SetItem(Index: Integer; const Value: TObject);
    {$ifndef minimal}
    procedure CheckValidIndex(Index: Integer);
    {$endif}
  public
    ReferenceOnly : boolean;
    constructor CreateReferenced;
    destructor Destroy; override;
    procedure Add(Item : TObject);
    procedure RemoveAt(Index : integer);
    function IndexOf(Item: TObject): Integer;
    function Last : TObject;
    procedure Remove(Item : TObject);
    procedure SwapRemoveAt(Index : integer);
    procedure SwapRemove(Item: TObject);
    procedure Clear;
    property Items[Index: Integer]: TObject read GetItem write SetItem; default;
    property Count : integer read FCount;
    procedure Push(Item : TObject);
    function Pop : TObject;
    function GetPtrToItem(Index: Integer): pointer;
    procedure Swap(Index1,Index2 : integer);
  end;

  //Anv�nds som property i komponenter f�r att h�lla children-komponenter
  //samt event-tr�d med command-komponenter
  //Obs, �ger sina componenter trots att TZArrayList ReferenceOnly=true
  TZComponentList = class(TZArrayList)
  private
    Owner : TZComponent;
  public
    IsChanged : boolean;
    constructor Create; overload;
    constructor Create(OwnerC : TZComponent); overload;
    destructor Destroy; override;
    procedure Clear;
    procedure AddComponent(Component: TZComponent);
    procedure RemoveComponent(Component: TZComponent);
    function GetComponent(Index : integer) : TZComponent;
    function ComponentCount : integer;
    procedure Update;
    procedure Change;
    procedure ExecuteCommands;
    {$ifndef minimal}
    procedure DesignerReset;
    procedure InsertComponent(Component: TZComponent; Index : integer);
    {$endif}
  end;


  //Info om en referens till en property p� en komponent
  PZPropertyRef = ^TZPropertyRef;
  TZPropertyRef = record
    Component : TZComponent;
    Prop : TZProperty;
    //index f�r indexed properties (f�r att v�lja x,y,z i en vector)
    Index : integer;
    {$ifndef minimal}
    HasPropIndex : boolean;
    {$endif}
  end;

  //Expression �r en egen propertytyp
  //I designl�ge s� anv�nds b�de Source-str�ng och lista med kompilerad kod
  //I minimal endast kompilerad kod (i n�stlad komponentlista)
  PZExpressionPropValue = ^TZExpressionPropValue;
  TZExpressionPropValue = record
    {$ifndef minimal}
    Source : string;            //Expression source
    {$endif}
    Code : TZComponentList;     //Expression byte code
  end;

  //Datatypes in Zc-script
  TZcDataType = (zctVoid,zctFloat,zctInt,zctString);

  PZBinaryPropValue = ^TZBinaryPropValue;
  TZBinaryPropValue = record
    Size : integer;
    Data : pointer;
  end;

  TZPropertyValue = record
    {$IFNDEF MINIMAL}
    //String-props kan ej ligga i case-switch f�r designer
    ExpressionValue : TZExpressionPropValue;
    StringValue : AnsiString;
    {$ENDIF}
    case integer of
      0 : (FloatValue : single);
      2 : (RectfValue : TZRectf);
      3 : (ColorfValue : TZColorf);
      4 : (IntegerValue : integer);
      5 : (ComponentValue : TZComponent);
      {$ifdef minimal}6 : (StringValue : PAnsiChar);{$endif}
      7 : (PropertyValue : TZPropertyRef);
      8 : (Vector3fValue : TZVector3f);
      9 : (ComponentListValue : TZComponentList);
     10 : (GenericValue : array[0..2] of integer); //f�r default-data test
     11 : (ByteValue : byte);
     12 : (BooleanValue : ByteBool);
     {$ifdef minimal}
     13 : (ExpressionValue : TZExpressionPropValue);
     {$endif}
     14 : (BinaryValue : TZBinaryPropValue);
  end;

  //zptScalar = float with 0..1 range
  TZPropertyType = (zptFloat,zptScalar,zptRectf,zptColorf,zptString,zptComponentRef,zptInteger,
    zptPropertyRef,zptVector3f,zptComponentList,zptByte,zptBoolean,
    zptExpression,zptBinary);

  TZProperty = class
  public
    DefaultValue : TZPropertyValue;
    NeverPersist : boolean;
    DontClone : boolean;
    IsStringTarget: boolean;   //Can be assigned as string in expressions, values are garbagecollected
    {$IFNDEF MINIMAL}public{$ELSE}private{$ENDIF}
    PropertyType : TZPropertyType;
    PropId : integer;             //Ordningsnr p� denna property f�r en klass
    Offset : integer;
    {$IFNDEF MINIMAL}
    Name : string;              //Namn p� property i designer 'Color'
    ExcludeFromBinary : boolean;  //Ta inte med denna prop i bin�rstr�m (designer only)
    ExcludeFromXml : boolean; //Spara ej i xml-fil
    IsReadOnly : boolean;       //Prop kan ej tilldelas i expressions
    NeedRefreshNodeName : boolean;//True f�r propertys som kr�ver refresh i nodtr�d vid �ndring av prop
    ChildClasses :               //F�r componentlists: krav p� vilka klasser som kan ligga i listan
      array of TZComponentClass; //F�r componentref: krav p� vilka klasser som g�r att referera till
    Options : array of string;  //F�r bytes: Valbara alternativ
    HideInGui : boolean;        //Visa inte denna prop i gui
    ReturnType : TZcDataType;      //For expresssions: return type of expression
    function IsDefaultValue(const Value : TZPropertyValue) : boolean;
    procedure SetChildClasses(const C : array of TZComponentClass);
    procedure SetOptions(const O : array of string);
    {$ENDIF}
  end;

  TZPropertyList = class(TZArrayList)
  private
    NextId : integer;
    TheSelf : integer;
  public
    procedure AddProperty({$IFNDEF MINIMAL}const Name : string; {$ENDIF} const Offset : integer; const PropType : TZPropertyType);
    {$IFNDEF MINIMAL}
    procedure SetDesignerProperty;
    function GetByName(Name : string) : TZProperty;
    function GetByType(Kind : TZPropertyType) : TZProperty;
    {$ENDIF}
    function GetLast : TZProperty;
    function GetById(PropId : integer) : TZProperty;
  end;

  //Baskomponentklass f�r allt som ska kunna redigeras i tool
  TZComponent = class
  private
    function DoClone(ObjIds,FixUps : TZArrayList) : TZComponent;
  protected
    ObjId : integer;    //only used in streaming
    IsChanged : boolean;
    procedure DefineProperties(List : TZPropertyList); virtual;
  public
    {$ifndef minimal}
    Name,Comment : TPropString;
    DesignDisable : boolean;
    {$endif}
    OwnerList : TZComponentList;
    constructor Create(OwnerList: TZComponentList); virtual;
    destructor Destroy; override;
    function GetProperties : TZPropertyList;
    procedure SetProperty(Prop : TZProperty; const Value : TZPropertyValue);
    procedure GetProperty(Prop : TZProperty; var Value : TZPropertyValue);
    function GetPropertyPtr(Prop : TZProperty; Index : integer) : pointer;
    procedure Update; virtual;
    procedure Change;
    function Clone : TZComponent;
    {$ifndef minimal}
    function GetDisplayName : AnsiString; virtual;
    procedure DesignerReset; virtual;  //Reset house-keeping state (such as localtime in animators)
    procedure DesignerFreeResources; virtual; //Free resources such as GL-handles
    function GetOwner : TZComponent;
    procedure SetString(const PropName : string; const Value : AnsiString);
    procedure GetAllChildren(List : TObjectList; IncludeExpressions : boolean);
    {$endif}
  end;


  //Command �r komponent som anv�nds i event-tr�d
  //Execute-metoden k�rs vid event-utv�rdering
  TCommand = class(TZComponent)
  public
    procedure Execute; virtual; abstract;
  end;


  //Standardkomponent med en definierad property: 'Children'
  //�rver TCommand s� att den exekverar children n�r den ligger i eventlists.
  TLogicalGroup = class(TCommand)
  protected
    procedure DefineProperties(List : TZPropertyList); override;
  public
    Children : TZComponentList;
    procedure Update; override;
    procedure Execute; override;
  end;



  //Info about one componentclass
  TZComponentInfo = class
    {$IFNDEF MINIMAL}public{$ELSE}private{$ENDIF}
    ZClass : TZComponentClass;
    ClassId : TZClassIds;
    Properties : TZPropertyList;
    {$IFNDEF MINIMAL}
    ZClassName : string;  //Klassnamn utan 'T'
    NoUserCreate : boolean;
    NoTopLevelCreate : boolean; //Till�t ej anv�ndare att skapa denna p� toppniv�
    ExcludeFromBinary : boolean; //Skippa hela komponenten i bin�rfilen
    ImageIndex : integer;  //Icon som ska visas i designertr�det
    HelpText : string;
    NeedParentComp : string;
    NeedParentList : string;
    AutoName : boolean;  //Give name automatically when inserted in designer
    ParamCount : integer; //Parameter count for contentproducers
    {$ENDIF}
    {$if (not defined(MINIMAL)) or defined(zzdc_activex)}
    public
    HasGlobalData : boolean; //See audiomixer. Do not cache property-list.
    {$ifend}
  end;


  TComponentInfoArray = array[TZClassIds] of TZComponentInfo;
  PComponentInfoArray = ^TComponentInfoArray;

  //Singleton
  //Keeps track of all componentclasses
  TZComponentManager = class
  private
    ComponentInfos : TComponentInfoArray;
    function GetInfoFromId(ClassId : TZClassIds) : TZComponentInfo;
  {$IFNDEF MINIMAL}
    function GetInfoFromName(const ZClassName : string) : TZComponentInfo;
  {$ENDIF}
    procedure Register(C : TZComponentClass; ClassId : TZClassIds);
    function GetProperties(Component : TZComponent) : TZPropertyList;
    {$ifndef minimal}public
    destructor Destroy; override;{$else}private{$endif}
    function GetInfo(Component : TZComponent) : TZComponentInfo;
  public
    {$if (not defined(MINIMAL)) or defined(zzdc_activex)}
    LastAdded : TZComponentInfo;
    {$ifend}
  {$IFNDEF MINIMAL}
    function SaveBinaryToStream(Component : TZComponent) : TObject;
    function LoadXmlFromFile(FileName : string) : TZComponent;
    function LoadXmlFromString(const XmlData : string; SymTab : TSymbolTable) : TZComponent;
    procedure SaveXml(Component : TZComponent; FileName : string);
    function SaveXmlToStream(Component: TZComponent) : TObject;
    function GetAllInfos : PComponentInfoArray;
  {$ENDIF}
    function LoadBinary : TZComponent;
  end;



  //Content that can be produced from contentproducers (bitmaps and meshes)
  TContent = class(TZComponent)
  protected
    procedure RefreshFromProducers;
    procedure CopyAndDestroy(Source : TContent); virtual; abstract;
    procedure DefineProperties(List: TZPropertyList); override;
  public
    Producers : TZComponentList;
  end;

  TContentProducer = class(TCommand)
  protected
    procedure ProduceOutput(Content : TContent; Stack : TZArrayList); virtual; abstract;
  public
    procedure Execute; override;
  end;


  //Baseclass for AppState and ModelState
  TStateBase = class(TZComponent)
  protected
    procedure DefineProperties(List: TZPropertyList); override;
  public
    OnStart : TZComponentList;
    OnUpdate : TZComponentList;
    OnLeave : TZComponentList;
    OnRender : TZComponentList;
    Definitions : TZComponentList;
    procedure Update; override;
  end;


  //Readonly stream
  TZInputStream = class
  private
    OwnsMemory : boolean;
    Memory : PBytes;
    {$ifdef zdebug}
    IsBitMode : boolean;
    {$endif}
    BitNo : integer;
    Bits : byte;
  public
  {
    Position
    Size
    function GetMemory : pointer;
    procedure LoadFromFile
    procedure LoadFromResource
    procedure Read(p,count)
  }
    Size,Position : integer;
    constructor CreateFromFile(FileName : PAnsiChar; IsRelative : Boolean);
    constructor CreateFromMemory(M : pointer; Size : integer);
    destructor Destroy; override;
    procedure Read(var Buf; Count : integer);
    function GetMemory : PBytes;
    procedure BitsBegin;
    function ReadBit : boolean;
    procedure BitsEnd;
  end;


function GetPropertyRef(const Prop : TZPropertyRef) : pointer;
function MakeColorf(const R,G,B,A : single) : TZColorf;

{.$IFNDEF MINIMAL}
function ComponentManager : TZComponentManager;
{.$ENDIF}

//Register componentclass
procedure Register(C : TZComponentClass; ClassId : TZClassIds);

//String functions
function ZStrLength(P : PAnsiChar) : integer;
procedure ZStrCopy(P : PAnsiChar; const Src : PAnsiChar);
procedure ZStrCat(P : PAnsiChar; const Src : PAnsiChar);
procedure ZStrConvertInt(const S : integer; Dest : PAnsiChar);
function ZStrPos(const SubStr,Str : PAnsiChar; const StartPos : integer) : integer;
function ZStrCompare(P1,P2 : PAnsiChar) : boolean;
procedure ZStrSubString(const Str,Dest : PAnsiChar; const StartPos,NChars : integer);
function ZStrToInt(const Str : PAnsiChar) : integer;

//Garbage collected managed heap
function ManagedHeap_Alloc(const Size : integer) : pointer;
function ManagedHeap_GetAllocCount : integer;
procedure ManagedHeap_GarbageCollect(Full : boolean);
procedure ManagedHeap_AddTarget(const P : pointer);
procedure ManagedHeap_RemoveTarget(const P : pointer);
{$ifndef minimal}
function ManagedHeap_GetStatus : string;
{$endif}


{$ifndef minimal}
const
  FloatTypes : set of TZPropertyType = [zptFloat,zptScalar,zptRectf,zptColorf,zptVector3f];
  FloatTextDecimals = 4;  //Nr of fraction digits when presenting float-values as text

function GetPropRefAsString(const PRef : TZPropertyRef) : string;

var
  DesignerPreviewProducer : TZComponent;
{$endif}

implementation

uses ZMath,ZLog,ZPlatform
  {$ifndef minimal},Classes,LibXmlParser,AnsiStrings,SysUtils,Math,zlib, ZApplication,
  Generics.Collections,Zc_Ops
  {$endif}
  ;


type
{$IFNDEF MINIMAL}
  TZOutputStream = class(TMemoryStream)
  private
    IsBitMode : boolean;
    BitNo : integer;
    Bits : byte;
  protected
    procedure BitsBegin;
    procedure WriteBit(B : boolean);
    procedure BitsEnd;
  end;

  TZWriter = class
  private
    Stream : TZOutputStream;
    Root : TZComponent;
    procedure DoWriteComponent(C : TZComponent); virtual; abstract;
    procedure Write(const B; Count : integer);
    procedure OnDocumentStart; virtual; abstract;
    procedure OnDocumentEnd; virtual; abstract;
  public
    constructor Create(Stream : TZOutputStream);
    procedure WriteRootComponent(C : TZComponent);
  end;

  //Write a component as xml
  TZXmlWriter = class(TZWriter)
  private
    IndentLevel : integer;
    OldSeparator : char;
    procedure LevelDown;
    procedure LevelUp;
    procedure WriteString(const S : string);
    procedure WriteLine(const S : string);
    procedure OnDocumentStart; override;
    procedure OnDocumentEnd; override;
    procedure DoWriteComponent(C : TZComponent); override;
  end;

  //Sepearate stream for each property-type
  //Main-stream (Stream) contains ClassIDs and propmasks
  TZBinaryWriter = class(TZWriter)
  private
    AssignedObjs : TZArrayList;
    PStreams : array[TZPropertyType] of TZOutputStream;
    procedure OnDocumentStart; override;
    procedure OnDocumentEnd; override;
    procedure DoWriteComponent(C : TZComponent); override;
  end;
{$ENDIF}

  TZReader = class
  private
    function DoReadComponent(OwnerList : TZComponentList) : TZComponent; virtual; abstract;
    procedure OnDocumentStart; virtual; abstract;
    procedure OnDocumentEnd; virtual; abstract;
    function ReadRootComponent : TZComponent;
  end;

  TZBinaryReader = class(TZReader)
  private
    PStreams : array[TZPropertyType] of TZInputStream;
    Stream : TZInputStream;
    FixUps,PropFixUps : TZArrayList;
    ObjIds : TZArrayList;
    procedure OnDocumentStart; override;
    procedure OnDocumentEnd; override;
    procedure Read(var B; Count : integer);
    function DoReadComponent(OwnerList : TZComponentList) : TZComponent; override;
    constructor Create(Stream : TZInputStream);
  end;

{$IFNDEF MINIMAL}
  TZXmlFixUp = class
    Name,PropName : string;
    Prop : TZProperty;
    Obj : TZComponent;
  end;

  TZXmlReader = class(TZReader)
  private
    MainXml : LibXmlParser.TXmlParser;
    FixUps : TZArrayList;
    SymTab : TSymbolTable;
    OldSeparator : char;
    ExternalSymTab : boolean;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromString(const XmlData: string; SymTab : TSymbolTable);
    function DoReadComponent(OwnerList : TZComponentList) : TZComponent; override;
    function XmlDoReadComponent(Xml : TXmlParser; OwnerList : TZComponentList) : TZComponent;
    procedure OnDocumentStart; override;
    procedure OnDocumentEnd; override;
  end;
{$ENDIF}

const
  TBinaryNested : set of TZPropertyType = [zptComponentList,zptExpression];

{$ifndef MINIMAL}
//Manage memory for strings set in designer
var
  StringCache : TDictionary<AnsiString,AnsiString>;
{$endif}


//Managed Heap
var
  mh_Targets,mh_Allocations,mh_Values : TZArrayList;
  mh_LastCount : integer;

const
  NilString : AnsiChar = #0;

procedure ManagedHeap_Create;
begin
  mh_Targets := TZArrayList.CreateReferenced;
  mh_Allocations := TZArrayList.CreateReferenced;
  mh_Values := TZArrayList.CreateReferenced;
end;

procedure ManagedHeap_FreeMem(const P : pointer);
begin
  mh_Allocations.SwapRemove(P);
  FreeMem(P);
end;

procedure ManagedHeap_Destroy;
begin
  while mh_Allocations.Count>0 do
    ManagedHeap_FreeMem( pointer(mh_Allocations[mh_Allocations.Count-1]) );
  mh_Targets.Free;
  mh_Allocations.Free;
  mh_Values.Free;
end;

function ManagedHeap_Alloc(const Size : integer) : pointer;
begin
  {$ifndef minimal}
  ZAssert(Size>=0,'Alloc called with size <=0');
  ZAssert(Size<1024*1024*128,'Alloc called with size > 128mb');
  {$endif}
  GetMem(Result,Size);
  mh_Allocations.Add(Result);
end;

procedure ManagedHeap_AddTarget(const P : pointer);
begin
  {$ifndef minimal}
  if mh_Targets.IndexOf(P)>-1 then
  begin
    GetLog('MH').Warning('Add target already in list');
    Exit;
  end;
  {$endif}
  mh_Targets.Add(P);
end;

procedure ManagedHeap_RemoveTarget(const P : pointer);
begin
  {$ifndef minimal}
  if mh_Targets.IndexOf(P)=-1 then
  begin
    GetLog('MH').Warning('Remove target not found');
    Exit;
  end;
  {$endif}
  mh_Targets.SwapRemove(P);
end;

function ManagedHeap_GetAllocCount : integer;
begin
  Result := mh_Allocations.Count;
end;

{$ifndef minimal}
function ManagedHeap_GetStatus : string;
begin
  Result := IntToStr(mh_Allocations.Count) + ' (t: ' + IntToStr(mh_Targets.Count) + ')';
end;
{$endif}

procedure ManagedHeap_GarbageCollect(Full : boolean);
var
  I,J : integer;
  PP : PPointer;
  P : pointer;
begin
  if mh_Allocations.Count=mh_LastCount then
    //Heap is stable since last call, no point in collecting
    Exit;
  mh_LastCount := mh_Allocations.Count;

  //Fill a list with all the current values of all variables that can hold a allocated pointer
  mh_Values.Clear;
  for I := 0 to mh_Targets.Count - 1 do
  begin
    PP := PPointer(mh_Targets[I]);
    P := PP^;
    if (P<>nil) and (P<>@NilString) then
      mh_Values.Add(P);
  end;

  I := 0;
  while I<mh_Allocations.Count do
  begin
    P := Pointer(mh_Allocations[I]);
    J := mh_Values.IndexOf(P);
    if J=-1 then
    begin
      //Pointer is no longer used
      FreeMem(P);
      mh_Allocations.SwapRemoveAt(I);
    end
    else
    begin
      //Pointer is used, remove this value to keep mh_Values as short as possible
      mh_Values.SwapRemoveAt(J);
      Inc(I);
    end;
  end;
end;


//Accessfunctions for componentmanager
var
  _ComponentManager : TZComponentManager = nil;

function ComponentManager : TZComponentManager;
begin
  if _ComponentManager = nil then
    _ComponentManager := TZComponentManager.Create;
  Result := _ComponentManager;
end;

procedure Register(C : TZComponentClass; ClassId : TZClassIds);
begin
  ComponentManager.Register(C,ClassId);
end;


{ TZComponent }

constructor TZComponent.Create(OwnerList: TZComponentList);
var
  PropList : TZPropertyList;
  Prop : TZProperty;
  I : integer;
  List : TZComponentList;
  P : Pointer;
begin
  PropList := GetProperties;
  for I := 0 to PropList.Count-1 do
  begin
    Prop := TZProperty(PropList[I]);
    //Initialize list properties
    case Prop.PropertyType of
      zptComponentList :
        begin
          List := TZComponentList.Create(Self);
          PPointer(GetPropertyPtr(Prop,0))^ := List;
        end;
      zptExpression :
        begin
          List := TZComponentList.Create;
          PZExpressionPropValue(GetPropertyPtr(Prop,0))^.Code := List;
        end;
      zptString :
        begin
          P := GetPropertyPtr(Prop,0);
          if Prop.IsStringTarget then
            ManagedHeap_AddTarget(P);
          PPointer(P)^ := @NilString;
        end;
    end;
    //Set defaultvalue for property
    //todo: Robustare s�tt att testa ifall defaultv�rde finns, generic4 �r < sizeof(value)
    if (Prop.DefaultValue.GenericValue[0]<>0) or
      (Prop.DefaultValue.GenericValue[1]<>0) or
      (Prop.DefaultValue.GenericValue[2]<>0)
     {$ifndef minimal}or
       (Prop.DefaultValue.StringValue<>'') or (Prop.DefaultValue.ExpressionValue.Source<>'')
     {$endif}
     then
      SetProperty(Prop,Prop.DefaultValue);
  end;

  //add to ownerlist
  if OwnerList <> nil then
    OwnerList.AddComponent(Self);
end;


destructor TZComponent.Destroy;
var
  PropList : TZPropertyList;
  Prop : TZProperty;
  Value : TZPropertyValue;
  I : integer;
begin
  //Remove from ownerlist
  if OwnerList <> nil then
    OwnerList.RemoveComponent(Self);
  //Release memory for properties
  PropList := GetProperties;
  for I := 0 to PropList.Count-1 do
  begin
    Prop := TZProperty(PropList[I]);
    case Prop.PropertyType of
      zptComponentList :
        begin
          GetProperty(Prop,Value);
          Value.ComponentListValue.Free;
        end;
      zptExpression :
        begin
          GetProperty(Prop,Value);
          Value.ExpressionValue.Code.Free;
        end;
      zptString :
        begin
          if Prop.IsStringTarget then
            ManagedHeap_RemoveTarget(GetPropertyPtr(Prop,0));
        end;
      {$ifndef minimal}
      zptBinary :
        begin
          //Frig�r binary mem enbart i designer.
          //I minimal s� klonas binary genom att peka p� samma source, mem skulle
          //d� frig�ras flera g�nger.
          GetProperty(Prop,Value);
          FreeMem(Value.BinaryValue.Data);
        end;
      {$endif}
    end;
  end;
  inherited;
end;

procedure TZComponent.DefineProperties(List: TZPropertyList);
begin
  {$IFNDEF MINIMAL}
  List.AddProperty('Name', integer(@Name), zptString);
    List.SetDesignerProperty;
    List.GetLast.NeedRefreshNodeName := True;
  List.AddProperty('Comment', integer(@Comment), zptString);
    List.SetDesignerProperty;
    List.GetLast.NeedRefreshNodeName := True;
  List.AddProperty('DesignDisable', integer(@DesignDisable), zptBoolean);
    List.SetDesignerProperty;
    List.GetLast.NeedRefreshNodeName := True;
  {$ENDIF}
  List.AddProperty({$IFNDEF MINIMAL}'ObjId',{$ENDIF}integer(@ObjId), zptInteger);
    {$IFNDEF MINIMAL}
    List.GetLast.ExcludeFromXml := True;
    List.GetLast.IsReadOnly := True;
    {$ENDIF}
    List.GetLast.DontClone := True;
end;

procedure TZComponent.GetProperty(Prop: TZProperty; var Value: TZPropertyValue);
var
  P : pointer;
begin
  P := pointer(integer(Self) + Prop.Offset);
  case Prop.PropertyType of
    zptFloat,zptScalar :
      Value.FloatValue := PFloat(P)^;
    zptString :
      {$IFDEF MINIMAL}
      Value.StringValue := PAnsiChar(PPointer(P)^);
      {$ELSE}
      Value.StringValue := PAnsiChar(PPointer(P)^);
      {$ENDIF}
    zptComponentRef :
      Value.ComponentValue := TZComponent(PPointer(P)^);
    zptInteger :
      Value.IntegerValue := PInteger(P)^;
    zptRectf :
      Value.RectfValue := PRectf(P)^;
    zptColorf :
      Value.ColorfValue := PColorf(P)^;
    zptPropertyRef :
      Value.PropertyValue := PZPropertyRef(PPointer(P))^;
    zptVector3f :
      Value.Vector3fValue := PZVector3f(P)^;
    zptComponentList :
      Value.ComponentListValue := TZComponentList(PPointer(P)^);
    zptByte :
      Value.ByteValue := PByte(P)^;
    zptBoolean :
      Value.BooleanValue := PBoolean(P)^;
    zptExpression :
      {$ifdef minimal}
      Value.ExpressionValue.Code := TZComponentList(PPointer(P)^);
      {$else}
      Value.ExpressionValue := PZExpressionPropValue(P)^;
      {$endif}
    zptBinary :
      Value.BinaryValue := PZBinaryPropValue(P)^;
    {$ifdef minimal}
    else
      ZHalt('GetProperty no handler');
    {$endif}
  end;
end;

procedure TZComponent.SetProperty(Prop: TZProperty; const Value: TZPropertyValue);
var
  P : pointer;
  {$ifndef MINIMAL}
  S : ansistring;
  {$endif}
begin
  P := pointer(integer(Self) + Prop.Offset);
  case Prop.PropertyType of
    zptFloat,zptScalar :
      PFloat(P)^ := Value.FloatValue;
    zptString :
      {$IFDEF MINIMAL}
      //string ska vara immutable.
      PPAnsiChar(P)^ := Value.StringValue;
      {$ELSE}
      begin
        S := Value.StringValue + #0;
        if not StringCache.ContainsKey(S) then
          StringCache.Add(S,S);
        PPointer(P)^ := @StringCache[S][1];
      end;
      {$ENDIF}
    zptComponentRef :
      PPointer(P)^ := pointer(Value.ComponentValue);
    zptInteger :
      PInteger(P)^ := Value.IntegerValue;
    zptByte :
      PByte(P)^ := Value.ByteValue;
    zptRectf :
      PRectf(P)^ := Value.RectfValue;
    zptColorf :
      PColorf(P)^ := Value.ColorfValue;
    zptPropertyRef :
      PZPropertyRef(P)^ := Value.PropertyValue;
    zptVector3f :
      PZVector3f(P)^ := Value.Vector3fValue;
    zptComponentList :
      begin
        {$IFNDEF MINIMAL}
        //M�ste tilldelas till samma v�rde, annars s� ska vi g�ra free p� �ldre v�rdet
        Assert(PPointer(P)^ = pointer(Value.ComponentListValue));
        {$ENDIF}
        //On�digt att tilldela samma v�rde
        //PPointer(P)^ := pointer(Value.ComponentListValue);
      end;
    zptBoolean :
      PBoolean(P)^ := Value.BooleanValue;
    zptExpression :
      {$ifdef minimal}
      //Tilldelas ej direkt i minimal. Skapas i create och fylls p� i binary-load.
      ;
      {$else}
      PZExpressionPropValue(P)^.Source := Value.ExpressionValue.Source;  //Tool tilldelar source-str�ngen
      {$endif}
    zptBinary :
      begin
        {$ifndef minimal}
        if PZBinaryPropValue(P)^.Size>0 then
          FreeMem(PZBinaryPropValue(P)^.Data);
        {$endif}
        PZBinaryPropValue(P)^ := Value.BinaryValue;
      end
    {$ifdef minimal}
    else
      ZHalt('SetProperty no handler');
    {$endif}
  end;
  Change;
end;

function TZComponent.GetProperties: TZPropertyList;
begin
  Result := ComponentManager.GetProperties(Self);
end;



//Returnerar pekare till property-value
//Anv�nds f�r att hitta target f�r propertyrefs
function TZComponent.GetPropertyPtr(Prop: TZProperty; Index: integer): pointer;
begin
  Result := pointer(integer(Self) + Prop.Offset);
  if Index>0 then
    Result := pointer(integer(Result) + Index*4);
end;

procedure TZComponent.Change;
begin
  IsChanged := True;
  //todo b�ttre hantering av change beh�vs nog
  if (OwnerList<>nil) then
    OwnerList.Change;
end;

procedure TZComponent.Update;
begin
  //
end;

procedure CloneAssignObjectIds(C : TZComponent; ObjIds,CleanUps : TZArrayList);
//Assigns all objects in tree with unique object-ids
var
  PropList : TZPropertyList;
  Prop : TZProperty;
  Value : TZPropertyValue;
  I,J : integer;
begin
  C.ObjId := ObjIds.Count;
  ObjIds.Add(nil);
  CleanUps.Add(@C.ObjId);
  PropList := C.GetProperties;
  for I := 0 to PropList.Count-1 do
  begin
    Prop := TZProperty(PropList[I]);
    case Prop.PropertyType of
      zptComponentList :
        begin
          C.GetProperty(Prop,Value);
          for J := 0 to Value.ComponentListValue.ComponentCount-1 do
            CloneAssignObjectIds(TZComponent(Value.ComponentListValue[J]),ObjIds,CleanUps);
        end;
      zptExpression :
        begin
          C.GetProperty(Prop,Value);
          for J := 0 to Value.ExpressionValue.Code.ComponentCount-1 do
            CloneAssignObjectIds(TZComponent(Value.ExpressionValue.Code[J]),ObjIds,CleanUps);
        end;
    end;
  end;
end;

function TZComponent.Clone: TZComponent;
var
  ObjIds,CleanUps,Fixups : TZArrayList;
  I,Id : integer;
  P : PPointer;
begin
{
  Set ObjIDs for this component and all children
  Clone children recursively
  If ref to component with ObjID set, keep in Fixup-list
  Every clone writes itself to ObjIds which is a map objid->cloned component replacing original.objid
  Loop fixups and set component references
  Zero out assigned objids
}
  ObjIds := TZArrayList.CreateReferenced;
  ObjIds.Add(nil);
  CleanUps := TZArrayList.CreateReferenced;
  FixUps := TZArrayList.CreateReferenced;
  CloneAssignObjectIds(Self,ObjIds,CleanUps);
  Result := DoClone(ObjIds,FixUps);

  //component references
  for I := 0 to FixUps.Count-1 do
  begin
    P := PPointer(FixUps[I]);
    Id := TZComponent(P^).ObjId;
    P^ := ObjIds[Id];
  end;
  FixUps.Free;

  ObjIds.Free;
  //Zero out objids after whole tree is cloned
  for I := 0 to CleanUps.Count-1 do
    PInteger(CleanUps[I])^:=0;
  CleanUps.Free;
end;



function TZComponent.DoClone(ObjIds,FixUps : TZArrayList): TZComponent;
var
  PropList : TZPropertyList;
  Prop : TZProperty;
  Value,Tmp : TZPropertyValue;
  I : integer;

  procedure InCloneList(List,DestList : TZComponentList);
  var
    I : integer;
    C : TZComponent;
  begin
    for I := 0 to List.Count-1 do
    begin
      C := List.GetComponent(I);
      DestList.AddComponent( C.DoClone(ObjIds,FixUps) );
    end;
  end;

begin
  Result := TZComponentClass(Self.ClassType).Create(nil);
  ObjIds[ Self.ObjId ] := Result;
  PropList := GetProperties;
  for I := 0 to PropList.Count-1 do
  begin
    Prop := TZProperty(PropList[I]);
    if Prop.DontClone then
      Continue; //Skip properties like: objid, model.personality
    GetProperty(Prop,Value);
    case Prop.PropertyType of
      zptComponentRef :
        begin
          Result.SetProperty(Prop,Value);
          if (Value.ComponentValue<>nil) and (Value.ComponentValue.ObjId<>0) then
            FixUps.Add( TObject(PPointer(integer(Result) + Prop.Offset)) );
        end;
      zptPropertyRef :
        begin
          Result.SetProperty(Prop,Value);
          if (Value.PropertyValue.Component<>nil) and (Value.PropertyValue.Component.ObjId<>0) then
            FixUps.Add( TObject(PPointer(integer(Result) + Prop.Offset)) );
        end;
      zptComponentList :
        begin
          Result.GetProperty(Prop,Tmp);
          InCloneList(Value.ComponentListValue,Tmp.ComponentListValue);
        end;
      zptExpression :
        begin
          Result.GetProperty(Prop,Tmp);
          InCloneList(Value.ExpressionValue.Code,Tmp.ExpressionValue.Code);
          {$ifndef minimal}
          //Also copy source if in designer
          Tmp.ExpressionValue.Source := Value.ExpressionValue.Source;
          Result.SetProperty(Prop,Tmp);
          {$endif}
        end;
      {$ifndef minimal}
      zptBinary :
        begin
          //Kopiera binary mem enbart i designer.
          //I minimal s� klonas binary genom att peka p� samma source
          GetMem(Tmp.BinaryValue.Data,Value.BinaryValue.Size);
          Tmp.BinaryValue.Size := Value.BinaryValue.Size;
          Move(Value.BinaryValue.Data^,Tmp.BinaryValue.Data^,Value.BinaryValue.Size);
          Result.SetProperty(Prop,Tmp);
        end;
      {$endif}
    else
      Result.SetProperty(Prop,Value);
    end;
  end;
end;

{$ifndef minimal}
function TZComponent.GetDisplayName: AnsiString;
var
  S,Cn : AnsiString;
begin
  S := Self.Name;
  Cn := AnsiString(ComponentManager.GetInfo(Self).ZClassName);
  if Length(S)=0 then
    S := Cn
  else
    S := S + ' : ' + Cn;
  Result := S;
end;

procedure TZComponent.SetString(const PropName : string; const Value : AnsiString);
var
  P : TZProperty;
  Pv : TZPropertyValue;
begin
  P := Self.GetProperties.GetByName(PropName);
  Pv.StringValue := Value;
  Self.SetProperty(P,Pv);
end;

procedure TZComponent.DesignerReset;
var
  PropList : TZPropertyList;
  Prop : TZProperty;
  Value : TZPropertyValue;
  I : integer;
begin
  //Reset all components in componentlists
  //This will reset Timers etc.
  PropList := GetProperties;
  for I := 0 to PropList.Count-1 do
  begin
    Prop := TZProperty(PropList[I]);
    case Prop.PropertyType of
      zptComponentList :
        begin
          GetProperty(Prop,Value);
          Value.ComponentListValue.DesignerReset;
        end;
    end;
  end;
end;

procedure TZComponent.DesignerFreeResources;
var
  PropList : TZPropertyList;
  Prop : TZProperty;
  Value : TZPropertyValue;
  I,J : integer;
begin
  PropList := GetProperties;
  for I := 0 to PropList.Count-1 do
  begin
    Prop := TZProperty(PropList[I]);
    case Prop.PropertyType of
      zptComponentList :
        begin
          GetProperty(Prop,Value);
          for J := 0 to Value.ComponentListValue.Count - 1 do
            (Value.ComponentListValue[J] as TZComponent).DesignerFreeResources;
        end;
    end;
  end;
end;


function TZComponent.GetOwner : TZComponent;
begin
  if Assigned(OwnerList) then
    Result := OwnerList.Owner
  else
    Result := nil;
end;

procedure TZComponent.GetAllChildren(List : TObjectList; IncludeExpressions : boolean);
//Returns all objects
var
  PropList : TZPropertyList;
  Prop : TZProperty;
  Value : TZPropertyValue;
  I,J : integer;
begin
  List.Add(Self);
  PropList := Self.GetProperties;
  for I := 0 to PropList.Count-1 do
  begin
    Prop := TZProperty(PropList[I]);
    case Prop.PropertyType of
      zptComponentList :
        begin
          Self.GetProperty(Prop,Value);
          for J := 0 to Value.ComponentListValue.ComponentCount-1 do
            TZComponent(Value.ComponentListValue[J]).GetAllChildren(List,IncludeExpressions);
        end;
      zptExpression :
        begin
          if IncludeExpressions then
          begin
            Self.GetProperty(Prop,Value);
            for J := 0 to Value.ExpressionValue.Code.ComponentCount-1 do
              TZComponent(Value.ExpressionValue.Code[J]).GetAllChildren(List,IncludeExpressions);
          end;
        end;
    end;
  end;
end;
{$endif}

function MakeColorf(const R,G,B,A : single) : TZColorf;
begin
  Result.R := R;
  Result.G := G;
  Result.B := B;
  Result.A := A;
end;



{ TZArrayList }

procedure TZArrayList.Add(Item: TObject);
begin
  if FCount = Capacity then
    Grow;
  List^[FCount] := Item;
  Inc(FCount);
end;

procedure TZArrayList.Clear;
var
  I : integer;
begin
  if ReferenceOnly then
    FCount := 0
  else
    for I := FCount - 1 downto 0 do
      RemoveAt(I);
end;

destructor TZArrayList.Destroy;
begin
  Clear;
  if List<>nil then
    FreeMem(List);
  inherited;
end;

{$ifndef minimal}
procedure TZArrayList.CheckValidIndex(Index: Integer);
begin
  if (Index < 0) or (Index >= FCount) then
    ZHalt('ZArrayList bad index');
end;
{$endif}

function TZArrayList.GetItem(Index: Integer): TObject;
begin
  {$ifndef minimal}CheckValidIndex(Index);{$endif}
  Result := List^[Index];
end;

function TZArrayList.GetPtrToItem(Index: Integer): pointer;
begin
  {$ifndef minimal}CheckValidIndex(Index);{$endif}
  Result := @List^[Index];
end;

procedure TZArrayList.Swap(Index1,Index2 : integer);
var
  Tmp : TObject;
begin
  Tmp := List^[Index1];
  List^[Index1] := List^[Index2];
  List^[Index2] := Tmp;
end;

procedure TZArrayList.SetItem(Index: Integer; const Value: TObject);
begin
  {$ifndef minimal}CheckValidIndex(Index);{$endif}
  List^[Index] := Value;
end;

procedure TZArrayList.Grow;
var
  Delta: Integer;
begin
  if Capacity > 64 then
    Delta := Capacity div 4
  else
    if Capacity > 8 then
      Delta := 16
    else
      Delta := 4;
  Inc(Capacity,Delta);
  ReallocMem(List, Capacity * SizeOf(Pointer));
end;

function TZArrayList.IndexOf(Item: TObject): Integer;
begin
  Result := 0;
  while (Result < FCount) and (List^[Result] <> Item) do
    Inc(Result);
  if Result = FCount then
    Result := -1;
end;

procedure TZArrayList.RemoveAt(Index: integer);
var
  Temp: TObject;
begin
  {$ifndef minimal}CheckValidIndex(Index);{$endif}
  Temp := List^[Index];
  Dec(FCount);
  if Index < FCount then
    System.Move(List^[Index + 1], List^[Index],
      (FCount - Index) * SizeOf(Pointer));
  if (not ReferenceOnly) and (Temp<>nil) then
    Temp.Free;
end;


function TZArrayList.Last: TObject;
begin
  Result := Items[ Count-1 ];
end;

procedure TZArrayList.Remove(Item: TObject);
begin
  RemoveAt( IndexOf(Item) );
end;

procedure TZArrayList.SwapRemove(Item: TObject);
begin
  SwapRemoveAt( IndexOf(Item) );
end;

procedure TZArrayList.SwapRemoveAt(Index: integer);
var
  Temp: TObject;
begin
  //Remove by replacing item at index with last and decreasing count.
  //Avoids system.move call.
  Temp := List^[Index];
  if (FCount>1) and (Index<>FCount-1) then
    List^[Index] := Last;
  Dec(FCount);
  if (not ReferenceOnly) and (Temp<>nil) then
    Temp.Free;
end;

function TZArrayList.Pop: TObject;
begin
  Result := Last;
  RemoveAt(Count-1);
end;

procedure TZArrayList.Push(Item: TObject);
begin
  Add(Item);
end;

constructor TZArrayList.CreateReferenced;
begin
  ReferenceOnly := True;
end;


{ TZComponentManager }

function TZComponentManager.GetInfo(Component: TZComponent) : TZComponentInfo;
var
  C : TZComponentClass;
  I : TZClassIds;
  Ci : TZComponentInfo;
begin
  //todo borde ligga i hashlist
  C := TZComponentClass(Component.ClassType);

  for I := Low(ComponentInfos) to High(ComponentInfos) do
  begin
    Ci := ComponentInfos[I];
    if Ci=nil then
      Continue;
    if Ci.ZClass=C then
    begin
      Result := Ci;
      Exit;
    end;
  end;
  {$IFNDEF MINIMAL}
//  ZHalt('getinfocomponent returned nil:' + Component.ClassName);
  raise Exception.Create('getinfocomponent not found: ' + Component.ClassName);
  {$ELSE}
  Result := nil;
  {$ENDIF}
end;


function TZComponentManager.GetInfoFromId(ClassId: TZClassIds): TZComponentInfo;
begin
  Result := ComponentInfos[ClassId];
  {$IFNDEF MINIMAL}
  Assert(Result.ClassId=ClassId);
  {$ENDIF}
end;

{$IFNDEF MINIMAL}
function TZComponentManager.GetInfoFromName(const ZClassName: string): TZComponentInfo;
var
  I : TZClassIds;
  Ci : TZComponentInfo;
begin
  for I := Low(ComponentInfos) to High(ComponentInfos) do
  begin
    Ci := ComponentInfos[I];
    if Ci=nil then
      Continue;
    if SysUtils.SameText(Ci.ZClassName,ZClassName) then
    begin
      Result := Ci;
      Exit;
    end;
  end;
  raise Exception.Create('Class not found: ' + ZClassName);
end;
{$ENDIF}

procedure TZComponentManager.Register(C: TZComponentClass; ClassId : TZClassIds);
var
  Ci : TZComponentInfo;
begin
  Ci := TZComponentInfo.Create;
  Ci.ZClass := C;
  Ci.ClassId := ClassId;
  {$IFNDEF MINIMAL}
  Ci.ZClassName := Copy(C.ClassName,2,100);
  {$ENDIF}
  {$if (not defined(MINIMAL)) or defined(zzdc_activex)}
  LastAdded := Ci;
  {$ifend}
  ComponentInfos[Ci.ClassId] := Ci;
end;

{$IFNDEF MINIMAL}
destructor TZComponentManager.Destroy;
var
  I : TZClassIds;
  Ci : TZComponentInfo;
begin
  for I := Low(ComponentInfos) to High(ComponentInfos) do
  begin
    Ci := ComponentInfos[I];
    if (Ci=nil) then
      Continue;
    if (Ci.Properties<>nil) then
      Ci.Properties.Free;
    Ci.Free;
  end;
  inherited;
end;

//Stream component and all children to a binary stream
//Result can be cast to TMemoryStream
function TZComponentManager.SaveBinaryToStream(Component : TZComponent) : TObject;
var
  Stream : TZOutputStream;
  Writer : TZWriter;
begin
  Stream := TZOutputStream.Create;
  Writer := TZBinaryWriter.Create(Stream);
  try
    Writer.WriteRootComponent(Component);
  finally
    Writer.Free;
  end;
  Result := Stream;
end;

//Stream component and all children to a xml stream
//Result can be cast to TMemoryStream
function TZComponentManager.SaveXmlToStream(Component: TZComponent) : TObject;
var
  Stream : TZOutputStream;
  Writer : TZWriter;
begin
  Stream := TZOutputStream.Create;
  Writer := TZXmlWriter.Create(Stream);
  try
    Writer.WriteRootComponent(Component);
  finally
    Writer.Free;
  end;
  Result := Stream;
end;


procedure TZComponentManager.SaveXml(Component: TZComponent; FileName: string);
var
  Stream : TZOutputStream;
begin
  ZLog.GetLog(Self.ClassName).Write('Saving: ' + FileName);
  Stream := SaveXmlToStream(Component) as TZOutputStream;
  try
    Stream.SaveToFile(FileName);
  finally
    Stream.Free;
  end;
end;

function TZComponentManager.LoadXmlFromFile(FileName: string): TZComponent;
var
  Reader : TZXmlReader;
begin
  Reader := TZXmlReader.Create;
  try
    Reader.LoadFromFile(FileName);
    Result := Reader.ReadRootComponent;
  finally
    Reader.Free;
  end;
end;

function TZComponentManager.LoadXmlFromString(const XmlData: string; SymTab : TSymbolTable): TZComponent;
var
  Reader : TZXmlReader;
begin
  Reader := TZXmlReader.Create;
  try
    Reader.LoadFromString(XmlData,SymTab);
    Result := Reader.ReadRootComponent;
  finally
    Reader.Free;
  end;
end;

function TZComponentManager.GetAllInfos: PComponentInfoArray;
begin
  Result := @ComponentInfos;
end;
{$ENDIF}

function TZComponentManager.LoadBinary: TZComponent;
var
  Stream : TZInputStream;
  Reader : TZBinaryReader;

  function InLoadPiggyback : TZInputStream;
  var
    FileName : PAnsiChar;
    DataSize,Magic : integer;
    Stream : TZInputStream;
  begin
    Result := nil;
    Filename := Platform_GetExeFileName;
    Stream := TZInputStream.CreateFromFile(FileName,False);
    if Stream.Size<=0 then
      Exit;
    Stream.Position := Stream.Size - 8;
    Stream.Read(DataSize,4);
    Stream.Read(Magic,4);
    if (Magic<>$01020304) then
      Exit;
    //Set position to start of stream
    Stream.Position := Stream.Size - 8 - DataSize;
    //Problem with verifying piggyback: binaryreader is dependent on stream size
    //Remove magic nr from stream end
    Dec(Stream.Size,4);
    Result := Stream;
  end;

begin
  //First check linked data, returns nil if not present
  Stream := Platform_LoadLinkedResource;
  //Second: check piggyback data
  if Stream=nil then
    Stream := InLoadPiggyback;
  //Last try: load from file
  if Stream=nil then
    Stream := TZInputStream.CreateFromFile('zzdc.dat',True);
  {$ifdef zlog}
  if Stream=nil then
    ZHalt('no data');
  {$endif}

  Reader := TZBinaryReader.Create(Stream);
  Result := Reader.ReadRootComponent;
  Reader.Free;
  Stream.Free;
end;

function TZComponentManager.GetProperties(Component: TZComponent): TZPropertyList;
var
  Ci : TZComponentInfo;
begin
  //Returnerar propertylista f�r en komponent
  //Listan ligger i classinfon, initieras f�rsta g�ngen genom att anropa component.defineproperties
  //Listan kan ej skapas vid klassregistrering f�r att prop-adressoffsets endast kan ber�knas n�r instans finns.
  //Den h�r metoden �r private, App-kod ska anropa c.GetProperties
  Ci := GetInfo(Component);
  Result := Ci.Properties;
  if Result=nil then
  begin
    Result := TZPropertyList.Create;
    Result.TheSelf := integer(Component);
    Component.DefineProperties(Result);
    Ci.Properties := Result;
  end
  {$if (not defined(MINIMAL)) or defined(zzdc_activex)}
  else if Ci.HasGlobalData then
  begin
    //Components that use global variables must be single instance
    //and redefines their properties each time (AudioMixer).
    Result.TheSelf := integer(Component);
    Result.Clear;
    Result.NextId := 0;
    Component.DefineProperties(Result);
  end
  {$ifend};
end;


{ TZPropertyList }

function TZPropertyList.GetLast;
begin
  Result := TZProperty(Self.Last);
end;

{$IFNDEF MINIMAL}
procedure TZPropertyList.SetDesignerProperty;
begin
  //S�tt senaste prop till bara ska anv�ndas i designer (t.ex. Name)
  GetLast.ExcludeFromBinary := True;
  GetLast.IsReadOnly := True;
  //Avallokera senaste id, dessa m�ste vara konstanta f�r alla bin�rprops
  Dec(NextId);
end;

function TZPropertyList.GetByName(Name: string): TZProperty;
var
  I : integer;
begin
  for I := 0 to Count-1 do
  begin
    Result := TZProperty(Self[I]);
    if SameText(Result.Name,Name) then
      Exit;
  end;
  Result := nil;
end;

//Returnerar den f�rsta propertyn av en viss typ
function TZPropertyList.GetByType(Kind: TZPropertyType): TZProperty;
var
  I : integer;
begin
  for I := 0 to Count-1 do
  begin
    Result := TZProperty(Self[I]);
    if Result.PropertyType = Kind then
      Exit;
  end;
  Result := nil;
end;
{$ENDIF}

function TZPropertyList.GetById(PropId: integer): TZProperty;
var
  I : integer;
begin
  for I := 0 to Count-1 do
  begin
    Result := TZProperty(Self[I]);
    if Result.PropId=PropId then
      Exit;
  end;
  Result := nil;
end;

procedure TZPropertyList.AddProperty({$IFNDEF MINIMAL}const Name: string;{$ENDIF} const Offset: integer; const PropType : TZPropertyType);
var
  P : TZProperty;
begin
  P := TZProperty.Create;
  P.PropertyType := PropType;
  P.Offset := Offset-Self.TheSelf;

  P.PropId := NextId;
  Inc(NextId);
  {$IFNDEF MINIMAL}
  P.Name := Name;
  Assert( ((P.Offset>=0) and (P.Offset<4096)) or (TObject(Self.TheSelf).ClassName='TAudioMixer') );
  {$ENDIF}
  Self.Add(P);
end;

//No writers are included in minimal runtime binary

{ TZWriter }

{$IFNDEF MINIMAL}
procedure WriteVarLength(Stream : TStream; Value: integer);
var
  B : byte;
  W : word;
begin
  if Value<255 then
  begin //one byte
    B := Value;
    Stream.Write(B,1);
  end else
  begin //Larger than 255, write using three bytes
    Assert(Value<High(Word));
    B := 255;
    Stream.Write(B,1);
    W := Value;
    Stream.Write(W,2);
  end;
end;

constructor TZWriter.Create(Stream: TZOutputStream);
begin
  Self.Stream := Stream;
end;

procedure TZWriter.Write(const B; Count: integer);
begin
  Stream.Write(B,Count);
end;

procedure TZWriter.WriteRootComponent(C: TZComponent);
begin
  Root := C;
  OnDocumentStart;
  DoWriteComponent(C);
  OnDocumentEnd;
end;

{ TZBinaryWriter }

procedure TZBinaryWriter.DoWriteComponent(C: TZComponent);
var
  Ci : TZComponentInfo;
  B : byte;
  PropList : TZPropertyList;
  Value : TZPropertyValue;
  I,J,Temp : integer;
  Prop : TZProperty;
  PStream : TStream;
  AfterList : TZArrayList;

  procedure WriteNulls(Stream : TStream; Count : integer);
  var
    I : integer;
    B : byte;
  begin
    B := 0;
    for I := 0 to Count-1 do
      Stream.Write(B,1);
  end;

  procedure WriteScalar(Stream : TStream; F : single);
  var
    B : byte;
  begin
    //Assert( (F>=0) and (F<=1.0) );
    //todo: warn if out of range
    F := Clamp(F,0,1);
    B := Trunc(F*255);
    Stream.Write(B,1);
  end;

  procedure InWriteList(List : TZComponentList);
  var
    I,Count : integer;

    function InCountOneList(List : TZComponentList) : integer;
    var
      C : TZComponent;
      I : integer;
    begin
      Result := List.Count;
      for I := 0 to List.Count-1 do
      begin
        C := List.GetComponent(I);
        if ComponentManager.GetInfo(C).ExcludeFromBinary then
          Dec(Result);
        {if (C is TLogicalGroup) and (C<>Root) then
          //ParentComponent is ignored in stream
          Inc(Result, InCountOneList( (C as TLogicalGroup).Children ) );}
      end;
    end;

  begin
    Count := InCountOneList(List);
    WriteVarLength(Self.Stream,Count);
    if Count>0 then
      for I:=0 to List.Count-1 do
        //Try to write all, DoWriteComponent return directly if ExcludeFromBinary
        DoWriteComponent(List.GetComponent(I));
  end;

begin
  {if (C is TLogicalGroup) and (C<>Root) then
  begin //ParentComponent is ignored in stream
    for I := 0 to (C as TLogicalGroup).Children.Count-1 do
      DoWriteComponent( (C as TLogicalGroup).Children.GetComponent(I) );
    Exit;
  end;}

  Ci := ComponentManager.GetInfo(C);
  Assert(Ord(Ci.ClassId)<127);

  if Ci.ExcludeFromBinary then
    Exit;

  //First byte: Classid
  B := Ord(Ci.ClassId);
  Write(B,1);

  //write properties
  PropList := C.GetProperties;
  AfterList := TZArrayList.CreateReferenced;
  Stream.BitsBegin;
  for I := 0 to PropList.Count-1 do
  begin
    Prop := TZProperty(PropList[I]);
    if Prop.ExcludeFromBinary or Prop.NeverPersist then
      Continue;
    C.GetProperty(Prop,Value);
    PStream := PStreams[Prop.PropertyType];
    if Prop.IsDefaultValue(Value) then
    begin
      //Prop has default value, write 0 in bitmask and skip to next
      Stream.WriteBit(False);
      Continue;
    end;
    Stream.WriteBit(True);
    case Prop.PropertyType of
      zptString :
        begin
          //Write null-terminated string
          Temp := Length(Value.StringValue);
          if Temp>0 then
            PStream.Write(Value.StringValue[1],Temp);
          B := 0;
          PStream.Write(B,1);
        end;
      zptFloat :
        begin
          PStream.Write(Value.FloatValue,4);
        end;
      zptScalar :
        WriteScalar(PStream,Value.FloatValue);
      zptRectf :
        PStream.Write(Value.RectfValue,SizeOf(TZRectf));
      zptColorf :
        for J := 0 to 3 do
          WriteScalar(PStream,Value.ColorfValue.V[J]);
      zptInteger :
        PStream.Write(Value.IntegerValue,SizeOf(integer));
      zptComponentRef :
        if Value.ComponentValue=nil then
          //todo: should not need to test for nil, n�r vi har defaultfiltrering
          WriteNulls(PStream,4)
        else
          PStream.Write(Value.ComponentValue.ObjId,4);
      zptPropertyRef :
        if Value.PropertyValue.Component=nil then
          //todo: should not need to test for nil, n�r vi har defaultfiltrering
          WriteNulls(PStream,6)
        else
        begin
          PStream.Write(Value.PropertyValue.Component.ObjId,4);
          WriteVarLength(PStream,Value.PropertyValue.Prop.PropId);
          B := Value.PropertyValue.Index;
          PStream.Write(B,1);
        end;
      zptVector3f :
        PStream.Write(Value.Vector3fValue,SizeOf(TZVector3f));
      zptByte :
        PStream.Write(Value.ByteValue,SizeOf(byte));
      zptBoolean :
        PStream.Write(Value.BooleanValue,SizeOf(ByteBool));
      zptComponentList,zptExpression :
        AfterList.Add(Prop);
      zptBinary :
        begin
          PStream.Write(Value.BinaryValue.Size,SizeOf(Value.BinaryValue.Size));
          if Value.BinaryValue.Size>0 then
            PStream.Write(Value.BinaryValue.Data^,Value.BinaryValue.Size);
        end
    else
      ZHalt('TZBinaryWriter: No writehandler');
    end;
  end;
  Stream.BitsEnd;
  //Skriv n�stlade componenter efter�t s� att alla propbits
  //hamnar i main-stream f�rst.
  for I := 0 to AfterList.Count-1 do
  begin
    Prop := TZProperty(AfterList[I]);
    C.GetProperty(Prop,Value);
    case Prop.PropertyType of
      zptComponentList :
        InWriteList(Value.ComponentListValue);
      zptExpression :
        InWriteList(Value.ExpressionValue.Code);
    else
      ZHalt('TZBinaryWriter: No writehandler');
    end;
  end;
  AfterList.Free;
end;

procedure TZBinaryWriter.OnDocumentEnd;
var
  I : integer;
  P : TZPropertyType;
  PStream : TMemoryStream;
  PSizes : packed array[TZPropertyType] of integer;
begin
  //Appenda alla propertystreams, samt g�r free p� dessa
  FillChar(PSizes,SizeOf(PSizes),0);
  for P := Low(TZPropertyType) to High(TZPropertyType) do
    if not (P in TBinaryNested) then
    begin
      PStream := PStreams[P];
      PStream.Position := 0;
      PSizes[P]:=PStream.Size;
      if PStream.Size>0 then
        Write(PStream.Memory^,PStream.Size);
      PStream.Free;
    end;
  //Skriv dictionary med sizes f�r varje pstream
  Stream.Write(PSizes,SizeOf(PSizes));
  //Write size of data last, this is used for piggybacking
  I := Stream.Size;
  Write(I,4);
  //Remove assigned object ids
  for I := 0 to AssignedObjs.Count-1 do
    TZComponent(AssignedObjs[I]).ObjId := 0;
  AssignedObjs.Free;
end;

procedure TZBinaryWriter.OnDocumentStart;
var
  NextObjId : integer;

  procedure InGiveObjIds(C : TZComponent);
  var
    PropList : TZPropertyList;
    Prop : TZProperty;
    Value : TZPropertyValue;
    I,J : integer;

    procedure InGiveOne(C : TZComponent);
    begin
      if (C=nil) or (C.ObjId<>0) then
        Exit;
      Inc(NextObjId);
      C.ObjId := NextObjId;
      AssignedObjs.Add(C);
    end;

  begin
    {if (C is TLogicalGroup) and (C<>Root) then
    begin //ParentComponent is ignored in stream
      for I := 0 to (C as TLogicalGroup).Children.Count-1 do
        InGiveObjIds( (C as TLogicalGroup).Children.GetComponent(I) );
      Exit;
    end;}
    PropList := C.GetProperties;
    for I := 0 to PropList.Count-1 do
    begin
      Prop := TZProperty(PropList[I]);
      case Prop.PropertyType of
        zptComponentRef :
          begin
            C.GetProperty(Prop,Value);
            InGiveOne(Value.ComponentValue);
          end;
        zptPropertyRef :
          begin
            C.GetProperty(Prop,Value);
            InGiveOne(Value.PropertyValue.Component);
          end;
        zptComponentList :
          begin
            C.GetProperty(Prop,Value);
            for J := 0 to Value.ComponentListValue.ComponentCount-1 do
              InGiveObjIds(Value.ComponentListValue.GetComponent(J));
          end;
        zptExpression :
          begin
            C.GetProperty(Prop,Value);
            for J := 0 to Value.ExpressionValue.Code.ComponentCount-1 do
              InGiveObjIds(Value.ExpressionValue.Code.GetComponent(J));
          end;
      else
        Continue;
      end;
    end;
  end;

  procedure InCreatePStreams;
  var
    P : TZPropertyType;
  begin
    for P := Low(TZPropertyType) to High(TZPropertyType) do
      if not (P in TBinaryNested) then
        PStreams[P] := TZOutputStream.Create;
  end;

begin
  AssignedObjs := TZArrayList.Create;
  AssignedObjs.ReferenceOnly := True;
  NextObjId := 0;
  InGiveObjIds(Root);
  InCreatePStreams;
end;


{ TZXmlWriter }

procedure TZXmlWriter.DoWriteComponent(C: TZComponent);
var
  Ci : TZComponentInfo;
  PropList : TZPropertyList;
  Value : TZPropertyValue;
  I,J : integer;
  Prop : TZProperty;
  S,V : string;
  NormalProps,NestedProps : TObjectList;

  function InFloat(F : single) : string;
  begin
    Result := FloatToStr( RoundTo( F ,-FloatTextDecimals) );
  end;

  function InArray(const A : array of single) : string;
  var
    I : integer;
    S : string;
  begin
    S := '';
    for I := 0 to High(A) do
      S:=S + InFloat(A[I]) + ' ';
    Result := Trim(S);
  end;

  function InAttrValue(const S : ansistring) : string;
  begin
    Result := String(S);
    Result := StringReplace(Result,'&','&amp;',[rfReplaceAll]);
    Result := StringReplace(Result,'"','&quot;',[rfReplaceAll]);
    Result := StringReplace(Result,'<','&lt;',[rfReplaceAll]);
    Result := StringReplace(Result,'>','&gt;',[rfReplaceAll]);
    Result := StringReplace(Result,'''','&apos;',[rfReplaceAll]);
  end;

  function InGetBinary(const BinaryValue : TZBinaryPropValue) : string;
  var
    Zs : zlib.TCompressionStream;
    Mem : TMemoryStream;
  begin
    Mem := TMemoryStream.Create;
    try
      Zs := TCompressionStream.Create(clMax,Mem);
      try
        Zs.Write(BinaryValue.Data^,BinaryValue.Size)
      finally
        Zs.Free;
      end;
      Mem.Position:=0;
      SetLength(Result,Mem.Size*2);
      Classes.BinToHex(PAnsiChar(Mem.Memory),PChar(Result),Mem.Size);
    finally
      Mem.Free;
    end;
  end;

  function SafeCdata(const S : ansistring) : string;
  begin
    Result := String(S);
    //Cdata cannot contain ']]>' string
    if Pos(']]>',Result)>0 then
      //As recommended here: http://en.wikipedia.org/wiki/CDATA
      //Result := StringReplace(S,']]>',']]]]><![CDATA[>',[rfReplaceAll])
      //This is simpler to parse
      Result := StringReplace(Result,']]>',']] >',[rfReplaceAll])
  end;

begin
  Ci := ComponentManager.GetInfo(C);

  NormalProps := TObjectList.Create(False);
  NestedProps := TObjectList.Create(False);
  try
    //G� igenom props f�r att ta reda p� vilka som ska skrivas
    //Skilj p� props som skrivs som attributes, och de som skrivs nested som elements
    PropList := C.GetProperties;
    for I := 0 to PropList.Count-1 do
    begin
      Prop := TZProperty(PropList[I]);
      C.GetProperty(Prop,Value);
      if Prop.NeverPersist or Prop.ExcludeFromXml or Prop.IsDefaultValue(Value) then
        Continue;
      case Prop.PropertyType of
        zptString :
          if (AnsiStrings.AnsiPos(#13,Value.StringValue)=0) {and
            (Pos('<',Value.StringValue)=0) and
            (Pos('>',Value.StringValue)=0)} then
            NormalProps.Add(Prop)
          else
            NestedProps.Add(Prop);
        zptComponentList :
          NestedProps.Add(Prop);
        zptBinary :
          if Value.BinaryValue.Size>0 then
            NestedProps.Add(Prop);
        zptExpression :
          if (Pos(#13,Value.ExpressionValue.Source)=0) then
            NormalProps.Add(Prop)
          else
            NestedProps.Add(Prop);
      else
        NormalProps.Add(Prop);
      end;
    end;

    S := '<' + Ci.ZClassName;

    for I := 0 to NormalProps.Count-1 do
    begin
      Prop := TZProperty(NormalProps[I]);
      C.GetProperty(Prop,Value);
      case Prop.PropertyType of
        zptString : V := InAttrValue( Value.StringValue );
        zptFloat,zptScalar : V := FloatToStr( RoundTo( Value.FloatValue ,-FloatTextDecimals) );
        zptRectf : V := InArray(Value.RectfValue.Area);
        zptColorf : V := InArray(Value.ColorfValue.V);
        zptInteger : V := IntToStr(Value.IntegerValue);
        zptComponentRef : V := String(Value.ComponentValue.Name);
        zptPropertyRef :
          begin
            V := String(Value.PropertyValue.Component.Name) + ' ' + Value.PropertyValue.Prop.Name;
            if Value.PropertyValue.Index>0 then
              V := V + ' ' + IntToStr(Value.PropertyValue.Index);
          end;
        zptVector3f : V := InArray(Value.Vector3fValue);
        zptByte : V := IntToStr(Value.ByteValue);
        zptBoolean : V := IntToStr( byte(Value.BooleanValue) );
        zptExpression : V := InAttrValue( AnsiString(Value.ExpressionValue.Source) );
      else
        raise Exception.Create('TZXmlWriter: No writehandler ' + Prop.Name);
      end;
      S:=S + ' ' + Prop.Name + '="' + V + '"';
    end;

    if NestedProps.Count=0 then
    begin
      S := S + '/>';
      WriteLine(S);
    end
    else
    begin
      S := S + '>';
      WriteLine(S);
      for I := 0 to NestedProps.Count-1 do
      begin
        Prop := TZProperty(NestedProps[I]);
        C.GetProperty(Prop,Value);
        LevelDown;
        WriteLine('<' + Prop.Name + '>');
        case Prop.PropertyType of
          zptString :
            WriteString('<![CDATA[' + SafeCdata(Value.StringValue) + ']]>'#13#10);
          zptExpression :
            WriteString('<![CDATA[' + SafeCdata( AnsiString(Value.ExpressionValue.Source) ) + ']]>'#13#10);
          zptComponentList :
            begin
              LevelDown;
              for J:=0 to Value.ComponentListValue.Count-1 do
                DoWriteComponent(Value.ComponentListValue.GetComponent(J));
              LevelUp;
            end;
          zptBinary :
            begin
              S := InGetBinary(Value.BinaryValue);
              WriteString('<![CDATA[' + S + ']]>'#13#10);
            end;
        else
          raise Exception.Create('TZXmlWriter: No writehandler');
        end;
        WriteLine('</' + Prop.Name + '>');
        LevelUp;
      end;
      S := '</' + Ci.ZClassName + '>';
      if (C is TLogicalGroup) and (C.Name<>'') then
        S := S + ' <!-- ' + String(C.Name) + ' -->'#13#10;
      WriteLine(S);
    end;

  finally
    NormalProps.Free;
    NestedProps.Free;
  end;
end;

procedure TZXmlWriter.LevelDown;
begin
  Inc(IndentLevel);
end;

procedure TZXmlWriter.LevelUp;
begin
  Dec(IndentLevel);
end;

procedure TZXmlWriter.OnDocumentEnd;
begin
  SysUtils.DecimalSeparator := Self.OldSeparator;
end;

procedure TZXmlWriter.OnDocumentStart;
begin
  WriteLine('<?xml version="1.0" encoding="iso-8859-1" ?>');
  Self.OldSeparator := SysUtils.DecimalSeparator;
  SysUtils.DecimalSeparator := '.';
end;

procedure TZXmlWriter.WriteString(const S: string);
var
  A : ansistring;
begin
  A := AnsiString(S);
  Write(A[1],Length(A));
end;

procedure TZXmlWriter.WriteLine(const S: string);
var
  Spaces : string;
  I : integer;
begin
  if Length(S)>0 then
  begin
    if IndentLevel>0 then
    begin
      SetLength(Spaces,IndentLevel*2);
      for I := 1 to Length(Spaces) do
        Spaces[I] := ' ';
      WriteString(Spaces);
    end;
    WriteString(S);
    WriteString(#13#10);
  end;
end;

{$ENDIF}

{ TZProperty }

{$IFNDEF MINIMAL}
function TZProperty.IsDefaultValue(const Value: TZPropertyValue): boolean;
begin
  Result := False;
  //true ifall value.equals(self.defaultvalue)
  //eller null. d�p om till ShouldStreamValue?
  case PropertyType of
    zptString : Result := {$ifdef minimal}Value.StringValue=nil;{$else}Value.StringValue=DefaultValue.StringValue;{$endif}
    zptByte : Result := Value.ByteValue=DefaultValue.ByteValue;
    zptInteger : Result := Value.IntegerValue=DefaultValue.IntegerValue;
    zptComponentRef : Result := Value.ComponentValue=nil;
    zptPropertyRef : Result := Value.PropertyValue.Component=nil;
    zptComponentList : Result := Value.ComponentListValue.Count=0;
    zptBoolean : Result := Value.BooleanValue=DefaultValue.BooleanValue;
    zptColorf : Result := ZMath.VecIsEqual4( TZVector4f(Value.ColorfValue),TZVector4f(DefaultValue.ColorfValue));
    zptVector3f : Result := ZMath.VecIsEqual3(Value.Vector3fValue,DefaultValue.Vector3fValue);
    zptFloat,zptScalar : Result := Value.FloatValue=DefaultValue.FloatValue;
    zptRectf : Result := ZMath.VecIsEqual4( TZVector4f(Value.RectfValue),TZVector4f(DefaultValue.RectfValue));
    zptExpression:
      Result := {$ifdef minimal}Value.ExpressionValue.Code.Count=0;
        {$else}
          (Trim(Value.ExpressionValue.Source)=Trim(DefaultValue.ExpressionValue.Source)) or
          (Trim(Value.ExpressionValue.Source)='');
        {$endif}
    zptBinary :
      Result := Value.BinaryValue.Size=0;
  end;
end;

procedure TZProperty.SetChildClasses(const C: array of TZComponentClass);
var
  I : integer;
begin
  SetLength(ChildClasses,Length(C));
  for I := 0 to Length(C)-1 do
    ChildClasses[I] := C[I];
end;

procedure TZProperty.SetOptions(const O: array of string);
var
  I : integer;
begin
  SetLength(Options,Length(O));
  for I := 0 to Length(O)-1 do
    Options[I] := O[I];
end;

{$ENDIF}

{ TZInputStream }

constructor TZInputStream.CreateFromFile(FileName: PAnsiChar; IsRelative : Boolean);
begin
  Platform_ReadFile(FileName,pointer(Memory),Size,IsRelative);
  OwnsMemory := True;
end;

constructor TZInputStream.CreateFromMemory(M: pointer; Size: integer);
begin
  Self.Memory := M;
  Self.Size := Size;
end;

destructor TZInputStream.Destroy;
begin
  if (Memory<>nil) and (OwnsMemory) then
    FreeMem(Memory);
  inherited;
end;

function TZInputStream.GetMemory: PBytes;
begin
  Result := @Memory^[Position]
end;

procedure TZInputStream.Read(var Buf; Count: integer);
begin
  if Position+Count>Size then
  begin
    {$ifdef zlog} 
    ZLog.GetLog(Self.ClassName).Write('Read beyond EOF attempted');
    {$endif}
    Exit;
  end;
  System.Move(Memory^[Position],Buf,Count);
  Inc(Position,Count);
end;

function TZInputStream.ReadBit: boolean;
begin
  {$ifdef zdebug}
  Assert(IsBitMode);
  {$endif}
  Inc(BitNo);
  if BitNo=8 then
  begin
    BitNo:=0;
    Read(Bits,1);
  end;
  Result := (Bits and (1 shl BitNo))<>0;
end;

procedure TZInputStream.BitsBegin;
begin
  {$ifdef zdebug}
  Assert(not IsBitMode);
  IsBitMode := True;
  {$endif}
  BitNo := 7;
end;

procedure TZInputStream.BitsEnd;
begin
  {$ifdef zdebug}
  Assert(IsBitMode);
  IsBitMode := False;
  {$endif}
end;

{ TZReader }


function TZReader.ReadRootComponent: TZComponent;
begin
  OnDocumentStart;
  Result := DoReadComponent(nil);
  OnDocumentEnd;
end;

{ TZBinaryReader }

function ReadVarLength(Stream : TZInputStream) : integer;
var
  B : byte;
  W : word;
begin
  Stream.Read(B,1);
  if B=255 then
  begin //List count is one or three bytes
    Stream.Read(W,2);
    Result := W;
  end else
    Result := B;
end;

constructor TZBinaryReader.Create(Stream: TZInputStream);
begin
  Self.Stream := Stream;
end;

procedure TZBinaryReader.Read(var B; Count: integer);
begin
  Stream.Read(B,Count);
end;

function TZBinaryReader.DoReadComponent(OwnerList : TZComponentList) : TZComponent;
var
  C : TZComponent;
  Ci : TZComponentInfo;
  B : byte;
  ClassId : TZClassIds;
  PropList : TZPropertyList;
  Value : TZPropertyValue;
  I,J,Temp : integer;
  Prop : TZProperty;
  PStream : TZInputStream;
  AfterList : TZArrayList;

  function ReadScalar(PStream : TZInputStream) : single;
  begin
    PStream.Read(B,1);
    Result := B / 255.0;
  end;

  procedure InReadList(List : TZComponentList);
  var
    I,Count : integer;
  begin
    Count := ReadVarLength(Self.Stream);
(*    Read(B,1);
    if B=255 then
    begin //List count is one or two bytes
      Read(W,2);
      Count := W;
    end else
      Count := B;*)
    for I := 0 to Count-1 do
      DoReadComponent(List);
  end;

begin
  //First byte: Classid
  Read(B,1);

  ClassId := TZClassIds(B);

  Ci := ComponentManager.GetInfoFromId(ClassId);
  C := Ci.ZClass.Create(OwnerList);

  //read properties
  PropList := C.GetProperties;
  AfterList := TZArrayList.CreateReferenced;
  Stream.BitsBegin;
  for I := 0 to PropList.Count-1 do
  begin
    Prop := TZProperty(PropList[I]);
    if Prop.NeverPersist then
      Continue;
    {$IFNDEF MINIMAL}
    if Prop.ExcludeFromBinary then
      Continue;
    {$ENDIF}
    //Read bitmask from main-stream, if zero then property
    //is not present in stream and has defaultvalue.
    if not Stream.ReadBit then
      Continue;
    PStream := PStreams[Prop.PropertyType];
    case Prop.PropertyType of
      zptString :
        begin
          //String is null-terminated
          Temp := ZStrLength(PAnsiChar(PStream.GetMemory));
          if Temp>0 then
          begin
            {$IFDEF MINIMAL}
            //Value.StringValue := PChar(PStream.GetMemory);
            //Inc(PStream.Position,Temp+1);
            GetMem(Value.StringValue,Temp+1);
            PStream.Read(Value.StringValue^,Temp+1);
            //Value.StringValue[Temp] := #0;
            {$ELSE}
            SetLength(Value.StringValue,Temp);
            PStream.Read(Value.StringValue[1],Temp);
            {$ENDIF}
          end else
          begin
            {$ifdef MINIMAL}
            Value.StringValue := nil;
            {$endif}
          end;
        end;
      zptFloat :
        begin
          PStream.Read(Value.FloatValue,4);
        end;
      zptScalar :
        Value.FloatValue := ReadScalar(PStream);
      zptRectf :
        PStream.Read(Value.RectfValue,SizeOf(TZRectf));
      zptColorf :
        begin
          for J := 0 to 3 do
            Value.ColorfValue.V[J] := ReadScalar(PStream);
        end;
      zptInteger :
        PStream.Read(Value.IntegerValue,SizeOf(integer));
      zptByte :
        PStream.Read(Value.ByteValue,SizeOf(byte));
      zptBoolean :
        PStream.Read(Value.BooleanValue,SizeOf(byte));
      zptComponentRef :
        begin
          PStream.Read(Value.ComponentValue,4);
          if Value.ComponentValue<>nil then
            FixUps.Add( TObject(PPointer(integer(C) + Prop.Offset)) );
        end;
      zptPropertyRef :
        begin
          PStream.Read(Value.PropertyValue.Component,4);
          PInteger(@Value.PropertyValue.Prop)^ := ReadVarLength(PStream);
          //PStream.Read(Value.PropertyValue.Prop,1);
          PStream.Read(B,1);
          Value.PropertyValue.Index := B;
          if Value.PropertyValue.Component<>nil then
            PropFixUps.Add( TObject(PPointer(integer(C) + Prop.Offset)) );
        end;
      zptVector3f :
        PStream.Read(Value.Vector3fValue,SizeOf(TZVector3f));
      zptComponentList,zptExpression :
        begin
          AfterList.Add(Prop);
          Continue;
        end;
      zptBinary :
       begin
         PStream.Read(Value.BinaryValue.Size,SizeOf(Value.BinaryValue.Size));
         if Value.BinaryValue.Size>0 then
         begin
           GetMem(Value.BinaryValue.Data,Value.BinaryValue.Size);
           PStream.Read(Value.BinaryValue.Data^,Value.BinaryValue.Size);
         end;
       end;
    {$ifdef zdebug}
    else
      ZHalt('TZBinaryReader: No readhandler');
    {$endif}
    end;
    C.SetProperty(Prop,Value);
  end;
  Stream.BitsEnd;

  //Ta n�stlade komponenter separat
  for I := 0 to AfterList.Count-1 do
  begin
    Prop := TZProperty(AfterList[I]);
    case Prop.PropertyType of
      zptComponentList :
        begin
          //l�s f�rst s� att vi f�r samma pekare (listan �gs av komponenten)
          C.GetProperty(Prop,Value);
          InReadList(Value.ComponentListValue);
        end;
      zptExpression :
        begin
          //l�s f�rst s� att vi f�r samma pekare (listan �gs av komponenten)
          C.GetProperty(Prop,Value);
          InReadList(Value.ExpressionValue.Code);
        end;
    {$ifdef zdebug}
    else
      ZHalt('TZBinaryReader: No readhandler');
    {$endif}
    end;
    C.SetProperty(Prop,Value);
  end;
  AfterList.Free;
  //If this has an objid, then it's a componentref target.
  //Store for fixups
  if C.ObjId>0 then
  begin
    while ObjIds.Count<=C.ObjId do
      ObjIds.Add(nil);
    ObjIds[C.ObjId] := C;
  end;
  Result := C;
end;

procedure TZBinaryReader.OnDocumentEnd;
var
  I,ObjId : integer;
  P : PPointer;
  PRef : PZPropertyRef;
  PropId : integer;
begin
  //component references
  for I := 0 to FixUps.Count-1 do
  begin
    P := PPointer(FixUps[I]);
    ObjId := integer(P^);
    P^ := ObjIds[ObjId];
  end;
  FixUps.Free;

  //property references
  for I := 0 to PropFixUps.Count-1 do
  begin
    PRef := PZPropertyRef(PropFixUps[I]);
    ObjId := integer(PRef^.Component);
    PRef^.Component := TZComponent(ObjIds[ObjId]);
    PropId := PInteger(@PRef^.Prop)^;
    PRef^.Prop := PRef^.Component.GetProperties.GetById(PropId);
  end;
  PropFixUps.Free;

  //nolla ut tilldelade objids s� att de kan anv�ndas runtime f�r clone
  for I := 0 to ObjIds.Count-1 do
    if ObjIds[I]<>nil then
      TZComponent(ObjIds[I]).ObjId:=0;

  ObjIds.Free;

  //todo: g�r free p� pstreams?
end;

procedure TZBinaryReader.OnDocumentStart;
var
  PSizes : packed array[TZPropertyType] of integer;
  OldPos : integer;
  P : TZPropertyType;
  PStream : TZInputStream;
  CurPos : integer;
begin
  OldPos := Stream.Position;
  CurPos := Stream.Size-4-SizeOf(PSizes);
  Stream.Position := CurPos;
  Stream.Read(PSizes,SizeOf(PSizes));
  //Loopa i omv�nd ordning och backa i stream
  //f�r att f� tag p� varje propstream.
  for P := High(PSizes) downto Low(PSizes) do
    if not (P in TBinaryNested) then
    begin
      if PSizes[P]>0 then
      begin
        Dec(CurPos,PSizes[P]);
        PStream := TZInputStream.CreateFromMemory(
          @Stream.Memory[CurPos],
          PSizes[P]
        );
        PStreams[P] := PStream;
      end;
    end;
  Stream.Position := OldPos;

  FixUps := TZArrayList.Create;
  FixUps.ReferenceOnly := True;
  PropFixUps := TZArrayList.Create;
  PropFixUps.ReferenceOnly := True;
  ObjIds := TZArrayList.Create;
  ObjIds.ReferenceOnly := True;
end;

{ TZXmlReader }

{$IFNDEF MINIMAL}
constructor TZXmlReader.Create;
begin
  MainXml := TXmlParser.Create;
  FixUps := TZArrayList.Create;
  Self.OldSeparator := SysUtils.DecimalSeparator;
  SysUtils.DecimalSeparator := '.';
end;

procedure TZXmlReader.LoadFromFile(const FileName: string);
begin
  ZLog.GetLog(Self.ClassName).Write('Loading: ' + FileName);
  ExternalSymTab := False;
  SymTab := TSymbolTable.Create;
  MainXml.LoadFromFile(ansistring(FileName));
end;

procedure TZXmlReader.LoadFromString(const XmlData: string; SymTab : TSymbolTable);
begin
  ExternalSymTab := True;
  Self.SymTab := SymTab;
  //Use the global symbol table
  //Let the locals be defines in a local scope
  SymTab.PushScope;
  MainXml.LoadFromBuffer(PAnsiChar(AnsiString(XmlData)));;
end;

destructor TZXmlReader.Destroy;
begin
  SysUtils.DecimalSeparator := Self.OldSeparator;
  MainXml.Free;
  FixUps.Free;
  if ExternalSymTab then
    SymTab.PopScope
  else
    SymTab.Free;
  inherited;
end;

function TZXmlReader.DoReadComponent(OwnerList: TZComponentList): TZComponent;
begin
  Result := XmlDoReadComponent(MainXml,OwnerList);
end;

function TZXmlReader.XmlDoReadComponent(Xml : TXmlParser; OwnerList: TZComponentList): TZComponent;
var
  ZClassName : string;
  C : TZComponent;
  Ci : TZComponentInfo;
  I,J : integer;
  PropList : TZPropertyList;
  Value : TZPropertyValue;
  Prop,NestedProp : TZProperty;
  S : ansistring;
  L,NotFounds : TStringList;
  Fix : TZXmlFixUp;
  Found : boolean;

  procedure InDecodeBinary(const HexS : string; var BinaryValue : TZBinaryPropValue);
  var
    CompMem,DecompMem : TMemoryStream;
    Zs : zlib.TDecompressionStream;
    S : ansistring;
    Buf : array[0..1023] of byte;
    I : integer;
  begin
    CompMem := TMemoryStream.Create;
    DecompMem := TMemoryStream.Create;
    try
      SetLength(S,Length(HexS) div 2);
      Classes.HexToBin(PChar(HexS),PAnsiChar(S),Length(S));

      CompMem.Write(S[1],Length(S));
      CompMem.Position := 0;

      Zs := TDecompressionStream.Create(CompMem);
      try
        I := Zs.Read(Buf,SizeOf(Buf));
        while I>0 do
        begin
          DecompMem.Write(Buf,I);
          I := Zs.Read(Buf,SizeOf(Buf));
        end;
        BinaryValue.Size := DecompMem.Size;
        GetMem(BinaryValue.Data,BinaryValue.Size);
        DecompMem.Position := 0;
        DecompMem.Read(BinaryValue.Data^,BinaryValue.Size);
      finally
        Zs.Free;
      end;
    finally
      CompMem.Free;
      DecompMem.Free;
    end;
  end;

  procedure PatchMaterialTextures;
  //Translate old-style texture settings to new MaterialTexture-component
  var
    S : ansistring;
    OtherXml : TXmlParser;
    procedure InFixTex(const Name : string);
    begin
      if NotFounds.Values[Name]<>'' then
        S := S + ansistring(Name) + '="' + ansistring(NotFounds.Values[Name]) + '" '
    end;
  begin
    if NotFounds.Values['Texture']='' then
      Exit;
    Prop := PropList.GetByName('Textures');
    C.GetProperty(Prop,Value);
    S := '<MaterialTexture Texture="' + ansistring(NotFounds.Values['Texture']) + '" ';
    InFixTex('TextureScale');
    InFixTex('TextureX');
    InFixTex('TextureY');
    InFixTex('TextureRotate');
    InFixTex('TextureWrapMode');
    InFixTex('TexCoords');
    S := S + '/>';
    OtherXml := TXmlParser.Create;

    OtherXml.LoadFromBuffer(PAnsiChar(S));
    OtherXml.Scan;
    XmlDoReadComponent(OtherXml,Value.ComponentListValue);

    if NotFounds.Values['Texture2']<>'' then
    begin
      OtherXml.LoadFromBuffer( PAnsiChar( AnsiString('<MaterialTexture Texture="' + NotFounds.Values['Texture2'] + '"/>') ));
      OtherXml.StartScan;
      OtherXml.Scan;
      XmlDoReadComponent(OtherXml,Value.ComponentListValue);
    end;
    if NotFounds.Values['Texture3']<>'' then
    begin
      OtherXml.LoadFromBuffer( PAnsiChar( AnsiString('<MaterialTexture Texture="' + NotFounds.Values['Texture3'] + '"/>') ));
      OtherXml.StartScan;
      OtherXml.Scan;
      XmlDoReadComponent(OtherXml,Value.ComponentListValue);
    end;

    OtherXml.Free;
  end;

begin
  ZClassName := string(Xml.CurName);

  Ci := ComponentManager.GetInfoFromName(ZClassName);
  C := Ci.ZClass.Create(OwnerList);

  L := TStringList.Create;
  NotFounds := TStringList.Create;
  try
    L.Delimiter := ' ';
    //read properties
    PropList := C.GetProperties;

    for I := 0 to Xml.CurAttr.Count-1 do
    begin
      S:=Xml.CurAttr.Name(I);
      Found := False;
      for J := 0 to PropList.Count-1 do
      begin
        Prop := TZProperty(PropList[J]);
        if SameText(Prop.Name,String(S)) then
        begin
          S := Xml.CurAttr.Value(I);
          Found := True;
          case Prop.PropertyType of
            zptString :
              Value.StringValue := S;
            zptFloat,zptScalar :
              Value.FloatValue := StrToFloat( String(S) );
            zptRectf :
              begin
                L.DelimitedText := String(S);
                Value.RectfValue.Area[0] := StrToFloat(L[0]);
                Value.RectfValue.Area[1] := StrToFloat(L[1]);
                Value.RectfValue.Area[2] := StrToFloat(L[2]);
                Value.RectfValue.Area[3] := StrToFloat(L[3]);
              end;
            zptColorf :
              begin
                L.DelimitedText := String(S);
                Value.ColorfValue.V[0] := StrToFloat(L[0]);
                Value.ColorfValue.V[1] := StrToFloat(L[1]);
                Value.ColorfValue.V[2] := StrToFloat(L[2]);
                Value.ColorfValue.V[3] := StrToFloat(L[3]);
              end;
            zptVector3f :
              begin
                L.DelimitedText := String(S);
                Value.Vector3fValue[0] := StrToFloat(L[0]);
                //Allow a single value to be specified, this is copied to all three elements
                //Used when switching type from float to vector3d (material.texturescale)
                if L.Count>1 then
                  Value.Vector3fValue[1] := StrToFloat(L[1])
                else
                  Value.Vector3fValue[1] := Value.Vector3fValue[0];
                if L.Count>2 then
                  Value.Vector3fValue[2] := StrToFloat(L[2])
                else
                  Value.Vector3fValue[2] := Value.Vector3fValue[0];
              end;
            zptInteger :
              Value.IntegerValue := StrToInt(String(S));
            zptByte :
              Value.ByteValue := StrToInt(String(S));
            zptBoolean :
              Value.BooleanValue := ByteBool(StrToInt(String(S)));
            zptComponentRef :
              begin
                Fix := TZXmlFixUp.Create;
                Fix.Name := String(LowerCase(S));
                Fix.Prop := Prop;
                Fix.Obj := C;
                FixUps.Add( Fix );
              end;
            zptPropertyRef :
              begin
                L.DelimitedText := String(S);
                if L.Count<2 then
                  raise Exception.Create('TZXmlReader: Bad property ref ' + String(S));
                Fix := TZXmlFixUp.Create;
                Fix.Name := String(LowerCase(L[0]));
                Fix.PropName := String(LowerCase(L[1]));
                if L.Count>2 then
                  Value.PropertyValue.Index := StrToIntDef(L[2],0);
                Fix.Prop := Prop;
                Fix.Obj := C;
                FixUps.Add( Fix );
              end;
            zptExpression :
              Value.ExpressionValue.Source := String(S);
          else
            ZHalt('TZXmlReader: No readhandler');
          end;
          C.SetProperty(Prop,Value);

          Break;
        end;
      end;
      if not Found then
        NotFounds.Values[String(S)] := String(Xml.CurAttr.Value(I));
    end;

    if (NotFounds.Count>0) and (ZClassName='Material') then
      PatchMaterialTextures;

    if Xml.CurPartType=ptStartTag then
    begin
      while Xml.Scan do
        case Xml.CurPartType of
          ptStartTag :
            begin
              //Hantera n�stlade komponnenter
              //Det g�ller componentlists
              S := Xml.CurName;
              NestedProp:=nil;
              for I := 0 to PropList.Count-1 do
              begin
                Prop := TZProperty(PropList[I]);
                if SameText(Prop.Name,String(Xml.CurName)) and
                  (Prop.PropertyType in [zptComponentList,zptString,zptExpression,zptBinary]) then
                begin
                  NestedProp := Prop;
                  Break;
                end;
              end;
              if NestedProp=nil then
                raise Exception.Create('TZXmlReader: Unknown nested property ' + String(Xml.CurName));
              C.GetProperty(NestedProp,Value);
              while Xml.Scan do
                case Xml.CurPartType of
                  ptStartTag,ptEmptyTag,ptCData  :
                    case NestedProp.PropertyType of
                      zptComponentList : DoReadComponent(Value.ComponentListValue);
                      zptString :
                        begin
                          Value.StringValue := Trim(Xml.CurContent);
                          C.SetProperty(NestedProp,Value);
                        end;
                      zptExpression :
                        begin
                          Value.ExpressionValue.Source := String(Trim(Xml.CurContent));
                          C.SetProperty(NestedProp,Value);
                        end;
                      zptBinary :
                        begin
                          try
                            InDecodeBinary(String(Xml.CurContent),Value.BinaryValue);
                            C.SetProperty(NestedProp,Value);
                          except
                            ZLog.GetLog(Self.ClassName).Write('*** Failed to read binary property: ' + String(C.Name));
                          end;
                        end;
                    end;
                  ptEndTag :
                    if SameText(NestedProp.Name,String(Xml.CurName)) then
                      Break;
                end;
            end;
          ptEndTag : Break;
        end;
    end;

  finally
    L.Free;
    NotFounds.Free;
  end;

  if C.Name<>'' then
    SymTab.Add(String(LowerCase(C.Name)),C);

  Result := C;
end;

procedure TZXmlReader.OnDocumentEnd;
var
  I : integer;
  Fix :  TZXmlFixUp;
  Value : TZPropertyValue;
  C : TZComponent;
begin
  for I := 0 to FixUps.Count-1 do
  begin
    Fix := TZXmlFixUp(FixUps[I]);
    C := SymTab.LookUp(Fix.Name) as TZComponent;
    if not Assigned(C) then
    begin //Handle missing symbol
      if ExternalSymTab then
      begin
        //When copy/paste, allow unknown references. They will be nil.
        ZLog.GetLog(Self.ClassName).Write('Unknown reference: ' + Fix.Name);
        FillChar(Value,SizeOf(Value),0);
        Fix.Obj.SetProperty(Fix.Prop,Value);
        Continue;
      end
      else
        if C=nil then
          raise Exception.Create('Unknown reference: ' + Fix.Name);
    end;
    case Fix.Prop.PropertyType of
      zptComponentRef :
        Value.ComponentValue := C;
      zptPropertyRef :
        begin
          Fix.Obj.GetProperty(Fix.Prop,Value);
          Value.PropertyValue.Component := C;
          Value.PropertyValue.Prop := C.GetProperties.GetByName(Fix.PropName);
          Assert(Value.PropertyValue.Prop<>nil,'Unknown reference: ' + Fix.PropName);
        end;
    end;
    Fix.Obj.SetProperty(Fix.Prop,Value);
  end;
end;

procedure TZXmlReader.OnDocumentStart;
begin
  while MainXml.Scan do
    if MainXml.CurPartType in [ptStartTag,ptEmptyTag] then
      Break;
end;
{$ENDIF}



{ TZComponentList }

procedure TZComponentList.Change;
begin
  IsChanged := True;
  if Owner<>nil then
    Owner.Change;
end;

function TZComponentList.ComponentCount: integer;
begin
  Result := Count;
end;

constructor TZComponentList.Create;
begin
  ReferenceOnly := True;
end;

constructor TZComponentList.Create(OwnerC: TZComponent);
begin
  Create;
  Self.Owner := OwnerC;
end;

destructor TZComponentList.Destroy;
begin
  Clear;
  inherited;
end;

procedure TZComponentList.ExecuteCommands;
var
  I : integer;
  C : TZComponent;
begin
  for I := 0 to Count-1 do
  begin
    C := TZComponent(Self[I]);
    {$ifndef minimal}
    if C.DesignDisable then
      Continue;
    {$endif}
    if C is TCommand then
      TCommand(C).Execute
    else
      //Call update on everything that isn't commands (expressions)
      C.Update;
    {$ifndef minimal}
    //Break after the producer that is marked as preview (in bitmap graph)
    if C=DesignerPreviewProducer then
      Break;
    {$endif}
  end;
end;

function TZComponentList.GetComponent(Index: integer): TZComponent;
begin
  Result := TZComponent(Self[Index]);
end;

procedure TZComponentList.AddComponent(Component: TZComponent);
begin
  Add(Component);
  Component.OwnerList := Self;
end;

procedure TZComponentList.RemoveComponent(Component: TZComponent);
begin
  Component.OwnerList := nil;
  Remove(Component);
end;


procedure TZComponentList.Update;
var
  I : integer;
  C : TZComponent;
begin
  for I := 0 to Count-1 do
  begin
    C := TZComponent(Self[I]);
    {$ifndef minimal}
    if C.DesignDisable then
      Continue;
    {$endif}
    C.Update;
  end;
end;

procedure TZComponentList.Clear;
var
  Instance: TZComponent;
begin
  //Destroy childcomponents
  while Count>0 do
  begin
    Instance := TZComponent(Last);
    RemoveComponent(Instance);
    Instance.Destroy;
  end;
end;

{$ifndef minimal}
procedure TZComponentList.DesignerReset;
var
  I : integer;
begin
  for I := 0 to Count-1 do
    TZComponent(Self[I]).DesignerReset;
end;

procedure TZComponentList.InsertComponent(Component: TZComponent; Index : integer);
var
  I : integer;
begin
  Component.OwnerList := Self;

  Add(nil);
  I := Count-1;
  while I>Index do
  begin
    Items[I] := Items[I-1];
    Dec(I);
  end;

  Items[ Index ] := Component;
end;
{$endif}



{ TLogicalGroup }

procedure TLogicalGroup.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Children',{$ENDIF}integer(@Children), zptComponentList);
end;

procedure TLogicalGroup.Execute;
begin
  Children.ExecuteCommands;
end;

procedure TLogicalGroup.Update;
begin
  inherited;
  Children.Update;
end;

{ TContent }


procedure TContent.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'Producers',{$ENDIF}integer(@Producers), zptComponentList);
end;

type
  TGlobalContent =
    record
      Content : TContent;
      Stack : TZArrayList;
    end;

var
  GlobalContent : TGlobalContent;
  {$ifndef minimal}
  RefreshDepth : integer;
  {$endif}

procedure TContent.RefreshFromProducers;
var
  Stack : TZArrayList;
  Save : TGlobalContent;
begin
  {$ifndef minimal}
  if Producers.Count>0 then
    ZLog.GetLog(Self.ClassName).BeginTimer;
  {$endif}

  Save := GlobalContent;

  Stack := TZArrayList.Create;
  {$ifndef minimal}
  try
    Inc(RefreshDepth);
  {$endif}
    Stack.ReferenceOnly := True;

    GlobalContent.Content := Self;
    GlobalContent.Stack := Stack;

    //Execute producers as commands
    //This way Repeat and Condition-statements can be used
    Producers.ExecuteCommands;

    if Stack.Count>0 then
      CopyAndDestroy(TContent(Stack.Pop));
    while(Stack.Count>0) do
      Stack.Pop().Free;
  {$ifndef minimal}
  finally
    Dec(RefreshDepth);
  {$endif}
    IsChanged := False;
    Producers.IsChanged := False;
  Stack.Free;
  {$ifndef minimal}
  end;
  {$endif}

//  FillChar(GlobalContent,SizeOf(GlobalContent),0);
  GlobalContent := Save;

  {$ifndef minimal}
  if (Producers.Count>0) and (not ZApp.DesignerIsRunning) and (RefreshDepth=0) then
    ZLog.GetLog(Self.ClassName).EndTimer('Refresh: ' + String(GetDisplayName));
  {$endif}
end;

///////////////////

function GetPropertyRef(const Prop : TZPropertyRef) : pointer;
begin
  Result := Prop.Component.GetPropertyPtr(Prop.Prop,Prop.Index);
end;

{ TZOutputStream }

{$ifndef minimal}
procedure TZOutputStream.BitsBegin;
begin
  Assert(not IsBitMode);
  IsBitMode := True;
  BitNo := 0;
  Bits := 0;
end;

procedure TZOutputStream.BitsEnd;
begin
  Assert(IsBitMode);
  IsBitMode := False;
  if BitNo<>0 then
    Write(Bits,1);
end;

procedure TZOutputStream.WriteBit(B: boolean);
begin
  Assert(IsBitMode);
  if B then
    Bits := Bits or (1 shl BitNo)
  else
    Bits := Bits and (not (1 shl BitNo));
  Inc(BitNo);
  if BitNo=8 then
  begin
    Write(Bits,1);
    BitNo := 0;
    Bits := 0;
  end;
end;
{$endif}


{ TStateBase }

procedure TStateBase.DefineProperties(List: TZPropertyList);
begin
  inherited;
  List.AddProperty({$IFNDEF MINIMAL}'OnStart',{$ENDIF}integer(@OnStart), zptComponentList);
  List.AddProperty({$IFNDEF MINIMAL}'OnUpdate',{$ENDIF}integer(@OnUpdate), zptComponentList);
  List.AddProperty({$IFNDEF MINIMAL}'OnLeave',{$ENDIF}integer(@OnLeave), zptComponentList);
  List.AddProperty({$IFNDEF MINIMAL}'OnRender',{$ENDIF}integer(@OnRender), zptComponentList);
  List.AddProperty({$IFNDEF MINIMAL}'Definitions',{$ENDIF}integer(@Definitions), zptComponentList);
end;


//String functions

function ZStrFindEnd(P : PAnsiChar) : PAnsiChar;
begin
  while P^<>#0 do Inc(P);
  Result := P;
end;

function ZStrLength(P : PAnsiChar) : integer;
begin
  Result := ZStrFindEnd(P) - P;
end;

procedure ZStrCopy(P : PAnsiChar; const Src : PAnsiChar);
var
  Len : integer;
begin
  Len := ZStrLength(Src);
  System.Move(Src^,P^,Len+1);
end;

procedure ZStrCat(P : PAnsiChar; const Src : PAnsiChar);
begin
  P := ZStrFindEnd(P);
  ZStrCopy(P,Src);
end;

procedure ZStrConvertInt(const S : integer; Dest : PAnsiChar);
var
  Value : integer;
  Tmp : PAnsiChar;
  Buf : array[0..15] of ansichar;
begin
  Value := Abs(S);
  Tmp := @Buf[High(Buf)];
  Tmp^ := #0;
  Dec(Tmp);
  while (Value>9) and (Tmp>@Buf) do
  begin
    Tmp^:=AnsiChar(Value mod 10 + 48);
    Dec(Tmp);
    Value := Value div 10;
  end;
  Tmp^ := AnsiChar(Value + 48);
  if S<0 then
  begin
    Dec(Tmp);
    Tmp^ := '-';
  end;
  ZStrCopy(Dest,Tmp);
end;

function ZStrPos(const SubStr,Str : PAnsiChar; const StartPos : integer) : integer;
var
  P,P1,SaveP : PAnsiChar;
begin
  Result := -1;
  {$ifndef minimal}
  ZAssert(StartPos<=ZStrLength(Str),'StrPos called with startpos>length');
  {$endif}
  P := Str + StartPos;
  while P^<>#0 do
  begin
    P1 := SubStr;
    if P^=P1^ then
    begin
      SaveP := P;
      repeat
        Inc(P); Inc(P1);
      until (P^<>P1^) or (P^=#0) or (P1^=#0);
      if P1^=#0 then
      begin
        Result := integer(SaveP) - integer(Str);
        Break;
      end;
    end else
      Inc(P);
  end;
end;

function ZStrCompare(P1,P2 : PAnsiChar) : boolean;
begin
  while (P1^=P2^) and (P1^<>#0) and (P2^<>#0) do
  begin
    Inc(P1); Inc(P2);
  end;
  Result := (P1^=#0) and (P2^=#0);
end;

procedure ZStrSubString(const Str,Dest : PAnsiChar; const StartPos,NChars : integer);
var
  P : PAnsiChar;
begin
  {$ifndef minimal}
  ZAssert(StartPos+NChars<=ZStrLength(Str),'SubString called with startpos+NChars>length');
  {$endif}
  P := Str + StartPos;
  Move(P^,Dest^,NChars);
  Dest[NChars] := #0;
end;

function ZStrToInt(const Str : PAnsiChar) : integer;
var
  P : PAnsiChar;
begin
  Result := 0;
  P := Str;
  while P^<>#0 do
  begin
    Result := Result * 10 + byte(P^)-48;
    Inc(P);
  end;
end;



{$ifndef minimal}
function GetPropRefAsString(const PRef : TZPropertyRef) : string;
begin
  Result := String(PRef.Component.Name) + '.' + PRef.Prop.Name;
  case PRef.Component.GetProperties.GetByName(PRef.Prop.Name).PropertyType of
    zptColorf : Result := Result + '.' + Copy('RGBA',PRef.Index+1,1);
    zptVector3f : Result := Result + '.' + Copy('XYZ',PRef.Index+1,1);
    zptRectf : Result := Result + '.' + Copy('XYZW',PRef.Index+1,1);
  end;
end;
{$endif}

procedure TStateBase.Update;
begin
  inherited;
  OnUpdate.ExecuteCommands;
  OnRender.Update;
end;

{ TContentProducer }

procedure TContentProducer.Execute;
begin
  Self.ProduceOutput(GlobalContent.Content,GlobalContent.Stack);
end;


initialization

  ManagedHeap_Create;

  //todo really need to register TLogicalGroup?
  Register(TLogicalGroup,LogicalGroupClassId);
    {$ifndef minimal}ComponentManager.LastAdded.ImageIndex:=4;{$endif}
    {$ifndef minimal}ComponentManager.LastAdded.ZClassName := 'Group';{$endif}

{$ifndef minimal}
  StringCache := TDictionary<AnsiString,AnsiString>.Create;

finalization

  Zc_Ops.CleanUp;
  if Assigned(_ComponentManager) then
    FreeAndNil(_ComponentManager);

  ManagedHeap_Destroy;

  StringCache.Free;

{$endif}

end.
