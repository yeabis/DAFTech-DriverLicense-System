using DAFTech.DriverLicenseSystem.Api.Helpers;
using DAFTech.DriverLicenseSystem.Api.Models.Entities;

namespace DAFTech.DriverLicenseSystem.Api.Models.Dtos
{
    public class RegisterDriverRequest
    {
        public string LicenseId { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string DateOfBirth { get; set; } = string.Empty;
        public string ExpiryDate { get; set; } = string.Empty;
        public string? LicenseType { get; set; }
        public string? QrRawData { get; set; }
        public string? OcrRawText { get; set; }
    }

    public class DriverResponse
    {
        public int DriverId { get; set; }
        public string LicenseId { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string DateOfBirth { get; set; } = string.Empty;
        public string ExpiryDate { get; set; } = string.Empty;
        public string LicenseType { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; }
        public int RegisteredBy { get; set; }

        public string Status { get; set; } = string.Empty;

        public static DriverResponse From(Driver driver)
        {
            return new DriverResponse
            {
                DriverId = driver.DriverId,
                LicenseId = driver.LicenseId,
                FullName = driver.FullName,
                DateOfBirth = DateHelper.ToIso(driver.DateOfBirth),
                ExpiryDate = DateHelper.ToIso(driver.ExpiryDate),
                LicenseType = driver.LicenseType,
                CreatedDate = DateTime.SpecifyKind(driver.CreatedDate, DateTimeKind.Utc),
                RegisteredBy = driver.RegisteredBy,
                Status = driver.ExpiryDate.Date < DateTime.UtcNow.Date ? "Expired" : "Active"
            };
        }
    }

    public class RegisterDriverResponse
    {
        public string Message { get; set; } = string.Empty;
        public DriverResponse? Driver { get; set; }
    }
}

