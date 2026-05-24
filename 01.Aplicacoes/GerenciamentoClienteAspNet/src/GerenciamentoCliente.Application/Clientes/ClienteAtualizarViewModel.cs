using System.ComponentModel.DataAnnotations;

namespace GerenciamentoCliente.App.Clientes;

public class ClienteAtualizarViewModel : ClienteCadastroViewModel
{
    [Required] public int Id { get; set; }
}