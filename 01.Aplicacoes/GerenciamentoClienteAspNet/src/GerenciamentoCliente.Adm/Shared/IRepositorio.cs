using System.Linq.Expressions;
using GerenciamentoCliente.Adm.Models;
using Microsoft.EntityFrameworkCore;

namespace GerenciamentoCliente.Adm.Shared;

public abstract class PaginacaoParametros<TEntidade> where TEntidade : class, new()
{
    private bool _paginacaoPreparada;

    public string? Consulta { get; set; }
    public int Pagina { get; set; } = 1;
    public int TamanhoPagina { get; set; } = 10;

    public abstract Expression<Func<TEntidade, bool>> Filtro();
    public abstract Expression<Func<TEntidade, object>> Ordenacao();
    public abstract Expression<Func<TEntidade, TEntidade>> Projecao();

    public void PrepararPaginacao()
    {
        if (_paginacaoPreparada)
            return;

        _paginacaoPreparada = true;
        Pagina = Pagina <= 0 ? 0 : Pagina - 1;
        TamanhoPagina = TamanhoPagina <= 0 ? 10 : TamanhoPagina > 100 ? 100 : TamanhoPagina;
    }
}

public interface IRepositorio<TEntidade> where TEntidade : class, new()
{
    Task<(int total, IEnumerable<TEntidade> data)> Buscar(PaginacaoParametros<TEntidade> parametros,
        CancellationToken token);

    Task<TEntidade?> Buscar(int id, CancellationToken token);
    Task Criar(TEntidade entidade, CancellationToken token);
    Task Atualizar(TEntidade entidade, CancellationToken token);
    Task<bool> Excluir(int id, CancellationToken token);
}

public class Repositorio<TEntidade> : IRepositorio<TEntidade> where TEntidade : class, new()
{
    public Repositorio(GerenciamentoClienteContexto contexto)
    {
        Contexto = contexto;
    }

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

    public virtual async Task<TEntidade?> Buscar(int id, CancellationToken token)
    {
        return await Contexto.Set<TEntidade>().FindAsync([id], token);
    }

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