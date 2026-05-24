using GerenciamentoCliente.Domain.Enderecos;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GerenciamentoCliente.Data.Enderecos;

internal class CidadeConfiguracao : IEntityTypeConfiguration<Cidade>
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