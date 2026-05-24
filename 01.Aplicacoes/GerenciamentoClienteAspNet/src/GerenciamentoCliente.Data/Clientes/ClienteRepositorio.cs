using GerenciamentoCliente.Data.Shared;
using GerenciamentoCliente.Domain.Clientes;
using Microsoft.EntityFrameworkCore;

namespace GerenciamentoCliente.Data.Clientes;

public sealed class ClienteRepositorio : Repositorio<Cliente>, IClienteRepositorio
{
    public ClienteRepositorio(GerenciamentoClienteContexto contexto) : base(contexto)
    {
    }

    public override Task<Cliente?> Buscar(int id, CancellationToken token)
    {
        return Contexto
            .Clientes
            .Include(x => x.Enderecos)
            .ThenInclude(x => x.Cidade)
            .ThenInclude(x => x.Estado)
            .Where(x => x.Id == id)
            .FirstOrDefaultAsync(token);
    }
}