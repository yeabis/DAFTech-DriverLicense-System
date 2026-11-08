using DAFTech.DriverLicenseSystem.Api.Models.Dtos;
using DAFTech.DriverLicenseSystem.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace DAFTech.DriverLicenseSystem.Api.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly AuthService _authService;
        private readonly IWebHostEnvironment _environment;

        public AuthController(AuthService authService, IWebHostEnvironment environment)
        {
            _authService = authService;
            _environment = environment;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var username = (request.Username ?? string.Empty).Trim();
            var password = request.Password ?? string.Empty;

            if (username.Length == 0 || password.Length == 0)
            {
                return BadRequest(new { message = "Username and password are required." });
            }

            var result = await _authService.LoginUser(username, password);
            if (result == null)
            {
                return Unauthorized(new { message = "Invalid username or password." });
            }

            return Ok(result);
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterUserRequest request)
        {
            if (!_environment.IsDevelopment())
            {
                return NotFound();
            }

            var username = (request.Username ?? string.Empty).Trim();
            var password = request.Password ?? string.Empty;

            if (username.Length < 3 || username.Length > 50)
            {
                return BadRequest(new { message = "Username must be 3 to 50 characters." });
            }
            if (password.Length < 6)
            {
                return BadRequest(new { message = "Password must be at least 6 characters." });
            }

            var user = await _authService.RegisterUser(username, password);
            if (user == null)
            {
                return Conflict(new { message = "That username is already taken." });
            }

            return StatusCode(201, new { userId = user.UserId, username = user.Username });
        }
    }
}
