using System.Linq.Expressions;
using GerenciamentoCliente.Domain.Shared;
using Microsoft.EntityFrameworkCore;

namespace GerenciamentoCliente.Data.Shared;

public class Repositorio<TEntidade> : IRepositorio<TEntidade> where TEntidade : class, new()
{
    public Repositorio(GerenciamentoClienteContexto contexto) => Contexto = contexto;

    protected GerenciamentoClienteContexto Contexto { get; }


    public async Task<(int total, IEnumerable<TEntidade> data)>
        Buscar(PaginacaoParametros<TEntidade> parametros, CancellationToken token)
    {
        var query = Contexto
            .Set<TEntidade>()
            .AsQueryable()
            .AsNoTracking()
            .Where(parametros.Filtro());
        var totalItems = await query.CountAsync(token);
        parametros.PrepararPaginacao();
        var result = await query
            .OrderBy(parametros.Ordenacao())
            .Skip(parametros.Pagina)
            .Take(parametros.TamanhoPagina)
            .Select(parametros.Projecao())
            .ToListAsync(token);

        return (totalItems, result);
    }

    public virtual async Task<TEntidade?> Buscar(int id, CancellationToken token) => 
        await Contexto.Set<TEntidade>().FindAsync([id], token);

    public Task Criar(TEntidade entidade, CancellationToken token)
    {
        Contexto.Set<TEntidade>().Add(entidade);
        return Contexto.SaveChangesAsync(token);
    }

    public Task Atualizar(TEntidade entidade, CancellationToken token)
    {
        Contexto.Set<TEntidade>().Update(entidade);
        return Contexto.SaveChangesAsync(token);
    }

    public async Task<bool> Excluir(int id, CancellationToken token)
    {
        var entidade = await Contexto.Set<TEntidade>().FindAsync([id], token);
        if (entidade is null)
            return false;
        Contexto.Set<TEntidade>().Remove(entidade);
        return await Contexto.SaveChangesAsync(token) > 0;
    }
}