using System.Linq.Expressions;
using Flunt.Notifications;
using GerenciamentoCliente.Adm.Models;
using GerenciamentoCliente.Adm.Shared;
using Microsoft.EntityFrameworkCore;

namespace GerenciamentoCliente.Adm.Clientes;

public interface IClienteRepositorio : IRepositorio<Cliente>
{
}

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
public interface IClienteServico
{
    Task<ClientePaginacaoViewModel> Buscar(ClientePaginacaoParametros parametros, CancellationToken token);
    Task<ClienteDetalhesViewModel?> Buscar(int id, CancellationToken token);
    Task<IReadOnlyCollection<Notification>> Cadastrar(ClienteCadastroViewModel cliente, CancellationToken token);
    Task<IReadOnlyCollection<Notification>> Atualizar(ClienteAtualizarViewModel cliente, CancellationToken token);
    Task<bool> Excluir(int id, CancellationToken token);
}

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