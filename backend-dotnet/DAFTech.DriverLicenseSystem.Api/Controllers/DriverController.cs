using DAFTech.DriverLicenseSystem.Api.Helpers;
using DAFTech.DriverLicenseSystem.Api.Models.Dtos;
using DAFTech.DriverLicenseSystem.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DAFTech.DriverLicenseSystem.Api.Controllers
{
    [ApiController]
    [Route("api/drivers")]
    [Authorize]
    public class DriverController : ControllerBase
    {
        private readonly DriverService _driverService;

        public DriverController(DriverService driverService)
        {
            _driverService = driverService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> RegisterDriver([FromBody] RegisterDriverRequest request)
        {
            var userId = User.GetUserId();
            if (userId == null)
            {
                return Unauthorized(new { message = "Your session is not valid. Please log in again." });
            }

            var result = await _driverService.RegisterAsync(request, userId.Value);

            switch (result.Outcome)
            {
                case RegisterOutcome.Created:
                    return StatusCode(201, new RegisterDriverResponse
                    {
                        Message = "License successfully registered!",
                        Driver = DriverResponse.From(result.Driver!)
                    });

                case RegisterOutcome.Duplicate:
                    return Conflict(new RegisterDriverResponse
                    {
                        Message = "License already registered",
                        Driver = DriverResponse.From(result.Driver!)
                    });

                default:
                    return BadRequest(new
                    {
                        message = string.Join(" ", result.Errors),
                        errors = result.Errors
                    });
            }
        }

        [HttpGet]
        public async Task<IActionResult> GetAllDrivers()
        {
            return Ok(await _driverService.GetAllAsync());
        }
    }
}
