using GerenciamentoCliente.Domain.Clientes;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace GerenciamentoCliente.Data.Clientes;

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