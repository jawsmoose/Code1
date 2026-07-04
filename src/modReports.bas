Attribute VB_Name = "modReports"
Option Compare Database
Option Explicit

' =====================================================================
'  modReports - builds two polished reports:
'    rptPortfolio        landscape, grouped by ISO/RTO, subtotals and
'                        portfolio totals of the most critical fields
'    rptPipelineSummary  one-page pipeline rollup by queue status
' =====================================================================

Public Sub BuildReports()
    BuildPortfolioReport
    BuildPipelineReport
End Sub

' ---------------------------------------------------------------------
Private Sub BuildPortfolioReport()
    Dim rpt As Report, sTemp As String
    Dim ctl As Control

    DeleteObjectIfExists acReport, "rptPortfolio"
    Set rpt = CreateReport
    sTemp = rpt.Name

    rpt.RecordSource = "qryProjectMaster"
    rpt.Caption = "Interconnection Portfolio by ISO/RTO"
    rpt.Width = 14000
    EnsureReportHeaderFooter rpt

    On Error Resume Next
    rpt.Printer.Orientation = acPRORLandscape
    rpt.Printer.LeftMargin = 360
    rpt.Printer.RightMargin = 360
    rpt.Printer.TopMargin = 432
    rpt.Printer.BottomMargin = 432
    On Error GoTo 0

    ' Group on ISO_RTO with header + footer bands
    Dim lGrp As Variant
    lGrp = CreateGroupLevel(sTemp, "ISO_RTO", True, True)
    rpt.GroupLevel(0).SortOrder = False

    ' ---- Report header: title band ------------------------------------
    rpt.Section(acHeader).Height = 1050
    rpt.Section(acHeader).BackColor = clrSlate()
    Set ctl = CreateReportControl(sTemp, acLabel, acHeader, , , 120, 160, 10000, 400)
    RptLabel ctl, "Solar, Storage & Large-Load Interconnection Portfolio", 15, True, RGB(255, 255, 255)
    Set ctl = CreateReportControl(sTemp, acLabel, acHeader, , , 120, 620, 8000, 280)
    RptLabel ctl, "Grouped by ISO / RTO  -  key capacity, status and schedule data", 9, False, RGB(176, 190, 197)
    Set ctl = CreateReportControl(sTemp, acTextBox, acHeader, , , 11400, 620, 2400, 280)
    With ctl
        .ControlSource = "=""Printed "" & Format(Date(),""yyyy-mm-dd"")"
        .FontName = "Segoe UI"
        .FontSize = 8
        .ForeColor = RGB(176, 190, 197)
        .BackStyle = 0
        .BorderStyle = 0
        .TextAlign = 3
    End With

    ' ---- Page header: column captions ---------------------------------
    rpt.Section(acPageHeader).Height = 400
    rpt.Section(acPageHeader).BackColor = RGB(255, 255, 255)
    ColCaption sTemp, "Project", 60, 2800, False
    ColCaption sTemp, "Developer", 2920, 1900, False
    ColCaption sTemp, "Type", 4880, 1300, False
    ColCaption sTemp, "St", 6240, 450, False
    ColCaption sTemp, "Solar MW", 6750, 850, True
    ColCaption sTemp, "BESS MW", 7660, 850, True
    ColCaption sTemp, "BESS MWh", 8570, 900, True
    ColCaption sTemp, "Load MW", 9530, 850, True
    ColCaption sTemp, "Queue Status", 10440, 2300, False
    ColCaption sTemp, "COD", 12800, 1100, True
    Set ctl = CreateReportControl(sTemp, acLine, acPageHeader, , , 60, 380, 13880, 0)
    ctl.BorderColor = clrPrimary()
    ctl.BorderWidth = 2

    ' ---- Group header: ISO/RTO band ------------------------------------
    rpt.Section(acGroupLevel1Header).Height = 400
    rpt.Section(acGroupLevel1Header).BackColor = clrPrimary()
    Set ctl = CreateReportControl(sTemp, acTextBox, acGroupLevel1Header, , "ISO_RTO", 60, 50, 4000, 300)
    With ctl
        .FontName = "Segoe UI Semibold"
        .FontSize = 10
        .FontBold = True
        .ForeColor = RGB(255, 255, 255)
        .BackStyle = 0
        .BorderStyle = 0
    End With

    ' ---- Detail --------------------------------------------------------
    rpt.Section(acDetail).Height = 330
    rpt.Section(acDetail).BackColor = RGB(255, 255, 255)
    On Error Resume Next
    rpt.Section(acDetail).AlternateBackColor = clrAltRow()
    On Error GoTo 0
    DetailText sTemp, "ProjectName", 60, 2800, False, ""
    DetailText sTemp, "Developer", 2920, 1900, False, ""
    DetailText sTemp, "ProjectType", 4880, 1300, False, ""
    DetailText sTemp, "State", 6240, 450, False, ""
    DetailText sTemp, "SolarCapacityMWac", 6750, 850, True, "#,##0"
    DetailText sTemp, "StorageCapacityMW", 7660, 850, True, "#,##0"
    DetailText sTemp, "StorageEnergyMWh", 8570, 900, True, "#,##0"
    DetailText sTemp, "LoadMW", 9530, 850, True, "#,##0"
    DetailText sTemp, "QueueStatus", 10440, 2300, False, ""
    DetailText sTemp, "CommercialOperationDate", 12800, 1100, True, "yyyy-mm-dd"

    ' ---- Group footer: subtotals ----------------------------------------
    rpt.Section(acGroupLevel1Footer).Height = 420
    rpt.Section(acGroupLevel1Footer).BackColor = RGB(232, 238, 242)
    Set ctl = CreateReportControl(sTemp, acTextBox, acGroupLevel1Footer, , , 60, 60, 4000, 300)
    With ctl
        .ControlSource = "=[ISO_RTO] & "" subtotal  ("" & Count(*) & "" projects)"""
        .FontName = "Segoe UI Semibold"
        .FontSize = 9
        .FontBold = True
        .ForeColor = clrTextDark()
        .BackStyle = 0
        .BorderStyle = 0
    End With
    SumText sTemp, acGroupLevel1Footer, "SolarCapacityMWac", 6750, 850
    SumText sTemp, acGroupLevel1Footer, "StorageCapacityMW", 7660, 850
    SumText sTemp, acGroupLevel1Footer, "StorageEnergyMWh", 8570, 900
    SumText sTemp, acGroupLevel1Footer, "LoadMW", 9530, 850

    ' ---- Report footer: portfolio totals ---------------------------------
    rpt.Section(acFooter).Height = 500
    rpt.Section(acFooter).BackColor = clrSlate()
    Set ctl = CreateReportControl(sTemp, acLabel, acFooter, , , 60, 100, 4000, 300)
    RptLabel ctl, "PORTFOLIO TOTAL", 10, True, RGB(255, 255, 255)
    SumText sTemp, acFooter, "SolarCapacityMWac", 6750, 850, RGB(255, 255, 255)
    SumText sTemp, acFooter, "StorageCapacityMW", 7660, 850, RGB(255, 255, 255)
    SumText sTemp, acFooter, "StorageEnergyMWh", 8570, 900, RGB(255, 255, 255)
    SumText sTemp, acFooter, "LoadMW", 9530, 850, RGB(255, 255, 255)

    ' ---- Page footer: page numbers ---------------------------------------
    rpt.Section(acPageFooter).Height = 300
    Set ctl = CreateReportControl(sTemp, acTextBox, acPageFooter, , , 11400, 30, 2400, 260)
    With ctl
        .ControlSource = "=""Page "" & [Page] & "" of "" & [Pages]"
        .FontName = "Segoe UI"
        .FontSize = 8
        .ForeColor = clrTextMuted()
        .BackStyle = 0
        .BorderStyle = 0
        .TextAlign = 3
    End With

    DoCmd.Close acReport, sTemp, acSaveYes
    DoCmd.Rename "rptPortfolio", acReport, sTemp
End Sub

' ---------------------------------------------------------------------
Private Sub BuildPipelineReport()
    Dim rpt As Report, sTemp As String
    Dim ctl As Control

    DeleteObjectIfExists acReport, "rptPipelineSummary"
    Set rpt = CreateReport
    sTemp = rpt.Name

    rpt.RecordSource = "qryPipelineSummary"
    rpt.Caption = "Pipeline Summary by Queue Status"
    rpt.Width = 9600
    EnsureReportHeaderFooter rpt

    ' Report header
    rpt.Section(acHeader).Height = 950
    rpt.Section(acHeader).BackColor = clrPrimary()
    Set ctl = CreateReportControl(sTemp, acLabel, acHeader, , , 120, 150, 9000, 400)
    RptLabel ctl, "Pipeline Summary by Queue Status", 14, True, RGB(255, 255, 255)
    Set ctl = CreateReportControl(sTemp, acLabel, acHeader, , , 120, 590, 9000, 260)
    RptLabel ctl, "Project counts and aggregate capacity across the tracked portfolio", 9, False, RGB(200, 230, 201)

    ' Page header captions
    rpt.Section(acPageHeader).Height = 400
    ColCaption sTemp, "Queue Status", 60, 3500, False
    ColCaption sTemp, "Projects", 3660, 900, True
    ColCaption sTemp, "Solar MW", 4660, 1150, True
    ColCaption sTemp, "BESS MW", 5910, 1150, True
    ColCaption sTemp, "BESS MWh", 7160, 1150, True
    ColCaption sTemp, "Load MW", 8410, 1100, True
    Set ctl = CreateReportControl(sTemp, acLine, acPageHeader, , , 60, 380, 9450, 0)
    ctl.BorderColor = clrPrimary()
    ctl.BorderWidth = 2

    ' Detail
    rpt.Section(acDetail).Height = 340
    On Error Resume Next
    rpt.Section(acDetail).AlternateBackColor = clrAltRow()
    On Error GoTo 0
    DetailText sTemp, "QueueStatus", 60, 3500, False, ""
    DetailText sTemp, "Projects", 3660, 900, True, "#,##0"
    DetailText sTemp, "SolarMW", 4660, 1150, True, "#,##0"
    DetailText sTemp, "StorageMW", 5910, 1150, True, "#,##0"
    DetailText sTemp, "StorageMWh", 7160, 1150, True, "#,##0"
    DetailText sTemp, "LoadMW", 8410, 1100, True, "#,##0"

    ' Report footer totals
    rpt.Section(acFooter).Height = 480
    rpt.Section(acFooter).BackColor = clrSlate()
    Set ctl = CreateReportControl(sTemp, acLabel, acFooter, , , 60, 100, 3400, 300)
    RptLabel ctl, "TOTAL", 10, True, RGB(255, 255, 255)
    SumText sTemp, acFooter, "Projects", 3660, 900, RGB(255, 255, 255)
    SumText sTemp, acFooter, "SolarMW", 4660, 1150, RGB(255, 255, 255)
    SumText sTemp, acFooter, "StorageMW", 5910, 1150, RGB(255, 255, 255)
    SumText sTemp, acFooter, "StorageMWh", 7160, 1150, RGB(255, 255, 255)
    SumText sTemp, acFooter, "LoadMW", 8410, 1100, RGB(255, 255, 255)

    DoCmd.Close acReport, sTemp, acSaveYes
    DoCmd.Rename "rptPipelineSummary", acReport, sTemp
End Sub

' ---------------------------------------------------------------------
'  Shared report control helpers
' ---------------------------------------------------------------------
Private Sub EnsureReportHeaderFooter(ByVal rpt As Report)
    ' Reports created with CreateReport may lack the Report Header/Footer
    ' and Page Header/Footer section pairs; toggle on whichever is missing.
    Dim lProbe As Long
    On Error Resume Next
    lProbe = rpt.Section(acHeader).Height
    If Err.Number <> 0 Then
        Err.Clear
        DoCmd.SelectObject acReport, rpt.Name, False
        DoCmd.RunCommand acCmdReportHdrFtr
    End If
    Err.Clear
    lProbe = rpt.Section(acPageHeader).Height
    If Err.Number <> 0 Then
        Err.Clear
        DoCmd.SelectObject acReport, rpt.Name, False
        DoCmd.RunCommand acCmdPageHdrFtr
    End If
    On Error GoTo 0
End Sub

Private Sub RptLabel(ByVal ctl As Control, ByVal sCaption As String, ByVal lSize As Long, _
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

Private Sub ColCaption(ByVal sRpt As String, ByVal sCaption As String, ByVal x As Long, _
                       ByVal w As Long, ByVal bRight As Boolean)
    Dim ctl As Control
    Set ctl = CreateReportControl(sRpt, acLabel, acPageHeader, , , x, 60, w, 280)
    With ctl
        .Caption = sCaption
        .FontName = "Segoe UI Semibold"
        .FontSize = 8
        .FontBold = True
        .ForeColor = clrPrimary()
        .BackStyle = 0
        .BorderStyle = 0
        If bRight Then .TextAlign = 3
    End With
End Sub

Private Sub DetailText(ByVal sRpt As String, ByVal sField As String, ByVal x As Long, _
                       ByVal w As Long, ByVal bRight As Boolean, ByVal sFormat As String)
    Dim ctl As Control
    Set ctl = CreateReportControl(sRpt, acTextBox, acDetail, , sField, x, 20, w, 290)
    With ctl
        .FontName = "Segoe UI"
        .FontSize = 8
        .ForeColor = clrTextDark()
        .BackStyle = 0
        .BorderStyle = 0
        .CanGrow = True
        If bRight Then .TextAlign = 3
        If Len(sFormat) > 0 Then .Format = sFormat
    End With
End Sub

Private Sub SumText(ByVal sRpt As String, ByVal lSection As Long, ByVal sField As String, _
                    ByVal x As Long, ByVal w As Long, Optional ByVal lColor As Long = -1)
    Dim ctl As Control
    Set ctl = CreateReportControl(sRpt, acTextBox, lSection, , , x, 60, w, 300)
    With ctl
        .ControlSource = "=Sum(Nz([" & sField & "],0))"
        .Format = "#,##0"
        .FontName = "Segoe UI Semibold"
        .FontSize = 9
        .FontBold = True
        .ForeColor = IIf(lColor = -1, clrTextDark(), lColor)
        .BackStyle = 0
        .BorderStyle = 0
        .TextAlign = 3
    End With
End Sub

' ---------------------------------------------------------------------
'  Preview entry points (wired to dashboard buttons)
' ---------------------------------------------------------------------
Public Function PreviewPortfolioReport()
    On Error Resume Next
    DoCmd.OpenReport "rptPortfolio", acViewPreview
End Function

Public Function PreviewPipelineReport()
    On Error Resume Next
    DoCmd.OpenReport "rptPipelineSummary", acViewPreview
End Function
