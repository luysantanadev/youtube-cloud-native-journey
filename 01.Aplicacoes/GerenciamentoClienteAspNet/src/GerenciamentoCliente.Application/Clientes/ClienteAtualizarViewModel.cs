using System.ComponentModel.DataAnnotations;

namespace GerenciamentoCliente.Application.Clientes;

public class ClienteAtualizarViewModel : ClienteCadastroViewModel
{
    [Required] public int Id { get; set; }
}