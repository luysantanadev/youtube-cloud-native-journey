using dotenv.net;
using GerenciamentoCliente.Adm.Clientes;
using GerenciamentoCliente.Adm.Models;
using Microsoft.EntityFrameworkCore;

namespace GerenciamentoCliente.Adm;

public class Program
{
    public static void Main(string[] args)
    {
        DotEnv.Load();

        var builder = WebApplication.CreateBuilder(args);

        builder.Services.AddDbContext<GerenciamentoClienteContexto>(options =>
        {
            var connectionString = Environment.GetEnvironmentVariable("PGSQL_CONNECTION_STRING");
            options.UseLowerCaseNamingConvention();
            options.UseNpgsql(connectionString);
        });

        builder.Services.AddScoped<IClienteRepositorio, ClienteRepositorio>();
        builder.Services.AddScoped<IClienteServico, ClienteServico>();

        // Add services to the container.
        builder.Services
            .AddControllersWithViews()
            .AddRazorRuntimeCompilation();

        var app = builder.Build();

        // Configure the HTTP request pipeline.
        if (!app.Environment.IsDevelopment())
        {
            app.UseExceptionHandler("/Home/Error");
        }

        app.UseRouting();

        app.UseAuthorization();

        app.MapStaticAssets();
        app.MapControllerRoute(
                name: "default",
                pattern: "{controller=Home}/{action=Index}/{id?}")
            .WithStaticAssets();

        app.Run();
    }
}