namespace GerenciamentoCliente.Domain.Enderecos;

public class Estado
{
    public Estado(int id, string sigla, string nome)
    {
        Id = id;
        Sigla = sigla;
        Nome = nome;
    }

    private List<Cidade> _cidades { get; } = new();

    public int Id { get; private set; }
    public string Sigla { get; private set; }
    public string Nome { get; private set; }

    public IReadOnlyList<Cidade> Cidades => _cidades.AsReadOnly();
}