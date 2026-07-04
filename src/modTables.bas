Attribute VB_Name = "modTables"
Option Compare Database
Option Explicit

' =====================================================================
'  modTables - schema: tables, lookup seed values, and queries
' =====================================================================

Public Sub BuildTables()
    Dim db As DAO.Database
    Set db = CurrentDb

    ' Drop in dependency order so the build is fully re-runnable
    DropQueryIfExists "qryProjectMaster"
    DropQueryIfExists "qryPipelineSummary"
    DropTableIfExists "tblProjectTechnologies"
    DropTableIfExists "tblProjectDetails"
    DropTableIfExists "tblStagingProjects"
    DropTableIfExists "tblProjects"
    DropTableIfExists "tblTechnologies"
    DropTableIfExists "tluStudyPhase"
    DropTableIfExists "tluLandControl"
    DropTableIfExists "tluPermitStatus"
    DropTableIfExists "tluRiskLevel"
    If Not TableExists("tblSettings") Then
        db.Execute "CREATE TABLE tblSettings (SettingKey TEXT(50) PRIMARY KEY, SettingValue TEXT(255))", dbFailOnError
    End If

    ' ---- Imported from the periodically-updated spreadsheet (15 fields)
    db.Execute _
        "CREATE TABLE tblProjects (" & _
        " ProjectCode TEXT(20) PRIMARY KEY," & _
        " ProjectName TEXT(120)," & _
        " Developer TEXT(80)," & _
        " ProjectType TEXT(30)," & _
        " ISO_RTO TEXT(20)," & _
        " State TEXT(2)," & _
        " County TEXT(40)," & _
        " SolarCapacityMWac DOUBLE," & _
        " StorageCapacityMW DOUBLE," & _
        " StorageEnergyMWh DOUBLE," & _
        " LoadMW DOUBLE," & _
        " QueueNumber TEXT(25)," & _
        " QueueStatus TEXT(60)," & _
        " CommercialOperationDate DATETIME," & _
        " Offtaker TEXT(80)," & _
        " LastImportedOn DATETIME)", dbFailOnError

    ' ---- Entered through the form (12 fields + key)
    db.Execute _
        "CREATE TABLE tblProjectDetails (" & _
        " DetailID COUNTER PRIMARY KEY," & _
        " ProjectCode TEXT(20)," & _
        " ProjectManager TEXT(100)," & _
        " StudyPhase TEXT(50)," & _
        " LandControl TEXT(50)," & _
        " PermittingStatus TEXT(50)," & _
        " InterconnectionVoltagekV DOUBLE," & _
        " RiskLevel TEXT(20)," & _
        " EstCapexUSDM CURRENCY," & _
        " NextMilestone TEXT(255)," & _
        " NextMilestoneDate DATETIME," & _
        " CommunityBenefit YESNO," & _
        " Notes LONGTEXT," & _
        " CONSTRAINT uqProjectCode UNIQUE (ProjectCode)," & _
        " CONSTRAINT fkDetailsProject FOREIGN KEY (ProjectCode) REFERENCES tblProjects (ProjectCode))", dbFailOnError

    ' ---- Technologies (multi-select) ---------------------------------
    db.Execute "CREATE TABLE tblTechnologies (TechID COUNTER PRIMARY KEY, TechName TEXT(60))", dbFailOnError
    db.Execute _
        "CREATE TABLE tblProjectTechnologies (" & _
        " ProjectCode TEXT(20), TechID LONG," & _
        " CONSTRAINT pkProjTech PRIMARY KEY (ProjectCode, TechID)," & _
        " CONSTRAINT fkPT_Project FOREIGN KEY (ProjectCode) REFERENCES tblProjects (ProjectCode)," & _
        " CONSTRAINT fkPT_Tech FOREIGN KEY (TechID) REFERENCES tblTechnologies (TechID))", dbFailOnError

    ' ---- Dropdown lookups ---------------------------------------------
    db.Execute "CREATE TABLE tluStudyPhase (Phase TEXT(50) PRIMARY KEY, SortOrder LONG)", dbFailOnError
    db.Execute "CREATE TABLE tluLandControl (LandControl TEXT(50) PRIMARY KEY, SortOrder LONG)", dbFailOnError
    db.Execute "CREATE TABLE tluPermitStatus (PermitStatus TEXT(50) PRIMARY KEY, SortOrder LONG)", dbFailOnError
    db.Execute "CREATE TABLE tluRiskLevel (RiskLevel TEXT(20) PRIMARY KEY, SortOrder LONG)", dbFailOnError

    SeedLookups
    BuildQueries
End Sub

Private Sub SeedLookups()
    Dim db As DAO.Database
    Set db = CurrentDb

    SeedList "tluStudyPhase", "Phase", Array( _
        "Feasibility / Screening", "System Impact Study", "Facilities Study", _
        "IA Negotiation", "IA Executed", "Construction", "Commissioning", "Commercial Operation")
    SeedList "tluLandControl", "LandControl", Array( _
        "Owned", "Leased", "Option Agreement", "In Negotiation", "N/A (Load Site Owned)")
    SeedList "tluPermitStatus", "PermitStatus", Array( _
        "Not Started", "Pre-Application", "Application Filed", "Under Review", "Approved", "Approved with Conditions")
    SeedList "tluRiskLevel", "RiskLevel", Array("Low", "Medium", "High")

    Dim vTech As Variant, i As Long
    vTech = Array( _
        "Single-Axis Tracker", "Bifacial Modules", "Thin-Film (CdTe) Modules", _
        "LFP Battery Storage", "DC-Coupled Storage", "AC-Coupled Storage", _
        "Grid-Forming Inverters", "Agrivoltaics / Dual Use", "Robotic Cleaning", _
        "On-Site Generation (BYOG)", "Controllable Load Resource", "Demand Response Enrolled", _
        "Long-Duration Storage (8h+)", "Domestic Content Equipment")
    For i = LBound(vTech) To UBound(vTech)
        db.Execute "INSERT INTO tblTechnologies (TechName) VALUES ('" & Replace(vTech(i), "'", "''") & "')", dbFailOnError
    Next i
End Sub

Private Sub SeedList(ByVal sTable As String, ByVal sField As String, ByVal vItems As Variant)
    Dim i As Long
    For i = LBound(vItems) To UBound(vItems)
        CurrentDb.Execute "INSERT INTO " & sTable & " (" & sField & ", SortOrder) VALUES ('" & _
            Replace(vItems(i), "'", "''") & "', " & (i + 1) & ")", dbFailOnError
    Next i
End Sub

Public Sub BuildQueries()
    Dim db As DAO.Database
    Set db = CurrentDb

    DropQueryIfExists "qryProjectMaster"
    db.CreateQueryDef "qryProjectMaster", _
        "SELECT p.ProjectCode, p.ProjectName, p.Developer, p.ProjectType, p.ISO_RTO, p.State, p.County, " & _
        " p.SolarCapacityMWac, p.StorageCapacityMW, p.StorageEnergyMWh, p.LoadMW, " & _
        " p.QueueNumber, p.QueueStatus, p.CommercialOperationDate, p.Offtaker, " & _
        " d.ProjectManager, d.StudyPhase, d.LandControl, d.PermittingStatus, " & _
        " d.InterconnectionVoltagekV, d.RiskLevel, d.EstCapexUSDM, " & _
        " d.NextMilestone, d.NextMilestoneDate, d.CommunityBenefit, d.Notes, " & _
        " ConcatTechnologies(p.ProjectCode) AS Technologies " & _
        "FROM tblProjects AS p LEFT JOIN tblProjectDetails AS d ON p.ProjectCode = d.ProjectCode " & _
        "ORDER BY p.ISO_RTO, p.ProjectName"

    DropQueryIfExists "qryPipelineSummary"
    db.CreateQueryDef "qryPipelineSummary", _
        "SELECT p.QueueStatus, Count(*) AS Projects, " & _
        " Sum(Nz(p.SolarCapacityMWac,0)) AS SolarMW, " & _
        " Sum(Nz(p.StorageCapacityMW,0)) AS StorageMW, " & _
        " Sum(Nz(p.StorageEnergyMWh,0)) AS StorageMWh, " & _
        " Sum(Nz(p.LoadMW,0)) AS LoadMW " & _
        "FROM tblProjects AS p GROUP BY p.QueueStatus ORDER BY p.QueueStatus"
End Sub
