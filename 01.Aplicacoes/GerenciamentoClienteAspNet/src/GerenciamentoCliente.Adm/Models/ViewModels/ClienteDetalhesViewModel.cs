using System.ComponentModel.DataAnnotations;

namespace GerenciamentoCliente.Adm.Models.ViewModels;

public class ClienteDetalhesViewModel
{
    [Display(Name = "ID")] public int Id { get; set; }

    [Display(Name = "Nome Completo")] public string NomeCompleto { get; set; }

    [Display(Name = "CPF")] public string Cpf { get; set; }

    [Display(Name = "Data de Nascimento")] public DateOnly Nascimento { get; set; }

    [Display(Name = "Email")] public string Email { get; set; }

    [Display(Name = "Telefone")] public string Telefone { get; set; }

    [Display(Name = "Endereços")]
    public IReadOnlyList<EnderecoDetalhesViewModel> Enderecos { get; set; } = new List<EnderecoDetalhesViewModel>();
}