# DAFTech Driver License Verification & Registration System

A full-stack, mobile and backend system designed for traffic officers and enforcement authorities to register and verify driving licenses in real time. The solution combines on-device Optical Character Recognition (OCR) and QR/barcode scanning with a centralized ASP.NET Core Web API and SQL Server database.

## Table of Contents

- [Project Overview](#project-overview)
- [Key Features](#key-features)
- [Technology Stack](#technology-stack)
- [Project Architecture & Structure](#project-architecture--structure)
- [Database Setup](#database-setup)
- [Setup & Installation Instructions](#setup--installation-instructions)
- [How to Run Backend](#how-to-run-backend)
- [How to Run Mobile App](#how-to-run-mobile-app)
- [API Endpoints Reference](#api-endpoints-reference)
- [Troubleshooting & FAQs](#troubleshooting--faqs)

## Project Overview

The DAFTech Driver License System streamlines traffic enforcement and license registry operations:

1. **Front-Side OCR Scanning** — Captures license card details (Full Name, License ID, Date of Birth, Expiry Date, License Type) directly from the physical card using on-device camera text recognition.
2. **QR / Barcode Decoding** — Scans and parses QR/barcode codes on a license to auto-fill the License ID and other fields.
3. **Instant Verification Engine** — Checks a scanned or manually entered license against the central database and reports whether it is **Real & Active**, **Real & Expired**, or **Fake / Not Found**.


## Key Features

- **Officer Authentication** — JWT-based login with BCrypt-hashed passwords.
- **Camera-Based Registration** — Live QR/barcode scanner or a captured front-card photo run through OCR, with all fields editable before saving.
- **Verification Screen** — Live QR scanning or a captured front-card photo for OCR lookup, plus manual License ID / Full Name entry.
- **Status Classification**:
  - **Real & Active** — License exists and has not expired.
  - **Real & Expired** — License exists but the expiry date has passed.
  - **Fake / Not Found** — License ID does not match any registered record.
- **Driver Directory** — Lists all registered drivers.
- **Verification Logs** — Every check is recorded with the checking officer and timestamp, viewable from the app.

## Technology Stack

### Backend 

- **Runtime & Framework**: .NET 8 / ASP.NET Core Web API
- **ORM / Data Access**: Entity Framework Core 8 (`Microsoft.EntityFrameworkCore.SqlServer`)
- **Database**: Microsoft SQL Server (SQL Server Express / LocalDB / full SQL Server)
- **Security**: Custom JWT authentication (`Microsoft.AspNetCore.Authentication.JwtBearer`) with `BCrypt.Net-Next` password hashing
- **API Documentation**: OpenAPI / Swagger (`Swashbuckle.AspNetCore`)

### Mobile App (`mobile-flutter`)

- **Framework & Language**: Flutter (SDK `^3.13.2`) & Dart
- **Machine Learning & Vision**:
  - `google_mlkit_text_recognition` — on-device OCR for the front card
  - `google_mlkit_barcode_scanning` / `mobile_scanner` — QR/barcode scanning
  - `image` — image preprocessing (grayscale, contrast, sharpening) before OCR
- **Hardware Integration**: `image_picker` for camera capture / gallery selection
- **Networking**: `http`, with the backend base URL set in `lib/core/api_constants.dart`
- **Secure Storage**: `flutter_secure_storage` for the JWT token

## Project Architecture & Structure

```
DAFTech-DriverLicense-System/
├── backend-dotnet/
│   └── DAFTech.DriverLicenseSystem.Api/
│       ├── Controllers/        # Auth, Driver, Verification API controllers
│       ├── Data/                # ApplicationDbContext (EF Core)
│       ├── Helpers/             # ClaimsPrincipalExtensions, DateHelper
│       ├── Middleware/          # Global exception handling
│       ├── Models/
│       │   ├── Entities/        # Driver, User, VerificationLog
│       │   └── Dtos/            # Request/response DTOs
│       ├── Services/            # AuthService, DriverService, VerificationService
│       ├── Properties/          # launchSettings.json
│       ├── appsettings.json     # Connection string & JWT configuration
│       └── Program.cs           # Startup, DI, middleware pipeline
│
├── mobile-flutter/
│   ├── lib/
│   │   ├── core/                # app_theme.dart, api_constants.dart
│   │   ├── models/               # Client-side data models
│   │   ├── screens/              # Login, Dashboard, Registration, Verification, Logs
│   │   ├── services/             # ApiService, AuthService, TesseractOcrService (ML Kit OCR)
│   │   ├── utils/                # LicenseParser, ImagePreprocessor, date_format
│   │   ├── widgets/               # CustomScannerWidget and shared UI pieces
│   │   └── main.dart              # Application entry point
│   └── pubspec.yaml              # Flutter package dependencies
│
└── database/
    └── schema.sql                 # Raw SQL schema (reference)
```

## Database Setup

The backend uses Entity Framework Core (Code-First) against SQL Server.

### 1. Connection String Configuration

Set in `backend-dotnet/DAFTech.DriverLicenseSystem.Api/appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost\\SQLEXPRESS;Database=LicenseSystemDB;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

> If you're using LocalDB instead of SQL Server Express, change the server to `(localdb)\\MSSQLLocalDB`.
> If running SQL Server in Docker: `Server=localhost,1433;Database=LicenseSystemDB;User Id=sa;Password=YourStrongPassword!;TrustServerCertificate=True;`

### 2. Applying Migrations

```bash
cd backend-dotnet/DAFTech.DriverLicenseSystem.Api

# One-time: install the EF Core CLI tool if you don't have it
dotnet tool install --global dotnet-ef

# Create and apply the database schema
dotnet ef database update
```

### 3. Database Schema & Entities

- **Users**
  - `UserId` (int, Primary Key)
  - `Username` (string, unique)
  - `PasswordHash` (string, BCrypt)
  - `Status` (string — `Active`/`Inactive`)
  - `CreatedDate` (DateTime, UTC)
- **Drivers**
  - `DriverId` (int, Primary Key)
  - `LicenseId` (string, unique)
  - `FullName` (string)
  - `DateOfBirth` (DateTime)
  - `LicenseType` (string)
  - `ExpiryDate` (DateTime)
  - `QrRawData` / `OcrRawText` (string)
  - `CreatedDate` (DateTime, UTC)
  - `RegisteredBy` (int, Foreign Key → Users)
- **VerificationLogs**
  - `LogId` (int, Primary Key)
  - `LicenseId` (string)
  - `VerificationStatus` (string)
  - `CheckedBy` (int, Foreign Key → Users)
  - `CheckedDate` (DateTime, UTC)

### 4. Creating an Officer Account

The database is not seeded with a default user automatically. Create one via the dev-only registration endpoint before logging in:

```bash
curl -X POST http://localhost:5270/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"TestUser@123"}'
```

## Setup & Installation Instructions

### Prerequisites

- .NET 8 SDK
- Microsoft SQL Server or SQL Server Express/LocalDB
- Flutter SDK (3.13.2 or later)
- Android Studio / Xcode, or a physical device with developer mode enabled

### Clone Repository

```bash
git clone https://github.com/<your-username>/DAFTech-DriverLicense-System.git
cd DAFTech-DriverLicense-System
```

## How to Run Backend

```bash
cd backend-dotnet/DAFTech.DriverLicenseSystem.Api

# Restore NuGet packages
dotnet restore

# Apply database migrations
dotnet ef database update

# Run the API
dotnet run
```

By default the `http` launch profile binds to `http://0.0.0.0:5270`, so it's reachable from both your machine and from an emulator/physical device on the same network. Swagger is available at:

```
http://localhost:5270/swagger
```

## How to Run Mobile App

```bash
cd mobile-flutter

# Fetch dependencies
flutter pub get

# Run the app
flutter run
```

The backend base URL is set in `lib/core/api_constants.dart`:

- **Android Emulator** → `http://10.0.2.2:5270/api` (default, already configured)
- **iOS Simulator** → `http://localhost:5270/api`
- **Physical Device** → `http://<YOUR_COMPUTER_LAN_IP>:5270/api` (phone and PC must be on the same Wi-Fi network)

After registering an officer account (see [Database Setup](#4-creating-an-officer-account)), sign in with those credentials.

## API Endpoints Reference

All endpoints except login/register require the HTTP header `Authorization: Bearer <JWT_TOKEN>`.

| Method | Endpoint              | Description                                      | Auth Required |
|--------|------------------------|---------------------------------------------------|---------------|
| POST   | `/api/auth/login`      | Officer login. Returns JWT token.                  | No            |
| POST   | `/api/auth/register`   | Dev-only: creates an officer account.              | No            |
| POST   | `/api/drivers/register`| Registers a new driver license record.             | Yes           |
| GET    | `/api/drivers`         | Retrieves all registered drivers.                  | Yes           |
| POST   | `/api/verification/verify` | Verifies a license ID; creates a verification log. | Yes       |
| GET    | `/api/verification/logs`   | Retrieves verification log history.            | Yes           |

## Troubleshooting & FAQs

**1. Mobile app fails with "Cannot reach backend server" / connection refused**

- Android emulator: the base URL must use `10.0.2.2`, not `localhost` (already set in `api_constants.dart` by default).
- Physical device: phone and PC must be on the same Wi-Fi network, and your firewall must allow inbound connections on port `5270`.
- Confirm the backend's `http` profile in `Properties/launchSettings.json` is bound to `0.0.0.0`, not `localhost` — otherwise it only accepts connections from the host machine itself.

**2. Database connection error when running the backend**

- Verify SQL Server/SQL Server Express is running and the server name in `appsettings.json` matches your instance.
- Make sure `dotnet ef database update` has been run before starting the API.

**3. "Registration failed. Check connection or duplicate ID"**

- This message covers two different cases: the backend being unreachable (see #1), or the License ID already being registered. Check the backend logs/Swagger response for the specific cause.

**4. Camera / scanning permissions on mobile**

- Accept camera and storage permissions when prompted.
- For OCR/QR testing on an Android emulator, set the AVD's camera to use your webcam or a virtual scene in Android Studio's AVD Manager.