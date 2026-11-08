using System.Security.Claims;

namespace DAFTech.DriverLicenseSystem.Api.Helpers
{
    public static class ClaimsPrincipalExtensions
    {
        public static int? GetUserId(this ClaimsPrincipal principal)
        {
            var raw = principal.FindFirst("UserId")?.Value;
            return int.TryParse(raw, out var id) ? id : (int?)null;
        }

        public static string GetUsername(this ClaimsPrincipal principal)
        {
            return principal.FindFirst("Username")?.Value ?? string.Empty;
        }
    }
}

