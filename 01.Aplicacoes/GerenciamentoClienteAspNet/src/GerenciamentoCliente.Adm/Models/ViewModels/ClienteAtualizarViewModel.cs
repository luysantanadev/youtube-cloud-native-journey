using System.ComponentModel.DataAnnotations;

namespace GerenciamentoCliente.Adm.Models.ViewModels;

public class ClienteAtualizarViewModel : ClienteCadastroViewModel
{
    [Required] public int Id { get; set; }
}