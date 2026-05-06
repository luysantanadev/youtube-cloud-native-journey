namespace GerenciamentoCliente.Adm.Models;

public class Cidade
{
    public Cidade(int id, int estadoId, string nome)
    {
        Id = id;
        EstadoId = estadoId;
        Nome = nome;
    }

    public int Id { get; private set; }
    public int EstadoId { get; private set; }
    public string Nome { get; private set; }

    public Estado Estado { get; private set; }
}