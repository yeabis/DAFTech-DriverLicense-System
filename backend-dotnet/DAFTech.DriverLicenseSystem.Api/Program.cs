using Microsoft.EntityFrameworkCore;
using DAFTech.DriverLicenseSystem.Api.Data;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using DAFTech.DriverLicenseSystem.Api.Services;
using DAFTech.DriverLicenseSystem.Api.Middleware;
using DAFTech.DriverLicenseSystem.Api.Models.Entities;

var builder = WebApplication.CreateBuilder(args);


builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));


builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"] ?? string.Empty))
        };
    });

builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<DriverService>();
builder.Services.AddScoped<VerificationService>();
builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseMiddleware<ExceptionMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
else
{
    app.UseHttpsRedirection();
}
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

using (var scope = app.Services.CreateScope())
{
    try
    {
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        var aaron = context.Users.FirstOrDefault(u => u.Username.ToLower() == "aaron");
        if (aaron == null)
        {
            context.Users.Add(new User
            {
                Username = "aaron",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("123"),
                CreatedDate = DateTime.UtcNow,
                Status = "Active"
            });
        }
        else
        {
            aaron.PasswordHash = BCrypt.Net.BCrypt.HashPassword("123");
            aaron.Status = "Active";
        }

        var officer1 = context.Users.FirstOrDefault(u => u.Username.ToLower() == "officer1");
        if (officer1 == null)
        {
            context.Users.Add(new User
            {
                Username = "officer1",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("password123"),
                CreatedDate = DateTime.UtcNow,
                Status = "Active"
            });
        }
        else
        {
            officer1.PasswordHash = BCrypt.Net.BCrypt.HashPassword("password123");
            officer1.Status = "Active";
        }

        context.SaveChanges();

        Console.ForegroundColor = ConsoleColor.Green;
        Console.WriteLine("[AUTH SEED] Active accounts ready in database:");
        foreach (var u in context.Users.Where(u => u.Status == "Active").Select(u => u.Username))
        {
            Console.WriteLine($"   -> Username: '{u}'");
        }
        Console.ResetColor();
    }
    catch (Exception ex)
    {
        Console.ForegroundColor = ConsoleColor.Red;
        Console.WriteLine($"[AUTH SEED ERROR] Could not connect to database or seed users: {ex.Message}");
        Console.ResetColor();
    }
}

app.Run();
