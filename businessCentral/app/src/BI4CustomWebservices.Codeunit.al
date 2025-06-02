codeunit 82578 BI4AdlsWebservice
{
    Subtype = Install;
    trigger OnInstallAppPerDatabase()
    VAR
        WebServiceRec: Record "Tenant Web Service";
    BEGIN

        WebServiceRec.SetRange(WebServiceRec."Object Type", WebServiceRec."Object Type"::Codeunit);
        WebServiceRec.SetRange(WebServiceRec."Service Name", 'BI4AdlsWebservices');

        IF WebServiceRec.FINDSET() THEN BEGIN
            WebServiceRec.Delete(true)
        END;

        WebServiceRec.Init();
        WebServiceRec."Object Type" := WebServiceRec."Object Type"::Codeunit;
        WebServiceRec."Object ID" := 82574;
        WebServiceRec."Service Name" := 'BI4AdlsWebservices';
        WebServiceRec.Published := true;
        IF NOT WebServiceRec.Insert(true) then
            WebServiceRec.Modify(true);
    END;
}