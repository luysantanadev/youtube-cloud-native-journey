using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GerenciamentoCliente.Adm.Models;


public class GerenciamentoClienteContexto : DbContext
{
    public GerenciamentoClienteContexto(DbContextOptions<GerenciamentoClienteContexto> options) : base(options)
    {
    }

    public DbSet<Cliente> Clientes { get; set; }
    public DbSet<Endereco> Enderecos { get; set; }
    public DbSet<Cidade> Cidades { get; set; }
    public DbSet<Estado> Estados { get; set; }

    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        base.ConfigureConventions(configurationBuilder);
    }

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

internal class ClienteConfiguracao : IEntityTypeConfiguration<Cliente>
{
    public void Configure(EntityTypeBuilder<Cliente> builder)
    {
        builder.HasKey(c => c.Id);
        builder.Property(c => c.NomeCompleto).IsRequired().HasMaxLength(100);
        builder.Property(c => c.Cpf).IsRequired().HasMaxLength(11);
        builder.Property(c => c.Nascimento).IsRequired();
        builder.Property(c => c.Email).IsRequired().HasMaxLength(100);
        builder.Property(c => c.Telefone).IsRequired().HasMaxLength(11);
        builder.HasMany(c => c.Enderecos)
            .WithOne(e => e.Cliente)
            .HasForeignKey(e => e.ClienteId)
            .OnDelete(DeleteBehavior.Cascade);
        
        builder.HasIndex(x => x.NomeCompleto).HasMethod("GIN").HasOperators("gin_trgm_ops");
        builder.HasIndex(x => x.Email).HasMethod("GIN").HasOperators("gin_trgm_ops");
        builder.HasIndex(x => x.Cpf).HasMethod("GIN").HasOperators("gin_trgm_ops");
        
        builder.Ignore(c => c.Notifications);
        builder.Ignore(c => c.IsValid);
    }
}

internal class EnderecoConfiguracao : IEntityTypeConfiguration<Endereco>
{
    public void Configure(EntityTypeBuilder<Endereco> builder)
    {
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Logradouro).IsRequired().HasMaxLength(200);
        builder.Property(e => e.Numero).IsRequired().HasMaxLength(20);
        builder.Property(e => e.Complemento).HasMaxLength(100);
        builder.Property(e => e.Referencia).HasMaxLength(100);
        builder.Property(e => e.Bairro).IsRequired().HasMaxLength(100);
        builder.Property(e => e.Cep).IsRequired().HasMaxLength(8);
        builder.HasOne(e => e.Cliente)
            .WithMany(c => c.Enderecos)
            .HasForeignKey(e => e.ClienteId)
            .OnDelete(DeleteBehavior.Cascade);
        
        builder.HasIndex(x => x.Logradouro).HasMethod("GIN").HasOperators("gin_trgm_ops");
        builder.HasIndex(x => x.Bairro).HasMethod("GIN").HasOperators("gin_trgm_ops");
        
        builder.Ignore(c => c.Notifications);
        builder.Ignore(c => c.IsValid);
    }
}

internal class EstadoConfiguracao: IEntityTypeConfiguration<Estado>
{
    public void Configure(EntityTypeBuilder<Estado> builder)
    {
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Nome).IsRequired().HasMaxLength(100);
        builder.Property(e => e.Sigla).IsRequired().HasMaxLength(2);
        builder.HasMany(e => e.Cidades)
            .WithOne(c => c.Estado)
            .HasForeignKey(c => c.EstadoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}

internal class CidadeConfiguracao: IEntityTypeConfiguration<Cidade>
{
    public void Configure(EntityTypeBuilder<Cidade> builder)
    {
        builder.HasKey(c => c.Id);
        builder.Property(c => c.Nome).IsRequired().HasMaxLength(100);
        builder.HasOne(c => c.Estado)
            .WithMany(e => e.Cidades)
            .HasForeignKey(c => c.EstadoId)
            .OnDelete(DeleteBehavior.Cascade);
        
        builder.HasIndex(x => x.Nome).HasMethod("GIN").HasOperators("gin_trgm_ops");
    }
}