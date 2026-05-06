using System.ComponentModel.DataAnnotations;

namespace GerenciamentoCliente.Adm.Clientes;

public class ClienteAtualizarViewModel : ClienteCadastroViewModel
{
    [Required] public int Id { get; set; }
}