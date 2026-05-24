using Flunt.Notifications;
using GerenciamentoCliente.Domain.Clientes;

namespace GerenciamentoCliente.App.Clientes;

public sealed class ClienteServico : IClienteServico
{
    private readonly IClienteRepositorio _repositorio;

    public ClienteServico(IClienteRepositorio repositorio)
    {
        _repositorio = repositorio;
    }


    public async Task<ClientePaginacaoViewModel> Buscar(ClientePaginacaoParametros parametros, CancellationToken token)
    {
        var dados = await _repositorio.Buscar(parametros, token);
        return new ClientePaginacaoViewModel
        {
            Itens = dados.data.Select(x => new ClienteIndexViewModel
            {
                Id = x.Id,
                Cpf = x.Cpf,
                NomeCompleto = x.NomeCompleto,
                Email = x.Email,
                Nascimento = x.Nascimento,
                Telefone = x.Telefone
            }).ToList(),
            Pagina = parametros.Pagina,
            TamanhoPagina = parametros.TamanhoPagina,
            Consulta = parametros.Consulta,
            TotalItems = dados.total,
            TotalPages = dados.total / parametros.TamanhoPagina
        };
    }

    public async Task<ClienteDetalhesViewModel?> Buscar(int id, CancellationToken token)
    {
        var cliente = await _repositorio.Buscar(id, token);
        if (cliente == null)
            return null;

        return new ClienteDetalhesViewModel
        {
            Id = cliente.Id,
            Cpf = cliente.Cpf,
            NomeCompleto = cliente.NomeCompleto,
            Email = cliente.Email,
            Nascimento = cliente.Nascimento,
            Telefone = cliente.Telefone,
            Enderecos = cliente.Enderecos.Select(x => new EnderecoDetalhesViewModel
            {
                Id = x.Id,
                Logradouro = x.Logradouro,
                Numero = x.Numero,
                Complemento = x.Complemento,
                Bairro = x.Bairro,
                CidadeNome = x.Cidade.Nome,
                EstadoSigla = x.Cidade.Estado.Nome
            }).ToList()
        };
    }

    public async Task<IReadOnlyCollection<Notification>> Cadastrar(ClienteCadastroViewModel cliente,
        CancellationToken token)
    {
        var novoCliente = new Cliente(cliente.NomeCompleto, cliente.Cpf, cliente.Nascimento, cliente.Email,
            cliente.Telefone);
        if (novoCliente.IsValid)
            await _repositorio.Criar(novoCliente, token);
        return novoCliente.Notifications;
    }

    public async Task<IReadOnlyCollection<Notification>> Atualizar(ClienteAtualizarViewModel cliente,
        CancellationToken token)
    {
        var clienteExistente = await _repositorio.Buscar(cliente.Id, token);
        if (clienteExistente == null)
            return new List<Notification>();
        clienteExistente.AtualizarNome(cliente.NomeCompleto);
        clienteExistente.AtualizarEmail(cliente.Email);
        clienteExistente.AtualizarNascimento(cliente.Nascimento);
        clienteExistente.AtualizarTelefone(cliente.Telefone);
        if (clienteExistente.IsValid)
            await _repositorio.Atualizar(clienteExistente, token);
        return clienteExistente.Notifications;
    }

    public async Task<bool> Excluir(int id, CancellationToken token)
    {
        return await _repositorio.Excluir(id, token);
    }
}