Attribute VB_Name = "modForms"
Option Compare Database
Option Explicit

' =====================================================================
'  modForms - builds the front end:
'    frmDashboard       modern flat navigation form
'    frmProjectDetails  data entry form (free-form text, drop-downs,
'                       multi-select technology list) with code-behind
' =====================================================================

Private Const TW As Long = 1440   ' twips per inch

' ---------------------------------------------------------------------
'  Dashboard
' ---------------------------------------------------------------------
Public Sub BuildDashboard()
    Dim frm As Form, sTemp As String
    Dim ctl As Control

    DeleteObjectIfExists acForm, "frmDashboard"
    Set frm = CreateForm
    sTemp = frm.Name

    With frm
        .Caption = "Solar & Storage Interconnection Tracker"
        .RecordSelectors = False
        .NavigationButtons = False
        .DividingLines = False
        .ScrollBars = 0
        .AutoCenter = True
        .BorderStyle = 1          ' thin
        .PopUp = False
        .Width = 9700
        .HasModule = False
    End With
    EnsureFormHeaderFooter frm

    ' Header band
    frm.Section(acHeader).Visible = True
    frm.Section(acHeader).Height = 1500
    frm.Section(acHeader).BackColor = clrSlate()

    Set ctl = CreateControl(sTemp, acLabel, acHeader, , , 400, 280, 8900, 420)
    StyleLabel ctl, "Solar & Storage Interconnection Tracker", 15, True, RGB(255, 255, 255)

    Set ctl = CreateControl(sTemp, acLabel, acHeader, , , 400, 800, 8900, 320)
    StyleLabel ctl, "Generator + load interconnection pipeline  |  imports, data entry, reports, Power BI export", 9, False, RGB(176, 190, 197)

    ' Detail: six flat action buttons in two columns
    frm.Section(acDetail).Height = 3900
    frm.Section(acDetail).BackColor = clrBackground()

    MakeDashButton sTemp, "cmdEnter", "Enter / Edit Project Details", "=OpenProjectForm()", 500, 450, clrAccent()
    MakeDashButton sTemp, "cmdImport", "Refresh Import from Spreadsheet", "=RefreshFromSpreadsheet()", 5000, 450, clrAccent()
    MakeDashButton sTemp, "cmdRpt1", "Portfolio Report (by ISO/RTO)", "=PreviewPortfolioReport()", 500, 1500, clrSlate()
    MakeDashButton sTemp, "cmdRpt2", "Pipeline Summary Report", "=PreviewPipelineReport()", 5000, 1500, clrSlate()
    MakeDashButton sTemp, "cmdCsv", "Export CSV  (Power BI ready)", "=ExportMasterCSV()", 500, 2550, RGB(21, 101, 192)
    MakeDashButton sTemp, "cmdXlsx", "Export Excel (XLSX)", "=ExportMasterXLSX()", 5000, 2550, RGB(21, 101, 192)

    ' Footer: live record counts
    frm.Section(acFooter).Visible = True
    frm.Section(acFooter).Height = 600
    frm.Section(acFooter).BackColor = clrBackground()
    Set ctl = CreateControl(sTemp, acTextBox, acFooter, , , 500, 150, 8700, 320)
    With ctl
        .Name = "txtCounts"
        .ControlSource = "=""Projects: "" & DCount(""*"",""tblProjects"") & ""   |   Generation: "" & " & _
            "DCount(""*"",""tblProjects"",""ProjectType<>'Load Only'"") & ""   |   Load-only: "" & " & _
            "DCount(""*"",""tblProjects"",""ProjectType='Load Only'"") & ""   |   Detail records: "" & " & _
            "DCount(""*"",""tblProjectDetails"")"
        .Locked = True
        .TabStop = False
        .BackStyle = 0
        .BorderStyle = 0
        .FontName = "Segoe UI"
        .FontSize = 9
        .ForeColor = clrTextMuted()
    End With

    DoCmd.Close acForm, sTemp, acSaveYes
    DoCmd.Rename "frmDashboard", acForm, sTemp
End Sub

Private Sub MakeDashButton(ByVal sForm As String, ByVal sName As String, ByVal sCaption As String, _
                           ByVal sOnClick As String, ByVal lLeft As Long, ByVal lTop As Long, ByVal lColor As Long)
    Dim btn As Control
    Set btn = CreateControl(sForm, acCommandButton, acDetail, , , lLeft, lTop, 4200, 800)
    With btn
        .Name = sName
        .Caption = sCaption
        .OnClick = sOnClick
        .FontName = "Segoe UI Semibold"
        .FontSize = 10
    End With
    StyleButtonFlat btn, lColor
End Sub

' ---------------------------------------------------------------------
'  Project details data-entry form
' ---------------------------------------------------------------------
Public Sub BuildProjectForm()
    Dim frm As Form, sTemp As String
    Dim ctl As Control

    DeleteObjectIfExists acForm, "frmProjectDetails"
    Set frm = CreateForm
    sTemp = frm.Name

    With frm
        .Caption = "Project Details - Data Entry"
        .RecordSource = "SELECT * FROM tblProjectDetails ORDER BY ProjectCode"
        .RecordSelectors = False
        .NavigationButtons = False
        .DividingLines = False
        .ScrollBars = 0
        .AutoCenter = True
        .BorderStyle = 2          ' sizable
        .Width = 11800
        .HasModule = True
    End With
    EnsureFormHeaderFooter frm

    ' Header band
    frm.Section(acHeader).Visible = True
    frm.Section(acHeader).Height = 1200
    frm.Section(acHeader).BackColor = clrPrimary()
    Set ctl = CreateControl(sTemp, acLabel, acHeader, , , 350, 220, 10800, 400)
    StyleLabel ctl, "Project Details", 14, True, RGB(255, 255, 255)
    Set ctl = CreateControl(sTemp, acLabel, acHeader, , , 350, 680, 10800, 300)
    StyleLabel ctl, "Free-form fields, drop-down selections, and multi-select technologies. Changes save automatically.", 9, False, RGB(200, 230, 201)

    frm.Section(acDetail).Height = 5750
    frm.Section(acDetail).BackColor = clrBackground()

    ' ---- Column 1 -----------------------------------------------------
    Dim x1 As Long: x1 = 350
    Dim w1 As Long: w1 = 3300

    Set ctl = MakeStacked(sTemp, acComboBox, "cboProjectCode", "Project (from imported spreadsheet)", "ProjectCode", x1, 250, w1)
    With ctl
        .RowSourceType = "Table/Query"
        .RowSource = "SELECT ProjectCode, ProjectName, Developer, ProjectType, QueueStatus " & _
                     "FROM tblProjects ORDER BY ProjectCode"
        .ColumnCount = 5
        .ColumnWidths = "1000;3600;0;0;0"
        .BoundColumn = 1
        .LimitToList = True
        .ListWidth = 4600
    End With

    Set ctl = MakeStacked(sTemp, acTextBox, "txtProjectManager", "Project Manager (free-form)", "ProjectManager", x1, 1100, w1)

    Set ctl = MakeStacked(sTemp, acComboBox, "cboStudyPhase", "Interconnection Study Phase", "StudyPhase", x1, 1950, w1)
    SetLookupRowSource ctl, "SELECT Phase FROM tluStudyPhase ORDER BY SortOrder"

    Set ctl = MakeStacked(sTemp, acComboBox, "cboLandControl", "Land / Site Control", "LandControl", x1, 2800, w1)
    SetLookupRowSource ctl, "SELECT LandControl FROM tluLandControl ORDER BY SortOrder"

    Set ctl = MakeStacked(sTemp, acComboBox, "cboPermitStatus", "Permitting Status", "PermittingStatus", x1, 3650, w1)
    SetLookupRowSource ctl, "SELECT PermitStatus FROM tluPermitStatus ORDER BY SortOrder"

    ' Read-only context line fed by the combo's hidden columns
    Set ctl = CreateControl(sTemp, acTextBox, acDetail, , , x1, 4600, 7000, 320)
    With ctl
        .Name = "txtProjectInfo"
        .ControlSource = "=[cboProjectCode].[Column](1) & ""  -  "" & [cboProjectCode].[Column](2) & " & _
                         """  ("" & [cboProjectCode].[Column](3) & "", "" & [cboProjectCode].[Column](4) & "")"""
        .Locked = True
        .TabStop = False
        .BackStyle = 0
        .BorderStyle = 0
        .FontName = "Segoe UI"
        .FontItalic = True
        .FontSize = 9
        .ForeColor = clrTextMuted()
    End With

    ' Community benefit checkbox
    Set ctl = CreateControl(sTemp, acCheckBox, acDetail, , "CommunityBenefit", x1, 5150, 260, 260)
    ctl.Name = "chkCommunityBenefit"
    Set ctl = CreateControl(sTemp, acLabel, acDetail, , , x1 + 350, 5120, 4200, 300)
    StyleLabel ctl, "Community benefit / host agreement in place", 9, False, clrTextDark()

    ' ---- Column 2 -----------------------------------------------------
    Dim x2 As Long: x2 = 4000
    Dim w2 As Long: w2 = 3300

    Set ctl = MakeStacked(sTemp, acComboBox, "cboVoltage", "Interconnection Voltage (kV)", "InterconnectionVoltagekV", x2, 250, w2)
    With ctl
        .RowSourceType = "Value List"
        .RowSource = "69;115;138;161;230;345;500"
        .LimitToList = False
    End With

    Set ctl = MakeStacked(sTemp, acComboBox, "cboRiskLevel", "Overall Risk Level", "RiskLevel", x2, 1100, w2)
    SetLookupRowSource ctl, "SELECT RiskLevel FROM tluRiskLevel ORDER BY SortOrder"

    Set ctl = MakeStacked(sTemp, acTextBox, "txtCapex", "Estimated Capex (USD millions)", "EstCapexUSDM", x2, 1950, w2)
    ctl.Format = "#,##0"

    Set ctl = MakeStacked(sTemp, acTextBox, "txtNextMilestone", "Next Milestone (free-form)", "NextMilestone", x2, 2800, w2)

    Set ctl = MakeStacked(sTemp, acTextBox, "txtMilestoneDate", "Next Milestone Date", "NextMilestoneDate", x2, 3650, w2)
    ctl.Format = "yyyy-mm-dd"
    On Error Resume Next
    ctl.ShowDatePicker = 1
    On Error GoTo 0

    ' ---- Column 3: multi-select technologies + notes ------------------
    Dim x3 As Long: x3 = 7650
    Dim w3 As Long: w3 = 3750

    Set ctl = CreateControl(sTemp, acLabel, acDetail, , , x3, 250, w3, 260)
    StyleLabel ctl, "Technologies (select all that apply)", 9, True, clrTextMuted()
    Set ctl = CreateControl(sTemp, acListBox, acDetail, , , x3, 540, w3, 2450)
    With ctl
        .Name = "lstTechnologies"
        .RowSourceType = "Table/Query"
        .RowSource = "SELECT TechID, TechName FROM tblTechnologies ORDER BY TechName"
        .ColumnCount = 2
        .ColumnWidths = "0;3600"
        .BoundColumn = 1
        .MultiSelect = 1          ' simple multi-select
        .FontName = "Segoe UI"
        .FontSize = 9
        .BackColor = clrCard()
        .BorderColor = RGB(200, 208, 216)
    End With

    Set ctl = CreateControl(sTemp, acLabel, acDetail, , , x3, 3120, w3, 260)
    StyleLabel ctl, "Notes (free-form)", 9, True, clrTextMuted()
    Set ctl = CreateControl(sTemp, acTextBox, acDetail, , "Notes", x3, 3410, w3, 1900)
    With ctl
        .Name = "txtNotes"
        .EnterKeyBehavior = True
        .ScrollBars = 2
    End With
    StyleInput frm.Controls("txtNotes")

    ' ---- Footer: navigation / actions ---------------------------------
    frm.Section(acFooter).Visible = True
    frm.Section(acFooter).Height = 950
    frm.Section(acFooter).BackColor = clrCard()

    MakeFooterButton sTemp, "cmdNew", "+ New Record", 350, clrAccent()
    MakeFooterButton sTemp, "cmdSave", "Save", 2100, clrAccent()
    MakeFooterButton sTemp, "cmdPrev", "< Prev", 3850, clrSlate()
    MakeFooterButton sTemp, "cmdNext", "Next >", 5250, clrSlate()
    MakeFooterButton sTemp, "cmdReport", "Portfolio Report", 6650, clrSlate()
    MakeFooterButton sTemp, "cmdClose", "Close", 9800, RGB(120, 60, 60)

    AddProjectFormCode frm

    DoCmd.Close acForm, sTemp, acSaveYes
    DoCmd.Rename "frmProjectDetails", acForm, sTemp
End Sub

Private Sub MakeFooterButton(ByVal sForm As String, ByVal sName As String, ByVal sCaption As String, _
                             ByVal lLeft As Long, ByVal lColor As Long)
    Dim btn As Control
    Dim lWidth As Long
    lWidth = IIf(sName = "cmdReport", 2900, 1550)
    Set btn = CreateControl(sForm, acCommandButton, acFooter, , , lLeft, 200, lWidth, 520)
    With btn
        .Name = sName
        .Caption = sCaption
        .FontName = "Segoe UI Semibold"
        .FontSize = 9
        .OnClick = "[Event Procedure]"
    End With
    StyleButtonFlat btn, lColor
End Sub

' ---------------------------------------------------------------------
'  Code-behind for frmProjectDetails (multi-select sync + navigation)
' ---------------------------------------------------------------------
Private Sub AddProjectFormCode(ByVal frm As Form)
    ' NOTE: the new form module already contains its own Option statements;
    ' adding them again here would cause a compile error.
    Dim s As String
    s = s & "Private Sub Form_Current()" & vbCrLf
    s = s & "    SyncTechList" & vbCrLf
    s = s & "End Sub" & vbCrLf & vbCrLf

    s = s & "Private Sub cboProjectCode_AfterUpdate()" & vbCrLf
    s = s & "    ' Persist the row so technology selections can attach to it" & vbCrLf
    s = s & "    On Error Resume Next" & vbCrLf
    s = s & "    If Me.Dirty Then Me.Dirty = False" & vbCrLf
    s = s & "End Sub" & vbCrLf & vbCrLf

    s = s & "Private Sub lstTechnologies_AfterUpdate()" & vbCrLf
    s = s & "    SaveTechSelections" & vbCrLf
    s = s & "End Sub" & vbCrLf & vbCrLf

    s = s & "Private Sub SyncTechList()" & vbCrLf
    s = s & "    Dim i As Long" & vbCrLf
    s = s & "    For i = 0 To Me.lstTechnologies.ListCount - 1" & vbCrLf
    s = s & "        If IsNull(Me.ProjectCode) Or Me.NewRecord Then" & vbCrLf
    s = s & "            Me.lstTechnologies.Selected(i) = False" & vbCrLf
    s = s & "        Else" & vbCrLf
    s = s & "            Me.lstTechnologies.Selected(i) = (DCount(""*"", ""tblProjectTechnologies"", _" & vbCrLf
    s = s & "                ""ProjectCode='"" & Me.ProjectCode & ""' AND TechID="" & Me.lstTechnologies.ItemData(i)) > 0)" & vbCrLf
    s = s & "        End If" & vbCrLf
    s = s & "    Next i" & vbCrLf
    s = s & "End Sub" & vbCrLf & vbCrLf

    s = s & "Private Sub SaveTechSelections()" & vbCrLf
    s = s & "    Dim v As Variant" & vbCrLf
    s = s & "    If IsNull(Me.ProjectCode) Then" & vbCrLf
    s = s & "        MsgBox ""Pick a project first, then select its technologies."", vbInformation" & vbCrLf
    s = s & "        Exit Sub" & vbCrLf
    s = s & "    End If" & vbCrLf
    s = s & "    If Me.Dirty Then Me.Dirty = False" & vbCrLf
    s = s & "    CurrentDb.Execute ""DELETE FROM tblProjectTechnologies WHERE ProjectCode='"" & Me.ProjectCode & ""'"", dbFailOnError" & vbCrLf
    s = s & "    For Each v In Me.lstTechnologies.ItemsSelected" & vbCrLf
    s = s & "        CurrentDb.Execute ""INSERT INTO tblProjectTechnologies (ProjectCode, TechID) VALUES ('"" & _" & vbCrLf
    s = s & "            Me.ProjectCode & ""', "" & Me.lstTechnologies.ItemData(v), dbFailOnError" & vbCrLf
    s = s & "    Next v" & vbCrLf
    s = s & "End Sub" & vbCrLf & vbCrLf

    s = s & "Private Sub Form_Error(DataErr As Integer, Response As Integer)" & vbCrLf
    s = s & "    If DataErr = 3022 Then" & vbCrLf
    s = s & "        MsgBox ""A detail record already exists for this project. Use Prev/Next to find and edit it."", vbExclamation" & vbCrLf
    s = s & "        Response = acDataErrContinue" & vbCrLf
    s = s & "    End If" & vbCrLf
    s = s & "End Sub" & vbCrLf & vbCrLf

    s = s & "Private Sub cmdNew_Click()" & vbCrLf
    s = s & "    DoCmd.GoToRecord , , acNewRec" & vbCrLf
    s = s & "    Me.cboProjectCode.SetFocus" & vbCrLf
    s = s & "End Sub" & vbCrLf & vbCrLf

    s = s & "Private Sub cmdSave_Click()" & vbCrLf
    s = s & "    If Me.Dirty Then Me.Dirty = False" & vbCrLf
    s = s & "End Sub" & vbCrLf & vbCrLf

    s = s & "Private Sub cmdPrev_Click()" & vbCrLf
    s = s & "    On Error Resume Next" & vbCrLf
    s = s & "    DoCmd.GoToRecord , , acPrevious" & vbCrLf
    s = s & "End Sub" & vbCrLf & vbCrLf

    s = s & "Private Sub cmdNext_Click()" & vbCrLf
    s = s & "    On Error Resume Next" & vbCrLf
    s = s & "    DoCmd.GoToRecord , , acNext" & vbCrLf
    s = s & "End Sub" & vbCrLf & vbCrLf

    s = s & "Private Sub cmdReport_Click()" & vbCrLf
    s = s & "    PreviewPortfolioReport" & vbCrLf
    s = s & "End Sub" & vbCrLf & vbCrLf

    s = s & "Private Sub cmdClose_Click()" & vbCrLf
    s = s & "    DoCmd.Close acForm, Me.Name, acSaveNo" & vbCrLf
    s = s & "End Sub" & vbCrLf

    frm.Module.AddFromString s
End Sub

' ---------------------------------------------------------------------
'  Shared styling helpers
' ---------------------------------------------------------------------
Private Sub EnsureFormHeaderFooter(ByVal frm As Form)
    ' Forms created with CreateForm start with a Detail section only;
    ' toggle the Form Header/Footer pair on if it is missing.
    Dim lProbe As Long
    On Error Resume Next
    lProbe = frm.Section(acHeader).Height
    If Err.Number <> 0 Then
        Err.Clear
        DoCmd.SelectObject acForm, frm.Name, False
        DoCmd.RunCommand acCmdFormHdrFtr
    End If
    On Error GoTo 0
End Sub

Private Function MakeStacked(ByVal sForm As String, ByVal lType As AcControlType, ByVal sName As String, _
                             ByVal sLabel As String, ByVal sField As String, _
                             ByVal x As Long, ByVal y As Long, ByVal w As Long) As Control
    ' Modern stacked layout: small muted caption above the input control
    Dim lbl As Control, ctl As Control
    Set lbl = CreateControl(sForm, acLabel, acDetail, , , x, y, w, 260)
    StyleLabel lbl, sLabel, 9, True, clrTextMuted()
    Set ctl = CreateControl(sForm, lType, acDetail, , sField, x, y + 290, w, 340)
    ctl.Name = sName
    StyleInput ctl
    Set MakeStacked = ctl
End Function

Private Sub SetLookupRowSource(ByVal ctl As Control, ByVal sSQL As String)
    With ctl
        .RowSourceType = "Table/Query"
        .RowSource = sSQL
        .ColumnCount = 1
        .BoundColumn = 1
        .LimitToList = True
    End With
End Sub

Private Sub StyleLabel(ByVal ctl As Control, ByVal sCaption As String, ByVal lSize As Long, _
                       ByVal bBold As Boolean, ByVal lColor As Long)
    With ctl
        .Caption = sCaption
        .FontName = IIf(bBold, "Segoe UI Semibold", "Segoe UI")
        .FontSize = lSize
        .FontBold = bBold
        .ForeColor = lColor
        .BackStyle = 0
        .BorderStyle = 0
    End With
End Sub

Private Sub StyleInput(ByVal ctl As Control)
    On Error Resume Next
    With ctl
        .FontName = "Segoe UI"
        .FontSize = 10
        .ForeColor = clrTextDark()
        .BackColor = clrCard()
        .BorderStyle = 1
        .BorderColor = RGB(200, 208, 216)
    End With
    On Error GoTo 0
End Sub

Public Sub StyleButtonFlat(ByVal btn As Control, ByVal lColor As Long)
    On Error Resume Next   ' some paint properties vary by Access version
    With btn
        .BackColor = lColor
        .ForeColor = RGB(255, 255, 255)
        .HoverColor = lColor + RGB(20, 20, 20)
        .HoverForeColor = RGB(255, 255, 255)
        .PressedColor = lColor
        .PressedForeColor = RGB(255, 255, 255)
        .BorderStyle = 0
        .BorderColor = lColor
        .Gradient = 12         ' flat, no gradient
        .Bevel = 0
        .Glow = 0
        .Shadow = 0
        .UseTheme = False
    End With
    On Error GoTo 0
End Sub

' ---------------------------------------------------------------------
'  Dashboard button targets
' ---------------------------------------------------------------------
Public Function OpenProjectForm()
    DoCmd.OpenForm "frmProjectDetails"
End Function
