Attribute VB_Name = "modBuild_Main"
Option Compare Database
Option Explicit

' =====================================================================
'  modBuild_Main - ONE-STEP BUILD for the Solar & Storage
'  Interconnection Tracker.
'
'  From a new blank .accdb:
'    1. Import all .bas files in \src (VBA editor: File > Import File),
'       or run scripts\Build-AccessApp.ps1 which does it for you.
'    2. Put data\InterconnectionProjects.xlsx next to the .accdb
'       (or keep the repo's \data folder beside it).
'    3. Run BuildSolarStorageApp (press Ctrl+G, type it, press Enter).
'
'  The build is fully re-runnable: it drops and recreates all
'  application objects each time.
' =====================================================================

Public Sub BuildSolarStorageApp(Optional ByVal bQuiet As Boolean = False)
    On Error GoTo ErrHandler
    Dim bImported As Boolean

    ' 1. Schema: tables, lookups, relationships, queries
    BuildTables

    ' 2. Load the generator/load interconnection data from the spreadsheet
    bImported = RefreshFromSpreadsheet(True)

    ' 3. Sample form-side detail records (only attach to imported projects)
    LoadSampleDetails

    ' 4. Front end
    BuildProjectForm
    BuildDashboard

    ' 5. Reports
    BuildReports

    ' 6. Open the dashboard on startup
    SetStartupForm "frmDashboard"

    If Not bQuiet Then
        If bImported Then
            MsgBox "Build complete." & vbCrLf & vbCrLf & _
                   "Tables, forms, reports and exports are ready." & vbCrLf & _
                   "The dashboard will now open (and opens automatically on startup).", _
                   vbInformation, "Solar & Storage Interconnection Tracker"
        Else
            MsgBox "Build complete, but InterconnectionProjects.xlsx was not found, so no " & _
                   "projects were imported." & vbCrLf & vbCrLf & _
                   "Use the dashboard's 'Refresh Import from Spreadsheet' button to pick the file, " & _
                   "then run LoadSampleDetails from the Immediate window if you also want the sample detail records.", _
                   vbExclamation, "Solar & Storage Interconnection Tracker"
        End If
    End If

    DoCmd.OpenForm "frmDashboard"
    Exit Sub

ErrHandler:
    MsgBox "Build failed at: " & Err.Source & vbCrLf & Err.Number & " - " & Err.Description, _
           vbCritical, "Build Solar & Storage App"
End Sub

Private Sub SetStartupForm(ByVal sFormName As String)
    On Error Resume Next
    Dim db As DAO.Database
    Dim prp As DAO.Property
    Set db = CurrentDb
    db.Properties("StartupForm") = sFormName
    If Err.Number = 3270 Then    ' property not found - create it
        Err.Clear
        Set prp = db.CreateProperty("StartupForm", dbText, sFormName)
        db.Properties.Append prp
    End If
    On Error GoTo 0
End Sub
