using Microsoft.EntityFrameworkCore;
using DAFTech.DriverLicenseSystem.Api.Models.Entities;

namespace DAFTech.DriverLicenseSystem.Api.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Driver> Drivers { get; set; }
        public DbSet<VerificationLog> VerificationLogs { get; set; }
    }
}