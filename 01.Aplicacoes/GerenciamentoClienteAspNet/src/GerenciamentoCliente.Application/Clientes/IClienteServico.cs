using Flunt.Notifications;

namespace GerenciamentoCliente.Application.Clientes;

public interface IClienteServico
{
    Task<ClientePaginacaoViewModel> Buscar(ClientePaginacaoParametros parametros, CancellationToken token);
    Task<ClienteDetalhesViewModel?> Buscar(int id, CancellationToken token);
    Task<IReadOnlyCollection<Notification>> Cadastrar(ClienteCadastroViewModel cliente, CancellationToken token);
    Task<IReadOnlyCollection<Notification>> Atualizar(ClienteAtualizarViewModel cliente, CancellationToken token);
    Task<bool> Excluir(int id, CancellationToken token);
}