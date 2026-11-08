using System.Globalization;

namespace DAFTech.DriverLicenseSystem.Api.Helpers
{
    public static class DateHelper
    {
        private static readonly string[] Formats =
        {
            "d-M-yyyy", "d/M/yyyy", "d.M.yyyy",
            "yyyy-M-d", "yyyy/M/d", "yyyy.M.d"
        };

        public static bool TryParse(string? raw, out DateTime date)
        {
            date = default;
            if (string.IsNullOrWhiteSpace(raw)) return false;

            var value = raw.Trim();
            DateTime parsed;

            if (!DateTime.TryParseExact(value, Formats, CultureInfo.InvariantCulture,
                    DateTimeStyles.None, out parsed))
            {
                if (!DateTime.TryParse(value, CultureInfo.InvariantCulture,
                        DateTimeStyles.None, out parsed))
                {
                    return false;
                }
            }

            if (parsed.Year < 1900 || parsed.Year > 2100) return false;

            date = parsed.Date;
            return true;
        }

        public static string ToIso(DateTime date) => date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
    }
}

