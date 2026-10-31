using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace DAFTech.DriverLicenseSystem.Api.Models.Entities
{
    public class Driver
    {
        [Key]
        public int DriverId { get; set; }
        public string LicenseId { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public DateTime DateOfBirth { get; set; }
        public string LicenseType { get; set; } = string.Empty;
        public DateTime ExpiryDate { get; set; }
        public string QrRawData { get; set; } = string.Empty;
        public string OcrRawText { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

        [ForeignKey("User")]
        public int RegisteredBy { get; set; }
        public User? User { get; set; }
    }
}