using DAFTech.DriverLicenseSystem.Api.Helpers;
using DAFTech.DriverLicenseSystem.Api.Models.Dtos;
using DAFTech.DriverLicenseSystem.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DAFTech.DriverLicenseSystem.Api.Controllers
{
    [ApiController]
    [Route("api/verification")]
    [Authorize]
    public class VerificationController : ControllerBase
    {
        private readonly VerificationService _verificationService;

        public VerificationController(VerificationService verificationService)
        {
            _verificationService = verificationService;
        }

        [HttpPost("verify")]
        public async Task<IActionResult> Verify([FromBody] VerifyLicenseRequest request)
        {
            var userId = User.GetUserId();
            if (userId == null)
            {
                return Unauthorized(new { message = "Your session is not valid. Please log in again." });
            }

            if (string.IsNullOrWhiteSpace(request.LicenseId))
            {
                return BadRequest(new { message = "A license ID is required." });
            }

            var result = await _verificationService.VerifyAsync(request, userId.Value, User.GetUsername());
            return Ok(result);
        }

        [HttpGet("logs")]
        public async Task<IActionResult> GetLogs([FromQuery] int take = 100)
        {
            return Ok(await _verificationService.GetLogsAsync(take));
        }
    }
}

