using System.ComponentModel.DataAnnotations;
using GerenciamentoCliente.Application.Shared;

namespace GerenciamentoCliente.Application.Clientes;

public class ClienteCadastroViewModel
{
    [Required(ErrorMessage = "O nome completo é obrigatório")]
    [StringLength(100, MinimumLength = 3, ErrorMessage = "O nome completo deve conter entre 3 e 100 caracteres")]
    [Display(Name = "Nome Completo")]
    public string NomeCompleto { get; set; }

    [Required]
    [Cpf]
    [Display(Name = "CPF")]
    public string Cpf { get; set; }

    [Required]
    [DataType(DataType.Date, ErrorMessage = "A data de nascimento deve ser uma data válida")]
    public DateOnly Nascimento { get; set; }

    [Required]
    [EmailAddress(ErrorMessage = "O email deve ser um endereço de email válido")]
    [Display(Name = "E-mail")]
    public string Email { get; set; }

    [Required]
    [Telefone]
    [Display(Name = "Telefone")]
    public string Telefone { get; set; }
}