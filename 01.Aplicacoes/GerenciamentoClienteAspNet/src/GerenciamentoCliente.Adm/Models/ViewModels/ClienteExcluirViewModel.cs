using System.ComponentModel.DataAnnotations;

namespace GerenciamentoCliente.Adm.Models.ViewModels;

public class ClienteExcluirViewModel
{
    [Required] public int Id { get; set; }

    [Display(Name = "Nome Completo")] public string NomeCompleto { get; set; }

    [Display(Name = "CPF")] public string Cpf { get; set; }

    [Display(Name = "Email")] public string Email { get; set; }
}