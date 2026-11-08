using DAFTech.DriverLicenseSystem.Api.Data;
using DAFTech.DriverLicenseSystem.Api.Models.Dtos;
using DAFTech.DriverLicenseSystem.Api.Models.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace DAFTech.DriverLicenseSystem.Api.Services
{
    public class AuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _config;

        public AuthService(ApplicationDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        public async Task<User?> RegisterUser(string username, string rawPassword)
        {
            if (await _context.Users.AnyAsync(u => u.Username == username)) return null;

            var user = new User
            {
                Username = username,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(rawPassword)
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return user;
        }

        public async Task<LoginResponse?> LoginUser(string username, string rawPassword)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username.ToLower() == username.ToLower());

            if (user == null)
            {
                Console.WriteLine($"[AUTH FAIL] User '{username}' not found in database.");
                return null;
            }

            if (!string.Equals(user.Status, "Active", StringComparison.OrdinalIgnoreCase))
            {
                Console.WriteLine($"[AUTH FAIL] User '{username}' account is '{user.Status}', not Active.");
                return null;
            }

            if (!BCrypt.Net.BCrypt.Verify(rawPassword, user.PasswordHash))
            {
                Console.WriteLine($"[AUTH FAIL] Password does not match for user '{username}'.");
                return null;
            }

            Console.WriteLine($"[AUTH SUCCESS] User '{user.Username}' authenticated successfully.");

            var now = DateTime.UtcNow;
            var expires = now.AddHours(2);

            return new LoginResponse
            {
                Token = GenerateJwtToken(user, expires),
                UserId = user.UserId,
                Username = user.Username,
                LoginDate = now,
                ExpiresAt = expires
            };
        }

        private string GenerateJwtToken(User user, DateTime expires)
        {
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Username),
                new Claim("UserId", user.UserId.ToString()),
                new Claim("Username", user.Username),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: expires,
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
