namespace GerenciamentoCliente.Application.Clientes;

public class ClienteIndexViewModel
{
    public int Id { get; set; }
    public string NomeCompleto { get; set; } = string.Empty;
    public string Cpf { get; set; } = string.Empty;
    public DateOnly Nascimento { get; set; }
    public string Email { get; set; } = string.Empty;
    public string Telefone { get; set; } = string.Empty;
}