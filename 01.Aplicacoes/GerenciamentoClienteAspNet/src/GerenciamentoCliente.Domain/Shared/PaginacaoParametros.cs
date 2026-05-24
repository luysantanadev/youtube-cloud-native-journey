using System.Linq.Expressions;

namespace GerenciamentoCliente.Domain.Shared;

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