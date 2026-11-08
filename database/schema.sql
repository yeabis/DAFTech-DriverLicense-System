CREATE DATABASE LicenseSystemDB;
GO

USE LicenseSystemDB;
GO


CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Active'
);


CREATE TABLE Drivers (
    DriverId INT IDENTITY(1,1) PRIMARY KEY,
    LicenseId NVARCHAR(50) NOT NULL UNIQUE,
    FullName NVARCHAR(100) NOT NULL,
    DateOfBirth DATE NOT NULL,
    LicenseType NVARCHAR(20) NOT NULL,
    ExpiryDate DATE NOT NULL,
    QrRawData NVARCHAR(MAX) NOT NULL,
    OcrRawText NVARCHAR(MAX) NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    RegisteredBy INT FOREIGN KEY REFERENCES Users(UserId)
);


CREATE TABLE VerificationLogs (
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    LicenseId NVARCHAR(50) NOT NULL,
    VerificationStatus NVARCHAR(50) NOT NULL,
    CheckedBy INT FOREIGN KEY REFERENCES Users(UserId),
    CheckedDate DATETIME DEFAULT GETDATE()
);

IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'officer1')
BEGIN
    INSERT INTO Users (Username, PasswordHash, Status)
    VALUES ('officer1', '$2a$11$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', 'Active');
END;
GO
