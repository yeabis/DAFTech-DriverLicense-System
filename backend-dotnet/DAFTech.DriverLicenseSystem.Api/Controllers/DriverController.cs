using Microsoft.AspNetCore.Mvc;
using DAFTech.DriverLicenseSystem.Api.Data;
using DAFTech.DriverLicenseSystem.Api.Models.Entities;

namespace DAFTech.DriverLicenseSystem.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DriverController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public DriverController(ApplicationDbContext context)
        {
            _context = context;
        }

       
        [HttpPost("register")]
        public async Task<IActionResult> RegisterDriver([FromBody] Driver driver)
        {
            try
            {
                driver.CreatedDate = DateTime.UtcNow;

                _context.Drivers.Add(driver);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "License successfully registered!",
                    driverId = driver.DriverId
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error saving to database", details = ex.Message });
            }
        }
        [HttpGet]
        public IActionResult GetAllDrivers()
        {
            var drivers = _context.Drivers.ToList();
            return Ok(drivers);
        }
    }
}