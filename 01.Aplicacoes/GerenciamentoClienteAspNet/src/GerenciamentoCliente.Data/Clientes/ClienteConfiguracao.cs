using GerenciamentoCliente.Domain.Clientes;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GerenciamentoCliente.Data.Clientes;

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