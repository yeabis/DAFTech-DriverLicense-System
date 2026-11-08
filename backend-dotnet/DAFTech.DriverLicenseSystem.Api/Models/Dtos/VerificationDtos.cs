namespace DAFTech.DriverLicenseSystem.Api.Models.Dtos
{
    public class VerifyLicenseRequest
    {
        public string LicenseId { get; set; } = string.Empty;
        public string? FullName { get; set; }
        public string? DateOfBirth { get; set; }
        public string? ExpiryDate { get; set; }
    }

    public class VerificationResultDto
    {
        public string LicenseId { get; set; } = string.Empty;
        public string? FullName { get; set; }

        public string Status { get; set; } = string.Empty;

        public string? ExpiryStatus { get; set; }

        public string? ExpiryDate { get; set; }
        public string Message { get; set; } = string.Empty;
        public string CheckedBy { get; set; } = string.Empty;
        public DateTime CheckedDate { get; set; }
    }

    public class VerificationLogDto
    {
        public int LogId { get; set; }
        public string LicenseId { get; set; } = string.Empty;
        public string? FullName { get; set; }

        public string VerificationStatus { get; set; } = string.Empty;

        public string? CheckedBy { get; set; }
        public DateTime CheckedDate { get; set; }
    }
}

