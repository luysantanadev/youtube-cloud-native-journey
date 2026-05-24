namespace GerenciamentoCliente.Domain.Shared;

public interface IRepositorio<TEntidade> where TEntidade : class, new()
{
    Task<(int total, IEnumerable<TEntidade> data)> Buscar(PaginacaoParametros<TEntidade> parametros,
        CancellationToken token);
    Task<TEntidade?> Buscar(int id, CancellationToken token);
    Task Criar(TEntidade entidade, CancellationToken token);
    Task Atualizar(TEntidade entidade, CancellationToken token);
    Task<bool> Excluir(int id, CancellationToken token);
}