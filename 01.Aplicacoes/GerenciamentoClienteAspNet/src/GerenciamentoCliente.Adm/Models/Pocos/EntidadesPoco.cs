namespace GerenciamentoCliente.Adm.Models.Pocos;

public class ClientePoco
{
    public int Id { get; set; }
    public string NomeCompleto { get; set; } = string.Empty;
    public string Cpf { get; set; } = string.Empty;
    public DateOnly Nascimento { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Telefone { get; set; } = string.Empty;
    public List<EnderecoPoco> Enderecos { get; set; } = [];
}

public class EnderecoPoco
{
    public int Id { get; set; }
    public int ClienteId { get; set; }
    public int CidadeId { get; set; }
    public string Logradouro { get; set; } = string.Empty;
    public string Numero { get; set; } = string.Empty;
    public string? Complemento { get; set; }
    public string? Referencia { get; set; }
    public string Bairro { get; set; } = string.Empty;
    public string Cep { get; set; } = string.Empty;
    public ClientePoco? Cliente { get; set; }
    public CidadePoco? Cidade { get; set; }
}

public class CidadePoco
{
    public int Id { get; set; }
    public int EstadoId { get; set; }
    public string Nome { get; set; } = string.Empty;
    public EstadoPoco? Estado { get; set; }
}

public class EstadoPoco
{
    public int Id { get; set; }
    public string Sigla { get; set; } = string.Empty;
    public string Nome { get; set; } = string.Empty;
    public List<CidadePoco> Cidades { get; set; } = [];
}