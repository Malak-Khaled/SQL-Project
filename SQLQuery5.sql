
IF DB_ID('HR_System') IS NOT NULL
    DROP DATABASE HR_System
GO

CREATE DATABASE HR_System
GO

USE HR_System
GO



-- Creation of tables


CREATE TABLE Departments (
    DepartmentID   INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName VARCHAR(100) NOT NULL,
    ManagerID      INT NULL,
    CreatedAt      DATETIME DEFAULT GETDATE()
)

CREATE TABLE JobGrades (
    GradeID    INT PRIMARY KEY IDENTITY(1,1),
    GradeName  VARCHAR(50)    NOT NULL,
    MinSalary  DECIMAL(12,2)  NOT NULL DEFAULT (0),
    MaxSalary  DECIMAL(12,2)  NOT NULL DEFAULT (0)
)

CREATE TABLE LeaveTypes (
    LeaveTypeID   INT PRIMARY KEY IDENTITY(1,1),
    LeaveTypeName VARCHAR(50) NOT NULL,
    DefaultDays   INT         NOT NULL DEFAULT (0)
)

CREATE TABLE Allowances (
    AllowanceID   INT PRIMARY KEY IDENTITY(1,1),
    AllowanceName VARCHAR(100) NOT NULL,
    IsFixed       BIT          DEFAULT (1)
)

CREATE TABLE Roles (
    RoleID      INT PRIMARY KEY IDENTITY(1,1),
    RoleName    VARCHAR(50)  NOT NULL UNIQUE,
    Description VARCHAR(255)
)

CREATE TABLE Permissions (
    PermissionID   INT PRIMARY KEY IDENTITY(1,1),
    PermissionName VARCHAR(100) NOT NULL UNIQUE,
    Description    VARCHAR(255)
)

CREATE TABLE TrainingPrograms (
    ProgramID   INT PRIMARY KEY IDENTITY(1,1),
    ProgramName VARCHAR(150)  NOT NULL,
    Description VARCHAR(MAX),
    Provider    VARCHAR(100),
    DurationDays INT,
    StartDate   DATE,
    EndDate     DATE,
    Status      VARCHAR(20)  DEFAULT 'Active',
    CONSTRAINT chk_training_status CHECK (Status IN ('Active','Completed','Cancelled'))
)


--  Creation of core tables


CREATE TABLE Employees (
    EmployeeID     INT PRIMARY KEY IDENTITY(1,1),
    FirstName      VARCHAR(50)    NOT NULL,
    LastName       VARCHAR(50)    NOT NULL,
    NationalID     VARCHAR(20)    UNIQUE NOT NULL,
    Gender         CHAR(1),
    DateOfBirth    DATE,
    HireDate       DATE           NOT NULL,
    Email          VARCHAR(100)   UNIQUE NOT NULL,
    Phone          VARCHAR(20),
    Address        VARCHAR(MAX),
    JobTitle       VARCHAR(100),
    BasicSalary    DECIMAL(12,2)  NOT NULL DEFAULT (0),
    EmploymentType VARCHAR(30)    DEFAULT 'Full-Time',
    Status         VARCHAR(20)    DEFAULT 'Active',
    DepartmentID   INT,
    GradeID        INT,
    CreatedAt      DATETIME       DEFAULT GETDATE(),

    CONSTRAINT chk_gender           CHECK (Gender IN ('M','F')),
    CONSTRAINT chk_employment_type  CHECK (EmploymentType IN ('Full-Time','Part-Time','Contract','Intern')),
    CONSTRAINT chk_employee_status  CHECK (Status IN ('Active','Inactive','Terminated')),

    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
    FOREIGN KEY (GradeID)      REFERENCES JobGrades(GradeID)
)

ALTER TABLE Departments
ADD CONSTRAINT fk_dept_manager FOREIGN KEY (ManagerID) REFERENCES Employees(EmployeeID)


CREATE TABLE UserAccounts (
    UserID       INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID   INT          UNIQUE,
    Username     VARCHAR(50)  UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    RoleID       INT,
    IsActive     BIT          DEFAULT (1),
    LastLogin    DATETIME,
    CreatedAt    DATETIME     DEFAULT GETDATE(),

    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    FOREIGN KEY (RoleID)     REFERENCES Roles(RoleID)
)

CREATE TABLE RolePermissions (
    RoleID       INT NOT NULL,
    PermissionID INT NOT NULL,
    PRIMARY KEY (RoleID, PermissionID),
    FOREIGN KEY (RoleID)       REFERENCES Roles(RoleID),
    FOREIGN KEY (PermissionID) REFERENCES Permissions(PermissionID)
)

CREATE TABLE EmploymentHistory (
    HistoryID    INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID   INT          NOT NULL,
    DepartmentID INT,
    JobTitle     VARCHAR(100),
    StartDate    DATE         NOT NULL,
    EndDate      DATE,
    ChangeReason VARCHAR(255),

    FOREIGN KEY (EmployeeID)   REFERENCES Employees(EmployeeID),
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
)

CREATE TABLE EmployeeAllowances (
    EmpAllowanceID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID     INT           NOT NULL,
    AllowanceID    INT           NOT NULL,
    Amount         DECIMAL(12,2) NOT NULL DEFAULT (0),

    FOREIGN KEY (EmployeeID)  REFERENCES Employees(EmployeeID),
    FOREIGN KEY (AllowanceID) REFERENCES Allowances(AllowanceID),

    CONSTRAINT uq_emp_allowance UNIQUE (EmployeeID, AllowanceID)
)

CREATE TABLE Attendance (
    AttendanceID   INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID     INT          NOT NULL,
    AttendanceDate DATE         NOT NULL,
    CheckIn        TIME,
    CheckOut       TIME,
    Status         VARCHAR(20)  DEFAULT 'Present',
    Notes          VARCHAR(255),

    CONSTRAINT chk_attendance_status CHECK (Status IN ('Present','Absent','Late','Half-Day')),

    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    CONSTRAINT uq_attendance UNIQUE (EmployeeID, AttendanceDate)
)

CREATE TABLE LeaveBalances (
    BalanceID    INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID   INT NOT NULL,
    LeaveTypeID  INT NOT NULL,
    Year         INT NOT NULL,
    TotalDays    INT DEFAULT (0),
    UsedDays     INT DEFAULT (0),

    FOREIGN KEY (EmployeeID)  REFERENCES Employees(EmployeeID),
    FOREIGN KEY (LeaveTypeID) REFERENCES LeaveTypes(LeaveTypeID),

    CONSTRAINT uq_leave_balance UNIQUE (EmployeeID, LeaveTypeID, Year)
)

CREATE TABLE LeaveRequests (
    LeaveRequestID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID     INT          NOT NULL,
    LeaveTypeID    INT          NOT NULL,
    StartDate      DATE         NOT NULL,
    EndDate        DATE         NOT NULL,
    TotalDays      AS (DATEDIFF(DAY, StartDate, EndDate) + 1),
    Status         VARCHAR(20)  DEFAULT 'Pending',
    Reason         VARCHAR(MAX),
    ApprovedByID   INT,
    ApprovedAt     DATETIME,
    CreatedAt      DATETIME     DEFAULT GETDATE(),

    CONSTRAINT chk_leave_status CHECK (Status IN ('Pending','Approved','Rejected')),

    FOREIGN KEY (EmployeeID)   REFERENCES Employees(EmployeeID),
    FOREIGN KEY (LeaveTypeID)  REFERENCES LeaveTypes(LeaveTypeID),
    FOREIGN KEY (ApprovedByID) REFERENCES Employees(EmployeeID)
)

CREATE TABLE Payroll (
    PayrollID      INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID     INT           NOT NULL,
    ProcessedByID  INT,
    PayPeriodMonth TINYINT       NOT NULL,
    PayPeriodYear  INT           NOT NULL,
    BasicSalary    DECIMAL(12,2) NOT NULL DEFAULT (0),
    TotalAllowance DECIMAL(12,2) DEFAULT (0),
    TaxDeduction   DECIMAL(12,2) DEFAULT (0),
    InsuranceDed   DECIMAL(12,2) DEFAULT (0),
    OtherDeduction DECIMAL(12,2) DEFAULT (0),
    NetSalary      AS (BasicSalary + TotalAllowance - TaxDeduction - InsuranceDed - OtherDeduction),
    ProcessedDate  DATE,

    CONSTRAINT chk_month CHECK (PayPeriodMonth BETWEEN 1 AND 12),

    FOREIGN KEY (EmployeeID)    REFERENCES Employees(EmployeeID),
    FOREIGN KEY (ProcessedByID) REFERENCES Employees(EmployeeID),

    CONSTRAINT uq_payroll UNIQUE (EmployeeID, PayPeriodMonth, PayPeriodYear)
)
GO


-- Data Insertion


-- 1. Job Grades
INSERT INTO JobGrades (GradeName, MinSalary, MaxSalary) VALUES
    ('Junior',   3000,  6000),
    ('Mid',      6001, 10000),
    ('Senior',  10001, 18000),
    ('Manager', 18001, 30000)
GO

-- 2. Departments 
INSERT INTO Departments (DepartmentName) VALUES
    ('Human Resources'),
    ('Information Technology'),
    ('Finance'),
    ('Operations')
GO

-- 3. Leave Types
INSERT INTO LeaveTypes (LeaveTypeName, DefaultDays) VALUES
    ('Annual Leave',   21),
    ('Sick Leave',     10),
    ('Emergency Leave', 3)
GO

-- 4. Allowances
INSERT INTO Allowances (AllowanceName, IsFixed) VALUES
    ('Housing Allowance',     1),
    ('Transportation',        1),
    ('Mobile Allowance',      1),
    ('Performance Bonus',     0)
GO

-- 5. Roles
INSERT INTO Roles (RoleName, Description) VALUES
    ('Admin',    'Full system access'),
    ('HR',       'HR module access'),
    ('Employee', 'Self-service access')
GO

-- 6. Permissions
INSERT INTO Permissions (PermissionName, Description) VALUES
    ('VIEW_EMPLOYEES',   'Can view employee records'),
    ('EDIT_EMPLOYEES',   'Can edit employee records'),
    ('MANAGE_PAYROLL',   'Can process payroll'),
    ('APPROVE_LEAVE',    'Can approve leave requests'),
    ('VIEW_REPORTS',     'Can view reports')
GO

-- 7. Role Permissions
INSERT INTO RolePermissions (RoleID, PermissionID) VALUES
    (1, 1),(1, 2),(1, 3),(1, 4),(1, 5),  -- Admin gets all
    (2, 1),(2, 2),(2, 4),(2, 5),          -- HR
    (3, 1)                                -- Employee: view only
GO

-- 8. Employees
--    Malak Khaled   → HR,  Grade Junior
--    Mahmoud Mostafa → IT, Grade Mid
--    Mohamed Ali    → Finance, Grade Senior
--    Aboudida Magdy → Operations, Grade Manager

INSERT INTO Employees
    (FirstName, LastName, NationalID, Gender, DateOfBirth, HireDate,
     Email, Phone, Address, JobTitle, BasicSalary, EmploymentType,
     DepartmentID, GradeID)
VALUES
    ('Malak',    'Khaled',  '29901010100011', 'F', '1999-01-01', '2022-03-15',
     'malak.khaled@company.com',    '01001000001', '10 Nile St, Cairo',
     'HR Specialist',      5000.00, 'Full-Time', 1, 1),

    ('Mahmoud',  'Mostafa', '29801020200022', 'M', '1998-02-02', '2021-06-01',
     'mahmoud.mostafa@company.com', '01001000002', '25 Tahrir Sq, Giza',
     'Software Developer',  8500.00, 'Full-Time', 2, 2),

    ('Mohamed',  'Ali',     '29701030300033', 'M', '1997-03-03', '2020-01-10',
     'mohamed.ali@company.com',     '01001000003', '5 Ahmed Orabi, Alexandria',
     'Senior Accountant',  13000.00, 'Full-Time', 3, 3),

    ('Aboudida', 'Magdy',   '29601040400044', 'M', '1996-04-04', '2018-09-20',
     'aboudida.magdy@company.com',  '01001000004', '18 El Nasr Rd, Cairo',
     'Operations Manager', 22000.00, 'Full-Time', 4, 4)
GO

-- 9. Set Department Managers
--    HR dept  → Malak (EmpID 1)
--    IT dept  → Mahmoud (EmpID 2)
--    Finance  → Mohamed (EmpID 3)
--    Ops      → Aboudida (EmpID 4)
UPDATE Departments SET ManagerID = 1 WHERE DepartmentID = 1
UPDATE Departments SET ManagerID = 2 WHERE DepartmentID = 2
UPDATE Departments SET ManagerID = 3 WHERE DepartmentID = 3
UPDATE Departments SET ManagerID = 4 WHERE DepartmentID = 4
GO

-- 10. Employment History (initial hire records)
INSERT INTO EmploymentHistory (EmployeeID, DepartmentID, JobTitle, StartDate, ChangeReason) VALUES
    (1, 1, 'HR Specialist',      '2022-03-15', 'Initial Hire'),
    (2, 2, 'Software Developer', '2021-06-01', 'Initial Hire'),
    (3, 3, 'Senior Accountant',  '2020-01-10', 'Initial Hire'),
    (4, 4, 'Operations Manager', '2018-09-20', 'Initial Hire')
GO

-- 11. Employee Allowances
INSERT INTO EmployeeAllowances (EmployeeID, AllowanceID, Amount) VALUES
    (1, 1, 1000), (1, 2, 300), (1, 3, 100),   -- Malak
    (2, 1, 1500), (2, 2, 500), (2, 3, 150),   -- Mahmoud
    (3, 1, 2000), (3, 2, 500), (3, 4, 1500),  -- Mohamed
    (4, 1, 3000), (4, 2, 700), (4, 4, 3000)   -- Aboudida
GO

-- 12. User Accounts
INSERT INTO UserAccounts (EmployeeID, Username, PasswordHash, RoleID) VALUES
    (1, 'malak.k',    CONVERT(VARCHAR(255), HASHBYTES('SHA2_256','Pass@1234'), 2), 2),
    (2, 'mahmoud.m',  CONVERT(VARCHAR(255), HASHBYTES('SHA2_256','Pass@1234'), 2), 3),
    (3, 'mohamed.a',  CONVERT(VARCHAR(255), HASHBYTES('SHA2_256','Pass@1234'), 2), 3),
    (4, 'aboudida.m', CONVERT(VARCHAR(255), HASHBYTES('SHA2_256','Pass@1234'), 2), 1)
GO

-- 13. Leave Balances 
INSERT INTO LeaveBalances (EmployeeID, LeaveTypeID, Year, TotalDays, UsedDays) VALUES
    (1, 1, 2025, 21, 3), (1, 2, 2025, 10, 0), (1, 3, 2025, 3, 0),
    (2, 1, 2025, 21, 5), (2, 2, 2025, 10, 2), (2, 3, 2025, 3, 0),
    (3, 1, 2025, 21, 7), (3, 2, 2025, 10, 1), (3, 3, 2025, 3, 1),
    (4, 1, 2025, 21, 2), (4, 2, 2025, 10, 0), (4, 3, 2025, 3, 0)
GO

-- 14. Attendance
INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckIn, CheckOut, Status) VALUES
    (1,'2025-02-24','08:55','17:05','Present'),(1,'2025-02-25','09:10','17:00','Late'),
    (1,'2025-02-26','08:50','17:00','Present'),(1,'2025-02-27','08:45','17:00','Present'),
    (1,'2025-02-28','09:00','17:00','Present'),

    (2,'2025-02-24','09:00','18:00','Present'),(2,'2025-02-25','09:00','18:00','Present'),
    (2,'2025-02-26','09:00','18:00','Present'),(2,'2025-02-27',NULL,NULL,'Absent'),
    (2,'2025-02-28','09:00','18:00','Present'),

    (3,'2025-02-24','08:30','17:00','Present'),(3,'2025-02-25','08:30','17:00','Present'),
    (3,'2025-02-26','08:30','13:00','Half-Day'),(3,'2025-02-27','08:30','17:00','Present'),
    (3,'2025-02-28','08:30','17:00','Present'),

    (4,'2025-02-24','08:00','17:00','Present'),(4,'2025-02-25','08:00','17:00','Present'),
    (4,'2025-02-26','08:00','17:00','Present'),(4,'2025-02-27','08:00','17:00','Present'),
    (4,'2025-02-28','08:00','17:00','Present')
GO

-- 15. Payroll 
INSERT INTO Payroll
    (EmployeeID, ProcessedByID, PayPeriodMonth, PayPeriodYear,
     BasicSalary, TotalAllowance, TaxDeduction, InsuranceDed, OtherDeduction, ProcessedDate)
VALUES
    (1, 4, 2, 2025,  5000.00, 1400.00,  500.00, 250.00,   0.00, '2025-02-28'),
    (2, 4, 2, 2025,  8500.00, 2150.00,  850.00, 425.00,   0.00, '2025-02-28'),
    (3, 4, 2, 2025, 13000.00, 4000.00, 1300.00, 650.00, 200.00, '2025-02-28'),
    (4, 4, 2, 2025, 22000.00, 6700.00, 2200.00, 900.00,   0.00, '2025-02-28')
GO

-- 16. Leave Requests
INSERT INTO LeaveRequests (EmployeeID, LeaveTypeID, StartDate, EndDate, Status, Reason, ApprovedByID, ApprovedAt) VALUES
    (1, 1, '2025-01-05', '2025-01-07', 'Approved', 'Personal vacation', 4, '2025-01-03'),
    (2, 2, '2025-02-10', '2025-02-11', 'Approved', 'Sick',              4, '2025-02-10'),
    (3, 3, '2025-02-20', '2025-02-20', 'Approved', 'Family emergency',  4, '2025-02-20'),
    (4, 1, '2025-03-01', '2025-03-02', 'Pending',  'Annual leave',      NULL, NULL)
GO

-- 17. Training Programs
INSERT INTO TrainingPrograms (ProgramName, Provider, DurationDays, StartDate, EndDate, Status) VALUES
    ('Excel Advanced',           'Coursera',    3, '2025-01-15', '2025-01-17', 'Completed'),
    ('SQL for HR Analytics',     'Udemy',       5, '2025-02-01', '2025-02-05', 'Completed'),
    ('Leadership & Management',  'Local Inst.', 2, '2025-03-10', '2025-03-11', 'Active'),
    ('Cybersecurity Basics',     'Coursera',    4, '2025-04-01', '2025-04-04', 'Active')
GO



-- REPORT VIEWS 


IF OBJECT_ID('dbo.rpt_DepartmentHeadcount','V') IS NOT NULL DROP VIEW dbo.rpt_DepartmentHeadcount;
GO
CREATE VIEW dbo.rpt_DepartmentHeadcount AS
SELECT
    d.DepartmentID,
    d.DepartmentName,
    m.FirstName + ' ' + m.LastName AS ManagerName,
    COUNT(CASE WHEN e.Status = 'Active'     THEN 1 END) AS ActiveCount,
    COUNT(CASE WHEN e.Status = 'Inactive'   THEN 1 END) AS InactiveCount,
    COUNT(CASE WHEN e.Status = 'Terminated' THEN 1 END) AS TerminatedCount,
    COUNT(e.EmployeeID) AS TotalCount,
    AVG(CASE WHEN e.Status = 'Active' THEN e.BasicSalary END) AS AvgSalary
FROM Departments d
LEFT JOIN Employees  e ON e.DepartmentID = d.DepartmentID
LEFT JOIN Employees  m ON d.ManagerID    = m.EmployeeID
GROUP BY d.DepartmentID, d.DepartmentName, m.FirstName, m.LastName;
GO

IF OBJECT_ID('dbo.rpt_EmployeeAllowances','V') IS NOT NULL DROP VIEW dbo.rpt_EmployeeAllowances;
GO
CREATE VIEW dbo.rpt_EmployeeAllowances AS
SELECT
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS FullName,
    d.DepartmentName,
    e.BasicSalary,
    SUM(ea.Amount) AS TotalAllowances,
    e.BasicSalary + SUM(ea.Amount) AS GrossSalary,
    STRING_AGG(a.AllowanceName, ', ') WITHIN GROUP (ORDER BY a.AllowanceName) AS AllowanceTypes
FROM EmployeeAllowances ea
JOIN Employees   e ON ea.EmployeeID  = e.EmployeeID
JOIN Allowances  a ON ea.AllowanceID = a.AllowanceID
JOIN Departments d ON e.DepartmentID = d.DepartmentID
GROUP BY e.EmployeeID, e.FirstName, e.LastName, d.DepartmentName, e.BasicSalary;
GO



-- STORED PROCEDURES


CREATE OR ALTER PROCEDURE sp_AddEmployee
    @FirstName      NVARCHAR(50),
    @LastName       NVARCHAR(50),
    @NationalID     NVARCHAR(20),
    @Gender         CHAR(1),
    @DOB            DATE,
    @HireDate       DATE,
    @Email          NVARCHAR(100),
    @Phone          NVARCHAR(20),
    @Address        NVARCHAR(MAX),
    @JobTitle       NVARCHAR(100),
    @BasicSalary    DECIMAL(12,2),
    @EmploymentType NVARCHAR(30),
    @DeptID         INT,
    @GradeID        INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EmpID INT;
    INSERT INTO Employees
        (FirstName, LastName, NationalID, Gender, DateOfBirth, HireDate,
         Email, Phone, Address, JobTitle, BasicSalary, EmploymentType, DepartmentID, GradeID)
    VALUES
        (@FirstName, @LastName, @NationalID, @Gender, @DOB, @HireDate,
         @Email, @Phone, @Address, @JobTitle, @BasicSalary, @EmploymentType, @DeptID, @GradeID);
    SET @EmpID = SCOPE_IDENTITY();
    INSERT INTO EmploymentHistory (EmployeeID, DepartmentID, JobTitle, StartDate, ChangeReason)
    VALUES (@EmpID, @DeptID, @JobTitle, @HireDate, 'Initial Hire');
    SELECT @EmpID AS NewEmployeeID;
END;
GO

CREATE OR ALTER PROCEDURE sp_UpdateEmployee
    @EmployeeID      INT,
    @Email           NVARCHAR(100),
    @Phone           NVARCHAR(20),
    @Address         NVARCHAR(MAX),
    @JobTitle        NVARCHAR(100),
    @BasicSalary     DECIMAL(12,2),
    @EmploymentType  NVARCHAR(30),
    @Status          NVARCHAR(20),
    @DeptID          INT,
    @GradeID         INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Employees
    SET Email          = @Email,
        Phone          = @Phone,
        Address        = @Address,
        JobTitle       = @JobTitle,
        BasicSalary    = @BasicSalary,
        EmploymentType = @EmploymentType,
        Status         = @Status,
        DepartmentID   = @DeptID,
        GradeID        = @GradeID
    WHERE EmployeeID = @EmployeeID;
END;
GO

CREATE OR ALTER PROCEDURE sp_DeleteEmployee
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Employees SET Status = 'Terminated' WHERE EmployeeID = @EmployeeID;
END;
GO

CREATE OR ALTER PROCEDURE sp_SelectEmployee
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM Employees WHERE EmployeeID = @EmployeeID;
END;
GO

CREATE OR ALTER PROCEDURE sp_LogAttendance
    @EmployeeID INT,
    @Date       DATE,
    @CheckIn    TIME,
    @CheckOut   TIME,
    @Status     NVARCHAR(20),
    @Notes      NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Attendance WHERE EmployeeID = @EmployeeID AND AttendanceDate = @Date)
    BEGIN
        UPDATE Attendance
        SET CheckIn  = @CheckIn, CheckOut = @CheckOut, Status = @Status, Notes = @Notes
        WHERE EmployeeID = @EmployeeID AND AttendanceDate = @Date;
    END
    ELSE
    BEGIN
        INSERT INTO Attendance (EmployeeID, AttendanceDate, CheckIn, CheckOut, Status, Notes)
        VALUES (@EmployeeID, @Date, @CheckIn, @CheckOut, @Status, @Notes);
    END
END;
GO

CREATE OR ALTER PROCEDURE sp_SubmitLeaveRequest
    @EmployeeID  INT,
    @LeaveTypeID INT,
    @StartDate   DATE,
    @EndDate     DATE,
    @Reason      NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Days      INT;
    DECLARE @Remaining INT = 0;
    SET @Days = DATEDIFF(DAY, @StartDate, @EndDate) + 1;
    SELECT @Remaining = TotalDays - UsedDays
    FROM LeaveBalances
    WHERE EmployeeID  = @EmployeeID
      AND LeaveTypeID = @LeaveTypeID
      AND Year        = YEAR(@StartDate);
    IF @Remaining < @Days
    BEGIN
        THROW 50000, 'Insufficient leave balance.', 1;
    END
    ELSE
    BEGIN
        INSERT INTO LeaveRequests (EmployeeID, LeaveTypeID, StartDate, EndDate, Reason)
        VALUES (@EmployeeID, @LeaveTypeID, @StartDate, @EndDate, @Reason);
        SELECT SCOPE_IDENTITY() AS NewLeaveRequestID;
    END
END;
GO




SELECT 'Employees'        AS [Table], COUNT(*) AS [Rows] FROM Employees
UNION ALL
SELECT 'Departments',       COUNT(*) FROM Departments
UNION ALL
SELECT 'Payroll',           COUNT(*) FROM Payroll
UNION ALL
SELECT 'Attendance',        COUNT(*) FROM Attendance
UNION ALL
SELECT 'LeaveRequests',     COUNT(*) FROM LeaveRequests
UNION ALL
SELECT 'EmployeeAllowances',COUNT(*) FROM EmployeeAllowances;
GO

-- View department summary
SELECT * FROM rpt_DepartmentHeadcount;
GO

-- View allowances summary
SELECT * FROM rpt_EmployeeAllowances;
GO