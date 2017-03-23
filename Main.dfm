object InsightiTrackWatcher: TInsightiTrackWatcher
  OldCreateOrder = False
  DisplayName = 'InsightiTrackWatcher'
  Height = 271
  Width = 311
  object qryMatterAttachment: TUniQuery
    Connection = uniInsight
    SQL.Strings = (
      'SELECT'
      '  DOC.DOCUMENT,'
      '  DOC.IMAGEINDEX,'
      '  DOC.FILE_EXTENSION,'
      '  DOC.DOC_NAME,'
      '  DOC.SEARCH,'
      '  DOC.DOC_CODE,'
      '  DOC.JURIS,'
      '  DOC.D_CREATE,'
      '  DOC.AUTH1,'
      '  DOC.D_MODIF,'
      '  DOC.AUTH2,'
      '  DOC.PATH,'
      '  DOC.DESCR,'
      '  DOC.FILEID,'
      '  DOC.DOCID,'
      '  DOC.NPRECCATEGORY,'
      '  DOC.NMATTER,'
      '  DOC.PRECEDENT_DETAILS,'
      '  DOC.NPRECCLASSIFICATION,'
      '  DOC.KEYWORDS,'
      '  DOC.DISPLAY_PATH,'
      '  DOC.EXTERNAL_ACCESS,'
      '  DOC.EMAIL_FROM,'
      '  DOC.EMAIL_SENT_TO,'
      '  DOC.NFEE, '
      '  DOC.ROWID'
      'FROM'
      '  DOC'
      'where'
      '  DOCID = :DOCID')
    CachedUpdates = True
    OnNewRecord = qryMatterAttachmentNewRecord
    Left = 25
    Top = 15
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'DOCID'
        Value = nil
      end>
  end
  object qrySearches: TUniQuery
    UpdatingTable = 'searches'
    KeyFields = 'search_id'
    SQLInsert.Strings = (
      'INSERT INTO SEARCHES'
      
        '  (AVAILABLEONLINE, BILLINGTYPENAME, CLIENTREFERENCE, COMMENTS, ' +
        'DATEORDERED, DATECOMPLETED, DESCRIPTION, ORDERID, PARENTORDERID,' +
        ' ORDEREDBY, REFERENCE, RETAILERREFERENCE, RETAILERFEE, RETAILERF' +
        'EEGST, RETAILERFEETOTAL, SUPPLIERFEE, SUPPLIERFEEGST, SUPPLIERFE' +
        'ETOTAL, TOTALFEE, TOTALFEEGST, TOTALFEETOTAL, SERVICENAME, STATU' +
        'S, STATUSMESSAGE, DOWNLOADURL, ONLINEURL, ISBILLABLE, FILEHASH, ' +
        'EMAIL, CLIENTID, SEQUENCENUMBER)'
      'VALUES'
      
        '  (:AVAILABLEONLINE, :BILLINGTYPENAME, :CLIENTREFERENCE, :COMMEN' +
        'TS, :DATEORDERED, :DATECOMPLETED, :DESCRIPTION, :ORDERID, :PAREN' +
        'TORDERID, :ORDEREDBY, :REFERENCE, :RETAILERREFERENCE, :RETAILERF' +
        'EE, :RETAILERFEEGST, :RETAILERFEETOTAL, :SUPPLIERFEE, :SUPPLIERF' +
        'EEGST, :SUPPLIERFEETOTAL, :TOTALFEE, :TOTALFEEGST, :TOTALFEETOTA' +
        'L, :SERVICENAME, :STATUS, :STATUSMESSAGE, :DOWNLOADURL, :ONLINEU' +
        'RL, :ISBILLABLE, :FILEHASH, :EMAIL, :CLIENTID, :SEQUENCENUMBER)')
    SQLDelete.Strings = (
      'DELETE FROM SEARCHES'
      'WHERE'
      '  SEARCH_ID = :Old_SEARCH_ID')
    SQLUpdate.Strings = (
      'UPDATE SEARCHES'
      'SET'
      
        '  AVAILABLEONLINE = :AVAILABLEONLINE, BILLINGTYPENAME = :BILLING' +
        'TYPENAME, CLIENTREFERENCE = :CLIENTREFERENCE, COMMENTS = :COMMEN' +
        'TS, DATEORDERED = :DATEORDERED, DATECOMPLETED = :DATECOMPLETED, ' +
        'DESCRIPTION = :DESCRIPTION, ORDERID = :ORDERID, PARENTORDERID = ' +
        ':PARENTORDERID, ORDEREDBY = :ORDEREDBY, REFERENCE = :REFERENCE, ' +
        'RETAILERREFERENCE = :RETAILERREFERENCE, RETAILERFEE = :RETAILERF' +
        'EE, RETAILERFEEGST = :RETAILERFEEGST, RETAILERFEETOTAL = :RETAIL' +
        'ERFEETOTAL, SUPPLIERFEE = :SUPPLIERFEE, SUPPLIERFEEGST = :SUPPLI' +
        'ERFEEGST, SUPPLIERFEETOTAL = :SUPPLIERFEETOTAL, TOTALFEE = :TOTA' +
        'LFEE, TOTALFEEGST = :TOTALFEEGST, TOTALFEETOTAL = :TOTALFEETOTAL' +
        ', SERVICENAME = :SERVICENAME, STATUS = :STATUS, STATUSMESSAGE = ' +
        ':STATUSMESSAGE, DOWNLOADURL = :DOWNLOADURL, ONLINEURL = :ONLINEU' +
        'RL, ISBILLABLE = :ISBILLABLE, FILEHASH = :FILEHASH, EMAIL = :EMA' +
        'IL, CLIENTID = :CLIENTID, SEQUENCENUMBER = :SEQUENCENUMBER'
      'WHERE'
      '  SEARCH_ID = :Old_SEARCH_ID')
    SQLLock.Strings = (
      
        'SELECT SEARCH_ID, AVAILABLEONLINE, BILLINGTYPENAME, CLIENTREFERE' +
        'NCE, COMMENTS, DATEORDERED, DATECOMPLETED, DESCRIPTION, ORDERID,' +
        ' PARENTORDERID, ORDEREDBY, REFERENCE, RETAILERREFERENCE, RETAILE' +
        'RFEE, RETAILERFEEGST, RETAILERFEETOTAL, SUPPLIERFEE, SUPPLIERFEE' +
        'GST, SUPPLIERFEETOTAL, TOTALFEE, TOTALFEEGST, TOTALFEETOTAL, SER' +
        'VICENAME, STATUS, STATUSMESSAGE, DOWNLOADURL, ONLINEURL, ISBILLA' +
        'BLE, FILEHASH, EMAIL, CLIENTID, SEQUENCENUMBER FROM SEARCHES'
      'WHERE'
      '  SEARCH_ID = :Old_SEARCH_ID'
      'FOR UPDATE NOWAIT')
    SQLRefresh.Strings = (
      
        'SELECT SEARCH_ID, AVAILABLEONLINE, BILLINGTYPENAME, CLIENTREFERE' +
        'NCE, COMMENTS, DATEORDERED, DATECOMPLETED, DESCRIPTION, ORDERID,' +
        ' PARENTORDERID, ORDEREDBY, REFERENCE, RETAILERREFERENCE, RETAILE' +
        'RFEE, RETAILERFEEGST, RETAILERFEETOTAL, SUPPLIERFEE, SUPPLIERFEE' +
        'GST, SUPPLIERFEETOTAL, TOTALFEE, TOTALFEEGST, TOTALFEETOTAL, SER' +
        'VICENAME, STATUS, STATUSMESSAGE, DOWNLOADURL, ONLINEURL, ISBILLA' +
        'BLE, FILEHASH, EMAIL, CLIENTID, SEQUENCENUMBER FROM SEARCHES'
      'WHERE'
      '  SEARCH_ID = :SEARCH_ID')
    SQLRecCount.Strings = (
      'SELECT Count(*) FROM ('
      'SELECT * FROM SEARCHES'
      ''
      ')')
    Connection = uniInsight
    SQL.Strings = (
      'select searches.*, searches.rowid'
      'from searches')
    DetailFields = 'search_id'
    Left = 102
    Top = 14
  end
  object qryTmp: TUniQuery
    Connection = uniInsight
    SQL.Strings = (
      'SELECT * FROM FEE')
    Left = 159
    Top = 18
  end
  object qrySysFile: TUniQuery
    Connection = uniInsight
    SQL.Strings = (
      'SELECT * FROM SYSTEMFILE')
    Left = 14
    Top = 65
  end
  object qryGetDocSeq: TUniQuery
    Connection = uniInsight
    SQL.Strings = (
      'select DOC_DOCID.nextval as nextdoc from dual')
    Left = 91
    Top = 69
  end
  object uniInsight: TUniConnection
    ProviderName = 'Oracle'
    SpecificOptions.Strings = (
      'Oracle.Direct=True'
      'Oracle.IPVersion=ivIPBoth')
    Options.KeepDesignConnected = False
    Options.LocalFailover = True
    PoolingOptions.MaxPoolSize = 50
    PoolingOptions.MinPoolSize = 1
    PoolingOptions.ConnectionLifetime = 10000000
    PoolingOptions.Validate = True
    Debug = True
    Username = 'axiom'
    Server = '192.168.0.22:1521:marketing'
    Connected = True
    LoginPrompt = False
    Left = 13
    Top = 120
    EncryptedPassword = '9EFF87FF96FF90FF92FF'
  end
  object procTemp: TUniStoredProc
    Connection = uniInsight
    Left = 90
    Top = 127
  end
  object qrySeqnums: TUniQuery
    Connection = uniInsight
    SQL.Strings = (
      'SELECT S.*, S.ROWID FROM SEQNUMS S')
    CachedUpdates = True
    AutoCalcFields = False
    Left = 157
    Top = 77
  end
  object qryCharts: TUniQuery
    Connection = uniInsight
    SQL.Strings = (
      'SELECT * FROM CHART WHERE BANK = :P_Bank AND CODE = :P_Code')
    Left = 221
    Top = 21
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'P_Bank'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'P_Code'
        Value = nil
      end>
  end
  object qryExpenseAllocations: TUniQuery
    Connection = uniInsight
    SQL.Strings = (
      'select *'
      'from gl_expense_allocations gl '
      'where master_code = :code'
      'and master_bank = :bank')
    Left = 171
    Top = 133
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'code'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'bank'
        Value = nil
      end>
  end
  object qryEmps: TUniQuery
    Connection = uniInsight
    SQL.Strings = (
      'SELECT CODE FROM EMPLOYEE')
    Left = 21
    Top = 185
  end
  object qryTransItemInsert: TUniQuery
    Connection = uniInsight
    SQL.Strings = (
      'INSERT INTO transitem'
      
        '            ( /*NACCOUNT, */created, acct, amount, tax, refno, d' +
        'escr, chart,'
      
        '             owner_code, nowner, ncheque, nreceipt, ninvoice, nj' +
        'ournal,'
      
        '             creditorcode, who, taxcode, parent_chart, nalloc, n' +
        'matter,'
      '             rvdate, VERSION, ntrans, bas_tax'
      '            )'
      
        '     VALUES (                                                   ' +
        '  --:NACCOUNT,'
      
        '             :created, :acct, :amount, :tax, :refno, :descr, :ch' +
        'art,'
      
        '             :owner_code, :nowner, :ncheque, :nreceipt, :ninvoic' +
        'e, :njournal,'
      
        '             :creditorcode, :who, :taxcode, :parent_chart, :nall' +
        'oc, :nmatter,'
      '             :rvdate, :VERSION, :ntrans, :bas_tax'
      '            )')
    Left = 96
    Top = 181
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CREATED'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'ACCT'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'AMOUNT'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'TAX'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'REFNO'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'DESCR'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'CHART'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'OWNER_CODE'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NOWNER'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NCHEQUE'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NRECEIPT'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NINVOICE'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NJOURNAL'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'CREDITORCODE'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'WHO'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'TAXCODE'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'PARENT_CHART'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NALLOC'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NMATTER'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'RVDATE'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'VERSION'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'NTRANS'
        Value = nil
      end
      item
        DataType = ftUnknown
        Name = 'BAS_TAX'
        Value = nil
      end>
  end
end
