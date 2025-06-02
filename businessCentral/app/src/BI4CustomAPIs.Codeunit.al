codeunit 82579 BI4CustomAPIs
{
    var
        ContainerUrlTxt: Label 'https://%1.blob.core.windows.net/%2', Comment = '%1: Account name, %2: Container Name';
        ADLSECredentials: Codeunit "ADLSE Credentials";

    [ServiceEnabled]
    procedure AddTableForExport(TableID: Integer): Text
    var
        adlsTable: Record "ADLSE Table";
        tempMultiCompStatus: Boolean;
    begin
        tempMultiCompStatus := GetMultiCompanyExportStatus();
        if tempMultiCompStatus then
            MultiCompanyExportChange(false);
        adlsTable.Add(TableID);
        if tempMultiCompStatus then
            MultiCompanyExportChange(true);
        exit('Table added')
    end;

    [ServiceEnabled]
    procedure AddMultiTablesForExport(Tables: Text): Text
    var
        adlsTable: Record "ADLSE Table";
        tableID: Integer;
        output: Text;
        textSplit: List of [Text];
        listOfTables: List of [Integer];
        txt: Text;
        tableInteger: Integer;
        tempMultiCompStatus: Boolean;
    begin
        textSplit := Tables.Split(',');

        foreach txt in textSplit do begin
            Evaluate(tableInteger, txt);
            listOfTables.Add(tableInteger);
        end;

        tempMultiCompStatus := GetMultiCompanyExportStatus();

        if tempMultiCompStatus then
            MultiCompanyExportChange(false);

        foreach tableID in listOfTables do begin
            if not CheckIfTablesExits(tableID) then
                adlsTable.Add(TableID)
        end;
        if tempMultiCompStatus then
            MultiCompanyExportChange(true);
        if StrLen(output) = 0 then begin
            exit('All tables added');
        end
        else begin
            exit(output);
        end;
    end;

    procedure CheckIfTablesExits(TableID: Integer): Boolean
    var
        adlsTable: Record "ADLSE Table";
    begin
        adlsTable.SetRange("Table ID", TableID);
        exit(adlsTable.FindFirst());
    end;

    [ServiceEnabled]
    procedure InsertFieldsForTable(TableID: Integer; Fields: Text; ResetAllFields: Boolean): Text
    var
        adlsTable: Record "ADLSE Table";
        adlsField: Record "ADLSE Field";
        fieldNo: Integer;
        textSplit: List of [Text];
        listOfFields: List of [Integer];
        txt: Text;
        fieldInteger: Integer;
    begin
        textSplit := Fields.Split(',');

        foreach txt in textSplit do begin
            Evaluate(fieldInteger, txt);
            listOfFields.Add(fieldInteger);
        end;

        adlsTable.SetRange("Table ID", TableID);
        if adlsTable.FindSet(true) then begin
            if ResetAllFields then begin
                adlsField.SetRange("Table ID", adlsTable."Table ID");
                if adlsField.FindFirst() then
                    adlsField.DeleteAll();
                adlsField.Reset();
            end;
            foreach fieldNo in listOfFields do begin
                if ResetAllFields = false then begin
                    adlsField.SetRange("Table ID", adlsTable."Table ID");
                    adlsField.SetRange("Field ID", fieldNo);
                    if not adlsField.FindFirst() then begin
                        adlsField."Table ID" := adlsTable."Table ID";
                        adlsField."Field ID" := fieldNo;
                        adlsField.Enabled := true;
                        adlsField.Insert();
                    end
                end
                else begin
                    adlsField."Table ID" := adlsTable."Table ID";
                    adlsField."Field ID" := fieldNo;
                    adlsField.Enabled := true;
                    adlsField.Insert();
                end;
            end;
            exit('Fields were inserted');
        end
        else begin
            exit('Cannot find a table')
        end;
    end;

    [ServiceEnabled]
    procedure GetTablesForExport(): Text
    var
        adlsTable: Record "ADLSE Table";
        exportedTables: Text;
    begin
        if adlsTable.FindSet(true) then begin
            repeat
                exportedTables += Format(adlsTable."Table ID") + ',';
            until adlsTable.Next() = 0;
        end;
        exportedTables := CopyStr(exportedTables, 1, StrLen(exportedTables) - 1);
        exit(exportedTables);
    end;

    [ServiceEnabled]
    procedure SetTableAndFieldsForExport(TableID: Integer): Text
    var
        adlsTable: Record "ADLSE Table";
        adlsField: Record "ADLSE Field";
    begin
        adlsTable.SetRange("Table ID", TableID);
        if adlsTable.FindSet(true) then begin
            adlsField.SetRange("Table ID", adlsTable."Table ID");
            if adlsField.FindSet() then begin
                repeat
                    adlsField.Enabled := true;
                    adlsField.Modify();
                until adlsField.Next() = 0;
            end;
            adlsTable.Enabled := true;
            adlsTable.Modify();
            exit('Table: ' + Format(TableID) + ' was enabled');
        end
        else begin
            exit('Cannot find a table')
        end;
    end;

    [ServiceEnabled]
    procedure DisbleTableAndFieldsExport(TableID: Integer): Text
    var
        adlsTable: Record "ADLSE Table";
        adlsField: Record "ADLSE Field";
    begin
        adlsTable.SetRange("Table ID", TableID);
        if adlsTable.FindSet(true) then begin
            adlsField.SetRange("Table ID", adlsTable."Table ID");
            if adlsField.FindSet() then begin
                repeat
                    adlsField.Enabled := false;
                    adlsField.Modify();
                until adlsField.Next() = 0;
            end;
            adlsTable.Enabled := false;
            adlsTable.Modify();
            exit('Table: ' + Format(TableID) + ' was disabled');
        end
        else begin
            exit('Cannot find a table');
        end;
    end;

    [ServiceEnabled]
    procedure GetExportStatus(): Text
    var
        adlsTable: Record "ADLSE Table";
        adlsStatus: Record "ADLSE Run";
        output: TextBuilder;
    begin
        if adlsTable.FindSet(false) then begin
            repeat
                adlsStatus.SetRange("Table ID", adlsTable."Table ID");
                if adlsStatus.FindFirst() then
                    output.AppendLine(Format(adlsTable."Table ID") + ',' + Format(adlsStatus.State));
            until adlsTable.Next() = 0;
            exit(output.ToText());
        end
        else begin
            exit('There are no exported tables');
        end;
    end;

    [ServiceEnabled]
    procedure StartExport(): Text
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
    begin
        ADLSEExecution.StartExport();
        exit('Export started');
    end;

    [ServiceEnabled]
    procedure StopExport(): Text
    var
        ADLSEExecution: Codeunit "ADLSE Execution";
    begin
        ADLSEExecution.StopExport();
        exit('Export stopped');
    end;

    procedure GetFieldsFromTable(TableID: Integer): List of [Integer]
    var
        fieldRec: Record Field;
        listOfIds: List of [Integer];
    begin
        fieldRec.SetRange("TableNo", TableId);
        if fieldRec.FindSet() then begin
            repeat
                listOfIds.Add(fieldRec."No.");
            until fieldRec.Next() = 0;
        end;
        exit(listOfIds);
    end;

    [ServiceEnabled]
    procedure MultiCompanyExportChange(AllowExport: Boolean)
    var
        adlsSetup: Record "ADLSE Setup";
    begin
        adlsSetup."Multi- Company Export" := AllowExport;
    end;

    [ServiceEnabled]
    procedure GetMultiCompanyExportStatus(): Boolean
    var
        adlsSetup: Record "ADLSE Setup";
    begin
        adlsSetup.FindFirst();
        exit(adlsSetup."Multi- Company Export");
    end;

    //METADATA
    [ServiceEnabled]
    PROCEDURE BI4GetMetadata(): Text //Calling from .NET
    var
        ADLSEGen2Util: Codeunit "ADLSE Gen 2 Util";
        outText: Text;
        BlockID: Text;
        DataBlobBlockIDs: List of [Text];
    begin
        //urlMetadata := 'https://' + AccountName + '.blob.core.windows.net/' + ContainerName + '/BI4Dynamics/' + Format(DsID) + '/Metadata/Metadata.xml' + TokenString;
        ADLSECredentials.Init();
        //ADLSEGen2Util.CreateDataBlob(GetBaseUrl() + '/Metadata/Metadata.xml', ADLSECredentials);
        outText := GetBI4Tables();
        BlockID := ADLSEGen2Util.AddBlockToDataBlob(GetBaseUrl() + '/Metadata/Metadata.xml', outText, ADLSECredentials);
        DataBlobBlockIDs.Add(BlockID);
        ADLSEGen2Util.CommitAllBlocksOnDataBlob(GetBaseUrl() + '/Metadata/Metadata.xml', ADLSECredentials, DataBlobBlockIDs);
        Message('Metadata read');
        exit('Metadata read');
    end;

    local procedure GetBaseUrl(): Text
    var
        ADLSESetup: Record "ADLSE Setup";
        DefaultContainerName: Text;
        accountName: Text;
    begin
        if DefaultContainerName = '' then begin
            ADLSESetup.GetSingleton();
            DefaultContainerName := ADLSESetup.Container;
            accountName := ADLSESetup."Account Name";
        end;
        exit(StrSubstNo(ContainerUrlTxt, accountName, DefaultContainerName));
    end;

    LOCAL PROCEDURE GetBI4Tables(): Text //Gets entire xml
    VAR
        BI4TablesXml: XmlElement;
        XmlDoc: XmlDocument;
        Out: Text;
    BEGIN
        BI4TablesXml := GetBI4TablesXml();
        XmlDoc := XmlDocument.Create();
        XmlDoc.Add(BI4TablesXml);
        XmlDoc.WriteTo(Out);
        Out := Out.Replace('BI4Prefix=""', 'xmlns="urn:schemas-microsoft-com:dynamics:NAV:MetaObjects"');
        exit(Out);
    END;

    LOCAL PROCEDURE GetBI4TablesXml(): XmlElement //Gets all XmlElements and creates Bi4Dynamics XmlElement
    VAR
        xmlTables: XmlElement;
        xmlTable: XmlElement;
        metadataTable: Record AllObjWithCaption; //Saves AllObjWithCaption as metadataTable
        recRef: RecordRef;
    begin
        xmlTables := XmlElement.Create('Bi4Dynamics');
        metadataTable.SetRange("Object ID", 0, 2000000000);
        metadataTable.SetRange("Object Type", metadataTable."Object Type"::"Table");
        if metadataTable.FindSet(true) then begin
            repeat
                recRef.Open(metadataTable."Object ID", true);
                xmlTable := MetaTableXml(recRef, metadataTable); //Gets MetaTable XmlElement
                xmlTable.Add(FieldsXml(metadataTable."Object ID", metadataTable."App Package ID"));
                xmlTable.Add(GetKeysXml(recRef, metadataTable."App Package ID"));
                xmlTables.Add(xmlTable); //Writes MetaTable to Bi4Dynamics
                recRef.Close();
            until metadataTable.Next() = 0;
        end;
        exit(xmlTables);
    end;

    LOCAL PROCEDURE MetaTableXml(recRef: RecordRef; metadataTable: Record "AllObjWithCaption"): XmlElement //Creates and writes to MetaTable XmlElement
    VAR
        xmlTable: XmlElement;
        idNavApp: Text;
        nameNavApp: Text;
        captionml: Text;
    BEGIN
        xmlTable := XmlElement.Create('MetaTable');
        idNavApp := GetNavDataId(Format(metadataTable."App Package ID"));
        nameNavApp := GetNavDataName(metadataTable."App Package ID");
        captionml := 'ENU=' + metadataTable."Object Name";
        xmlTable.SetAttribute('BI4Prefix', '');
        xmlTable.SetAttribute('NAVAppID', metadataTable."App Package ID");
        xmlTable.SetAttribute('SourceAppId', idNavApp);
        xmlTable.SetAttribute('BcAppName', nameNavApp);
        xmlTable.SetAttribute('Object_Caption', metadataTable."Object Caption");
        xmlTable.SetAttribute('ID', Format(metadataTable."Object ID"));
        xmlTable.SetAttribute('Name', metadataTable."Object Name");
        xmlTable.SetAttribute('Object_Subtype', Format(metadataTable."Object Subtype"));
        xmlTable.SetAttribute('Object_Type', Format(metadataTable."Object Type"));
        xmlTable.SetAttribute('CaptionML', captionml);
        xmlTable.SetAttribute('SystemId', metadataTable.SystemId);
        EXIT(xmlTable);
    END;

    LOCAL PROCEDURE FieldsXml(TableNumber: Integer; appID: Text): XmlElement //Creates and writes to Fields XmlElement
    VAR
        xmlFields: XmlElement;
        xmlField: XmlElement;
        xmlRelation: XmlElement;
        xmlConditions: XmlElement;
        field: Record Field;
        x: Integer;
        idNavApp: Text;
        recRef: RecordRef;
        RelationTable: Record "Table Relations Metadata";
        hasRelation: Boolean;
        hasFieldRelation: Boolean;
    BEGIN
        xmlFields := XmlElement.Create('Fields');
        idNavApp := GetNavDataId(appID);
        field.SetRange(TableNo, TableNumber);
        field.SetRange(field.ObsoleteState, field.ObsoleteState::No);
        field.SetRange(field.Class, field.Class::Normal);
        field.SetFilter(field.Type, '<>%1 & <>%2', field.Type::GUID, field.Type::BLOB);
        RelationTable.SetRange("Table ID", TableNumber);
        hasRelation := RelationTable.FindSet(true);
        IF field.FINDSET(true) THEN BEGIN
            REPEAT
                xmlField := XmlElement.Create('Field');
                xmlField.SetAttribute('Name', field.FieldName);
                xmlField.SetAttribute('ID', Format(field."No."));
                xmlField.SetAttribute('Datatype', Format(field.Type));
                xmlField.SetAttribute('RelationFieldNo', Format(field.RelationFieldNo));
                xmlField.SetAttribute('RelationTableNo', Format(field.RelationTableNo));
                xmlField.SetAttribute('OptionString', field.OptionString);
                xmlField.SetAttribute('FieldClass', Format(field.Class));
                xmlField.SetAttribute('DataClassification', Format(field.DataClassification));
                xmlField.SetAttribute('Enabled', FormatBoolean(field.Enabled));
                xmlField.SetAttribute('Field_Caption', field."Field Caption");
                xmlField.SetAttribute('DataLength', Format(field.Len));
                xmlField.SetAttribute('ObsoleteReason', field.ObsoleteReason);
                xmlField.SetAttribute('ObsoleteState', Format(field.ObsoleteState));
                xmlField.SetAttribute('SQLDataType', Format(field.SQLDataType));
                xmlField.SetAttribute('SystemId', field.SystemId);
                xmlField.SetAttribute('TableName', field.TableName);
                xmlField.SetAttribute('TableNo', Format(field.TableNo));
                xmlField.SetAttribute('Type_Name', field."Type Name");
                xmlField.SetAttribute('SourceAppId', GetNavDataId(field."App Package ID"));
                xmlField.SetAttribute('IsPartOfPrimaryKey', Format(field.IsPartOfPrimaryKey));
                if hasRelation then begin
                    RelationTable.SetRange("Field No.", field."No.");
                    if RelationTable.FindFirst() then begin
                        repeat
                            xmlRelation := XmlElement.Create('TableRelations');
                            xmlRelation.SetAttribute('TableID', Format(RelationTable."Related Table ID"));
                            xmlRelation.SetAttribute('TableName', RelationTable."Related Table Name");
                            xmlRelation.SetAttribute('FieldID', Format(RelationTable."Related Field No."));
                            if (Format(RelationTable."Condition Value") <> '') then begin
                                xmlConditions := XmlElement.Create('Conditions');
                                xmlConditions.SetAttribute('FieldID', Format(RelationTable."Condition Field No."));
                                xmlConditions.SetAttribute('ConditionType', Format(RelationTable."Condition Type"));
                                xmlConditions.SetAttribute('ConditionValue', RelationTable."Condition Value");
                                xmlRelation.Add(xmlConditions);
                            end;
                            xmlField.Add(xmlRelation);
                        until RelationTable.Next() = 0;
                    end;
                end;
                xmlFields.Add(xmlField);
            UNTIL field.NEXT = 0;
        END;
        EXIT(xmlFields);
    END;

    LOCAL PROCEDURE GetKeysXml(recRef: RecordRef; appID: Text): XmlElement //Creates and writes to Keys XmlElement
    VAR
        xmlKey: XmlElement;
        xmlKeys: XmlElement;
        i: Integer;
        idNavApp: Text;
    BEGIN
        idNavApp := GetNavDataId(appID);
        xmlKeys := XmlElement.Create('Keys');
        FOR i := 1 TO RecRef.KeyCount() DO BEGIN
            xmlKey := XmlElement.Create('Key');
            xmlKey.SetAttribute('Enabled', FormatBoolean(RecRef.KEYINDEX(i).Active()));
            xmlKey.SetAttribute('Key', FORMAT(RecRef.KEYINDEX(i)));
            xmlKey.SetAttribute('SourceAppId', idNavApp);
            xmlKey.SetAttribute('KeyName', 'Key1');
            xmlKey.SetAttribute('SourceExtensionType', '2');
            xmlKey.SetAttribute('MaintainSQLIndex', '1');
            xmlKey.SetAttribute('MaintainSIFTIndex', '1');
            xmlKey.SetAttribute('Clustered', '1');
            xmlKey.SetAttribute('Unique', '0');
            xmlKeys.Add(xmlKey);
        END;
        EXIT(xmlKeys);
    END;

    Local procedure GetNavDataId(appID: Text): Text//Get id field from Nav App Installed App table
    var
        navTable: Record "NAV App Installed App";
    begin
        navTable.SetRange("Package ID", appID);
        if navTable.FindFirst() then
            exit(Format(navTable."App ID"));

        exit('');
    end;

    Local procedure GetNavDataName(appID: Guid): Text //Get name field from Nav App Installed App table
    var
        navTable: Record "NAV App Installed App";
    begin
        navTable.SetRange("Package ID", appID);
        if navTable.FindFirst() then
            exit(navTable.Name);

        exit('');
    end;

    LOCAL PROCEDURE FormatBoolean(boolValue: Boolean): Text //Returns value as 1 or 0
    VAR
    BEGIN
        IF (boolValue) THEN
            EXIT('1')
        ELSE
            EXIT('0')
    END;
}