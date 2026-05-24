using System.Linq.Expressions;
using GerenciamentoCliente.App.Shared;
using GerenciamentoCliente.Domain.Clientes;
using GerenciamentoCliente.Domain.Shared;
using Microsoft.EntityFrameworkCore;

namespace GerenciamentoCliente.App.Clientes;

public sealed class ClientePaginacaoParametros : PaginacaoParametros<Cliente>
{
    public override Expression<Func<Cliente, bool>> Filtro()
    {
        if (string.IsNullOrWhiteSpace(Consulta))
            return x => true;


        var pesquisa = string.Join("%", Consulta
            .Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToList());

        return x =>
            EF.Functions.ILike(x.NomeCompleto, $"%{pesquisa}%") ||
            EF.Functions.ILike(x.Cpf, $"%{pesquisa}%");
    }

    public override Expression<Func<Cliente, object>> Ordenacao()
    {
        return x => x.NomeCompleto;
    }

    public override Expression<Func<Cliente, Cliente>> Projecao()
    {
        return cliente => cliente;
    }
}

// entidades e viewmodels