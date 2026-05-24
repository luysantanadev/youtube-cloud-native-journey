using GerenciamentoCliente.Data.Clientes;
using GerenciamentoCliente.Data.Enderecos;
using GerenciamentoCliente.Domain.Clientes;
using GerenciamentoCliente.Domain.Enderecos;
using Microsoft.EntityFrameworkCore;

namespace GerenciamentoCliente.Data;

public class GerenciamentoClienteContexto : DbContext
{
    public GerenciamentoClienteContexto(DbContextOptions<GerenciamentoClienteContexto> options) : base(options)
    {
    }

    public DbSet<Cliente> Clientes { get; set; }
    public DbSet<Endereco> Enderecos { get; set; }
    public DbSet<Cidade> Cidades { get; set; }
    public DbSet<Estado> Estados { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.HasPostgresExtension("pg_trgm");
        modelBuilder.ApplyConfiguration(new ClienteConfiguracao());
        modelBuilder.ApplyConfiguration(new EnderecoConfiguracao());
        modelBuilder.ApplyConfiguration(new CidadeConfiguracao());
        modelBuilder.ApplyConfiguration(new EstadoConfiguracao());
    }
}