using GerenciamentoCliente.Domain.Enderecos;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GerenciamentoCliente.Data.Enderecos;

internal class EstadoConfiguracao : IEntityTypeConfiguration<Estado>
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