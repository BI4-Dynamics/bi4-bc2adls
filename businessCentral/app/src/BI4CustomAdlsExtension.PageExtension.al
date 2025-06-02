pageextension 82576 BI4CustomAdlsExtension extends "ADLSE Setup Tables"
{
    actions
    {
        addlast(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Image = Refresh;
                trigger OnAction()
                var
                begin
                    CurrPage.Update();
                    Rec.FindFirst();
                end;
            }
            action(BI4StandardTables)
            {
                ApplicationArea = All;
                Image = AddAction;
                trigger OnAction()
                var
                    adlsTable: Record "ADLSE Table";
                    adlsField: Record "ADLSE Field";
                    bi4codeunit: Codeunit "BI4CustomAPIs";
                    listOfTables: List of [Integer];
                    listOfFields: List of [Integer];
                    tableID: Integer;
                    fieldID: Integer;
                begin
                    listOfTables.Add(2000000058); //AllObjWithCaption
                    listOfTables.Add(2000000153); //NavInstalledApp
                    listOfTables.Add(2000000006); //Company
                    //listOfTables.Add(2000000207); //Application Object Metadata
                    //listOfTables.Add(2000000206); //Published Application

                    foreach tableID in listOfTables do begin
                        listOfFields := bi4codeunit.GetFieldsFromTable(tableID);
                        if not bi4codeunit.CheckIfTablesExits(tableID) then begin
                            adlsTable.Add(TableID);
                            foreach fieldID in listOfFields do begin
                                adlsField.Reset();
                                adlsField.SetRange("Table ID", adlsTable."Table ID");
                                adlsField.SetRange("Field ID", fieldID);
                                if not adlsField.FindFirst() then begin
                                    adlsField."Table ID" := adlsTable."Table ID";
                                    adlsField."Field ID" := fieldID;
                                    adlsField.Enabled := true;
                                    adlsField.Insert();
                                end
                            end;
                        end;
                    end
                end;
            }
            action(GetMetadata)
            {
                ApplicationArea = All;
                Image = AddAction;
                trigger OnAction()
                var
                    bi4codeunit: Codeunit "BI4CustomAPIs";
                begin
                    bi4codeunit.BI4GetMetadata();
                end;
            }
        }
    }
}