Attribute VB_Name = "modUtil"
Option Compare Database
Option Explicit

' =====================================================================
'  modUtil - shared helpers for the Solar & Storage Interconnection app
' =====================================================================

' --- Theme colors (modern flat palette) ------------------------------
Public Function clrPrimary() As Long      ' deep green header bands
    clrPrimary = RGB(27, 94, 32)
End Function

Public Function clrAccent() As Long       ' brighter green for buttons
    clrAccent = RGB(46, 125, 50)
End Function

Public Function clrSlate() As Long        ' dark slate for dashboard header
    clrSlate = RGB(38, 50, 56)
End Function

Public Function clrBackground() As Long   ' soft off-white page background
    clrBackground = RGB(245, 247, 250)
End Function

Public Function clrCard() As Long
    clrCard = RGB(255, 255, 255)
End Function

Public Function clrAltRow() As Long
    clrAltRow = RGB(238, 244, 238)
End Function

Public Function clrTextDark() As Long
    clrTextDark = RGB(33, 33, 33)
End Function

Public Function clrTextMuted() As Long
    clrTextMuted = RGB(96, 108, 118)
End Function

' --- Object existence / cleanup --------------------------------------
Public Function TableExists(ByVal sName As String) As Boolean
    Dim tdf As DAO.TableDef
    TableExists = False
    For Each tdf In CurrentDb.TableDefs
        If StrComp(tdf.Name, sName, vbTextCompare) = 0 Then
            TableExists = True
            Exit Function
        End If
    Next tdf
End Function

Public Sub DropTableIfExists(ByVal sName As String)
    If TableExists(sName) Then
        CurrentDb.Execute "DROP TABLE [" & sName & "]", dbFailOnError
    End If
End Sub

Public Sub DropQueryIfExists(ByVal sName As String)
    Dim qdf As DAO.QueryDef
    For Each qdf In CurrentDb.QueryDefs
        If StrComp(qdf.Name, sName, vbTextCompare) = 0 Then
            CurrentDb.QueryDefs.Delete sName
            Exit Sub
        End If
    Next qdf
End Sub

Public Sub DeleteObjectIfExists(ByVal lType As AcObjectType, ByVal sName As String)
    On Error Resume Next
    DoCmd.Close lType, sName, acSaveNo
    DoCmd.DeleteObject lType, sName
    On Error GoTo 0
End Sub

' --- Settings ---------------------------------------------------------
Public Function GetSetting_(ByVal sKey As String, Optional ByVal sDefault As String = "") As String
    Dim v As Variant
    v = DLookup("SettingValue", "tblSettings", "SettingKey='" & Replace(sKey, "'", "''") & "'")
    If IsNull(v) Then GetSetting_ = sDefault Else GetSetting_ = CStr(v)
End Function

Public Sub SaveSetting_(ByVal sKey As String, ByVal sValue As String)
    Dim db As DAO.Database
    Set db = CurrentDb
    If DCount("*", "tblSettings", "SettingKey='" & Replace(sKey, "'", "''") & "'") > 0 Then
        db.Execute "UPDATE tblSettings SET SettingValue='" & Replace(sValue, "'", "''") & _
                   "' WHERE SettingKey='" & Replace(sKey, "'", "''") & "'", dbFailOnError
    Else
        db.Execute "INSERT INTO tblSettings (SettingKey, SettingValue) VALUES ('" & _
                   Replace(sKey, "'", "''") & "','" & Replace(sValue, "'", "''") & "')", dbFailOnError
    End If
End Sub

' --- Concatenate technologies for the master/export query -------------
Public Function ConcatTechnologies(ByVal vProjectCode As Variant) As String
    Dim rs As DAO.Recordset
    Dim s As String
    ConcatTechnologies = ""
    If IsNull(vProjectCode) Then Exit Function
    Set rs = CurrentDb.OpenRecordset( _
        "SELECT t.TechName FROM tblTechnologies AS t INNER JOIN tblProjectTechnologies AS pt " & _
        "ON t.TechID = pt.TechID WHERE pt.ProjectCode = '" & Replace(CStr(vProjectCode), "'", "''") & _
        "' ORDER BY t.TechName", dbOpenSnapshot)
    Do While Not rs.EOF
        If Len(s) > 0 Then s = s & "; "
        s = s & rs!TechName
        rs.MoveNext
    Loop
    rs.Close
    ConcatTechnologies = s
End Function

' --- Path helpers ------------------------------------------------------
Public Function EnsureFolder(ByVal sPath As String) As String
    If Len(Dir(sPath, vbDirectory)) = 0 Then MkDir sPath
    EnsureFolder = sPath
End Function

Public Function GetImportPath() As String
    ' Resolution order: saved setting, then db folder, then db\data folder.
    Dim s As String
    s = GetSetting_("ImportFilePath")
    If Len(s) > 0 And Len(Dir(s)) > 0 Then GetImportPath = s: Exit Function
    s = CurrentProject.Path & "\InterconnectionProjects.xlsx"
    If Len(Dir(s)) > 0 Then GetImportPath = s: Exit Function
    s = CurrentProject.Path & "\data\InterconnectionProjects.xlsx"
    If Len(Dir(s)) > 0 Then GetImportPath = s: Exit Function
    GetImportPath = ""
End Function
