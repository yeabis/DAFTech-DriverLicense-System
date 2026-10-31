using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DAFTech.DriverLicenseSystem.Api.Models.Entities
{
    public class VerificationLog
    {
        [Key]
        public int LogId { get; set; }
        public string LicenseId { get; set; } = string.Empty;
        public string VerificationStatus { get; set; } = string.Empty;

        [ForeignKey("User")]
        public int CheckedBy { get; set; }
        public User? User { get; set; }
        public DateTime CheckedDate { get; set; } = DateTime.UtcNow;
    }
}