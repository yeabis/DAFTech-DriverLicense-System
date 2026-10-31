using System;
using System.ComponentModel.DataAnnotations;

namespace DAFTech.DriverLicenseSystem.Api.Models.Entities
{
    public class User
    {
        [Key]
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
        public string Status { get; set; } = "Active";
    }
}