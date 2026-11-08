using DAFTech.DriverLicenseSystem.Api.Data;
using DAFTech.DriverLicenseSystem.Api.Helpers;
using DAFTech.DriverLicenseSystem.Api.Models.Dtos;
using DAFTech.DriverLicenseSystem.Api.Models.Entities;
using Microsoft.EntityFrameworkCore;

namespace DAFTech.DriverLicenseSystem.Api.Services
{
    public class VerificationService
    {
        public const string StatusActive = "Active";
        public const string StatusExpired = "Expired";
        public const string StatusFake = "Fake";

        private const int MaxLogLicenseIdLength = 50;

        private readonly ApplicationDbContext _context;
        private readonly DriverService _drivers;

        public VerificationService(ApplicationDbContext context, DriverService drivers)
        {
            _context = context;
            _drivers = drivers;
        }

        public async Task<VerificationResultDto> VerifyAsync(
            VerifyLicenseRequest request, int userId, string username)
        {
            var scannedId = (request.LicenseId ?? string.Empty).Trim();
            var driver = await _drivers.FindByLicenseIdAsync(scannedId);

            string logStatus;
            string message;
            string? expiryStatus = null;

            if (driver == null)
            {
                logStatus = StatusFake;
                message = "This license is not registered in the system.";
            }
            else
            {
                var mismatches = FindMismatches(driver, request);

                if (mismatches.Count > 0)
                {
                    logStatus = StatusFake;
                    message = "Scanned details do not match the registered record ("
                              + string.Join(", ", mismatches) + ").";
                }
                else if (driver.ExpiryDate.Date < DateTime.UtcNow.Date)
                {
                    logStatus = StatusExpired;
                    expiryStatus = StatusExpired;
                    message = "Genuine license, but it has expired.";
                }
                else
                {
                    logStatus = StatusActive;
                    expiryStatus = StatusActive;
                    message = "Genuine license and it is active.";
                }
            }

            var checkedDate = DateTime.UtcNow;

            _context.VerificationLogs.Add(new VerificationLog
            {
                LicenseId = Truncate(driver?.LicenseId ?? scannedId.ToUpperInvariant(), MaxLogLicenseIdLength),
                VerificationStatus = logStatus,
                CheckedBy = userId,
                CheckedDate = checkedDate
            });
            await _context.SaveChangesAsync();

            return new VerificationResultDto
            {
                LicenseId = driver?.LicenseId ?? scannedId,
                FullName = driver?.FullName,
                Status = logStatus == StatusFake ? "Fake" : "Real",
                ExpiryStatus = expiryStatus,
                ExpiryDate = driver != null ? DateHelper.ToIso(driver.ExpiryDate) : null,
                Message = message,
                CheckedBy = username,
                CheckedDate = checkedDate
            };
        }

        public async Task<List<VerificationLogDto>> GetLogsAsync(int take)
        {
            take = Math.Clamp(take, 1, 500);

            var logs = await _context.VerificationLogs
                .AsNoTracking()
                .OrderByDescending(l => l.CheckedDate)
                .ThenByDescending(l => l.LogId)
                .Take(take)
                .Select(l => new
                {
                    l.LogId,
                    l.LicenseId,
                    l.VerificationStatus,
                    l.CheckedDate,
                    CheckedBy = l.User != null ? l.User.Username : null
                })
                .ToListAsync();

            var licenseIds = logs.Select(l => l.LicenseId).Distinct().ToList();

            var names = await _context.Drivers
                .AsNoTracking()
                .Where(d => licenseIds.Contains(d.LicenseId))
                .Select(d => new { d.LicenseId, d.FullName })
                .ToDictionaryAsync(d => d.LicenseId, d => d.FullName, StringComparer.OrdinalIgnoreCase);

            return logs.Select(l => new VerificationLogDto
            {
                LogId = l.LogId,
                LicenseId = l.LicenseId,
                FullName = names.TryGetValue(l.LicenseId, out var name) ? name : null,
                VerificationStatus = l.VerificationStatus,
                CheckedBy = l.CheckedBy,
                CheckedDate = DateTime.SpecifyKind(l.CheckedDate, DateTimeKind.Utc)
            }).ToList();
        }

        private static List<string> FindMismatches(Driver driver, VerifyLicenseRequest request)
        {
            var mismatches = new List<string>();

            if (!string.IsNullOrWhiteSpace(request.FullName) &&
                NormalizeName(request.FullName) != NormalizeName(driver.FullName))
            {
                mismatches.Add("name");
            }

            if (DateHelper.TryParse(request.DateOfBirth, out var scannedDob) &&
                scannedDob != driver.DateOfBirth.Date)
            {
                mismatches.Add("date of birth");
            }

            if (DateHelper.TryParse(request.ExpiryDate, out var scannedExpiry) &&
                scannedExpiry != driver.ExpiryDate.Date)
            {
                mismatches.Add("expiry date");
            }

            return mismatches;
        }

        private static string NormalizeName(string? name)
        {
            if (string.IsNullOrWhiteSpace(name)) return string.Empty;
            return string.Join(' ', name.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries))
                .ToUpperInvariant();
        }

        private static string Truncate(string value, int maxLength)
        {
            return value.Length <= maxLength ? value : value.Substring(0, maxLength);
        }
    }
}

