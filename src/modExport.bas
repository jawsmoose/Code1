Attribute VB_Name = "modExport"
Option Compare Database
Option Explicit

' =====================================================================
'  modExport - one-click CSV / XLSX exports of qryProjectMaster (the
'  flat, Power BI-ready join of imported + form-entered data).
'  Files land in an "Exports" folder beside the database, timestamped.
' =====================================================================

Public Function ExportMasterCSV()
    On Error GoTo ErrHandler
    Dim sPath As String
    sPath = ExportFolder() & "\SolarStorageProjects_" & TimeStamp() & ".csv"
    DoCmd.TransferText acExportDelim, , "qryProjectMaster", sPath, True
    AnnounceExport sPath, "CSV"
    Exit Function
ErrHandler:
    MsgBox "CSV export failed: " & Err.Description, vbCritical, "Export"
End Function

Public Function ExportMasterXLSX()
    On Error GoTo ErrHandler
    Dim sPath As String
    sPath = ExportFolder() & "\SolarStorageProjects_" & TimeStamp() & ".xlsx"
    DoCmd.TransferSpreadsheet acExport, acSpreadsheetTypeExcel12Xml, "qryProjectMaster", sPath, True
    AnnounceExport sPath, "Excel"
    Exit Function
ErrHandler:
    MsgBox "Excel export failed: " & Err.Description, vbCritical, "Export"
End Function

Private Function ExportFolder() As String
    ExportFolder = EnsureFolder(CurrentProject.Path & "\Exports")
End Function

Private Function TimeStamp() As String
    TimeStamp = Format(Now(), "yyyymmdd_hhnnss")
End Function

Private Sub AnnounceExport(ByVal sPath As String, ByVal sKind As String)
    MsgBox sKind & " export complete - ready for Power BI or any other tool." & vbCrLf & vbCrLf & sPath, _
           vbInformation, "Export"
End Sub
