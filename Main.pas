unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs, Cromis.DirectoryWatch,XMLIntf, XMLDoc,
  XSBuiltIns, URLMon, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdHTTP, IdSSLOpenSSL, IdURI, Data.DB, MemDS, DBAccess, Uni, AccountCreate,
  Variants, glComponentUtil;

const
// macro
  C_MACRO_USERHOME      = '[USERHOME]';
  C_MACRO_NMATTER       = '[NMATTER]';
  C_MACRO_FILEID        = '[FILEID]';
  C_MACRO_TEMPDIR       = '[TEMPDIR]';
  C_MACRO_TEMPFILE      = '[TEMPFILE]';
  C_MACRO_DATE          = '[DATE]';
  C_MACRO_TIME          = '[TIME]';
  C_MACRO_DATETIME      = '[DATETIME]';
  C_WORKFLOW            = 'WORKFLOW';
  C_WKF                 = 'WKF';
  C_MERGETYPE           = 'MERGETYPE';
  C_MACRO_CLIENTID      = '[CLIENTID]';
  C_MACRO_AUTHOR        = '[AUTHOR]';
  C_MACRO_USERINITIALS  = '[USERINITIALS]';
  C_MACRO_DOCSEQUENCE   = '[DOCSEQUENCE]';
  C_MACRO_DOCID         = '[DOCID]';
  C_MACRO_DOCDESCR      = '[DOCDESCR]';

  C_VERSION             =  '1.0';

type
  TInsightiTrackWatcher = class(TService)
    qryMatterAttachment: TUniQuery;
    qrySearches: TUniQuery;
    qryTmp: TUniQuery;
    qrySysFile: TUniQuery;
    qryGetDocSeq: TUniQuery;
    uniInsight: TUniConnection;
    procTemp: TUniStoredProc;
    qrySeqnums: TUniQuery;
    qryCharts: TUniQuery;
    qryExpenseAllocations: TUniQuery;
    qryEmps: TUniQuery;
    qryTransItemInsert: TUniQuery;
    procedure qryMatterAttachmentNewRecord(DataSet: TDataSet);
  private
    { Private declarations }
    FDocID: integer;
    FUserID: string;
    FEntity: string;
    procedure OnNotify(const Sender: TObject;
                       const Action: TWatchAction;
                       const FileName: string);
    procedure SaveSearchFromXML(AFileName: string);
    function InfoTrackLogin(const Url: string; TargetFileName, User, Pass: string): boolean;
    procedure SaveDocument(ACreated: TDateTime; AFileID, AAuthor, AFileName, AKeyword, ASearch: string;
                         AImageIndex: integer = 5);
    function SystemString(sField: string): string;
    function SystemInteger(sField: string): integer;
    function CleanFileName(AFileName: string; ANewChar: char = ' '): string;
    function ParseMacros(AFileName: String; ANMatter: Integer = -1; ADocID: Integer = -1; ADocDescr: string = ''): String;
    function ProcString(Proc: string; LookupValue: integer): string;
  public
    FDirectoryWatch: TDirectoryWatch;
    property Entity: string read FEntity write FEntity;
    property DocID: integer read FDocID write FDocID;
    property UserID: string read FUserID write FUserID;

    function TableInteger(Table, LookupField, LookupValue, ReturnField: string): integer;
    function MatterString(iFile: integer; sField: string): string;
    function TableString(Table, LookupField, LookupValue, ReturnField: string): string;
    function GetSeqnum(sField: string): integer;
    function ValidLedger(sEntity, sLedger: string): boolean;
    procedure PostLedger(dtDate: TDateTime; cAmount: currency; cTax: Currency;
                         sRefno: string; sOwnerCode: string; iOwner: int64; sDesc: string;
                         sLedger: string; sAuthor: string; iInvoice: int64;
                         CreditorCode: string; sTaxCode : String; bJournalSplit : Boolean = FALSE;
                         sParentChart : String = '0'; nAlloc: int64 = 0; nMatter: int64 = 0;
                         nAccount: int64 = 0; UseRvDate: Boolean = FALSE; nTrans: integer = 0;
                         cBAS_Tax: currency = 0);
    function GetSubchart(sEntity: string; sMainChart: string; sEmp: string): string;
    procedure SaveLedger(dtDate: TDateTime; cAmount: currency; cTax: Currency;
                         sRefno, sOwnerCode: string; iOwner: integer; sDesc,
                         sFullLedger, sAuthor: string; iInvoice: Integer;
                         CreditorCode, sTaxCode, sParentChart: String; nAlloc: integer = 0; nMatter: int64 = 0;
                         nAccount: integer = 0; UseRvDate: Boolean = FALSE; nTrans: integer = 0;
                         cBAS_Tax: currency = 0);
    function IsActiveLedger(sEntity : String; sFullLedger : String) : Boolean;
    procedure ParamsNullify(parClear: TParams);
    function getGlComponents : TglComponentSetup;
    procedure loadGlComponent;

    function TableStringEntity(aTable, aLookupField: string; aLookupValue: Integer; aReturnField: string; aEntity: string): string;
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  InsightiTrackWatcher: TInsightiTrackWatcher;

implementation

{$R *.DFM}

var
   GHomePath,
   GTempPath: String;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  InsightiTrackWatcher.Controller(CtrlCode);
end;

function TInsightiTrackWatcher.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TInsightiTrackWatcher.OnNotify(const Sender: TObject; const Action: TWatchAction;
                               const FileName: string);
begin
   if (Action = waAdded) then
   begin
      SaveSearchFromXML( FileName);
   end;
end;

procedure TInsightiTrackWatcher.qryMatterAttachmentNewRecord(DataSet: TDataSet);
begin
   qryGetDocSeq.ExecSQL;
   FDocID := qryGetDocSeq.FieldByName('nextdoc').AsInteger;
   DataSet.FieldByName('docid').AsInteger := FDocID;
end;

procedure TInsightiTrackWatcher.SaveSearchFromXML(AFileName: string);
var
  LDocument: IXMLDocument;
  OrderNode: IXMLNode;
  SequenceNumber,
  OrderId,
  LFileLoc,
  NewDocPath,
  NewDocName,
  AParsedDocName,
  ADownloadURL,
  LFileID,
  FileHash: String;
  xsDateTime: TXSDateTime;
  DupeSearch: Boolean;
begin
   try
      LFileLoc := SystemString('INFOTRACK_STAGING_FLDR')+'\'+AFileName;
      if FileExists(LFileLoc) then
      begin
         LDocument := TXMLDocument.Create(nil);
         try
            LDocument.LoadFromFile(LFileLoc);

            OrderNode := LDocument.ChildNodes.FindNode('Order');

            if (OrderNode <> nil) then
            begin
               SequenceNumber := OrderNode.ChildNodes['SequenceNumber'].Text;
               OrderId := OrderNode.ChildNodes['OrderId'].Text;
               FileHash := OrderNode.ChildNodes['FileHash'].Text;
               with qryTmp do
               begin
                  Close;
                  SQL.Text := 'select 1 from searches where sequencenumber = :sequencenumber '+
                              'and OrderId = :OrderId and isbillable = ''true'' and '+
                              'filehash = :filehash';
                  ParamByName('SequenceNumber').AsString := SequenceNumber;
                  ParamByName('OrderId').AsString := OrderId;
                  ParamByName('FileHash').AsString := FileHash;
                  Open;
                  DupeSearch := (IsEmpty = False);
               end;

               if (DupeSearch = False) then
               begin
                  NewDocPath := IncludeTrailingPathDelimiter(SystemString('DRAG_DEFAULT_DIRECTORY'));
                  NewDocName := NewDocPath + CleanFileName(OrderNode.ChildNodes['OrderId'].Text, '-');
                  AParsedDocName := ParseMacros(NewDocName, StrToInt(OrderNode.ChildNodes['ClientReference'].Text));
                  ADownloadURL := OrderNode.ChildNodes['DownloadUrl'].Text;

                  with qryTmp do
                  begin
                     Close;
                     SQL.Clear;
                     SQL.Add('SELECT code from EMPLOYEE where name = :name');
                     ParamByName('name').AsString := OrderNode.ChildNodes['OrderedBy'].Text;
                     Open;
                     FUserID := Fields.Fields[0].AsString;
                     Close;
                  end;

                  with qrySearches do
                  begin
                     Open;
                     Insert;

                     FieldByName('AvailableOnline').AsString := OrderNode.ChildNodes['AvailableOnline'].Text;
                     FieldByName('ClientReference').AsInteger := StrToInt(OrderNode.ChildNodes['ClientReference'].Text);
                     FieldByName('BillingTypeName').AsString := OrderNode.ChildNodes['BillingTypeName'].Text;

                     try
                        xsDateTime := TXSDateTime.Create;
                        xsDateTime.XSToNative(OrderNode.ChildNodes['DateOrdered'].Text);

                        FieldByName('DateOrdered').AsDateTime := xsDateTime.AsDateTime;

                        if (OrderNode.ChildNodes['DateCompleted'].Text <> '') then
                        begin
                           xsDateTime.XSToNative(OrderNode.ChildNodes['DateCompleted'].Text);
                           FieldByName('DateCompleted').AsDateTime := xsDateTime.AsDateTime;
                        end;
                     finally
                        xsDateTime := nil;
                     end;

                     FieldByName('Description').AsString := OrderNode.ChildNodes['Description'].Text;
                     FieldByName('OrderId').AsString := OrderNode.ChildNodes['OrderId'].Text;
                     FieldByName('ParentOrderId').AsString := OrderNode.ChildNodes['ParentOrderId'].Text;
                     FieldByName('OrderedBy').AsString := OrderNode.ChildNodes['OrderedBy'].Text;
                     FieldByName('Reference').AsString := OrderNode.ChildNodes['Reference'].Text;
                     FieldByName('RetailerReference').AsString := OrderNode.ChildNodes['RetailerReference'].Text;
                     FieldByName('RetailerFee').AsString := OrderNode.ChildNodes['RetailerFee'].Text;
                     FieldByName('RetailerFeeGST').AsString := OrderNode.ChildNodes['RetailerFeeGST'].Text;
                     FieldByName('RetailerFeeTotal').AsString := OrderNode.ChildNodes['RetailerFeeTotal'].Text;
                     FieldByName('SupplierFee').AsString := OrderNode.ChildNodes['SupplierFee'].Text;
                     FieldByName('SupplierFeeGST').AsString := OrderNode.ChildNodes['SupplierFeeGST'].Text;
                     FieldByName('SupplierFeeTotal').AsString := OrderNode.ChildNodes['SupplierFeeTotal'].Text;
                     FieldByName('TotalFee').AsString := OrderNode.ChildNodes['TotalFee'].Text;
                     FieldByName('TotalFeeGST').AsString := OrderNode.ChildNodes['TotalFeeGST'].Text;
                     FieldByName('TotalFeeTotal').AsString := OrderNode.ChildNodes['TotalFeeTotal'].Text;
                     FieldByName('ServiceName').AsString := OrderNode.ChildNodes['ServiceName'].Text;
                     FieldByName('Status').AsString := OrderNode.ChildNodes['Status'].Text;
                     FieldByName('StatusMessage').AsString := OrderNode.ChildNodes['StatusMessage'].Text;
                     if (ADownloadURL <> '') then
                     begin
                        FieldByName('DownloadUrl').AsString := AParsedDocName+'.pdf' ;   //OrderNode.ChildNodes['DownloadUrl'].Text;
                        FieldByName('OnlineUrl').AsString := OrderNode.ChildNodes['OnlineUrl'].Text;
                     end;
                     FieldByName('IsBillable').AsString := OrderNode.ChildNodes['IsBillable'].Text;
                     FieldByName('FileHash').AsString := OrderNode.ChildNodes['FileHash'].Text;
                     FieldByName('Email').AsString := OrderNode.ChildNodes['Email'].Text;
                     FieldByName('ClientId').AsString := OrderNode.ChildNodes['ClientId'].Text;
                     FieldByName('SequenceNumber').AsString := OrderNode.ChildNodes['SequenceNumber'].Text;
                     Post;
                  end;

                  LFileID := TableString('MATTER', 'NMATTER', OrderNode.ChildNodes['ClientReference'].Text, 'FILEID');
                  if (OrderNode.ChildNodes['IsBillable'].Text = 'true') then
                  begin
                     if InfoTrackLogin(ADownloadURL, AParsedDocName, SystemString('INFOTRACK_USER'),
                                       SystemString('INFOTRACK_PASSWORD')) = True then
                     begin
                        if (ADownloadURL <> '') then
                           SaveDocument(now, LFileID, UserID, AParsedDocName+'.pdf','InfoTrack Search',
                                     'InfoTrack Search - ' + qrySearches.FieldByName('Description').AsString);
                        // create invoice
                        try
                           if not Assigned(dmAccountCreate) then
                              Application.CreateForm(TdmAccountCreate, dmAccountCreate);
                           dmAccountCreate.SaveAccount(qrySearches.FieldByName('ClientReference').AsInteger,
                                                    SystemInteger('INFOTRACK_NCREDITOR'),
                                                    qrySearches.FieldByName('OrderID').AsInteger,
                                                    qrySearches.FieldByName('TotalFee').AsCurrency,
                                                    qrySearches.FieldByName('TotalFeeGST').AsCurrency,
                                                    qrySearches.FieldByName('Description').AsString,
                                                    MatterString(qrySearches.FieldByName('ClientReference').AsInteger, 'FILEID'));
                        finally
                           FreeAndNil(dmAccountCreate);
                        end;
                     end
                     else
//                        ShowMessage('Error with download - ' + ADownloadURL);
                  end;
               end;
            end;
         except
            //
         end;
      end;
   finally
      LDocument := nil;
   end;
end;

function TInsightiTrackWatcher.InfoTrackLogin(const Url: string; TargetFileName, User, Pass: string): boolean;
var
   IdHTTP: TIdHTTP;
   Response,
   FullTargetFileName: string;
   FileStream: TFileStream;
   LHandler: TIdSSLIOHandlerSocketOpenSSL;
   FileHandle,
   numBytes: integer;
   URI: TIdURI;
   bFileError: boolean;
begin
   Result := False;
   bFileError := False;
   if (Url <> '') then
   begin
      try
         IdHTTP := TIdHTTP.Create(nil);
         LHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
         LHandler.SSLOptions.Method := sslvTLSv1;
         try
            FullTargetFileName := TargetFileName + '.pdf';
            If FileExists(FullTargetFileName) = False then
            begin
               FileHandle := FileCreate(FullTargetFileName);
               if FileHandle = -1 then
               begin
                  bFileError := True;
//                    MsgErr('Unable to create download file.');
               end;
               FileClose(FileHandle);
            end;

            if bFileError = False then
            begin
               IdHTTP.AllowCookies := True;
               IdHTTP.HandleRedirects := True;

               IdHTTP.Request.Username := User;
               IdHTTP.Request.Password := Pass;
               IdHTTP.Request.BasicAuthentication := False;
               IdHTTP.HTTPOptions := [hoInProcessAuth];

               IdHTTP.Request.ContentType := 'application/x-www-form-urlencoded';
               IdHTTP.Request.Connection := 'keep-alive';
               // Download file
               try
                  IdHTTP.IOHandler:=LHandler;
                  URI := TIdURI.Create(Url);
                  URI.Username := User;
                  URI.Password := Pass;

                  FileStream := TFileStream.Create(FullTargetFileName, fmOpenReadWrite);
                  try
                     IdHTTP.Get(URI.GetFullURI([ofAuthInfo]), FileStream);
                     numBytes := IdHTTP.response.contentLength;
                  finally
                     FileStream.Free;
                  end;
               finally
                  LHandler.Free;
                  Result := True;
                  IdHTTP.Disconnect;
               end;
            end;
         except
            on E: Exception do
               ShowMessage(E.Message);
         end;
      finally
         IdHTTP.Free;
         URI.Free;
      end;
   end
   else
      Result := True;
end;

procedure TInsightiTrackWatcher.SaveDocument(ACreated: TDateTime; AFileID, AAuthor, AFileName, AKeyword, ASearch: string;
                       AImageIndex: integer);
begin
   try
      qryMatterAttachment.Open;
      qryMatterAttachment.Insert;
      qryMatterAttachment.FieldByName('docid').AsInteger := DocID;
      qryMatterAttachment.FieldByName('fileid').AsString := AFileid;
      qryMatterAttachment.FieldByName('nmatter').AsInteger := TableInteger('MATTER','FILEID',AFileID,'nMatter');
      qryMatterAttachment.FieldByName('auth1').AsString := AAuthor;
      qryMatterAttachment.FieldByName('D_CREATE').AsDateTime := Now;

      qryMatterAttachment.FieldByName('IMAGEINDEX').AsInteger := AImageIndex;

      qryMatterAttachment.FieldByName('DESCR').AsString := ExtractFileName(AFileName);
      qryMatterAttachment.FieldByName('SEARCH').AsString := ASearch;
      qryMatterAttachment.FieldByName('FILE_EXTENSION').AsString := Copy(ExtractFileExt(AFileName),2, Length(ExtractFileExt(AFileName)));
      qryMatterAttachment.FieldByName('doc_name').AsString := ASearch;
      qryMatterAttachment.FieldByName('KEYWORDS').AsString := AKeyword;
      qryMatterAttachment.FieldByName('PATH').AsString := AFileName;
		qryMatterAttachment.FieldByName('DISPLAY_PATH').AsString := AFileName;
      qryMatterAttachment.FieldByName('EXTERNAL_ACCESS').AsString := 'N';

      try
         qryMatterAttachment.ApplyUpdates;
      finally
         qryMatterAttachment.CommitUpdates;
      end;
   except
      qryMatterAttachment.CancelUpdates;
   end;
end;

function TInsightiTrackWatcher.SystemString(sField: string): string;
begin
   with qrySysfile do
   begin
      SQL.Text := 'SELECT ' + sField + ' FROM SYSTEMFILE';
      try
         Open;
         SystemString := FieldByName(sField).AsString;
         Close;
      except
      //
      end;
   end;
end;

function TInsightiTrackWatcher.SystemInteger(sField: string): integer;
begin
   with qrySysfile do
   begin
      SQL.Text := 'SELECT ' + sField + ' FROM SYSTEMFILE';
      try
         Open;
         SystemInteger := FieldByName(sField).AsInteger;
         Close;
      except
      //
      end;
   end;
end;

function TInsightiTrackWatcher.CleanFileName(AFileName: string; ANewChar: char = ' '): string;
var
   x: integer;
begin
   // clean up File Name
   for x := 1 to length(AFileName) do
   begin
      if (AFileName[x] in ['\','?','"','<','>','|','*',':',';','/']) then
         AFileName[x] := ANewChar;
   end;
   Result := AFileName;
end;

function TInsightiTrackWatcher.ParseMacros(AFileName: String; ANMatter: Integer; ADocID: Integer; ADocDescr: string): String;
var
  LBfr: Array[0..MAX_PATH] of Char;
begin
  if(GHomePath = '') then
    GHomePath := GetEnvironmentVariable('HOMEDRIVE') + GetEnvironmentVariable('HOMEPATH');

  if(GTempPath = '') then
  begin
    GetTempPath(MAX_PATH,Lbfr);
    GTempPath := String(LBfr);
  end;

  Result := AFileName;

  Result := StringReplace(Result,C_MACRO_USERHOME,GHomePath,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,C_MACRO_TEMPDIR,GTempPath,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,C_MACRO_NMATTER,IntToStr(ANMatter),[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,C_MACRO_FILEID, TableString('MATTER','NMATTER',IntToStr(ANMatter),'FILEID'),[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,C_MACRO_CLIENTID, TableString('MATTER','NMATTER',IntToStr(ANMatter),'CLIENTID'),[rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result,C_MACRO_DATE,FormatDateTime('dd-mm-yyyy',Now()) ,[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,C_MACRO_TIME,FormatDateTime('hh-nn-ss',Now()),[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,C_MACRO_DATETIME,FormatDateTime('dd-mm-yyyy-hh-nn-ss',Now()),[rfReplaceAll, rfIgnoreCase]);

  Result := StringReplace(Result,C_MACRO_AUTHOR, TableString('MATTER','NMATTER',IntToStr(ANMatter),'AUTHOR'),[rfReplaceAll, rfIgnoreCase]);
  if (ADocDescr <> '')  then
     Result := StringReplace(Result,C_MACRO_DOCDESCR, ADocDescr ,[rfReplaceAll, rfIgnoreCase]);
  if (pos(C_MACRO_DOCSEQUENCE,UpperCase(Result)) > 0) then
     Result := StringReplace(Result,C_MACRO_DOCSEQUENCE, ProcString('getDocSequence',ANMatter),[rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result,C_MACRO_USERINITIALS, UserID ,[rfReplaceAll, rfIgnoreCase]);
  if ADocID > 0 then
     Result := StringReplace(Result,C_MACRO_DOCID, IntToStr(ADocID),[rfReplaceAll, rfIgnoreCase]);

  if(Pos(C_MACRO_TEMPFILE,Result) > 0) then
  begin
    GetTempFileName(PChar(GTempPath),'axm',0,LBfr);
    Result := StringReplace(Result,C_MACRO_TEMPFILE,String(LBfr),[rfReplaceAll, rfIgnoreCase]);
  end;
end;

function TInsightiTrackWatcher.TableInteger(Table, LookupField, LookupValue,
                                            ReturnField: string): integer;
var
   qryLookup: TUniQuery;
begin
   try
      qryLookup := TUniQuery.Create(nil);
      qryLookup.Connection := uniInsight;
      with qryLookup do
      begin
         SQL.Text := 'SELECT ' + ReturnField + ' FROM ' + Table + ' WHERE ' + LookupField + ' = :' + LookupField;
         Params[0].AsString := LookupValue;
         Open;
         Result := Fields[0].AsInteger;
         Close;
      end;
   finally
      qryLookup.Free;
   end;
end;

function TInsightiTrackWatcher.ProcString(Proc: string; LookupValue: integer): string;
begin
   with procTemp do
   begin
     storedProcName := Proc;
     PrepareSQL;
     Params[1].AsInteger := LookupValue;
     Execute;
     Result := Params[0].AsString;
   end;
end;

function TInsightiTrackWatcher.MatterString(iFile: integer; sField: string): string;
var
  sGetField: string;
  qryThisMatter: TUniQuery;
begin
   Result := '0';
   qryThisMatter := TUniQuery.Create(nil);
   try
      sGetField := sField;

      with qryThisMatter do
      begin
         Connection := uniInsight;
         SQL.Text := 'SELECT ' + sGetField + ' FROM MATTER M WHERE NMATTER = :NMATTER';
         Params[0].AsInteger := iFile;
         Open;
         if not IsEmpty then
            Result := FieldByName(sField).AsString;
         Close;
      end;
   except
      On E:Exception do
//      MsgErr('Error occured accessing Matter field ' + sGetField + #13#13 + E.Message);
   end;
   qryThisMatter.Free;
end;

function TInsightiTrackWatcher.TableString(Table, LookupField, LookupValue, ReturnField: string): string;
var
  qryLookup: TUniQuery;
begin

  if (Table = 'TAXTYPE') AND ((ReturnField = 'LEDGER') OR  (ReturnField = 'OUTPUTLEDGER') OR (ReturnField = 'ADJUSTLEDGER'))
  then
  begin
    qryLookup := TUniQuery.Create(nil);
    qryLookup.Connection := uniInsight;
    with qryLookup do
        begin
        SQL.Text := 'SELECT ' + ReturnField + ' FROM TAXTYPE_LEDGER WHERE ' + LookupField + ' = :' + LookupField + ' and entity = :entity ';
        ParamByName(LookupField).AsString := LookupValue;
        ParamByName('ENTITY').AsString := Entity;
        open;
        Result := Fields[0].AsString;
        Close;
        end;
    exit;
  end;

  qryLookup := TUniQuery.Create(nil);
  qryLookup.Connection := uniInsight;
  with qryLookup do
  begin
    SQL.Text := 'SELECT ' + ReturnField + ' FROM ' + Table + ' WHERE ' + LookupField + ' = :LookupField';
    Params[0].AsString := LookupValue;
    Open;
    Result := Fields[0].AsString;
    Close;
  end;
  qryLookup.Free;
end;

function TInsightiTrackWatcher.GetSeqnum(sField: string): integer;
var
  iTmp: integer;
begin
{ GetSeqnum grabs the Seqnum specified by sField and returns it.
}
  try
    with qrySeqNums do
    begin
      Close;

      SQL.Text := 'SELECT ' + sField + ' FROM SEQNUMS FOR UPDATE';
      Open;
      iTmp := -1;
      if not IsEmpty then
      begin
        iTmp := FieldByName(sField).AsInteger + 1;
        SQL.Text := 'UPDATE SEQNUMS SET ' + sField + ' = ' + IntToStr(iTmp);
        ExecSQL;
        Close;
      end;
      Close;
      Result := iTmp;
    end;
  except
    // Didn't work for some reason
    On E: Exception do
    begin
//      MsgErr('Could not get next sequential number: ' + sField + #13#13 + E.Message);
//      raise;
    end;
  end;
end;


function TInsightiTrackWatcher.TableStringEntity(aTable, aLookupField: string; aLookupValue: integer; aReturnField: string; aEntity: string): string;
var
  qryLookup    : TUniQuery;
  lsEntitySQL  : String;
begin
  if aEntity = '' then
    aEntity:= Entity;

  qryLookup := TUniQuery.Create(nil);
  qryLookup.Connection := uniInsight;

  if (UpperCase(aTable) = 'CHART') then
    lsEntitySQL := ' AND BANK = :ENTITY '
  else
    lsEntitySQL := ' AND ENTITY = :ENTITY ';

  with qryLookup do
  begin
    SQL.Text := 'SELECT ' + aReturnField + ' FROM ' + aTable + ' WHERE ' + aLookupField + ' = :' + aLookupField + lsEntitySQL;
    Params[0].AsInteger := aLookupValue;

    Params[1].AsString := aEntity;

    Open;
    Result := Fields[0].AsString;
    Close;
  end;
  qryLookup.Free;
end;

function TInsightiTrackWatcher.ValidLedger(sEntity, sLedger: string): boolean;
begin
   // Make sure that the ledger exists
   try
      with qryCharts do
      begin
         Close;
         SQL.Clear;
         SQL.Add('SELECT CODE');
         SQL.Add('FROM CHART');
         SQL.Add('WHERE BANK = :BANK');
         SQL.Add('  AND COMPONENT_CODE_DISPLAY = :CODE');

         ParamByName('BANK').AsString := sEntity;
         ParamByName('CODE').AsString := sLedger;
         Open;

         if FieldByName('CODE').IsNull then
         begin
            Close;
            SQL.Clear;
            SQL.Add('SELECT CODE');
            SQL.Add('FROM CHART');
            SQL.Add('WHERE BANK = :BANK');
            SQL.Add('  AND CODE = :CODE');
            ParamByName('BANK').AsString := sEntity;
            ParamByName('CODE').AsString := sLedger;
            Open;
            if FieldByName('CODE').IsNull then
               ValidLedger := False
            else
               ValidLedger := True;
         end
         else
            ValidLedger := True;
      end;
   finally
      qryCharts.Close;
   end;
end;

procedure TInsightiTrackWatcher.PostLedger(dtDate: TDateTime; cAmount: currency; cTax: Currency;
                          sRefno: string; sOwnerCode: string; iOwner: int64; sDesc: string;
                          sLedger: string; sAuthor: string; iInvoice: int64;
                          CreditorCode: string; sTaxCode : String; bJournalSplit : Boolean = FALSE;
                          sParentChart : String = '0'; nAlloc: int64 = 0; nMatter: int64 = 0;
                          nAccount: int64 = 0; UseRvDate: Boolean = FALSE; nTrans: integer = 0;
                          cBAS_Tax: currency = 0);
var
  sFullLedger,
  sSubChart,
  sRoundChart : String;
  fPercent,fSubChartAmount,fSubChartAmountTax : currency;
  fTotalPosted,fTotalTaxPosted : currency;
  iNumRound : integer;
  iTotalPercent : double;
begin
   if (sAuthor = '') then
      sFullLedger := sLedger
   else
      sFullLedger := GetSubchart(Entity, sLedger, sAuthor);
   try
      with qryExpenseAllocations do
      begin
         close;
         paramByName('CODE').AsString := sFullLedger;
         paramByName('BANK').AsString := Entity;
         open;
         first;

         if eof then
         begin
            SaveLedger(dtDate, cAmount, cTax, sRefno, sOwnerCode, iOwner, sDesc,
                       sFullLedger, sAuthor, iInvoice, CreditorCode, sTaxCode,
                       sParentChart, nAlloc, nMatter, nAccount,UseRvDate, nTrans, cBAS_Tax);
         end
         else
         begin
            fTotalPosted := 0;
            fTotalTaxPosted := 0;
            iTotalPercent := 0;
            iNumRound := 0;
            while not eof do
            begin
               iTotalPercent := iTotalPercent + fieldByName('percentage').AsFloat;
               if fieldByname('is_rounding').AsString = 'Y' then
               begin
                  sRoundChart := fieldByName('CODE').AsString;
                  inc(iNumRound);
               end
               else
               begin
                  sSubChart := fieldByName('CODE').AsString;
                  fPercent := fieldByName('percentage').AsFloat;
                  fPercent := fPercent / 100;
                  fSubChartAmount := cAmount * fPercent;
                  fSubChartAmountTax := cTax * fPercent;
                  // make sure the amounts round !
                  fSubChartAmount := round(fSubChartAmount*100)/100;
                  fSubChartAmountTax := round(fSubChartAmountTax*100)/100;

                  fTotalPosted := fTotalPosted + fSubChartAmount;
                  fTotalTaxPosted := fTotalTaxPosted + fSubChartAmountTax;

                  SaveLedger(dtDate, fSubChartAmount, fSubChartAmountTax, sRefno, sOwnerCode, iOwner, sDesc,
                             sSubChart, sAuthor, iInvoice, CreditorCode, sTaxCode,
                             sParentChart, nAlloc, nMatter, nAccount,UseRvDate, nTrans, cBAS_Tax);
               end;
               next;
           end;
           {now post the rounding amout}
           if iNumRound <> 1then
//              raise Exception.Create('Error one rounding must exists in expense allocations');

           if round(iTotalPercent*100)/100 <> 100 then
//              raise Exception.Create('Total percentage in expense allocations must be 100%');

           SaveLedger(dtDate, cAmount-fTotalPosted, cTax-fTotalTaxPosted, sRefno, sOwnerCode, iOwner, sDesc,
               sRoundChart, sAuthor, iInvoice, CreditorCode, sTaxCode,
               sParentChart, nAlloc, nMatter, nAccount,UseRvDate, nTrans, cBAS_Tax);
        end;
        close;
      end;
   except
//
  end;
end;

function TInsightiTrackWatcher.GetSubchart(sEntity: string; sMainChart: string; sEmp: String): string;
var
  sTmpLedger: string;
begin
   with qryEmps do
   begin
      Close;
      SQL.Text := 'SELECT CHART_SUFFIX FROM EMPLOYEE WHERE CODE = :CODE';
      Params[0].AsString := sEmp;
      Open;

      if not IsEmpty then
      begin
         sTmpLedger := sMainChart + FieldByName('CHART_SUFFIX').AsString;
         if not ValidLedger(sEntity, sTmpLedger) then
            sTmpLedger := sMainChart;
      end
      else
         sTmpLedger := sMainChart;
   end;

   if not ValidLedger(sEntity, sTmpLedger) then
//    Raise EPostError.Create('Invalid Ledger Code: ' + sMainChart);

   GetSubchart := sTmpLedger;
end;

procedure TInsightiTrackWatcher.SaveLedger(dtDate: TDateTime; cAmount: currency; cTax: Currency;
  sRefno, sOwnerCode: string; iOwner: integer; sDesc, sFullLedger, sAuthor: string;
  iInvoice: Integer; CreditorCode, sTaxCode, sParentChart: String; nAlloc: integer = 0;
  nMatter: int64 = 0; nAccount: integer = 0; UseRvDate: boolean = FALSE; nTrans: integer = 0;
  cBAS_Tax: currency = 0);
const
  TransactionsFile = 'Transactions.log';
var
  Text                 : String;
  TransactionsFilePath : String;
  t                    : TextFile;
begin
   if (not ValidLedger(Entity, sFullLedger)) then
//    Raise EPostError.Create('Invalid Ledger: ' + sFullLedger)
   else
      if (not IsActiveLedger(Entity, sFullLedger)) then
//      Raise EPostError.Create('Inactive Ledger: ' + sFullLedger)
      else
      if (cAmount <> 0) then
      begin

        try
          with qryTransItemInsert do
          begin
            ParamsNullify(Params);

            ParamByName('CREATED').AsDateTime := dtDate;
            ParamByName('ACCT').AsString := Entity;
            ParamByName('AMOUNT').AsFloat := cAmount;
            ParamByName('TAX').AsFloat := cTax;
            ParamByName('REFNO').AsString := sRefno;
            ParamByName('DESCR').AsString := sDesc;
            ParamByName('CHART').AsString := sFullLedger;
            ParamByName('OWNER_CODE').AsString := sOwnerCode;
            ParamByName('NOWNER').AsInteger := iOwner;
            ParamByName('TAXCODE').AsString := sTaxCode;
            ParamByName('PARENT_CHART').AsString := sParentChart;
            if nTrans > 0 then
               ParamByName('NTRANS').AsInteger := nTrans;

            ParamByName('WHO').AsString := UserID;

            if (sOwnerCode = 'CHEQUE') then
              ParamByName('NCHEQUE').AsInteger := iOwner;

            if (iInvoice <> -1) then
            begin
             ParamByName('NINVOICE').AsInteger := iInvoice;
             ParamByName('CREDITORCODE').AsString := CreditorCode;
            end;

            if (sOwnerCode = 'RECEIPT') then
              ParamByName('NRECEIPT').AsInteger := iOwner;

            if (sOwnerCode = 'JOURNAL') then
              ParamByName('NJOURNAL').AsInteger := iOwner;

            if (nAlloc <> 0) then
              ParamByName('NALLOC').AsInteger := nAlloc;

            if (nMatter <> 0) then
              ParamByName('NMATTER').AsInteger := nMatter;

            if (UseRvDate)then
              ParamByName('RVDATE').AsDate := Now;

            ParamByName('VERSION').AsString := C_VERSION;

            ParamByName('BAS_TAX').AsFloat := cBAS_Tax;
            ExecSQL;
            Close;

//            cLedgerTotal := cLedgerTotal + cAmount;
          end;
        except
          on E : Exception do
          begin
            Raise;

          end;
        end;
      end;
end;

function TInsightiTrackWatcher.IsActiveLedger(sEntity : String; sFullLedger : String) : Boolean;
var
  loQryCharts : TUniQuery;
begin
  loQryCharts := nil;
  try
    loQryCharts := qryCharts;
    loQryCharts.Connection := uniInsight;
    loQryCharts.Close;
    loQryCharts.SQL.Clear;
    loQryCharts.SQL.Add('SELECT ACTIVE');
    loQryCharts.SQL.Add('FROM CHART');
    loQryCharts.SQL.Add('WHERE BANK = :BANK');
    loQryCharts.SQL.Add('  AND CODE = :CODE');
    loQryCharts.Params[0].AsString := sEntity;
    loQryCharts.Params[1].AsString := sFullLedger;
    loQryCharts.Open;

    if (not loQryCharts.IsEmpty) then
      begin
        Result := (loQryCharts.FieldByName('ACTIVE').AsString = 'Y');
      end
    else
      Result := False;
  finally
    loQryCharts.Close;
  end;    //  end try-finally
end;

procedure TInsightiTrackWatcher.ParamsNullify(parClear: TParams);
var
  iCtr: integer;
begin
  for iCtr := 0 to parClear.Count - 1 do
    parClear.Items[iCtr].Value := null;
end;

function TInsightiTrackWatcher.getGlComponents : TglComponentSetup;
begin
   if glComponentReg = nil then
      loadGlComponent;

   getGlComponents := glComponentReg;
end;

procedure TInsightiTrackWatcher.loadGlComponent;
begin
   if glComponentReg <> nil then
      glComponentReg.Free;
   glComponentReg := TglComponentSetup.init(TInsightiTrackWatcher.Entity, uniInsight);
end;

end.
