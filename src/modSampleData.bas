Attribute VB_Name = "modSampleData"
Option Compare Database
Option Explicit

' =====================================================================
'  modSampleData - illustrative form-side detail records so the forms,
'  reports and exports have content on first build. PM names, capex,
'  milestones and risk ratings are fictional placeholders; the projects
'  themselves are real (see README for sources).
' =====================================================================

Public Sub LoadSampleDetails()
    Dim db As DAO.Database
    Set db = CurrentDb

    db.Execute "DELETE FROM tblProjectTechnologies", dbFailOnError
    db.Execute "DELETE FROM tblProjectDetails", dbFailOnError

    AddDetail "DCE-001", "A. Rivera", "IA Executed", "Option Agreement", "Approved", 500, "Medium", 2100, _
        "Mobilize EPC contractor", #9/15/2026#, True, _
        "First project approved under the CEC opt-in certification path. 4,600 MWh BESS is among the largest permitted in CAISO."
    AddDetail "TEH-001", "J. Whitfield", "Construction", "Leased", "Approved", 345, "Medium", 1150, _
        "Energize collector substation", #12/1/2026#, False, _
        "Largest single solar addition expected on ERCOT in 2026 per EIA 860M. Developer attribution pending; verify against latest EIA/ERCOT queue extract."
    AddDetail "EDS-001", "M. Chen", "Commercial Operation", "Owned", "Approved", 230, "Low", 1900, _
        "Annual performance review", #1/15/2027#, True, _
        "Operational since Jan 2024; 875 MW solar with 3,287 MWh of storage across Edwards AFB and Sanborn sites in Kern County."
    AddDetail "GEM-001", "S. Okafor", "Commercial Operation", "Leased", "Approved", 230, "Low", 1200, _
        "Capacity test - summer peak", #6/30/2027#, True, _
        "690 MWac solar + 380 MW / 1,416 MWh DC-coupled storage on BLM land serving NV Energy."
    AddDetail "ELD-001", "K. Patel", "Construction", "Leased", "Approved", 230, "Low", 1100, _
        "Phase 2 substantial completion", #10/31/2026#, True, _
        "Phase 1 operational 2025; Phase 2 in construction. 25-year PPAs with LADWP and City of Glendale."
    AddDetail "BLF-002", "D. Moreau", "Construction", "Option Agreement", "Approved with Conditions", 230, "Medium", 900, _
        "Module delivery milestone", #11/15/2026#, False, _
        "Second 500 MW + 500 MW phase of the Bellefield complex; offtake contracted to Amazon."
    AddDetail "SES-001", "L. Gutierrez", "Commercial Operation", "Owned", "Approved", 230, "Low", 450, _
        "Augmentation study", #3/31/2027#, False, _
        "250 MW / 1,000 MWh standalone LFP system delivering capacity to Salt River Project."
    AddDetail "NPB-001", "R. Novak", "Commercial Operation", "Owned", "Approved", 500, "Low", 700, _
        "Phase 2 augmentation decision", #2/28/2027#, False, _
        "680 MW / 2,720 MWh standalone storage in Menifee, CA - one of the largest battery plants in CAISO."
    AddDetail "MAM-001", "T. Kowalski", "Construction", "Leased", "Approved", 345, "Medium", 1500, _
        "Mammoth South mechanical completion", #8/31/2026#, True, _
        "1.3 GW multi-phase agrivoltaics campus across Pulaski and Starke counties, Indiana (MISO)."
    AddDetail "OAK-001", "P. Sandoval", "Facilities Study", "Option Agreement", "Approved with Conditions", 345, "High", 1400, _
        "Finalize GIA amendments", #12/15/2026#, True, _
        "800 MW solar + 300 MW storage with large-scale agrivoltaics commitments (sheep grazing / crops) in Madison County, Ohio."

    ' Load-only interconnection applications
    AddDetail "LLD-001", "N. Ferraro", "Commercial Operation", "Owned", "Approved", 345, "Medium", 0, _
        "Phase 2 energization", #12/31/2026#, False, _
        "Load-only: ~1.2 GW AI data center campus in Abilene, TX (Stargate). Phase 1 energized; behind-the-meter generation planned."
    AddDetail "LLD-002", "H. Broussard", "Construction", "Owned", "Under Review", 500, "High", 0, _
        "Substation civil works complete", #6/30/2027#, True, _
        "Load-only: multi-GW Meta AI data center in Richland Parish, LA; Entergy building dedicated generation and transmission."
    AddDetail "LLD-003", "E. Vance", "Commercial Operation", "Owned", "Approved with Conditions", 161, "Medium", 0, _
        "Expansion interconnection study", #9/30/2026#, False, _
        "Load-only: xAI Colossus supercomputer in Memphis, TN served by MLGW/TVA; ~300 MW with further expansion requested."
    AddDetail "LLD-004", "C. Ibarra", "System Impact Study", "Option Agreement", "Pre-Application", 345, "High", 0, _
        "Complete ERCOT large load study", #3/31/2027#, False, _
        "Load-only: planned ~1.4 GW hyperscale campus in Shackelford County, TX in the ERCOT large load interconnection queue."

    ' Technology selections (multi-select examples)
    AddTech "DCE-001", Array("Single-Axis Tracker", "Bifacial Modules", "LFP Battery Storage", "DC-Coupled Storage", "Domestic Content Equipment")
    AddTech "TEH-001", Array("Single-Axis Tracker", "LFP Battery Storage", "AC-Coupled Storage")
    AddTech "EDS-001", Array("Single-Axis Tracker", "Bifacial Modules", "LFP Battery Storage", "AC-Coupled Storage")
    AddTech "GEM-001", Array("Single-Axis Tracker", "LFP Battery Storage", "DC-Coupled Storage", "Robotic Cleaning")
    AddTech "ELD-001", Array("Single-Axis Tracker", "Bifacial Modules", "LFP Battery Storage", "DC-Coupled Storage")
    AddTech "BLF-002", Array("Single-Axis Tracker", "Thin-Film (CdTe) Modules", "LFP Battery Storage", "Grid-Forming Inverters")
    AddTech "SES-001", Array("LFP Battery Storage", "Grid-Forming Inverters")
    AddTech "NPB-001", Array("LFP Battery Storage", "AC-Coupled Storage")
    AddTech "MAM-001", Array("Single-Axis Tracker", "Bifacial Modules", "Agrivoltaics / Dual Use", "Domestic Content Equipment")
    AddTech "OAK-001", Array("Single-Axis Tracker", "Bifacial Modules", "Agrivoltaics / Dual Use", "LFP Battery Storage")
    AddTech "LLD-001", Array("On-Site Generation (BYOG)", "Controllable Load Resource")
    AddTech "LLD-002", Array("On-Site Generation (BYOG)")
    AddTech "LLD-003", Array("On-Site Generation (BYOG)", "Demand Response Enrolled")
    AddTech "LLD-004", Array("Controllable Load Resource", "Demand Response Enrolled")
End Sub

Private Sub AddDetail(ByVal sCode As String, ByVal sPM As String, ByVal sPhase As String, _
                      ByVal sLand As String, ByVal sPermit As String, ByVal dVoltage As Double, _
                      ByVal sRisk As String, ByVal cCapex As Currency, ByVal sMilestone As String, _
                      ByVal dMilestoneDate As Date, ByVal bCBA As Boolean, ByVal sNotes As String)
    Dim rs As DAO.Recordset
    ' Skip silently if the project code is not in tblProjects (e.g. removed from the spreadsheet)
    If DCount("*", "tblProjects", "ProjectCode='" & sCode & "'") = 0 Then Exit Sub
    Set rs = CurrentDb.OpenRecordset("tblProjectDetails", dbOpenDynaset)
    rs.AddNew
    rs!ProjectCode = sCode
    rs!ProjectManager = sPM
    rs!StudyPhase = sPhase
    rs!LandControl = sLand
    rs!PermittingStatus = sPermit
    rs!InterconnectionVoltagekV = dVoltage
    rs!RiskLevel = sRisk
    rs!EstCapexUSDM = cCapex
    rs!NextMilestone = sMilestone
    rs!NextMilestoneDate = dMilestoneDate
    rs!CommunityBenefit = bCBA
    rs!Notes = sNotes
    rs.Update
    rs.Close
End Sub

Private Sub AddTech(ByVal sCode As String, ByVal vTechNames As Variant)
    Dim i As Long, vID As Variant
    If DCount("*", "tblProjects", "ProjectCode='" & sCode & "'") = 0 Then Exit Sub
    For i = LBound(vTechNames) To UBound(vTechNames)
        vID = DLookup("TechID", "tblTechnologies", "TechName='" & Replace(vTechNames(i), "'", "''") & "'")
        If Not IsNull(vID) Then
            CurrentDb.Execute "INSERT INTO tblProjectTechnologies (ProjectCode, TechID) VALUES ('" & _
                sCode & "', " & vID & ")", dbFailOnError
        End If
    Next i
End Sub
