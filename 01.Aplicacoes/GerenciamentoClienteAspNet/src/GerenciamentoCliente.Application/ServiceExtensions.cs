using GerenciamentoCliente.Application.Clientes;
using GerenciamentoCliente.Data;
using GerenciamentoCliente.Data.Clientes;
using GerenciamentoCliente.Domain.Clientes;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace GerenciamentoCliente.Application;

public static class ServiceExtensions
{

    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddDbContext<GerenciamentoClienteContexto>(options =>
        {
            var connectionString = Environment.GetEnvironmentVariable("PGSQL_CONNECTION_STRING");
            options.UseLowerCaseNamingConvention();
            options.UseNpgsql(connectionString);
        });
        
        services.AddScoped<IClienteRepositorio, ClienteRepositorio>();
        services.AddScoped<IClienteServico, ClienteServico>();

        return services;
    }
}