Attribute VB_Name = "modImport"
Option Compare Database
Option Explicit

' =====================================================================
'  modImport - refresh tblProjects from the periodically updated
'  spreadsheet (InterconnectionProjects.xlsx, sheet "Projects").
'  Upserts on ProjectCode so form-entered detail records survive.
' =====================================================================

Public Function RefreshFromSpreadsheet(Optional ByVal bQuiet As Boolean = False) As Boolean
    On Error GoTo ErrHandler
    Dim db As DAO.Database
    Dim sPath As String
    Dim lUpdated As Long, lInserted As Long

    Set db = CurrentDb
    sPath = GetImportPath()

    If Len(sPath) = 0 Then
        If bQuiet Then Exit Function
        sPath = PickImportFile()
        If Len(sPath) = 0 Then
            MsgBox "No spreadsheet selected. Import cancelled.", vbExclamation, "Import Projects"
            Exit Function
        End If
    End If
    SaveSetting_ "ImportFilePath", sPath

    DropTableIfExists "tblStagingProjects"
    DoCmd.TransferSpreadsheet acImport, acSpreadsheetTypeExcel12Xml, _
        "tblStagingProjects", sPath, True, "Projects!"

    ' Update rows that already exist (keyed on ProjectCode)
    db.Execute _
        "UPDATE tblProjects AS p INNER JOIN tblStagingProjects AS s ON p.ProjectCode = s.ProjectCode SET " & _
        " p.ProjectName = s.ProjectName, p.Developer = s.Developer, p.ProjectType = s.ProjectType," & _
        " p.ISO_RTO = s.ISO_RTO, p.State = s.State, p.County = s.County," & _
        " p.SolarCapacityMWac = s.SolarCapacityMWac, p.StorageCapacityMW = s.StorageCapacityMW," & _
        " p.StorageEnergyMWh = s.StorageEnergyMWh, p.LoadMW = s.LoadMW," & _
        " p.QueueNumber = s.QueueNumber, p.QueueStatus = s.QueueStatus," & _
        " p.CommercialOperationDate = s.CommercialOperationDate, p.Offtaker = s.Offtaker," & _
        " p.LastImportedOn = Now()", dbFailOnError
    lUpdated = db.RecordsAffected

    ' Insert rows that are new in the spreadsheet
    db.Execute _
        "INSERT INTO tblProjects (ProjectCode, ProjectName, Developer, ProjectType, ISO_RTO, State, County," & _
        " SolarCapacityMWac, StorageCapacityMW, StorageEnergyMWh, LoadMW, QueueNumber, QueueStatus," & _
        " CommercialOperationDate, Offtaker, LastImportedOn) " & _
        "SELECT s.ProjectCode, s.ProjectName, s.Developer, s.ProjectType, s.ISO_RTO, s.State, s.County," & _
        " s.SolarCapacityMWac, s.StorageCapacityMW, s.StorageEnergyMWh, s.LoadMW, s.QueueNumber, s.QueueStatus," & _
        " s.CommercialOperationDate, s.Offtaker, Now() " & _
        "FROM tblStagingProjects AS s LEFT JOIN tblProjects AS p ON s.ProjectCode = p.ProjectCode " & _
        "WHERE p.ProjectCode Is Null AND s.ProjectCode Is Not Null", dbFailOnError
    lInserted = db.RecordsAffected

    DropTableIfExists "tblStagingProjects"

    RefreshFromSpreadsheet = True
    If Not bQuiet Then
        MsgBox "Import complete." & vbCrLf & vbCrLf & _
               "Source:  " & sPath & vbCrLf & _
               "Updated: " & lUpdated & " project(s)" & vbCrLf & _
               "Added:   " & lInserted & " project(s)", vbInformation, "Import Projects"
    End If
    Exit Function

ErrHandler:
    DropTableIfExists "tblStagingProjects"
    If Not bQuiet Then MsgBox "Import failed: " & Err.Description, vbCritical, "Import Projects"
End Function

Private Function PickImportFile() As String
    ' msoFileDialogFilePicker = 3 (late-bound so no Office reference is needed)
    On Error GoTo Fallback
    Dim fd As Object
    Set fd = Application.FileDialog(3)
    With fd
        .Title = "Select the interconnection projects spreadsheet"
        .AllowMultiSelect = False
        .Filters.Clear
        .Filters.Add "Excel Workbooks", "*.xlsx; *.xlsm; *.xls"
        If .Show Then PickImportFile = .SelectedItems(1)
    End With
    Exit Function
Fallback:
    PickImportFile = InputBox("Enter the full path to InterconnectionProjects.xlsx:", "Import Projects")
End Function
