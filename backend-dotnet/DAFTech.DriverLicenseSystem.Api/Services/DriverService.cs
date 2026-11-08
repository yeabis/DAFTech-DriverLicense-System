using DAFTech.DriverLicenseSystem.Api.Data;
using DAFTech.DriverLicenseSystem.Api.Helpers;
using DAFTech.DriverLicenseSystem.Api.Models.Dtos;
using DAFTech.DriverLicenseSystem.Api.Models.Entities;
using Microsoft.EntityFrameworkCore;

namespace DAFTech.DriverLicenseSystem.Api.Services
{
    public enum RegisterOutcome
    {
        Created,
        Duplicate,
        Invalid
    }

    public class RegisterDriverResult
    {
        public RegisterOutcome Outcome { get; init; }
        public Driver? Driver { get; init; }
        public List<string> Errors { get; init; } = new();
    }

    public class DriverService
    {
        private const int MaxLicenseIdLength = 50;
        private const int MaxNameLength = 100;
        private const int MaxLicenseTypeLength = 20;

        private readonly ApplicationDbContext _context;

        public DriverService(ApplicationDbContext context)
        {
            _context = context;
        }

        public static string NormalizeId(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return string.Empty;
            return new string(raw.Where(char.IsLetterOrDigit).ToArray()).ToUpperInvariant();
        }

        public async Task<Driver?> FindByLicenseIdAsync(string? licenseId)
        {
            var normalized = NormalizeId(licenseId);
            if (normalized.Length == 0) return null;

            return await _context.Drivers
                .AsNoTracking()
                .FirstOrDefaultAsync(d =>
                    d.LicenseId.Replace("-", "").Replace(" ", "").Replace("/", "") == normalized);
        }

        public async Task<List<DriverResponse>> GetAllAsync()
        {
            var drivers = await _context.Drivers
                .AsNoTracking()
                .OrderByDescending(d => d.CreatedDate)
                .ToListAsync();

            return drivers.Select(DriverResponse.From).ToList();
        }

        public async Task<RegisterDriverResult> RegisterAsync(RegisterDriverRequest request, int userId)
        {
            var errors = new List<string>();

            var licenseId = (request.LicenseId ?? string.Empty).Trim().ToUpperInvariant();
            var fullName = (request.FullName ?? string.Empty).Trim();

            if (NormalizeId(licenseId).Length < 4)
                errors.Add("A valid license ID number is required.");
            if (licenseId.Length > MaxLicenseIdLength)
                errors.Add($"License ID must be at most {MaxLicenseIdLength} characters.");
            if (fullName.Length == 0)
                errors.Add("Full name is required.");
            if (fullName.Length > MaxNameLength)
                errors.Add($"Full name must be at most {MaxNameLength} characters.");
            if (!DateHelper.TryParse(request.DateOfBirth, out var dateOfBirth))
                errors.Add("Date of birth is missing or is not a valid date.");
            if (!DateHelper.TryParse(request.ExpiryDate, out var expiryDate))
                errors.Add("Expiry date is missing or is not a valid date.");

            if (errors.Count > 0)
            {
                return new RegisterDriverResult { Outcome = RegisterOutcome.Invalid, Errors = errors };
            }

            var existing = await FindByLicenseIdAsync(licenseId);
            if (existing != null)
            {
                return new RegisterDriverResult { Outcome = RegisterOutcome.Duplicate, Driver = existing };
            }

            var licenseType = string.IsNullOrWhiteSpace(request.LicenseType)
                ? "Public 1"
                : request.LicenseType.Trim();
            if (licenseType.Length > MaxLicenseTypeLength)
                licenseType = licenseType.Substring(0, MaxLicenseTypeLength);

            var driver = new Driver
            {
                LicenseId = licenseId,
                FullName = fullName,
                DateOfBirth = dateOfBirth,
                ExpiryDate = expiryDate,
                LicenseType = licenseType,
                QrRawData = request.QrRawData ?? string.Empty,
                OcrRawText = request.OcrRawText ?? string.Empty,
                CreatedDate = DateTime.UtcNow,
                RegisteredBy = userId
            };

            _context.Drivers.Add(driver);

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                _context.Entry(driver).State = EntityState.Detached;

                var raced = await FindByLicenseIdAsync(licenseId);
                if (raced != null)
                {
                    return new RegisterDriverResult { Outcome = RegisterOutcome.Duplicate, Driver = raced };
                }

                throw;
            }

            return new RegisterDriverResult { Outcome = RegisterOutcome.Created, Driver = driver };
        }
    }
}

