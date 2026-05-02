namespace GerenciamentoCliente.Adm.Models.ViewModels;

public class ClienteCadastroViewModel
{
    public string NomeCompleto { get; set; }
    public string Cpf { get; set; }
    public DateOnly Nascimento { get; set; }
    public string Email { get; set; }
    public string Telefone { get; set; }
}